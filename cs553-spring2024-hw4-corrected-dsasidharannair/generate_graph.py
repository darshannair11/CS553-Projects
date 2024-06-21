import pandas as pd
import matplotlib.pyplot as plt
import sys

if len(sys.argv) != 2:
    print("Invalid number of arguments")
    sys.exit(1)

size = sys.argv[1]

if(size == 's'):
    dirr = "1GB"
else:
    dirr = "64GB"

df = pd.read_csv("results_"+size+".csv", names=["Config", "Time", "MHs", "MBs"])
metrics = ["Time", "MHs", "MBs"]
for metric in metrics:
    plt.figure(figsize=(10, 6))
    bars = plt.bar(df.index, df[metric], color='#967BB6')

    for i, value in enumerate(df[metric]):
        if value == df[metric].max():
            bars[i].set_color('#B80000')
        elif value == df[metric].min():
            bars[i].set_color('#90D26D')

    plt.xlabel('Config')
    plt.ylabel(metric)
    plt.title('Comparison of '+metric+' for 27 Configs')
    plt.xticks(df.index, df['Config'], rotation=90)
    plt.tight_layout()
    plt.savefig("./results/"+dirr+"/"+metric+'_graph_'+size+'.png')
    plt.close()

df[['Hash Threads', 'Sort Threads', 'Write Threads']]=df['Config'].str.split('-', expand=True)
df = df[['Hash Threads', 'Sort Threads', 'Write Threads', 'Time', 'MHs', 'MBs']]
df.to_csv("./results/"+dirr+"/result_mod_"+size+".csv", index=False)