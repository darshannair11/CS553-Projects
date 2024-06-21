#!/bin/bash

#Can ignore part of code attempt simulate mutiple commands simultaneous
create_tmux_session(){
    name=$1
    tmux new-session -d -s "$name"
    for i in {1..7}; do
        tmux new-window -t "$name:$i" -n "Thread $((2 ** (i-1)))"
    done
}

#Can ignore reads the user choice
read_user_choice(){
    read -p "What type of machine do you wish to perform the benchmark on(Baremetal(b),Virtual Machine(v),Container(c)):" machine
    echo $machine
}
#Can ignore
initialize_VM(){
	name="ThreadVM"
	session_name=$1
	for i in {1..7}; do
		tmux send-keys -t "$session_name:$i" "sudo lxc launch ubuntu:22.04 '$name-$((2 ** (i-1)))' --vm -c limits.cpu=$((2 ** (i-1))) -c limits.memory=4GiB;sleep 15;sudo lxc exec $name-$((2 ** (i-1))) -- bash -c 'echo \"$name-$((2 ** (i-1))) has been initialized with $((2 ** (i-1))) cores\" >> \"VM.txt\"';sleep 5" C-m
	done
}

#Can Ignore
delete_VM(){
	name="ThreadVM"
	session_name=$1
	for i in {1..7}; do
		#tmux send-keys -t "$session_name:$i" "echo 'Is this working'" C-m
		tmux send-keys -t "$session_name:$i" "sudo lxc stop '$name-$((2 ** (i-1)))' && sudo lxc delete '$name-$((2 ** (i-1)))'" C-m
	done
}

#Can Ignore
wait_tmux(){
	name=$1
	for i in {1..7}; do
                   while tmux list-windows -t $name | grep -q "Thread $((2 ** (i-1)))"; do
                          sleep 1
                   done
        done
        tmux kill-session -t $name
}	


#Can Ignore
cpu_eval(){
        machine=$1
        if [ "$machine" == "b" ]; then
                name="cpu_eval_b"
                echo "Performing Baremetal CPU Benchmark"
                create_tmux_session "$name"
                for i in {1..7}; do
                        > "cpu_eval_b_$((2 ** (i-1))).txt"
                        tmux send-keys -t "$name:$i" "echo '' >> 'cpu_eval_b_$((2 ** (i-1))).txt';echo 'CPU EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'cpu_eval_b_$((2 ** (i-1))).txt';echo '' >> 'cpu_eval_b_$((2 ** (i-1))).txt'; sysbench cpu --cpu-max-prime=100000 --threads=$((2 ** (i-1))) run >> 'cpu_eval_b_$((2 ** (i-1))).txt';exit" C-m
                done
                tmux attach-session -t $name
		wait_tmux $name
        fi
}

#Can Ignore
memory_eval(){
        machine=$1
        if [ "$machine" == "b" ]; then
                name="memory_eval_b"
                echo "Performing Baremetal Memory Benchmark"
                create_tmux_session "$name"
                for i in {1..7}; do
                        > "memory_eval_b_$((2 ** (i-1))).txt"
                        tmux send-keys -t "$name:$i" "echo '' >> 'memory_eval_b_$((2 ** (i-1))).txt';echo 'MEMORY EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'memory_eval_b_$((2 ** (i-1))).txt';echo '' >> 'memory_eval_b_$((2 ** (i-1))).txt';sysbench memory --memory-block-size=1K --memory-total-size=120G --memory-oper=read --memory-access-mode=rnd --threads=$((2 ** (i-1))) run >> 'memory_eval_b_$((2 ** (i-1))).txt';exit" C-m
                done
                tmux attach-session -t $name
		wait_tmux $name
        fi
}


#Can Ignore
disk_eval(){
        machine=$1
        if [ "$machine" == "b" ]; then
                name="disk_eval_b"
                echo "Performing Baremetal Disk Benchmark"
                sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=1 prepare
                create_tmux_session "$name"
                for i in {1..7}; do
                        > "disk_eval_b_$((2 ** (i-1))).txt"
                        tmux send-keys -t "$name:$i" "echo '' >> 'disk_eval_b_$((2 ** (i-1))).txt';echo 'DISK EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'disk_eval_b_$((2 ** (i-1))).txt';echo '' >> 'disk_eval_b_$((2 ** (i-1))).txt';sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$((2 ** (i-1))) run >> 'disk_eval_b_$((2 ** (i-1))).txt';exit" C-m
                done
                tmux attach-session -t $name
		wait_tmux $name
                sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=1 cleanup
        fi
}

