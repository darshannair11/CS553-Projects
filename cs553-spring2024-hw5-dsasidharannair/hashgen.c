#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
#include <sys/time.h>
#include <pthread.h>
#include <stdint.h>
#include "blake3.h"
#include <inttypes.h>
#include <errno.h>

#define NONCE_SIZE 6
#define HASH_SIZE 10
#define RECORD_SIZE 16
#define HASH_COUNT_SMALL (1 << 26)
#define HASH_COUNT_BIG (1ULL << 32)

typedef unsigned long long ull;

typedef struct {
    uint8_t hash[HASH_SIZE];
    uint8_t nonce[NONCE_SIZE];
} Record;

struct ThreadArgs {
    int thread_index;
    ull iteration_index;
};

struct WriteThreadArgs1 {
    int i;
    int bucket_start;
};

struct WriteThreadArgs2 {
    int k;
    int i;
    int bucket_start;
};

struct ReadThreadArgs {
    int file_no;
    FILE **inputs;
};

Record *hashes;
pthread_mutex_t global_mutex = PTHREAD_MUTEX_INITIALIZER;
size_t prog_idx = 0;
ull total_hash_count;

int hash_threads,sort_threads,write_threads,max_mem,max_records,write_iter,write_segment,no_files = 0;
bool debug=false;


// Converts string to boolean value
bool convert_string_to_bool(const char *str) {
    if (strcmp(str, "true") == 0 || strcmp(str, "1") == 0) {
        return true;
    } else if (strcmp(str, "false") == 0 || strcmp(str, "0") == 0) {
        return false;
    } else {
        fprintf(stderr, "Invalid boolean string: %s\n", str);
        return false;
    }
}

// prints out the hash passed to the function
void print_hash(const uint8_t *hash, size_t size) {
    for (size_t i = 0; i < size; ++i) {
        printf("%02X", hash[i]);
    }
    printf("\n");
}

// Comapres two records 
int compare(const void *a, const void *b) {
    Record *r1 = (Record *)a;
    Record *r2 = (Record *)b;
    int result=memcmp(r1->hash, r2->hash, HASH_SIZE);
    return result;
}

//Returns the current time
double get_current_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
}

//For multithreading each has is assigned a segement of the array
void *hashing(void *arg){
    struct ThreadArgs *args = (struct ThreadArgs *)arg;
    size_t thread_no = (size_t)(intptr_t)args->thread_index;
    ull x = args->iteration_index;
    int bucket_no = (hash_threads * x) + (int)thread_no;
    size_t hashes_per_thread = max_records / hash_threads;
    size_t start_index = thread_no * hashes_per_thread;
    size_t end_index = (thread_no == hash_threads - 1) ? max_records : (thread_no + 1) * hashes_per_thread;
    // printf("[%zu][HASHGEN]: Starting Hashing from Thread:%zu\n",thread_no,thread_no);
    // printf("Hashing from idx:%zu to idx:%zu\n",start_index,end_index);
    for (size_t i = start_index; i < end_index; i++) {
        ull temp = (x * max_records) + i;
        // printf("The value of the long long unsigned number is: %llu\n",temp);
        for (int j = 0; j < NONCE_SIZE; j++) {
            hashes[i].nonce[j] = (temp >> (j * 8)) & 0xFF;
    }
        blake3_hasher hasher;
        blake3_hasher_init(&hasher);
        blake3_hasher_update(&hasher, hashes[i].nonce, NONCE_SIZE);
        blake3_hasher_finalize(&hasher, hashes[i].hash, HASH_SIZE);
    }
    return NULL;
}

// For multithreading each sort thread is assigned this function to work on a particular segment of the array
void *sorting(void *arg){
    size_t thread_no=(size_t)(intptr_t)arg;
    size_t sort_per_thread = max_records / sort_threads;
    size_t start_index = thread_no * sort_per_thread;
    size_t end_index = (thread_no == sort_threads - 1) ? max_records : (thread_no + 1) * sort_per_thread;
    // printf("[%zu][SORTING]: Starting Sorting from Thread:%zu\n",thread_no,thread_no);
    // printf("Sorting from idx:%zu to idx:%zu\n",start_index,end_index);
    qsort(&hashes[start_index],end_index-start_index,sizeof(Record), compare);
    return NULL;
}

