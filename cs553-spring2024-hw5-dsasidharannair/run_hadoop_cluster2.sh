#!/bin/bash

> results_hadoop_cluster2.csv

Cluster1=("tiny-instance-2" "small-instance-1" "small-instance-2" "small-instance-3" "small-instance-4" "small-instance-5" "small-instance-6")

for value in 16 32; do
    if [ "$value" -eq 64 ]; then
        for vname in "${Cluster1[@]}"; do
            sudo lxc exec $vname -- bash -c "iostat -x 1 > disk_stats.txt & mpstat 1 > cpu_stats.txt & sar -r 1 > memory_stats.txt & "
            echo "Sysstat started on $vname"
        done
    fi

    echo "Started Running Hadoop Sort for $value GB"

    start_t=$(date +%s.%N)
    ssh "dsasidharannair@10.10.192.141" <<EOF >> "HadoopSort_${value}_results_config2.txt"
        for ((i=1; i<=$value; i++)); do
            ./create_files -n \$i
            hdfs dfs -appendToFile data.bin input/data.bin
            rm data.bin
            echo "Added \$i GB of data"
        done
        echo "Starting Hadoop Program"
        yarn jar /home/dsasidharannair/sort-hadoop/target/sort-hadoop-1.0-SNAPSHOT.jar input/data.bin output
        hdfs dfs -rm -r output 
        hdfs dfs -rm input/data.bin
EOF
    end_t=$(date +%s.%N)
    time_hadoop=$(echo "$end_t - $start_t" | bc)
    if [ "$value" -eq 64 ]; then
        for vname in "${Cluster1[@]}"; do
            sudo lxc exec $vname -- bash -c "pkill iostat && pkill mpstat && pkill sar"
            echo "Sysstat Killed on $vname"
        done
    fi

    echo "6 small.instance $value GB dataset , $time_hadoop" >> results_hadoop_cluster2.csv

    echo "Completed"
done

for vname in "${Cluster1[@]}"; do
    sudo lxc file pull "$vname/root/disk_stats.txt" "$vname/root/cpu_stats.txt" "$vname/root/memory_stats.txt" "/home/cc/$vname-log"
    echo "Sysstat file pulled from $vname"
done