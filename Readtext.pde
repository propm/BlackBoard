import java.util.regex.*;
import java.util.*;
import java.io.*;

//テキストを読み込む
class ReadText{
  
  final String[] tags = {"<size>", "<sound>", "<appear>" , "<bgm>", "<bs>"};
  final String[] commands = {"die", "erase", "attacked"};
  final String[] objects = {"Attacker", "Sin", "Tangent", "Parachuter", "Cannon", "Ninja"};
  
  String[] blines;
  String[] lines;
  int counter;                           //60なら1秒
  
  MyComparator compa = new MyComparator();
  AudioPlayer nullplayer;
  
  //テキストファイルを読む
  void read(){
    blines = loadStrings("settings.txt");
    lines = new String[blines.length];
  }
  
  //コマンドを読む
  void readCommands(){
    
    String creg = "^(";                                //タグのパターン用変数
    
    //タグのパターン作成
    for(int i = 0; i < tags.length; i++){
      creg = creg + tags[i];
      if(i < tags.length - 1)  creg = creg + "|";
      else                     creg = creg + ")";
    }
    
    //1秒ごとに文を読む
    for(int i = 0; i < lines.length; i++){
      Pattern p = Pattern.compile(creg);
      Matcher m = p.matcher(blines[i]);
      
      //半角空白、タブ削除
      lines[i] = Pattern.compile(" ").matcher(blines[i]).replaceAll("");
      lines[i] = Pattern.compile("\t").matcher(lines[i]).replaceAll("");
      
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
        
        Datasaver ds = new Datasaver();
        
        //ファイル名とオブジェクト名保持用の変数
        String object, filename;
        int ifcount = 0;
        
        //タグごとの処理
        switch(tagnum){
          
          case 1:
            sizepro(ds, code, tagnum, i);
            break;
          
          case 2:
            soundpro(ds, code, tagnum, i);
            break;
          
          case 3:
            appearpro(ds, code, tagnum, i);
            break;
            
          case 4:
            bgmpro(ds, code, tagnum, i);
            break;
            
          case 5:
            bspro(ds, code, tagnum, i);
            break;
        }
      }
    }
    
  }
  
  //*****************************************************************************************************************
  
  //sizeタグの処理
  void sizepro(Datasaver ds, String code, int tagnum, int i){
    
    //エラー処理
    if(!Pattern.matches(tags[tagnum-1]+"[0-9]+", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      System.exit(0);
    }
    
    //widthの抽出
    int w = 0;
    
    String a = getword(code, 0, "");
    if(a != null) w = Integer.parseInt(a);
    
    if(w > 0){
      db.screenw = w;
    }else{
      println("sizeが0になっています。　行数: "+(i+1));
      System.exit(0);
    }
  }
  
  //*****************************************************************************************************************
  
  //soundタグの処理
  void soundpro(Datasaver ds, String code, int tagnum, int i){
    String object, filename;
    
    //エラー処理
    if(!Pattern.matches(tags[tagnum-1]+"\".+\">>[a-z]+\\([a-zA-z]*\\)", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      System.exit(0);
    }
    
    //どのコマンドが使われているか調べる
    int comnum = -1;
    for(int j = 0; j < commands.length; j++)
      if(Pattern.compile(commands[j]).matcher(lines[i]).find())  comnum = j+1;
    
    if(error("そのようなコマンドは存在しません", comnum, i, true))  System.exit(0);
    
    //オブジェクト名取得
    int number = getnum(code, 0, "(");
    object = getword(code, number, ")");
    
    //どのオブジェクトを指しているか調べる
    int objectnum = -1;
    for(int j = 0; j < objects.length; j++)
      if(object.equals(objects[j]))  objectnum = j+1;
    
    if(object.equals(""))  objectnum = 0;
    if(error("そのようなオブジェクトは存在しません"+object, objectnum, i, true))  System.exit(0);
    
    //ファイル名取得
    number = getnum(code, 0, "\"");
    if(error("ファイル名を「\"\"」付きで書いてください", number, i, true))  System.exit(0);
    
    filename = getword(code, number, "\"");
    
    //ファイルが存在するかの確認
    if(conffile(filename, i))  System.exit(0);
    
    //音楽セット
    if(comnum == 1 || comnum == 3){
      if(objectnum > 0)                  db.setsound(objects[objectnum-1], commands[comnum-1], filename);
      else     for(String obj: objects)  db.setsound(obj, commands[comnum-1], filename);
    }
    else if(comnum == 2){
      if(objectnum > 0){
        println("オブジェクトの情報は必要ありません　行数: "+(i+1));
        System.exit(0);
      }
      db.oriplayer.erase = minim.loadSample(filename);
    }
  }
  
  //*****************************************************************************************************************
  
  //appearタグの処理
  void appearpro(Datasaver ds, String code, int tagnum, int i){
    if(!Pattern.matches(tags[tagnum-1]+"[A-Z][a-z]+(:[0-9]+,[0-9]+){0,1}:[0-9]+s+(,[0-9]+s)*", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      System.exit(0);
    }
    
    //秒数取得
    Matcher m = Pattern.compile("[0-9]+s").matcher(code);
    
    int freq = 0;      //秒数がいくつ指定されているか
    while(m.find()){
      freq++;
    }
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
    
    //dscの[intdata]    0:x座標 1:y座標
    //dscの[stringdata] 0:オブジェクト名
    
    for(int j = 0; j < freq; j++){
      Datasaver dsc = new Datasaver();
      dsc.tag = tagnum;
      dsc.intdata = new int[2];
      dsc.stringdata = new String[1];
      dsc.intdata[0] = dsc.intdata[1] = -10000;
      
      //座標取得(座標が書かれてない場合、intdata[1], [2]には何も入らない)
      if(number < nums[j][0]-1){
        for(int k = number; k < nums[0][0] - 1; k++){
          if(code.substring(k, k+1).equals(",")){
            dsc.intdata[0] = Integer.parseInt(code.substring(number, k));
            dsc.intdata[1] = Integer.parseInt(code.substring(k+1, nums[0][0]-1));
          }
        }
      }
      
      //データ保存
      dsc.sec = Integer.parseInt(code.substring(nums[j][0], nums[j][1]));
      dsc.stringdata[0] = object;
      tm.events.add(dsc);
    }
  }
  
  //*****************************************************************************************************************
  
  //bgmタグの処理
  void bgmpro(Datasaver ds, String code, int tagnum, int i){
    String filename;
    int ifcount = 0;
    
    //書式通りに記入されてなかった場合の処理
    if(!Pattern.matches(tags[tagnum-1]+"\".+\":[0-9]+s", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      System.exit(0);
    }
    
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
    
    //ファイルが存在するかの確認
    if(conffile(filename, i))  System.exit(0);
    
    //データ保存
    //[stringdata]  0:ファイル名
    
    ds.stringdata = new String[1];
    
    ds.tag = tagnum;
    ds.sec = Integer.parseInt(code.substring(nums[0], nums[1]));
    ds.stringdata[0] = filename;
    
    tm.events.add(ds);
  }
  
  //*****************************************************************************************************************
  
  //bsタグの処理
  void bspro(Datasaver ds, String code, int tagnum, int i){
    
    //書式通りに記入されてなかった場合の処理
    if(!Pattern.matches(tags[tagnum-1]+"[0-9]+", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      System.exit(0);
    }
    
    //弾速取得
    db.bs = Integer.parseInt(code.substring(0, code.length()));
  }
  
  //*****************************************************************************************************************
  
  int[] getsec(String code, int begin){
    //秒数取得
    int[] nums = {0, 0};                 //1つ目の要素は秒数の書き始めの位置、2つ目は書き終わりの位置
                                         //3つ目は0ならこれより左に秒数が書かれていないことを表す
    Pattern p = Pattern.compile(":|,");
    
    for(int j = begin; j >= 0; j--){
      if(nums[0] == 0 && nums[1] != 0 && p.matcher(code.substring(j, j+1)).find()){
        nums[0] = j+1;
      }
      if(nums[1] == 0 && code.substring(j, j+1).equals("s"))  nums[1] = j;
    }
    
    return nums;
  }
  
  //begin: 探し始める位置  end:探し終わる部分にある文字（「:」など）
  String getword(String code, int begin, String end){
    
    for(int i = begin; i <= code.length(); i++){
      try{
        if((end.equals("") && i == code.length()) || (code.substring(i, i+1).equals(end))){
          
          return code.substring(begin, i);
        }
      }catch(Exception e){}
    }
    return null;
  }
  
  //begin: 探し始める位置  end:探し終わる部分にある文字（「:」など）
  int getnum(String code, int begin, String end){
    
    for(int i = begin; i < code.length(); i++){
      if(code.substring(i, i+1).equals(end)){
        return i+1;
      }
    }
    return -1;
  }
    
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
  
  boolean error(String errorcode, int num, int i, boolean flag){
    if((num == -1) == flag){
      println(errorcode+"  行数: "+(i+1));
      return true;
    }else{
      return false;
    }
  }
  
  //ファイルが存在するかの確認
  boolean conffile(String filename, int i){
    
    try{
      nullplayer = minim.loadFile(filename);
    }catch(NullPointerException e){
      println("そのようなファイルは存在しません: \""+filename+"\"　行数: "+(i+1));
      return true;
    }
    
    return false;
  }
}

//一時保存用クラス
class Datasaver{
  int tag;
  int sec;
  int[] intdata;
  String[] stringdata;
  
  Datasaver(){
    sec = -1;
  }
}