// For multithreading adequate threads are used when number of segments to write is less than write threads
void *writing_write(void *arg){
    struct WriteThreadArgs1 *args = (struct WriteThreadArgs1 *)arg;
    int i = args->i;
    int bucket_start = args->bucket_start;
    size_t thread_no = (size_t)i;
    int bucket_no = bucket_start + i;
    size_t write_per_thread = max_records / sort_threads;
    size_t start_index = thread_no * write_per_thread;
    size_t end_index = (thread_no == sort_threads - 1) ? max_records : (thread_no + 1) * write_per_thread;
    // printf("[%zu][I/O]: Starting Writing from Thread:%zu\n",thread_no,thread_no);
    // printf("Writing from idx:%zu to idx:%zu\n",start_index,end_index);
    char filename[20]; 

    sprintf(filename, "bucket_%d.bin", bucket_no);
    
    FILE *f = fopen(filename, "wb");
    if (f != NULL) {
        fwrite(&hashes[start_index],sizeof(Record),end_index-start_index,f);
        fclose(f);
    } else {
        if(debug){
           printf("ERROR : UNABLE TO OPEN %s.\n", filename); 
        }
    }
    free(arg);
    return NULL; 
}

// For multithreading when the number of sorted segments is greated than the write threads
void *writing_sort(void *arg){
    struct WriteThreadArgs2 *args = (struct WriteThreadArgs2 *)arg;
    int k = args->k;
    int i = args->i;
    int bucket_start = args->bucket_start;
    size_t thread_no = (size_t)i;
    int bucket_no = bucket_start + (write_threads * k) + i;
    size_t write_per_thread = write_segment / write_threads;
    size_t start_index = (k * write_segment) + (thread_no * write_per_thread);
    size_t end_index = (thread_no == write_threads - 1) ? ((k * write_segment) + write_segment) : ((k * write_segment) + ((thread_no + 1) * write_per_thread));
    // printf("[%zu][I/O]: Starting Writing from Thread:%zu\n",thread_no,thread_no);
    // printf("Writing from idx:%zu to idx:%zu\n",start_index,end_index);
    char filename[20]; 

    sprintf(filename, "bucket_%d.bin", bucket_no);
    
    FILE *f = fopen(filename, "wb");
    if (f != NULL) {
        fwrite(&hashes[start_index],sizeof(Record),end_index-start_index,f);
        fclose(f);
    } else {
        if(debug){
           printf("ERROR : UNABLE TO OPEN %s.\n", filename); 
        }
    }
    free(arg);
    return NULL; 
}

int records_per_read;
Record **records;

// Copies records acorss memory
void copy(Record *t, Record *s) {
    memcpy(t, s, sizeof(Record));
}

// Loads records from disk into memory using mutlthreading
void *load(void *arg){
    struct ReadThreadArgs *args = (struct ReadThreadArgs *)arg;
    int file_no = args->file_no;
    FILE **inputs = args->inputs;
    char filename[100];
    sprintf(filename, "bucket_%d.bin", file_no);
    inputs[file_no] = fopen(filename, "rb");
    if (inputs[file_no] == NULL) {
        fprintf(stderr, "Failed to open file: %s. Error: %s\n", filename, strerror(errno));
        free(arg);
        return NULL;
    }
    records[file_no] = (Record *)malloc(records_per_read * sizeof(Record));
    if (records[file_no] == NULL) {
        fprintf(stderr, "Failed to allocate memory for records[%d] array\n",file_no);
        exit(EXIT_FAILURE);
    }
    if (fread(records[file_no], sizeof(Record), records_per_read, inputs[file_no]) != records_per_read) {
        free(records[file_no]);
        records[file_no] = NULL;
        printf("ERROR FILE:%d\n",file_no);
    }
    free(arg);
    return NULL;
}

