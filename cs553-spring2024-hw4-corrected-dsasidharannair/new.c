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

Record *hashes;
pthread_mutex_t global_mutex = PTHREAD_MUTEX_INITIALIZER;
size_t total_completed_hash = 0;

int hash_threads,sort_threads,write_threads,max_mem,max_records,write_iter,write_segment,no_files = 0;
bool debug=false;

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

void print_hash(const uint8_t *hash, size_t size) {
    for (size_t i = 0; i < size; ++i) {
        printf("%02X", hash[i]);
    }
    printf("\n");
}

int compare(const void *a, const void *b) {
    Record *r1 = (Record *)a;
    Record *r2 = (Record *)b;
    int result=memcmp(r1->hash, r2->hash, HASH_SIZE);
    return result;
}

void *hashing(void *arg){
    struct ThreadArgs *args = (struct ThreadArgs *)arg;
    size_t thread_no = (size_t)(intptr_t)args->thread_index;
    ull x = args->iteration_index;
    int bucket_no = (hash_threads * x) + (int)thread_no;
    size_t hashes_per_thread = max_records / hash_threads;
    size_t start_index = thread_no * hashes_per_thread;
    size_t end_index = (thread_no == hash_threads - 1) ? max_records : (thread_no + 1) * hashes_per_thread;
    printf("[%zu][HASHGEN]: Starting Hashing from Thread:%zu\n",thread_no,thread_no);
    printf("Hashing from idx:%zu to idx:%zu\n",start_index,end_index);
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


void *sorting(void *arg){
    size_t thread_no=(size_t)(intptr_t)arg;
    size_t sort_per_thread = max_records / sort_threads;
    size_t start_index = thread_no * sort_per_thread;
    size_t end_index = (thread_no == sort_threads - 1) ? max_records : (thread_no + 1) * sort_per_thread;
    printf("[%zu][SORTING]: Starting Sorting from Thread:%zu\n",thread_no,thread_no);
    printf("Sorting from idx:%zu to idx:%zu\n",start_index,end_index);
    qsort(&hashes[start_index],end_index-start_index,sizeof(Record), compare);
    return NULL;
}

void *writing_write(void *arg){
    struct WriteThreadArgs1 *args = (struct WriteThreadArgs1 *)arg;
    int i = args->i;
    int bucket_start = args->bucket_start;
    size_t thread_no = (size_t)i;
    int bucket_no = bucket_start + i;
    size_t write_per_thread = max_records / write_threads;
    size_t start_index = thread_no * write_per_thread;
    size_t end_index = (thread_no == write_threads - 1) ? max_records : (thread_no + 1) * write_per_thread;
    printf("[%zu][I/O]: Starting Writing from Thread:%zu\n",thread_no,thread_no);
    printf("Writing from idx:%zu to idx:%zu\n",start_index,end_index);
    char filename[20]; 

    sprintf(filename, "bucket_%d.bin", bucket_no);
    
    FILE *f = fopen(filename, "wb");
    if (f != NULL) {
        fwrite(&hashes[start_index],sizeof(Record),end_index-start_index,f);
        if(debug){
            printf("Sorted records written to %s.\n", filename);
        }
        fclose(f);
    } else {
        if(debug){
           printf("ERROR : UNABLE TO OPEN %s.\n", filename); 
        }
    }
    free(arg);
    return NULL; 
}

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
    printf("[%zu][I/O]: Starting Writing from Thread:%zu\n",thread_no,thread_no);
    printf("Writing from idx:%zu to idx:%zu\n",start_index,end_index);
    char filename[20]; 

    sprintf(filename, "bucket_%d.bin", bucket_no);
    
    FILE *f = fopen(filename, "wb");
    if (f != NULL) {
        fwrite(&hashes[start_index],sizeof(Record),end_index-start_index,f);
        if(debug){
            printf("Sorted records written to %s.\n", filename);
        }
        fclose(f);
    } else {
        if(debug){
           printf("ERROR : UNABLE TO OPEN %s.\n", filename); 
        }
    }
    free(arg);
    return NULL; 
}

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
                printf("Filename value initialized as %s\n", filename);
                break;
            case 'd':
                temp=optarg;
                debug=convert_string_to_bool(temp);
                printf("Debug value initialized as %s\n", debug ? "true" : "false");
                break; 
            case 'p':
                head_record=atoi(optarg);
                printf("Head Record value initialized as %d\n", head_record);
                break;
            case 'r':
                tail_record=atoi(optarg);
                printf("Tail Record value initialized as %d\n", tail_record);
                break;
            case 'v':
                temp=optarg;
                check_sort=convert_string_to_bool(temp);
                printf("Verify Sorted value initialized as %s\n", check_sort ? "true" : "false");
                break;
            case 'b':
                temp=optarg;
                check_hash=convert_string_to_bool(temp);
                printf("Verify Correct Hash value initialized as %s\n", check_hash ? "true" : "false");
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
    if (debug){	    	
    	printf("NUM_THREADS_HASH=%d\n", hash_threads);
    	printf("NUM_THREADS_SORT=%d\n", sort_threads);
    	printf("NUM_THREADS_WRITE=%d\n", write_threads);
    	printf("FILENAME=%s\n", filename);
    	printf("MEMORY_SIZE=%dMB\n", max_mem);
        printf("MEMORY_SIZE=%dMB\n", file_size);
    	printf("RECORD_SIZE=%dB\n", RECORD_SIZE);
    	printf("HASH_SIZE=%dB\n", HASH_SIZE);
    	printf("NONCE_SIZE=%dB\n", NONCE_SIZE);
    }
    pthread_t hash_threads_array[hash_threads];
    pthread_t sort_threads_array[sort_threads];
    pthread_t write_threads_array[write_threads];

    struct timeval start, end;

    max_records= (max_mem * 1048576) / 16;
    int iterations;
    if(file_size == 1024){
        iterations= HASH_COUNT_SMALL / max_records; 
    }else{
        iterations= HASH_COUNT_BIG / max_records; 
    }
    printf("Iterations: %d\n",iterations);
    printf("Max Records: %d\n",max_records);

    gettimeofday(&start, NULL);

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

        print_hash(hashes[0].hash,HASH_SIZE);
        print_hash(hashes[0].nonce,NONCE_SIZE);
        print_hash(hashes[1].hash,HASH_SIZE);
        print_hash(hashes[1].nonce,NONCE_SIZE);
       
        for (int i = 0; i < sort_threads; i++) {
            pthread_create(&sort_threads_array[i], NULL, sorting, (void *)(intptr_t)i);
        }

        for (int i = 0; i < sort_threads; i++) {
            pthread_join(sort_threads_array[i], NULL);
        }

        print_hash(hashes[0].hash,HASH_SIZE);
        print_hash(hashes[0].nonce,NONCE_SIZE);

        if(write_threads >= sort_threads){
            for (int i = 0; i < write_threads; i++) {
                struct WriteThreadArgs1 *args = malloc(sizeof(struct WriteThreadArgs1));
                args->i = i;
                args->bucket_start = no_files;
                pthread_create(&write_threads_array[i], NULL, writing_write, args);
        }

            for (int i = 0; i < write_threads; i++) {
                pthread_join(write_threads_array[i], NULL);
        }
            no_files += write_threads;
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
    }
 
    gettimeofday(&end, NULL);
    double time=(end.tv_sec-start.tv_sec) + (end.tv_usec-start.tv_usec) / 1e6;

    printf("Number of sub files created: %d\n",no_files);
    printf("Total time taken: %.2f seconds\n", time);

    return 0;
}
