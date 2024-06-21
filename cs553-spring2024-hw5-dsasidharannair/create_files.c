#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>
#include "blake3.h"
#include <inttypes.h>
#include <errno.h>

#define NONCE_SIZE 6
#define HASH_SIZE 10
#define RECORD_SIZE 16

typedef unsigned long long ull;

typedef struct {
    uint8_t hash[HASH_SIZE];
    uint8_t nonce[NONCE_SIZE];
} Record;

Record *hashes;

ull total_hash_count;

int main(int argc, char *argv[]) {
    if (argc != 3 || strcmp(argv[1], "-n") != 0) {
        printf("Usage: %s -n [nonce_start]\n", argv[0]);
        return 1;
    }

    int n_start = atoi(argv[2]);

    ull total_hash_count = 67108864;
    ull start_index = total_hash_count * (n_start-1);
    ull end_index = total_hash_count * n_start;
    hashes = malloc(total_hash_count * sizeof(Record));

    for (ull i = start_index; i < end_index; i++) {
        for (int j = 0; j < NONCE_SIZE; j++) {
            hashes[i-start_index].nonce[j] = (i >> (j * 8)) & 0xFF;
    }
        blake3_hasher hasher;
        blake3_hasher_init(&hasher);
        blake3_hasher_update(&hasher, hashes[i-start_index].nonce, NONCE_SIZE);
        blake3_hasher_finalize(&hasher, hashes[i-start_index].hash, HASH_SIZE);
    }

    FILE *f = fopen("data.bin", "wb");
    fwrite(hashes, sizeof(Record), total_hash_count, f);
    fclose(f);

    free(hashes);
}
