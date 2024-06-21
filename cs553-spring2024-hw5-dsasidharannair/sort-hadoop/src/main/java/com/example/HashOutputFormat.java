package com.example;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import org.apache.hadoop.fs.*;
import org.apache.hadoop.mapreduce.*;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.io.*;


public class HashOutputFormat extends FileOutputFormat<NullWritable, BytesWritable> {

    protected static class HashRecordWriter extends RecordWriter<NullWritable, BytesWritable> {
        private DataOutputStream out;
	private ByteArrayOutputStream buffer;

        public HashRecordWriter(DataOutputStream out) {
    		this.out = out;
		this.buffer = new ByteArrayOutputStream(16384);
        }

        @Override
        public void write(NullWritable key,BytesWritable record) throws IOException {
     		if (record != null) {
			int record_length = record.getLength();
			if (buffer.size() + record_length > 16384) {
                    		out.write(buffer.toByteArray());
				buffer.reset();
                	}
                	buffer.write(record.getBytes(),0,record_length);
            	}
        }

        @Override
        public void close(TaskAttemptContext context) throws IOException {
		if(buffer.size() > 0){
			out.write(buffer.toByteArray());
			buffer.reset();
		}
		buffer.close();
		out.close();
        }
    }

    @Override
    public RecordWriter<NullWritable, BytesWritable> getRecordWriter(TaskAttemptContext job)
        throws IOException, InterruptedException {
        Path file = getDefaultWorkFile(job, "");
        FileSystem fs = file.getFileSystem(job.getConfiguration());
        FSDataOutputStream out =fs.create(file, false);
        return new HashRecordWriter(new DataOutputStream(out));
    }
}

