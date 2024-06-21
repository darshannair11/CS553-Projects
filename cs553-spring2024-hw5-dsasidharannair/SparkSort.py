from pyspark import SparkConf, SparkContext
from pyspark.sql import SparkSession

def hash(record):
    return record[:10]

conf = SparkConf().setAppName("App").setMaster("yarn").set("spark.submit.deployMode", "client").set("spark.executor.instances", "4").set("spark.executor.memory", "4g").set("spark.executor.cores", "4").set("spark.yarn.am.memory", "1g")

sc = SparkContext(conf=conf)
spark = SparkSession(sc)

hashes = sc.binaryRecords("hdfs://tiny-instance-1:9000/user/dsasidharannair/input/new_output.bin", 16)

print("First few records:")
for record in hashes.take(5):
    print(list(record))

sorted_hashes = hashes.map(lambda record: (NullWritable.get(), BytesWritable(record))).sortBy(lambda x: extract_hash(x[1].getBytes()), ascending=True)

# I was planning to use my define custom output file class to write the output but I did not get the time

output_file = "hdfs://tiny-instance-1:9000/user/dsasidharannair/output"

sorted_hashes.saveAsNewAPIHadoopFile(output_path,"org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat","org.apache.hadoop.io.NullWritable","org.apache.hadoop.io.BytesWritable")
sc.stop()