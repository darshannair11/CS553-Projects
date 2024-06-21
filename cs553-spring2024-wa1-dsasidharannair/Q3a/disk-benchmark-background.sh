#!/bin/bash
echo "Benchmakr Process Started"
(time dd if="/dev/zero" of=OutputDeleteFile bs=1M count=1024) &> "disk-benchmark-background-log.txt" &
sleep 10
echo "DONE"
