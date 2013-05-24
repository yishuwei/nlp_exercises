import java.io.*;

import org.apache.hadoop.fs.*;
import org.apache.hadoop.conf.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapred.*;
import org.apache.hadoop.util.*;

public class ChunkInputFormat extends FileInputFormat<Text, Text> {
  @Override
  protected boolean isSplitable(FileSystem fs, Path filename) {
    // Don't split the chunk
    return false;
  }

  @Override
  public RecordReader<Text, Text> getRecordReader(InputSplit split, JobConf job, Reporter reporter) throws IOException {
    return new ChunkRecordReader((FileSplit) split, job);
  }

  public static class ChunkRecordReader implements RecordReader<Text, Text> {
    private long start;
    private long pos;
    private long end;
    private LineReader in;
    private Text buffer;

    public ChunkRecordReader(FileSplit split, Configuration job) throws IOException {
      start = split.getStart();
      end = start + split.getLength();
      final Path file = split.getPath();
      
      // open the file and seek to the start of the split
      FileSystem fs = file.getFileSystem(job);
      FSDataInputStream fileIn = fs.open(split.getPath());

      fileIn.seek(start);
      in = new LineReader(fileIn, job);
      buffer = new Text();      
      pos = start;
    }

    public Text createKey() {
      return new Text();
    }
  
    public Text createValue() {
      return new Text();
    }
    
    public synchronized boolean next(Text key, Text value) throws IOException {
      int newSize = 0;
      // find the next title line
      while (!isTitle(buffer.toString())) {
        newSize = in.readLine(buffer);
        if (newSize <= 0){
          return false;
        }
        pos += newSize;
      }
      
      key.set(getTitle(buffer.toString()));
      // store page content as value
      StringBuilder content = new StringBuilder();
      while (pos <= end) {
        newSize = in.readLine(buffer);
        if (newSize <= 0)
          break;
        pos += newSize;
        
        if (isTitle(buffer.toString()))
          break;
        content.append(buffer.toString()).append('\n');
      }
      value.set(content.toString());
      return true;
    }

    public boolean isTitle(String s) {
      int start = s.indexOf("<title>");
      int end = s.indexOf("</title>");
      if (start == -1 || end == -1)
        return false;
      return true;
    }
        
    public String getTitle(String s) {
      int start = s.indexOf("<title>");
      int end = s.indexOf("</title>");
      return s.substring(start + 7,end);
    }

    /**
     * Get the progress within the split
     */
    public float getProgress() throws IOException {
      if (start == end) {
        return 0.0f;
      } else {
        return Math.min(1.0f, (pos - start) / (float)(end - start));
      }
    }
  
    public synchronized long getPos() throws IOException {
      return pos;
    }

    public synchronized void close() throws IOException {
      if (in != null)
        in.close();
    }
  }
}
