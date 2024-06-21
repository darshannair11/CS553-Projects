#!/bin/bash

save(){
    machine=$1
    > "cpu_eval_$machine.txt"
    echo "Threads,Average Latency,Measured Throughput" >> "cpu_eval_$machine.txt"
    for i in {1..7}; do
        avg_latency=$(grep "avg:" "cpu_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $2}')
        events_per_second=$(grep "events per second:" "cpu_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $4}')
        echo "$((2 ** (i-1))),$avg_latency,$events_per_second" >> "cpu_eval_$machine.txt"
    done
}

main(){
	save "b"
	save "v"
	save "c"
	python3 python_cpu.py
}

main
