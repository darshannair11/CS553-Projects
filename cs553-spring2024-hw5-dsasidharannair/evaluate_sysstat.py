import matplotlib.pyplot as plt
import pandas as pd
import sys

arg1 = sys.argv[1]

memory_data = pd.read_csv("logs/memory_stats_"+arg1+".txt", delimiter="\s+", skiprows=2)
cpu_data = pd.read_csv("logs/cpu_stats_"+arg1+".txt", delimiter="\s+", skiprows=2)

temp = []

with open("logs/disk_stats_"+arg1+".txt", 'r') as file:
    for line in file:
        if line.startswith('sda'):
            data = line.split()
            temp.append(data[1:])

columns = ['r/s', 'rkB/s', 'rrqm/s', '%rrqm', 'r_await', 'rareq-sz', 'w/s', 'wkB/s', 'wrqm/s', '%wrqm', 'w_await', 'wareq-sz', 'd/s', 'dkB/s', 'drqm/s', '%drqm', 'd_await', 'dareq-sz', 'f/s', 'f_await', 'aqu-sz', '%util']
disk_data = pd.DataFrame(temp, columns=columns)
disk_data = disk_data.apply(pd.to_numeric)

print(disk_data.sample(2))


plt.figure(figsize=(10, 5))
plt.plot(memory_data.index, memory_data['%memused'], label='Memory', color='blue')
plt.plot(cpu_data.index, cpu_data['%usr'], label='CPU', color='green')
plt.plot(disk_data.index, disk_data['%util'], label='Disk', color='red')

plt.title('Usage')
plt.xlabel('Time')
plt.ylabel('Usage')
plt.legend()
plt.grid(True)

plt.savefig('usage_'+arg1+'.png')