#Can ignore
network_eval(){
        machine=$1
        if [ "$machine" == "b" ]; then
                name="network_eval_b"
                echo "Performing Baremetal Network Benchmark"
                create_tmux_session "$name"
                tmux send-keys -t "$name:0" "iperf -s -w 1M" C-m
		sleep 3
		for i in {1..7}; do
			> "network_eval_b_$((2 ** (i-1))).txt"
			tmux send-keys -t "$name:$i" "echo '' >> 'network_eval_b_$((2 ** (i-1))).txt';echo 'NETWORK EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'network_eval_b_$((2 ** (i-1))).txt';echo '' >> 'network_eval_b_$((2 ** (i-1))).txt';iperf -c 127.0.0.1 -e -i 1 --nodelay -l 8192K -w 2500K --trip-times --parallel $((2 ** (i-1))) >> 'network_eval_b_$((2 ** (i-1))).txt';exit" C-m
		done
		wait_tmux $name
		pkill iperf
	fi
}

#This code reads all the cpu benchmark log output for the specified machine and formats all the crucial data in table format in a text file seperated by commas
save_cpu(){
    machine=$1
    > "cpu_eval_$machine.txt"
    echo "Threads,Average Latency,Measured Throughput" >> "cpu_eval_$machine.txt"
    for i in {1..7}; do
        avg_latency=$(grep "avg:" "cpu_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $2}')
        events_per_second=$(grep "events per second:" "cpu_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $4}')
        echo "$((2 ** (i-1))),$avg_latency,$events_per_second" >> "cpu_eval_$machine.txt"
    done
}

#This code reads all the memory benchmark log output for the specified machine and formats all the crucial data in table format in a text file seperated by commas
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


#Creates a single tmux session to work in
create_single_tmux(){
	name=$1
	tmux new-session -d -s "$name"
}

#Waits for the specified session to terminate
wait_session(){
	name=$1
	while tmux list-sessions | grep -q "$name"; do
                          sleep 1
        done
        sleep 1
}

#Benchmarks the cpu for the bare metal instance by running the sysbench command within a tmux session. Autmoates the creation of a VM and Container for benchmarking installs and updates nescessary software and runs the benchmark on a VM/Container that has the same number of cores as threads needed
cpu_eval_main(){
	name="cpu_eval"
        echo "Performing Baremetal CPU Benchmark"
	create_single_tmux $name
	for i in {1..7}; do
		> "cpu_eval_b_$((2 ** (i-1))).txt"
		tmux send-keys -t "$name" "echo '' >> 'cpu_eval_b_$((2 ** (i-1))).txt';echo 'CPU EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'cpu_eval_b_$((2 ** (i-1))).txt';echo '' >> 'cpu_eval_b_$((2 ** (i-1))).txt'; sysbench cpu --cpu-max-prime=100000 --threads=$((2 ** (i-1))) run >> 'cpu_eval_b_$((2 ** (i-1))).txt'" C-m
	done
	tmux send-keys -t "$name" "exit" C-m
	tmux attach-session -t $name
	wait_session $name
	echo "Performing Virtual Machine CPU Benchmark"
        for i in {1..7}; do
		create_single_tmux $name
                > "cpu_eval_v_$((2 ** (i-1))).txt"
                tmux send-keys -t "$name" "echo '' >> 'cpu_eval_v_$((2 ** (i-1))).txt';echo 'CPU EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'cpu_eval_v_$((2 ** (i-1))).txt';echo '' >> 'cpu_eval_v_$((2 ** (i-1))).txt';sudo lxc launch ubuntu:22.04 'THREADVM-$((2 ** (i-1)))' --vm -c limits.cpu=$((2 ** (i-1))) -c limits.memory=4GiB;sleep 15;sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'echo \"THREADVM-$((2 ** (i-1))) has been initialized with $((2 ** (i-1))) cores\" >> \"VM.txt\"';sleep 2;sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'sudo apt update;sudo apt install -y sysbench';sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'sysbench cpu --cpu-max-prime=100000 --threads=$((2 ** (i-1))) run' >> 'cpu_eval_v_$((2 ** (i-1))).txt';sudo lxc stop 'THREADVM-$((2 ** (i-1)))' && sudo lxc delete 'THREADVM-$((2 ** (i-1)))';exit" C-m
		tmux attach-session -t $name
		wait_session $name
        done
	echo "Performing Container CPU Benchmark"
        for i in {1..7}; do
                create_single_tmux $name
                > "cpu_eval_c_$((2 ** (i-1))).txt"
                tmux send-keys -t "$name" "echo '' >> 'cpu_eval_c_$((2 ** (i-1))).txt';echo 'CPU EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'cpu_eval_c_$((2 ** (i-1))).txt';echo '' >> 'cpu_eval_c_$((2 ** (i-1))).txt';sudo lxc launch ubuntu:22.04 'THREADC-$((2 ** (i-1)))' -c limits.cpu=$((2 ** (i-1))) -c limits.memory=4GiB;sleep 15;sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c 'echo \"THREADC-$((2 ** (i-1))) has been initialized with $((2 ** (i-1))) cores\" >> \"C.txt\"';sleep 2;sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c 'sudo apt update;sudo apt install -y sysbench';sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c 'sysbench cpu --cpu-max-prime=100000 --threads=$((2 ** (i-1))) run' >> 'cpu_eval_c_$((2 ** (i-1))).txt';sudo lxc stop 'THREADC-$((2 ** (i-1)))' && sudo lxc delete 'THREADC-$((2 ** (i-1)))';exit" C-m
                tmux attach-session -t $name
                wait_session $name
        done
	save_cpu "b" #Saves Benchmark data
        save_cpu "v" #Saves VM data
        save_cpu "c" #Saves Container data
        python3 python_cpu.py #Analyzes data into a csv file as required and forms and saves graphs
}

#Benchmarks the memory for the bare metal instance by running the sysbench command within a tmux session. Autmoates the creation of a VM and Container for benchmarking installs and updates nescessary software and runs t
#he benchmark on a VM/Container that has the same number of cores as threads needed
memory_eval_main(){
        name="memory_eval"
        echo "Performing Baremetal Memory Benchmark"
        create_single_tmux $name
        for i in {1..7}; do
                > "memory_eval_b_$((2 ** (i-1))).txt"
                tmux send-keys -t "$name" "echo '' >> 'memory_eval_b_$((2 ** (i-1))).txt';echo 'MEMORY EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'memory_eval_b_$((2 ** (i-1))).txt';echo '' >> 'memory_eval_b_$((2 ** (i-1))).txt'; sysbench memory --memory-block-size=1K --memory-total-size=120G --memory-oper=read --memory-access-mode=rnd --threads=$((2 ** (i-1))) run  >> 'memory_eval_b_$((2 ** (i-1))).txt'" C-m
        done
        tmux send-keys -t "$name" "exit" C-m
        tmux attach-session -t $name
        wait_session $name
        echo "Performing Virtual Machine Memory Benchmark"
        for i in {1..7}; do
                create_single_tmux $name
                > "memory_eval_v_$((2 ** (i-1))).txt"
                tmux send-keys -t "$name" "echo '' >> 'memory_eval_v_$((2 ** (i-1))).txt';echo 'MEMORY EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'memory_eval_v_$((2 ** (i-1))).txt';echo '' >> 'memory_eval_v_$((2 ** (i-1))).txt';sudo lxc launch ubuntu:22.04 'THREADVM-$((2 ** (i-1)))' --vm -c limits.cpu=$((2 ** (i-1))) -c limits.memory=4GiB;sleep 15;sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'echo \"THREADVM-$((2 ** (i-1))) has been initialized with $((2 ** (i-1))) cores\" >> \"VM.txt\"';sleep 2;sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'sudo apt update;sudo apt install -y sysbench';sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'sysbench memory --memory-block-size=1K --memory-total-size=120G --memory-oper=read --memory-access-mode=rnd --threads=$((2 ** (i-1))) run' >> 'memory_eval_v_$((2 ** (i-1))).txt';sudo lxc stop 'THREADVM-$((2 ** (i-1)))' && sudo lxc delete 'THREADVM-$((2 ** (i-1)))';exit" C-m
                tmux attach-session -t $name
                wait_session $name
        done
        echo "Performing Container Memory Benchmark"
        for i in {1..7}; do
                create_single_tmux $name
                > "memory_eval_c_$((2 ** (i-1))).txt"
                tmux send-keys -t "$name" "echo '' >> 'memory_eval_c_$((2 ** (i-1))).txt';echo 'MEMORY EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'memory_eval_c_$((2 ** (i-1))).txt';echo '' >> 'memory_eval_c_$((2 ** (i-1))).txt';sudo lxc launch ubuntu:22.04 'THREADC-$((2 ** (i-1)))' -c limits.cpu=$((2 ** (i-1))) -c limits.memory=4GiB;sleep 15;sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c 'echo \"THREADC-$((2 ** (i-1))) has been initialized with $((2 ** (i-1))) cores\" >> \"C.txt\"';sleep 2;sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c 'sudo apt update;sudo apt install -y sysbench';sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c 'sysbench memory --memory-block-size=1K --memory-total-size=120G --memory-oper=read --memory-access-mode=rnd --threads=$((2 ** (i-1))) run' >> 'memory_eval_c_$((2 ** (i-1))).txt';sudo lxc stop 'THREADC-$((2 ** (i-1)))' && sudo lxc delete 'THREADC-$((2 ** (i-1)))';exit" C-m
                tmux attach-session -t $name
                wait_session $name
        done
	save_memory "b" #Saves Baremetal Data
        save_memory "v" #Saves Virtual Machine Data
        save_memory "c" #Saves Container Data
	python3 python_memory.py #Analyzes data into a csv file as required and forms and saves graphs
}


#This code reads all the network benchmark log output for the specified machine and formats all the crucial data in table format in a text file seperated by commas
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

#Benchmarks the network of the bare metal instance by running the sysbench command within a tmux session. Autmoates the creation of a VM and Container for benchmarking installs and updates nescessary software and runs the benchmark on a VM/Container that has the same number of cores as threads needed
network_eval_container(){
    name=$1
    cores=$2
    session_name="container_network"
    sudo lxc launch ubuntu:22.04 $name -c limits.cpu=$cores -c limits.memory=4GiB
    sleep 15
    sudo lxc exec $name -- bash -c "sudo apt update && sudo apt upgrade -y && sudo apt install iperf -y"
    tmux new-session -d -s $session_name
    tmux new-window -t "$session_name:1" -n "Server"
    tmux new-window -t "$session_name:2" -n "Client"
    tmux send-keys -t "$session_name:1" "sudo lxc exec $name -- bash -c 'iperf -s -w 1M' >> 'server_eval_c_$cores.txt'" C-m
    tmux send-keys -t "$session_name:2" "sleep 1;sudo lxc exec $name -- bash -c 'iperf -c 127.0.0.1 -e -i 1 --nodelay -l 8192K -w 2500K --trip-times --parallel $cores' >> 'network_eval_c_$cores.txt';sleep 5;exit" C-m
    while tmux list-windows -t "$session_name" | grep -q "Client"; do
               sleep 1
    done
    tmux kill-session -t "$session_name"
    echo "Deleting the VM"
    sudo lxc stop $name && sudo lxc delete $name
}

network_eval_main(){
        name="network_eval"
        echo "Performing Baremetal Network Benchmark"
        create_single_tmux $name
        for i in {1..7}; do
                > "network_eval_b_$((2 ** (i-1))).txt"
		> "server_eval_b_$((2 ** (i-1))).txt"
                tmux send-keys -t "$name" "echo '' >> 'network_eval_b_$((2 ** (i-1))).txt';echo 'NETWORK EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'network_eval_b_$((2 ** (i-1))).txt';echo '' >> 'network_eval_b_$((2 ** (i-1))).txt'; iperf -s -w 1M  >> 'server_eval_b_$((2 ** (i-1))).txt' & sleep 2 ; iperf -c 127.0.0.1 -e -i 1 --nodelay -l 8192K -w 2500K --trip-times --parallel $((2 ** (i-1))) >> 'network_eval_b_$((2 ** (i-1))).txt'; pkill iperf ; sleep 2" C-m
        done
        tmux send-keys -t "$name" "exit" C-m
        tmux attach-session -t $name
        wait_session $name
	echo "Performing Container Virtual Machine Benchmark"
	for i in {1..7}; do
                create_single_tmux $name
                > "network_eval_v_$((2 ** (i-1))).txt"
		> "server_eval_v_$((2 ** (i-1))).txt"
                tmux send-keys -t "$name" "echo '' >> 'network_eval_v_$((2 ** (i-1))).txt';echo 'NETWORK EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'network_eval_v_$((2 ** (i-1))).txt';echo '' >> 'network_eval_v_$((2 ** (i-1))).txt';sudo lxc launch ubuntu:22.04 'THREADVM-$((2 ** (i-1)))' --vm -c limits.cpu=$((2 ** (i-1))) -c limits.memory=4GiB;sleep 15;sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'echo \"THREADVM-$((2 ** (i-1))) has been initialized with $((2 ** (i-1))) cores\" >> \"VM.txt\"';sleep 2;sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'sudo apt update;sudo apt install -y iperf';sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'iperf -s -w 1M &' >> 'server_eval_v_$((2 ** (i-1))).txt' & sleep 3;sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c 'iperf -c 127.0.0.1 -e -i 1 --nodelay -l 8192K -w 2500K --trip-times --parallel $((2 ** (i-1)));pkill iperf; sleep 2' >> 'network_eval_v_$((2 ** (i-1))).txt';sudo lxc stop 'THREADVM-$((2 ** (i-1)))' && sudo lxc delete 'THREADVM-$((2 ** (i-1)))';exit" C-m
                tmux attach-session -t $name
                wait_session $name
        done
        echo "Performing Container Network Benchmark"
        for i in {1..7}; do
                > "network_eval_c_$((2 ** (i-1))).txt"
		> "server_eval_c_$((2 ** (i-1))).txt"
		network_eval_container "THREADC-$((2 ** (i-1)))" $((2 ** (i-1)))
	done
	save_network b #Save benchmark output
	save_network v #Save Virtual Machine Output
	save_network c #Save Container Output
	python3 "python_network.py" #Analyzes data into a csv file as required and forms and saves graphs
}


#Can Ignore an attmept to use LXC push to push io test files for disk benchmarking into the VM. Led to a INstance not found error after executing following function so aborted
push_iofiles(){
	instance_name=$1
	name="file_t"
	for ((i=0; i<128; i+=8)); do
		tmux new-session -d -s "$name"
    		for j in {1..8}; do
			echo "Creating new window"
        		tmux new-window -t "$name:$j" -n "File $j"
    		done
		for j in {1..8}; do
			echo "Pushing test file no $((i+(j-1)))"
			tmux send-keys -t "$name:$j" "sudo lxc file push test_file.$((i+(j-1))) $instance_name/root/ ; exit" C-m 
			#sudo lxc file push test_file.$i $instance_name/root/
		done
		tmux attach-session -t $name
		echo "REACHED WAIT"
		for j in {1..8}; do
                   while tmux list-windows -t $name | grep -q "File $j"; do
                          sleep 1
                   done
        	done
		echo "REACHED KILL"
        	tmux kill-session -t $name
		sleep 2
	done
	sleep 5
	

}

save_disk(){
        machine=$1
    echo "Threads,Total Operations,Measured Throughput" >> "disk_eval_$machine.txt"
    for i in {1..7}; do
        read_throughput=$(grep "read, MiB/s:" "disk_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $3}')
        read_operations=$(grep "reads/s:" "disk_eval_${machine}_$((2 ** (i-1))).txt" | awk '{print $2}')
        echo "$((2 ** (i-1))),$read_operations,$read_throughput" >> "disk_eval_$machine.txt"
    done
}

#Benchmarks the Disk of the bare metal instance by running the sysbench command within a tmux session. Autmoates the creation of a VM and Container for benchmarking installs and updates nescessary software and runs the benchmark on a VM/Container that has the same number of cores as threads needed. Warning takes a lot of time to execute
disk_eval_main(){
        name="disk_eval"
        echo "Performing Baremetal Disk Benchmark"
        create_single_tmux $name
        tmux send-keys -t "$name" "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=1 prepare" C-m
        for i in {1..7}; do
                > "disk_eval_b_$((2 ** (i-1))).txt"
                tmux send-keys -t "$name" "echo '' >> 'disk_eval_b_$((2 ** (i-1))).txt';echo 'DISK EVAL FOR THREAD COUNT $((2 ** (i-1)))' >> 'disk_eval_b_$((2 ** (i-1))).txt';echo '' >> 'disk_eval_b_$((2 ** (i-1))).txt'; sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$((2 ** (i-1))) run >> 'disk_eval_b_$((2 ** (i-1))).txt'" C-m
        done
        tmux send-keys -t "$name" "exit" C-m
	tmux attach-session -t $name
        wait_session $name
	echo "Performing Virtual Machine Disk Benchmark"
        for i in {1..7}; do
		> "disk_eval_v_$((2 ** (i-1))).txt"
                sudo lxc launch ubuntu:22.04 THREADVM-$((2 ** (i-1))) --vm -c limits.cpu=$((2 ** (i-1))) -c limits.memory=4GiB 
		sleep 20
		sudo lxc info THREADVM-$((2 ** (i-1)))
		sleep 10
		echo "VM is Running"
		sudo lxc stop THREADVM-$((2 ** (i-1))) --force
		sudo lxc config device override THREADVM-$((2 ** (i-1))) root size=150GB
		sudo lxc config device set THREADVM-$((2 ** (i-1))) root size=150GB
		sudo lxc start THREADVM-$((2 ** (i-1)))
		sleep 15
		sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c "sudo apt update && sudo apt install sysbench -y"
		#push_iofiles "THREADVM-$((2 ** (i-1)))"
		sleep 2
		sudo lxc list
		sudo lxc info THREADVM-$((2 ** (i-1)))
		sleep 5
		sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$((2 ** (i-1))) prepare"
		sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$((2 ** (i-1))) run" >> "disk_eval_v_$((2 ** (i-1))).txt"
		sudo lxc exec THREADVM-$((2 ** (i-1))) -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$((2 ** (i-1))) cleanup"
		sudo lxc stop THREADVM-$((2 ** (i-1))) &&  sudo lxc delete THREADVM-$((2 ** (i-1)))
	done	
	echo "Performing Container Disk Benchmark"
	for i in {1..7}; do
                > "disk_eval_c_$((2 ** (i-1))).txt"
                sudo lxc launch ubuntu:22.04 THREADC-$((2 ** (i-1))) -c limits.cpu=$((2 ** (i-1))) -c limits.memory=4GiB
                sleep 20
                sudo lxc info THREADC-$((2 ** (i-1)))
                sleep 10
                echo "Container is Running"
                sudo lxc stop THREADC-$((2 ** (i-1))) --force
                sudo lxc config device override THREADVM-$((2 ** (i-1))) root size=150GB
                sudo lxc config device set THREADVM-$((2 ** (i-1))) root size=150GB
                sudo lxc start THREADC-$((2 ** (i-1)))
                sleep 15
                sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c "sudo apt update && sudo apt install sysbench -y"
                #push_iofiles "THREADVM-$((2 ** (i-1)))"
                sleep 2
                sudo lxc list
                sudo lxc info THREADC-$((2 ** (i-1)))
                sleep 5
                sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$((2 ** (i-1))) prepare"
                sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$((2 ** (i-1))) run" >> "disk_eval_c_$((2 ** (i-1))).txt"
                sudo lxc exec THREADC-$((2 ** (i-1))) -- bash -c "sysbench fileio --file-num=128 --file-block-size=4096 --file-total-size=120G --file-test-mode=rndrd --file-io-mode=sync --file-extra-flags=direct --threads=$((2 ** (i-1))) cleanup"
                sudo lxc stop THREADC-$((2 ** (i-1))) &&  sudo lxc delete THREADC-$((2 ** (i-1)))
        done
	save_disk b #Reads Benchmark Output
	save_disk v #Reads Virtual Machine Output
	save_disk c # Reads Container Output
	python3 "python_disk.py" #Analyzes data into a csv file as required and forms and saves graphs
}

#Main function to choose form of benchmarking
main(){
    read -p "What type of benchmark do you wish to perform(CPU(c),Memory(m),Disk(d),Network(n)):" type
    if [ "$type" == "c" ]; then
                cpu_eval_main
    elif [ "$type" == "m" ]; then
                memory_eval_main 
    elif [ "$type" == "d" ]; then
                disk_eval_main
    elif [ "$type" == "n" ]; then
                network_eval_main
    else
                echo "Incorrect option"
                exit 1
    fi
}
#create_tmux_session "Example"
#initialize_VM "Example"
#delete_VM "Example"

main
