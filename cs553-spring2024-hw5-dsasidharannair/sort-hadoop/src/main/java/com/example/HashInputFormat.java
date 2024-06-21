package com.example;

import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.*;
import org.apache.hadoop.mapreduce.lib.input.*;

public class HashInputFormat extends FileInputFormat<NullWritable, BytesWritable> {

    @Override
    public RecordReader<NullWritable, BytesWritable> createRecordReader(InputSplit split, TaskAttemptContext context) {
        return new HashRecordReader();
    }

    public static class HashRecordReader extends RecordReader<NullWritable, BytesWritable> {

        private FSDataInputStream in;
        private long start_position;
        private long end_position;
        private long current_position;
        private BytesWritable record= new BytesWritable();
	private byte[] buffer = new byte[16384]; 
    	private int buffer_idx = 0;  
    	private int buffer_length = 0;

        @Override
        public void initialize(InputSplit genericSplit, TaskAttemptContext context) throws IOException, InterruptedException {
	    	FileSplit fsplit = (FileSplit) genericSplit;
    	    	Path file = fsplit.getPath();
    	    	FileSystem fs = file.getFileSystem(context.getConfiguration());
            	this.in = fs.open(fsplit.getPath());
            	this.start_position = fsplit.getStart();
            	this.end_position = start_position + fsplit.getLength();
            	this.current_position = start_position;
        }

        @Override
        public boolean nextKeyValue() throws IOException, InterruptedException {
		if (current_position >= end_position && buffer_idx >= buffer_length ) {
        		return false; 
    		}

		if(buffer_idx >= buffer_length){
			int bytes_to_read = (int)Math.min(end_position - current_position, 16384);
			if ((buffer_length = in.read(current_position, buffer, 0, bytes_to_read)) <= 0){ 
				return false;
			}
			buffer_idx =0;
			current_position+= buffer_length;
		}
		if(buffer_length-buffer_idx >= 16){
			byte[] record_buffer = new byte[16];
			System.arraycopy(buffer, buffer_idx, record_buffer, 0, 16);
			record.set(record_buffer, 0, 16);
			buffer_idx+=16;
			return true;
		}
		return false;
        }

        @Override
        public NullWritable getCurrentKey() throws IOException, InterruptedException {
		return NullWritable.get();
        }

        @Override
        public BytesWritable getCurrentValue() throws IOException, InterruptedException {
		return record;
        }

        @Override
        public float getProgress() throws IOException, InterruptedException {
		return (current_position-start_position)/(float)(end_position-start_position);
        }

        @Override
        public void close() throws IOException {
		if (in != null) {
                	in.close();
            	}
        }
    }
}
