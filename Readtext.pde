import java.util.regex.*;
import java.util.*;
import java.io.*;

//テキストを読み込む
class ReadText extends CheckText{
  
  //テキストファイルを読む
  void read(){
    lines = loadStrings("settings.txt");
  }
  
  //コマンドを読む
  void readCommands(){
    
    if(!isInitialized)  initial();
    
    //1行ごとに文を読む
    for(int i = 0; i < lines.length; i++){
      Pattern p = Pattern.compile(creg);
      Matcher m = p.matcher(lines[i]);
      
      //文中にタグが存在したら
      if(m.find()){
        
        //どのタグかを取得
        int tagnum = 0;
        for(int j = 0; j < tags.length; j++)
          if(Pattern.compile("^"+tags[j]).matcher(lines[i]).find())  tagnum = j+1;
        
        //タグの後の文を取得
        String code = "";
        for(int j = 0; j < lines[i].length(); j++){
          if(lines[i].substring(j, j+1).equals(">")){
            code = lines[i].substring(j+1, lines[i].length());
            break;
          }
        }
        
        ds = new Datasaver();
        
        //タグごとの処理
        switch(tags[tagnum-1]){
          case "<appear>":
            appearpro(code, tagnum, i);
            break;
          case "<bgm>":
            bgmpro(code, tagnum, i);
            break;
        }
      }
    }
  }
  
  //*****************************************************************************************************************
  
  //appearタグの処理
  void appearpro(String code, int tagnum, int i){
    
    //秒数取得
    Matcher m = Pattern.compile("[0-9]+s").matcher(code);
    
    int freq = 0;      //秒数がいくつ指定されているか
    while(m.find()){
      freq++;
    }
    
    //
    int[][] nums = new int[freq][2];
    for(int j = nums.length-1; j >= 0; j--){
      nums[j] = getsec(code, j != nums.length-1 ? nums[j+1][0] : code.length()-1);
    }
    
    //オブジェクト名取得
    int number = 0;        //オブジェクト名の次の:の終わりの位置
    String object = "";    //オブジェクト名
    
    String[] a = getnumword(code, 0, ":");
    object = a[0];
    number = Integer.parseInt(a[1]);
    
    //[intdata]    0:x座標 1:y座標
    //[stringdata] オブジェクト名
    
    for(int j = 0; j < freq; j++){
      ds = new Datasaver();
      ds.tag = tagnum;
      
      //座標取得(座標が書かれてない場合、intdata[1], [2]には何も入らない)
      if(number < nums[j][0]-1){
        for(int k = number; k < nums[0][0] - 1; k++){
          if(code.substring(k, k+1).equals(",")){
            ds.intdata[0] = Integer.parseInt(code.substring(number, k));
            ds.intdata[1] = Integer.parseInt(code.substring(k+1, nums[0][0]-1));
          }
        }
      }
      
      //データ保存
      ds.sec = Integer.parseInt(code.substring(nums[j][0], nums[j][1]));
      ds.stringdata = object;
      tm.Add(ds);
    }
  }
  
  //*****************************************************************************************************************
  
  //bgmタグの処理
  void bgmpro(String code, int tagnum, int i){
    String filename;
    int ifcount = 0;
    
    //秒数取得
    int[] nums = getsec(code, code.length()-1);
    
    //ファイル名取得
    filename = "";
    for(int j = 0; j < code.length(); j++){
      if(code.substring(j, j+1).equals("\"")){
        if(ifcount == 1)  filename = code.substring(1, j);
        ifcount++;
      }
    }
    
    //データ保存
    //[stringdata]  ファイル名
    
    ds.tag = tagnum;
    ds.sec = Integer.parseInt(code.substring(nums[0], nums[1]));
    
    ds.stringdata = filename;
    tm.Add(ds);
  }
  
  //*****************************************************************************************************************
  
  //引数: code:読み込む文字列　begin:探し始める位置
  //戻り値: 秒数
  int[] getsec(String code, int begin){
    //秒数取得
    int[] nums = {0, 0};                 //1つ目の要素は秒数の書き始めの位置、2つ目は書き終わりの位置
    Pattern p = Pattern.compile(":|,");
    
    for(int j = begin; j >= 0; j--){
      if(nums[0] == 0 && nums[1] != 0 && p.matcher(code.substring(j, j+1)).find()){
        nums[0] = j+1;
      }
      if(nums[1] == 0 && code.substring(j, j+1).equals("s"))  nums[1] = j;
    }
    
    return nums;
  }
  
  //引数:  code:読み込む文字列　begin:探し始める位置　end:探し終わりの位置にある文字
  //戻り値:  1つ目の要素：抜き取った文字列　　2つ目の要素：次に文字列を抜き取るときにどこから始めるか
  String[] getnumword(String code, int begin, String end){
    
    String[] word = {null, "-1"};
    for(int i = begin; i < code.length(); i++)
      if(code.substring(i, i+1).equals(end)){
        word[0] = code.substring(begin, i);
        word[1] = String.valueOf(i+1);
        return word;
      }
      
    return word;
  }
}

//一時保存用クラス
class Datasaver implements Cloneable{
  int tag;
  int sec;
  int[] intdata;
  String stringdata;
  
  { sec = -1;
    intdata = new int[]{-10000, -10000};
  }
}