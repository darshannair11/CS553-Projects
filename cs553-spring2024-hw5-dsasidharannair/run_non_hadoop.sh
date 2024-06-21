#!/bin/bash

execute() {
    local vm=$1
    local data=$2
    local command=$3
    echo "Running $command on $vm for $data GB"
    sudo lxc exec $vm -- /bin/bash -c "$command"
}

vault_command(){
    local size=$1
    if [ "$size" == "16" ]; then
        echo "./vault -t 4 -o 4 -i 4 -m 2 -s 16 -f data-16GB.bin ; rm data-16GB.bin"
    elif [ "$size" == "32" ]; then
        echo "./vault -t 16 -o 4 -i 4 -m 2 -s 32 -f data-32GB.bin ; rm data-32GB.bin"
    elif [ "$size" == "64" ]; then
        echo "iostat -x 1 > disk_stats_vault.txt & mpstat 1 > cpu_stats_vault.txt & sar -r 1 > memory_stats_vault.txt & ./vault -t 16 -o 16 -i 4 -m 16 -s 64 -f data-64GB.bin -d true > vault64GB.log ; pkill iostat && pkill mpstat && pkill sar ; rm data-64GB.bin" 
    fi
}

hashgen_command(){
    local size=$1
    if [ "$size" == "16" ]; then
        echo "./hashgen -t 16 -o 1 -i 1 -m 2048 -s 16 -f data-16GB.bin ; rm data-16GB.bin"
    elif [ "$size" == "32" ]; then
        echo "./hashgen -t 16 -o 4 -i 4 -m 2048 -s 32 -f data-32GB.bin ; rm data-32GB.bin"
    elif [ "$size" == "64" ]; then
        echo "iostat -x 1 > disk_stats_hashgen.txt & mpstat 1 > cpu_stats_hashgen.txt & sar -r 1 > memory_stats_hashgen.txt & ./hashgen -t 16 -o 1 -i 1 -m 16384 -s 64 -f data-64GB.bin > hashgen64GB.log ; pkill iostat && pkill mpstat && pkill sar ; rm data-64GB.bin" 
    fi
}

small_vm="small-instance-spare"
large_vm="large-instance-spare"

sizes=("16" "32" "64")

> results_1.csv

echo "Device, Hashgen, Vault" >> results_1.csv

for size in "${sizes[@]}"; do

    v_com=$(vault_command "$size") 

    if [ "$size" != "64" ]; then
        start_t=$(date +%s.%N)
        execute "$small_vm" "$size" "$v_com"
        end_t=$(date +%s.%N)
        time_s_vault=$(echo "$end_t - $start_t" | bc)
    fi
    start_t=$(date +%s.%N)
    execute "$large_vm" "$size" "$v_com"
    end_t=$(date +%s.%N)
    time_l_vault=$(echo "$end_t - $start_t" | bc)

    h_com=$(hashgen_command "$size") 

    if [ "$size" == "16" ]; then
        start_t=$(date +%s.%N)
        execute "$small_vm" "$size" "$h_com"
        end_t=$(date +%s.%N)
        time_s_hashgen=$(echo "$end_t - $start_t" | bc)
    fi
    start_t=$(date +%s.%N)
    execute "$large_vm" "$size" "$h_com"
    end_t=$(date +%s.%N)
    time_l_hashgen=$(echo "$end_t - $start_t" | bc)

    echo "1 $small_vm ${size}GB dataset 2GB RAM,$time_s_hashgen,$time_s_vault" >> results_1.csv
    echo "1 $large_vm ${size}GB dataset 16GB RAM,$time_l_hashgen,$time_l_vault" >> results_1.csv
done

lxc file pull $large_vm/root/cpu_stats_vault.txt /home/cc/logs
lxc file pull $large_vm/root/disk_stats_vault.txt /home/cc/logs
lxc file pull $large_vm/root/memory_stats_vault.txt /home/cc/logs
lxc file pull $large_vm/root/vault64GB.log /home/cc/logs
lxc file pull $large_vm/root/cpu_stats_hashgen.txt /home/cc/logs
lxc file pull $large_vm/root/disk_stats_hashgen.txt /home/cc/logs
lxc file pull $large_vm/root/memory_stats_hashgen.txt /home/cc/logs
lxc file pull $large_vm/root/hashgen64GB.log /home/cc/logs
