### CS553 Cloud Computing Assignment 4 Repo

**Illinois Institute of Technology**

**Team Name**: Cloud Computers

**Students**:

- Darshan Sasidharan Nair (dsasidharannair)

# Instructions

**Instructions for Running The Program**

- The hashgen.c is the only important file to be considered the rest of the .c files are not important
- I was unable to upload the BLAKE3 repo due to some embedded issue in git that I was unable to solve. So please make sure to clone the BLAKE3 repo from the official site before proceeding with the next steps
- Either use this gcc command "gcc -O3 -o hashgen ./hashgen.c ./BLAKE3/c/blake3.c ./BLAKE3/c/blake3_dispatch.c ./BLAKE3/c/blake3_portable.c ./BLAKE3/c/blake3_sse2_x86-64_unix.S ./BLAKE3/c/blake3_sse41_x86-64_unix.S ./BLAKE3/c/blake3_avx2_x86-64_unix.S ./BLAKE3/c/blake3_avx512_x86-64_unix.S -I./BLAKE3/c/ ". You will find the execytable in the primary folder.
- Or go into the build folder. Run "cmake .." which created the nessceray dependencies and then do "make". You will find the executable in the build folder.
- The executable can be run in the same way as described in the assignement handout. Including the extra utilities as well.
- The results of the tests can be seen in results folder for both the 1Gb and 64GB case
- To run the benchmark for 1GB run "run_benchmark_s.sh" and for 64 GB "run_benchmakr_b.sh". Make sure to chmod +x before running the bash scripts.

**Areas of Caution**

- Make sure to use a linux machine, as the BLAKE3 repo was not compatible with my mac.
- Run the benchmakrs in the tmux sessions as it takes a while to get through
- If any problems reach out to me through email

**Changes made from previous submission and notes for new one**

1. The below part of the code was commented out. From lines 468-473. So the hashgen.c file should now compile without error

```c
bool sorted = check_if_sorted(records,num_records);
if(sorted){
printf("Read %llu bytes and found all records are sorted\n",size);
}else{
printf("Records are not in sorted order\n");
}
```

2. In the case that there are still errors with the hashgen.c file which there shouldn't be. You can compile new.c using a similar command as given above and then run the object file. This would result in the creation of n number of individually sorted buckets. Now to sort these into a single file you can run. This should result in a single output file called output.bin which contains all the records in file to test if there are sorted correctly.

```bash
gcc -o external_sort external_sort.c
./external_sort.c -n [number of buckets created]
```

3. Feel free to contact me over email if any issues arise
