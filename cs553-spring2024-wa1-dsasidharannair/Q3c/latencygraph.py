import matplotlib.pyplot as plt

names=[]
avg_rtt=[]

f=open("network-test-latency.txt",'r')
for line in f:
    array=line.split()
    if(array):
        names.append(array[0])
        avg_rtt.append(float(array[1]))


plt.figure(figsize=(11, 7))
plt.bar(names,avg_rtt,color='lightgreen')
plt.title("Network Latency Test Bar Graph")
plt.xlabel("Domain Names")
plt.ylabel("Average RTT")
plt.savefig('LatencyGraph.png')

