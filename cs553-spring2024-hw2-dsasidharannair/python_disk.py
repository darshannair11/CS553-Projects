import csv
import matplotlib.pyplot as plt

xlabel=''
ylabel1=''
ylabel2=''
x=[]
y1=[]
y2=[]
z1=[]
z2=[]
k1=[]
k2=[]

fileer='disk_eval'

with open(fileer+'_b.txt', 'r') as file:
    header=file.readline().strip('\n').split(',')
    xlabel=header[0]
    ylabel1=header[1]
    ylabel2=header[2]
    for line in file:
        l=line.split(',')
        x.append(l[0])
        y1.append(float(l[1]))
        y2.append(float(l[2]))

with open(fileer+'_v.txt', 'r') as file:
    header=file.readline()
    for line in file:
        l=line.split(',')
        z1.append(float(l[1]))
        z2.append(float(l[2]))

#with open(fileer+'_c.txt', 'r') as file:
#    header=file.readline()
#    for line in file:
#        l=line.split(',')
#        k1.append(float(l[1]))
#        k2.append(float(l[2]))

csv_path="disk_eval.csv"
with open(csv_path, mode='w', newline='') as file:
    writer=csv.writer(file)
    line=["Virtualization Type","Threads","BlockSize (KB)","Operation","Access Pattern","I/O Mode","I/O Flag","Total Operations","Measured Throughput(MiB/sec)","Efficiency"]
    writer.writerow(line)
    for i in range(0,7):
        line=["BareMetal",x[i],4,"Read","Random","Sync","DirectIO",y1[i],y2[i],str(y2[i]/y2[i]*100)+"%"]
        writer.writerow(line)
        line = ["Virtual Machine",x[i],4,"Read","Random","Sync","DirectIO",z1[i],z2[i],str(z2[i]/y2[i]*100)+ "%"]
        writer.writerow(line)
        #line = ["Container",x[i],4,"Read","Random","Sync","DirectIO",k1[i], k2[i],str(k2[i]/y2[i]*100)+ "%"]
        #writer.writerow(line)

plt.figure(1)
plt.plot(x, y1, label='Baremetal')
plt.plot(x, z1, label='Virtual Machine')
#plt.plot(x, k1, label='Container')
plt.xlabel(xlabel)
plt.ylabel(ylabel1)
plt.title(xlabel+" VS "+ylabel1)
plt.legend()
plt.savefig('disk_operations.png')

plt.figure(2)
plt.plot(x, y2, label='Baremetal')
plt.plot(x, z2, label='Virtual Machine')
#plt.plot(x, k2, label='Container')
plt.xlabel(xlabel)
plt.ylabel(ylabel2)
plt.title(xlabel+" VS "+ylabel2)
plt.legend()
plt.savefig('disk_throughput.png')
