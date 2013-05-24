import java.io.*;
import java.util.*;

import org.apache.hadoop.fs.Path;
import org.apache.hadoop.filecache.DistributedCache;
import org.apache.hadoop.conf.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapred.*;
import org.apache.hadoop.util.*;

public class Ngram extends Configured implements Tool {

  public static class Map extends MapReduceBase implements Mapper<Text, Text, IntWritable, ScoreTitlePair> { 
    private final static IntWritable one = new IntWritable(1); 
    private int n;
    private Set<String> queryGrams = new HashSet<String>();

    public void configure(JobConf job) {
      n = job.getInt("value.of.n", 4);
      
      Path[] queryFiles = new Path[0];
      try {
        queryFiles = DistributedCache.getLocalCacheFiles(job); 
      } catch (IOException ioe) {
          System.err.println("Caught exception while getting cached files: " + StringUtils.stringifyException(ioe)); 
      }
      for (Path file : queryFiles) {
        extractQueryGrams(file);
      }
    }

    private void extractQueryGrams(Path file) {
      try {
        LinkedList<String> gram = new LinkedList<String>();
        BufferedReader fis = new BufferedReader(new FileReader(file.toString())); 
        String line = null;
        StringBuilder query = new StringBuilder();
        while ((line = fis.readLine()) != null) {
          query.append(line).append(' ');
        }
        Tokenizer tokenizer = new Tokenizer(query.toString());
        while (tokenizer.hasNext()) {
          if (gram.size() < n) {
            gram.add(tokenizer.next());
            if (gram.size() == n) queryGrams.add(gram.toString());
          }
          else {
            gram.add(tokenizer.next());
            gram.remove();
            queryGrams.add(gram.toString());
          }
        }
      } catch (IOException ioe) {
        System.err.println("Caught exception while parsing the cached file '" + file + "': " + StringUtils.stringifyException(ioe)); 
      }
    }

    public void map(Text key, Text value, OutputCollector<IntWritable, ScoreTitlePair> output, Reporter reporter) throws IOException {
      LinkedList<String> gram = new LinkedList<String>();
      int score = 0;
      Tokenizer tokenizer = new Tokenizer(value.toString());
      while (tokenizer.hasNext()) {
        if (gram.size() < n) {
          gram.add(tokenizer.next());
        }
        else {
          gram.add(tokenizer.next());
          gram.remove();
        }
        if (queryGrams.contains(gram.toString())) score++;
      }
      
      if (score > 0) {
        output.collect(one, new ScoreTitlePair(score, key.toString()));
      }
    }
  }

  public static class Combine extends MapReduceBase implements Reducer<IntWritable, ScoreTitlePair, IntWritable, ScoreTitlePair> { 
    public void reduce(IntWritable key, Iterator<ScoreTitlePair> values, OutputCollector<IntWritable, ScoreTitlePair> output, Reporter reporter) throws IOException { 
      List<ScoreTitlePair> top20 = new ArrayList<ScoreTitlePair>(20);
      while (values.hasNext()) {
        ScoreTitlePair value = values.next();
        ScoreTitlePair value_copy = new ScoreTitlePair(value.getScore(), value.getTitle());
        if (top20.size() < 20) top20.add(value_copy);
        else {
          ScoreTitlePair currentMin = Collections.min(top20);
          if (currentMin.compareTo(value_copy) < 0) {
            top20.remove(currentMin);
            top20.add(value_copy);
          }
        }
      }
      for (ScoreTitlePair value : top20) {
        output.collect(key, value);
      }
    }
  }

  public static class Reduce extends MapReduceBase implements Reducer<IntWritable, ScoreTitlePair, IntWritable, Text> {
    public void reduce(IntWritable key, Iterator<ScoreTitlePair> values, OutputCollector<IntWritable, Text> output, Reporter reporter) throws IOException {
      List<ScoreTitlePair> top20 = new ArrayList<ScoreTitlePair>(20);
      while (values.hasNext()) {
        ScoreTitlePair value = values.next();
        ScoreTitlePair value_copy = new ScoreTitlePair(value.getScore(), value.getTitle());
        if (top20.size() < 20) top20.add(value_copy);
        else {
          ScoreTitlePair currentMin = Collections.min(top20);
          if (currentMin.compareTo(value_copy) < 0) {
            top20.remove(currentMin);
            top20.add(value_copy);
          }
        }
      }
      Collections.sort(top20, Collections.reverseOrder());
      for (ScoreTitlePair value : top20) {
        output.collect(new IntWritable(value.getScore()), new Text(value.getTitle()));
      }
    }
  }

  public int run(String[] args) throws Exception {
    // args: n query_file input_dir output_dir
    JobConf conf = new JobConf(getConf(), Ngram.class); 
    conf.setJobName("Ngram");

    conf.setOutputKeyClass(IntWritable.class);
    conf.setOutputValueClass(ScoreTitlePair.class);

    conf.setMapperClass(Map.class);
    conf.setCombinerClass(Combine.class);
    conf.setReducerClass(Reduce.class);

    conf.setInputFormat(ChunkInputFormat.class);
    conf.setOutputFormat(TextOutputFormat.class);
    
    conf.setInt("value.of.n", Integer.parseInt(args[0]));
    DistributedCache.addCacheFile(new Path(args[1]).toUri(), conf);
    FileInputFormat.setInputPaths(conf, new Path(args[2]));
    FileOutputFormat.setOutputPath(conf, new Path(args[3]));

    JobClient.runJob(conf);
    return 0;
  }

  public static void main(String[] args) throws Exception { 
    int res = ToolRunner.run(new Configuration(), new Ngram(), args); 
    System.exit(res);
  }
}