package com.example;

import com.example.HashInputFormat;
import com.example.HashOutputFormat;

import java.io.*;
import java.util.Arrays;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class HadoopSort
{
  public static class HashMapper
    extends Mapper<NullWritable, BytesWritable , BytesWritable, BytesWritable>{

    public void map(NullWritable key, BytesWritable value, Context context
                    ) throws IOException, InterruptedException {
	    byte[] record = value.getBytes();
	    byte[] hash = Arrays.copyOfRange(record,0,10);
	    BytesWritable temp_hash_key = new BytesWritable(hash);
	    context.write(temp_hash_key,value);
      }
    }

  public static class HashReducer
    extends Reducer<BytesWritable,BytesWritable,NullWritable,BytesWritable> {

    public void reduce(BytesWritable key, Iterable<BytesWritable> values,
                       Context context
                       ) throws IOException, InterruptedException {
      for (BytesWritable val : values) {
        context.write(NullWritable.get(),val);
      }
    }
  }

  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    Job job = Job.getInstance(conf, "Hadoop Sort");
    conf.set("mapreduce.reduce.memory.mb", "1024");  
    conf.set("mapreduce.reduce.java.opts", "-Xmx921m");
    job.setNumReduceTasks(16);
    job.setJarByClass(HadoopSort.class);
    job.setMapperClass(HashMapper.class);
    job.setReducerClass(HashReducer.class);
    job.setInputFormatClass(HashInputFormat.class);
    job.setOutputFormatClass(HashOutputFormat.class);
    job.setMapOutputKeyClass(BytesWritable.class); 
    job.setMapOutputValueClass(BytesWritable.class);
    job.setOutputKeyClass(NullWritable.class); 
    job.setOutputValueClass(BytesWritable.class);
    FileInputFormat.addInputPath(job, new Path(args[0]));
    FileOutputFormat.setOutputPath(job, new Path(args[1]));
    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}

