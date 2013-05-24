import java.io.*;
import org.apache.hadoop.io.*;

public class ScoreTitlePair implements WritableComparable<ScoreTitlePair> {
  private int score;
  private String title;

  public ScoreTitlePair() {
    score = 0;
    title = "";
  }
  
  public ScoreTitlePair(int score, String title){
    this.score = score;
    this.title = title;
  } 

  public void write(DataOutput out) throws IOException {
    out.writeInt(score);
    WritableUtils.writeString(out, title);
  }
       
  public void readFields(DataInput in) throws IOException {
    score = in.readInt();
    title = WritableUtils.readString(in);
  }
  
  public int getScore() {
    return score;
  }
  
  public String getTitle() {
    return title;
  }

  public int compareTo(ScoreTitlePair other) {
    int diff = this.score - other.score;
    return diff == 0 ? this.title.compareTo(other.title) : diff;
  }
}
