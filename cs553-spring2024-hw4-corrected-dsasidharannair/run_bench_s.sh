#!/bin/bash

EXE="./build/hashgen"
VER="./hashverify"
values=(1 4 16)

> "results_s.csv"

for t in "${values[@]}"; do
    for o in "${values[@]}"; do
        for i in "${values[@]}"; do
            echo "Starting Benchmark for -t $t -o $o -i $i -f "data.bin" -m 128 -s 1024 -d false config"
            output=$("$EXE" -t "$t" -o "$o" -i "$i" -f "data.bin" -m 128 -s 1024 -d "false")
            echo "$output"
            time_taken=$(echo "$output" | awk '{print $7}')
            MHs=$(echo "$output" | awk '{print $8}')
            MBs=$(echo "$output" | awk '{print $9}')
            echo "$t-$o-$i,$time_taken,$MHs,$MBs" >> "results_s.csv"
            $VER -f "data.bin" -v "true"
            rm "data.bin"
        done
    done
done

python3 generate_graph.py s