// External sort where adequate files are loaded into memory and is sorted and wirtten to a single output file
void ExternalSort(int no_files,const char *fname) {
    FILE **inputs = (FILE **)malloc(no_files * sizeof(FILE *));
    if (inputs == NULL) {
        fprintf(stderr, "Failed to allocate memory for inputs array\n");
        exit(EXIT_FAILURE);
    }
    FILE *output;
    int i;

    int max_records= (max_mem * 1048576) / 16;
    int divider = max_records / 2;
    records_per_read = divider / no_files;
    int expected_flushes = total_hash_count / divider ;
    if(debug){
        printf("External Sort Started. Expected %d flushes for %d files\n",expected_flushes,no_files);
    }
    double start_time = get_current_time();

    records = (Record **)malloc(no_files * sizeof(Record *));
    if (records == NULL) {
        fprintf(stderr, "Failed to allocate memory for records array\n");
        exit(EXIT_FAILURE);
    }

    if(no_files < write_threads){
        int max_load_threads = no_files; 
        pthread_t load_threads_array[max_load_threads];

        for (int i = 0; i < max_load_threads ; ++i) {
            struct ReadThreadArgs *args = malloc(sizeof(struct ReadThreadArgs));
            args->file_no = i;
            args->inputs = inputs;
            pthread_create(&load_threads_array[i], NULL, load, args);
        }
        for (int i = 0; i < max_load_threads; ++i) {
            pthread_join(load_threads_array[i], NULL);
        }
    }else{
        int loops = no_files / write_threads ; 
        int max_load_threads = write_threads; 
        for (int j = 0; j < loops; ++j){
            pthread_t load_threads_array[max_load_threads];
            for (int i = 0; i < max_load_threads ; ++i) {
                struct ReadThreadArgs *args = malloc(sizeof(struct ReadThreadArgs));
                args->file_no = (write_threads * j) + i;
                args->inputs = inputs;
                pthread_create(&load_threads_array[i], NULL, load, args);
            }
            for (int i = 0; i < max_load_threads; ++i) {
                pthread_join(load_threads_array[i], NULL);
            }
        }
    }
    int *idx = (int *)malloc(no_files * sizeof(int));
    memset(idx, 0, no_files * sizeof(int));
    char filename[100];
    strcpy(filename,fname);
    output = fopen(filename, "ab");
    Record *sorted = (Record *)malloc(divider * sizeof(Record));
    int sorted_idx = 0;
    int flushes = 0;

    while (1) {
        int small_idx = -1;
        for (i = 0; i < no_files; ++i) {
            if (records[i] != NULL && idx[i] < records_per_read) {
                if (small_idx == -1 || memcmp(records[i][idx[i]].hash, records[small_idx][idx[small_idx]].hash, HASH_SIZE) < 0) {
                    small_idx = i;
                }
            }
        }

        if (small_idx == -1) break;

        copy(&sorted[sorted_idx], records[small_idx] + idx[small_idx]);
        sorted_idx++;
        idx[small_idx]++;

        if(sorted_idx == divider){
            fwrite(sorted, sizeof(Record), divider, output);
            memset(sorted, 0, divider * sizeof(Record));
            sorted_idx = 0;
            flushes++;
            if(debug){
                double end_time = get_current_time();
                double time_taken = end_time - start_time;
                ull hashes_completed = (double)(flushes * divider) ;
                double percent_complete = ((double)flushes / expected_flushes) * 100;
                double throughput = ((double)hashes_completed / time_taken);
                double ETA = ((double)(total_hash_count - hashes_completed)) / throughput;
                printf("[%zu][SORT]: %.2f%% completed, ETA %.1f seconds, %d/%d flushes, %.1f MB/sec\n",prog_idx,percent_complete,ETA,flushes,expected_flushes,(throughput * 16 / (1024 * 1024)));
                prog_idx++;
            }
        }

        if (idx[small_idx] == records_per_read) {
            if (fread(records[small_idx], sizeof(Record), records_per_read, inputs[small_idx]) != records_per_read) {
                free(records[small_idx]);
                records[small_idx] = NULL;
            }
        idx[small_idx] = 0;
        }
    }

    if(sorted_idx > 0){
        fwrite(sorted, sizeof(Record), sorted_idx, output);
    }

    free(sorted);

    fclose(output);
    for (i = 0; i < no_files; ++i) {
        if (inputs[i] != NULL) {
            fclose(inputs[i]);
        }
    }
}

// Deletes the sub files created 
void delete_bins(int no_files){
    char filename[100]; 
    for (int i = 0; i < no_files; ++i) {
        sprintf(filename, "bucket_%d.bin", i);
        remove(filename);
    }   
}

