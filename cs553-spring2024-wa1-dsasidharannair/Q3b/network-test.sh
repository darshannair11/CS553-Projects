#!/bin/bash

ifile="network-test-machinelist.txt"

> "network-test-latency.txt"

while IFS= read -r line
do
	echo "Pinging for $line ..."
	ping_result=$(ping -c 3 "$line" | grep "rtt" | awk -F '/' '{print $5}')
	echo "$ping_result"
	echo "$line $ping_result" >> "network-test-latency.txt"
done < "$ifile"


