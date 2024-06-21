save_network(){
    machine=$1
    > "network_eval_$machine.txt"
    echo "Threads,Latency,Measured Throughput" >> "network_eval_$machine.txt"
    throughput=$(grep "\[  1\]" server_eval_${machine}_1.txt | tail -n +2 | awk '{print $7}')
    avg_latency=$(calculate_latency 1 $machine)
    echo "1,$avg_latency,$throughput" >> "network_eval_$machine.txt"
    for i in {2..7}; do
	    avg_latency=$(calculate_latency $((2 ** (i-1))) $machine)
	    throughput=$(awk -v i="$((2 ** (i-1)))" '/\[SUM\]/ { print $6 / i }' "server_eval_${machine}_$((2 ** (i-1))).txt")
	    echo "$((2 ** (i-1))),$avg_latency,$throughput" >> "network_eval_$machine.txt"
    done
}


calculate_latency(){
	core=$1
	machine=$2
    sum=0
    count=0
    output=$(grep '^\[ *[0-9]\+\]' server_eval_${machine}_$core.txt | tail -n +$((core + 1)))  # Ignore the first four lines
    while IFS= read -r line; do
        latency=$(echo "$line" | awk '{print $9}' | awk -F'/' '{print $1}' | awk '{s+=$1} END {print s}')
        sum=$(echo "$sum + $latency" | bc)
	((count++))
    done <<< "$output"
    echo "$(awk "BEGIN {print $sum / $count}")"
}

save_network b
save_network v
save_network c