//Main function where everything is executed
int main(int argc, char *argv[]) {
    int opt;
    int file_size;
    char *value = NULL;
    char *filename=NULL;
    int head_record=0;
    int tail_record=0;
    bool check_sort=false;
    bool check_hash=false;
    char *temp;
    char flag_raised='N';
    if(argc == 1){
           fprintf(stderr,"No Argument Provided (Expected at least one argument) "); 
        }

    while ((opt = getopt(argc, argv, "f:p:r:d:v:b:h:t:o:i:m:s:")) != -1) {
        switch (opt) {
            case 'h':
                printf("Help:\n");
                printf("\t-f <filename>: Specify the filename\n");
                printf("\t-p <num_records>: Specify the number of records to print from head\n");
                printf("\t-r <num_records>: Specify the number of records to print from tail\n");
                printf("\t-d <bool>: turns on debug mode with true, off with false\n");
                printf("\t-v <bool>: verify hashes sort order from file, off with false, on with true (false by default)\n");
                printf("\t-b <num_records>: verify hashes as correct BLAKE3 hashes (false by default)\n");
                printf("\t-h: Display this help message\n");
                break;
            case 'f':
                filename=optarg;
                break;
            case 'd':
                temp=optarg;
                debug=convert_string_to_bool(temp);
                break; 
            case 'p':
                head_record=atoi(optarg);
                flag_raised = 'p';
                break;
            case 'r':
                tail_record=atoi(optarg);
                flag_raised = 'r';
                break;
            case 'v':
                temp=optarg;
                check_sort=convert_string_to_bool(temp);
                flag_raised = 'v';
                break;
            case 'b':
                check_hash=atoi(optarg);
                flag_raised = 'b';
                break;
            case 't':
                hash_threads=atoi(optarg);
                break;
            case 'o':
                sort_threads=atoi(optarg);
                break;
            case 'i':
                write_threads=atoi(optarg);
                break;
            case 'm':
                max_mem=atoi(optarg);
                break;
            case 's':
                file_size=atoi(optarg);
                break;
            default:
                fprintf(stderr, "Usage: %s [-a value] [-b value] [-c value]\n", argv[0]);
                return 1;   
        }
    }

    if(flag_raised != 'N'){
        FILE *f = fopen(filename, "rb");
        if (f == NULL) {
            perror("No such file exists in the current directory\n");
            return EXIT_FAILURE;
    }
        if(flag_raised == 'p'){
            Record *head = malloc(head_record * sizeof(Record));
            if (fread(head, sizeof(Record), head_record,f) != head_record) {
                free(head);
                printf("Not enough files to Read\n");
                return 1;
            }
            printf("Printing the first %d values of the file %s\n",head_record,filename);
            for(int i=0; i < head_record ; i++){
                printf("[%d] Hash :", (i * RECORD_SIZE));
                print_hash(head[i].hash,HASH_SIZE);
            }
            free(head);
        }else if(flag_raised == 'r'){
            Record *tail = malloc(tail_record * sizeof(Record));
            fseek(f,-tail_record * sizeof(Record), SEEK_END);
            if (fread(tail, sizeof(Record), tail_record,f) != tail_record) {
                free(tail);
                printf("Not enough files to Read\n");
                return 1;
            }
            printf("Printing the last %d values of the file %s\n",tail_record,filename);
            for(int i=0; i < tail_record ; i++){
                printf("[%d] Hash :", i);
                print_hash(tail[i].hash,HASH_SIZE);
            }
            free(tail);
        }else if(flag_raised == 'v' && check_sort){
            fseek(f, 0, SEEK_END);
            unsigned long long size = ftell(f);
            printf("File Size:%llu\n",size);
            rewind(f);
            unsigned long long num_records = size / RECORD_SIZE ;
            Record *records = (Record *)malloc(num_records * sizeof(Record));
            if(fread(records, sizeof(Record), num_records, f) != num_records){
                free(records);
                printf("Not enough files to Read\n");
                return 1;
            }
            //bool sorted = check_if_sorted(records,num_records);
            //if(sorted){
            //    printf("Read %llu bytes and found all records are sorted\n",size);
            //}else{
            //    printf("Records are not in sorted order\n");
            //}
            free(records);

        }else if(flag_raised == 'b'){
            char command[200];
            char new_debug[20];
            if (debug) {
                strcpy(new_debug, "true");
            } else {
                strcpy(new_debug, "false");
            }
            sprintf(command, "./hashverify -f %s -b %d -d %s", filename,check_hash, new_debug);
            printf("Command is %s\n",command);
            int return_value = system(command);
        }
    }else{
        if (debug){	    	
            printf("NUM_THREADS_HASH=%d\n", hash_threads);
            printf("NUM_THREADS_SORT=%d\n", sort_threads);
            printf("NUM_THREADS_WRITE=%d\n", write_threads);
            printf("FILENAME=%s\n", filename);
            printf("MEMORY_SIZE=%dMB\n", max_mem);
            printf("FILE_SIZE=%dMB\n", file_size);
            printf("RECORD_SIZE=%dB\n", RECORD_SIZE);
            printf("HASH_SIZE=%dB\n", HASH_SIZE);
            printf("NONCE_SIZE=%dB\n", NONCE_SIZE);
        }
        pthread_t hash_threads_array[hash_threads];
        pthread_t sort_threads_array[sort_threads];
        pthread_t write_threads_array[write_threads];

        max_records= (max_mem * 1048576) / 16;
        int iterations;
        unsigned long long file_size_bytes = file_size * 1024ULL * 1024ULL * 1024ULL;
	total_hash_count = file_size_bytes / 16ULL;
	iterations= total_hash_count / max_records; 

        double start_time = get_current_time();

        for (int j = 0; j < iterations; j++){
            
            hashes = malloc(max_records * sizeof(Record));

            for (int i = 0; i < hash_threads; i++) {
                struct ThreadArgs *args = malloc(sizeof(struct ThreadArgs));
                args->thread_index = i;
                args->iteration_index = (ull)j;
                pthread_create(&hash_threads_array[i], NULL,hashing, args);
            }
            for (int i = 0; i < hash_threads; i++) {
                pthread_join(hash_threads_array[i], NULL);
            }
        
            for (int i = 0; i < sort_threads; i++) {
                pthread_create(&sort_threads_array[i], NULL, sorting, (void *)(intptr_t)i);
            }

            for (int i = 0; i < sort_threads; i++) {
                pthread_join(sort_threads_array[i], NULL);
            }

            if(write_threads >= sort_threads){
                for (int i = 0; i < sort_threads; i++) {
                    struct WriteThreadArgs1 *args = malloc(sizeof(struct WriteThreadArgs1));
                    args->i = i;
                    args->bucket_start = no_files;
                    pthread_create(&write_threads_array[i], NULL, writing_write, args);
            }

                for (int i = 0; i < sort_threads; i++) {
                    pthread_join(write_threads_array[i], NULL);
            }
                no_files += sort_threads;
            }else{  
                write_iter = sort_threads / write_threads;
                write_segment = max_records / write_iter;
                for (int k = 0; k < write_iter ; k++){
                for (int i = 0; i < write_threads; i++) {
                    struct WriteThreadArgs2 *args = malloc(sizeof(struct WriteThreadArgs2));
                    args->k = k;
                    args->i = i;
                    args->bucket_start = no_files;
                    pthread_create(&write_threads_array[i], NULL, writing_sort, args);
            }
                for (int i = 0; i < write_threads; i++) {
                    pthread_join(write_threads_array[i], NULL);
            }   
                }
                no_files += sort_threads;
            }
            free(hashes);
            if(debug){
                double end_time = get_current_time();
                double time_taken = end_time - start_time;
                ull hashes_completed = (ull)((j+1) * max_records);
                double percent_complete = ((double)hashes_completed / total_hash_count) * 100;
                double throughput = (hashes_completed / time_taken);
                double ETA = ((double)(total_hash_count - hashes_completed)) / throughput;
                printf("[%zu][HASHGEN]: %.2f%% completed, ETA %.1f seconds, %llu/%llu hashes, %.1f MB/sec\n", prog_idx, percent_complete, ETA, hashes_completed, total_hash_count, (throughput * 16 / (1024 * 1024)));
                prog_idx++;
            }
        }
        if(debug){
            printf("Moving to External Sort, %d sub files detected\n",no_files);
        }

        ExternalSort(no_files,filename);

        delete_bins(no_files);
    
        double end = get_current_time();
        double time = end - start_time;
        double MHS = (total_hash_count / time) * 1e-6;
        double throughput_MB = ((total_hash_count * 16 ) / (time * 1024 * 1024));
        if(debug){
            printf("Completed %d MB file %s in %.2f seconds : %.2f MH/s %.2f MB/s\n",file_size,filename,time,MHS,throughput_MB);
        }else{
            printf("hashgen t%d o%d i%d m%d s%d %.2f %.2f %.2f\n",hash_threads,sort_threads,write_threads,max_mem,file_size,time,MHS,throughput_MB);
        }
    }
    

    return 0;
}
