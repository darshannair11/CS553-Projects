#!/bin/bash

save_memory(){
    machine=$1
    > "memory_eval_$machine.txt"
    echo "Threads,Total Operations,Throughput" >> "memory_eval_$machine.txt"
    for i in {1..7}; do
        total_operations=$(grep "Total operations:" "memory_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $3}')
        mib_per_sec=$(grep "MiB/sec" "memory_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $(NF-1)}' | tr -d '(')
        echo "$((2 ** (i-1))),$total_operations,$mib_per_sec" >> "memory_eval_$machine.txt"
    done
}

main(){
	save_memory "b"
	save_memory "v"
	save_memory "c"
	python3 "python_memory.py"
}

main
