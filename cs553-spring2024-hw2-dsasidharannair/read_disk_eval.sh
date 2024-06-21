#!/bin/bash

save_disk(){
	machine=$1
    echo "Threads,Total Operations,Measured Throughput" >> "disk_eval_$machine.txt"
    for i in {1..7}; do
        read_throughput=$(grep "read, MiB/s:" "disk_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $3}')
        read_operations=$(grep "reads/s:" "disk_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $2}')
        echo "$((2 ** (i-1))),$read_throughput,$read_operations" >> "disk_eval_$machine.txt"
    done
}

save_disk b
save_disk v
#save_disk c
