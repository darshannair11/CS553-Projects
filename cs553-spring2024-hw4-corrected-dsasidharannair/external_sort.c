#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>

#define TOTAL_RECORDS (1 << 26)
#define HASH_COUNT_BIG (1ULL << 32)
#define HASH_SIZE 10
#define NONCE_SIZE 6
#define RECORD_SIZE 16

typedef struct {
    uint8_t hash[HASH_SIZE]; 
    uint8_t nonce[NONCE_SIZE]; 
} Record;

struct ReadThreadArgs {
    int file_no;
    FILE **inputs;
};

int max_mem = 128;
int records_per_read;
int write_threads = 16;
Record **records;

void print_hash(const uint8_t *hash, size_t size) {
    for (size_t i = 0; i < size; ++i) {
        printf("%02X", hash[i]);
    }
}

void copy(Record *t, Record *s) {
    memcpy(t, s, sizeof(Record));
}

void *load(void *arg){
    struct ReadThreadArgs *args = (struct ReadThreadArgs *)arg;
    int file_no = args->file_no;
    FILE **inputs = args->inputs;
    char filename[100];
    sprintf(filename, "bucket_%d.bin", file_no);
    inputs[file_no] = fopen(filename, "rb");
    printf("Opened File %d\n",file_no);
    records[file_no] = (Record *)malloc(records_per_read * sizeof(Record));
    fread(records[file_no], sizeof(Record), records_per_read, inputs[file_no]);
    free(arg);
    return NULL;
}

void mergeSortedFiles(int no_files) {
    FILE *inputs[no_files];
    FILE *output;
    int i;

    int max_records= (max_mem * 1048576) / 16;
    int divider = max_records/2;
    records_per_read = divider / no_files;

    printf("Records Per Read is %d\n", records_per_read);

    records = (Record **)malloc(no_files * sizeof(Record *));

    // for (i = 0; i < no_files; ++i) {
    //     char filename[100];
    //     sprintf(filename, "bucket_%d.bin", i);
    //     inputs[i] = fopen(filename, "rb");
    //     printf("Opened File %d\n",i);
    //     records[i] = (Record *)malloc(records_per_read * sizeof(Record));
    //     printf("Memory Allocated\n");
    //     if (fread(records[i], sizeof(Record), records_per_read, inputs[i]) != records_per_read) {
    //         free(records[i]);
    //         records[i] = NULL;
    //     }
    // }

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

    

    printf("Reached Here \n");

    for (i = 0; i < no_files; ++i) {
        print_hash(records[i][0].hash,HASH_SIZE);
        printf("\n");
    }

    int *idx = (int *)malloc(no_files * sizeof(int));
    memset(idx, 0, no_files * sizeof(int));
    output = fopen("output.bin", "ab");
    Record *sorted = (Record *)malloc(divider * sizeof(Record));
    int sorted_idx = 0;

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


        // fwrite(records[small_idx] + idx[small_idx], sizeof(Record), 1, output);
        copy(&sorted[sorted_idx], records[small_idx] + idx[small_idx]);
        sorted_idx++;
        idx[small_idx]++;

        if(sorted_idx == divider){
            fwrite(sorted, sizeof(Record), divider, output);
            printf("Written to the output file \n");
            memset(sorted, 0, divider * sizeof(Record));
            sorted_idx = 0;
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

int main(int argc, char *argv[]) {
    int no_files;
    int opt;
    if(argc == 1){
           fprintf(stderr,"No Argument Provided (Expected at least one argument) "); 
        }

    while ((opt = getopt(argc, argv, "n:")) != -1) {
        switch (opt) {
            case 'n':
                no_files=atoi(optarg);
                break;
            default:
                fprintf(stderr, "Usage: %s [-a value] [-b value] [-c value]\n", argv[0]);
                return 1;  
        }
    }        
    mergeSortedFiles(no_files);
    return 0;
}
