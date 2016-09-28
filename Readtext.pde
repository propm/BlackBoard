import java.util.regex.*;
import java.util.*;
import java.io.*;

class ReadText{
  
  final String[] tags = {"<size>", "<sound>", "<appear>" , "<bgm>", "<bs>"};
  final String[] commands = {"die", "erase", "attacked"};
  final String[] objects = {"Attacker", "Sin", "Tangent", "Parachuter"};
  
  String[] blines;
  String[] lines;
  ArrayList<Datasaver> secline;          //秒数が関係するタグの情報を保存する可変長配列
  ArrayList<Datasaver> nsecline;         //秒数が関係しない(ry
  ArrayList<Integer> misprintline;       //タグはついてるけど誤字ってる行を保存する配列
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
    secline = new ArrayList<Datasaver>();
    nsecline = new ArrayList<Datasaver>();
    misprintline = new ArrayList<Integer>();
    int asterisk = -1;
    
    //タグのパターン作成
    for(int i = 0; i < tags.length; i++){
      creg = creg + tags[i];
      if(i < tags.length - 1)  creg = creg + "|";
      else                     creg = creg + ")";
    }
    
    for(int i = 0; i < lines.length; i++){
      //アスタリスクの行であれば
      if(Pattern.compile("\\*{30,}").matcher(blines[i]).find())  asterisk = i;
    }
    
    //1秒ごとに文を読む
    for(int i = 0; i < lines.length; i++){
      Pattern p = Pattern.compile(creg);
      Matcher m = p.matcher(blines[i]);
      
      //半角空白、タブ削除
      lines[i] = Pattern.compile(" ").matcher(blines[i]).replaceAll("");
      lines[i] = Pattern.compile("\t").matcher(lines[i]).replaceAll("");
      
      if(i > asterisk){
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
              if(sizepro(ds, code, tagnum, i)){
                misprintline.add(i);
                continue;
              }
              break;
            
            case 2:
              if(soundpro(ds, code, tagnum, i)){
                misprintline.add(i);
                continue;
              }
              break;
            
            case 3:
              if(appearpro(ds, code, tagnum, i)){
                misprintline.add(i);
                continue;
              }
              break;
              
            case 4:
              if(bgmpro(ds, code, tagnum, i)){
                misprintline.add(i);
                continue;
              }
              break;
              
            case 5:
              if(bspro(ds, code, tagnum, i)){
                misprintline.add(i);
                continue;
              }
              break;
          }
        }else{
          if(!lines[i].equals("")){
            misprintline.add(i);
          }
        }
      }
    }
    
    //秒数順にソート
    Collections.sort(secline, compa);
    //タグ順にソート
    Collections.sort(nsecline, compa);
    
    //ファイル出力
    writetext();
  }
  
  //*****************************************************************************************************************
  
  //sizeタグの処理
  boolean sizepro(Datasaver ds, String code, int tagnum, int i){
    
    //エラー処理
    if(!Pattern.matches(tags[tagnum-1]+"[0-9]+", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
    }
    
    //widthの抽出
    int w = 0;
    
    String a = getword(code, 0, "");
    if(a != null) w = Integer.parseInt(a);
    
    if(w > 0){
      db.screenw = w;
    }else{
      println("sizeが0になっています。　行数: "+(i+1));
      return true;
    }
    
    //行数とタグを記憶
    ds.line = i;
    ds.tag = tagnum;
    
    nsecline.add(ds);
    return false;
  }
  
  //*****************************************************************************************************************
  
  //soundタグの処理
  boolean soundpro(Datasaver ds, String code, int tagnum, int i){
    String object, filename;
    
    //エラー処理
    if(!Pattern.matches(tags[tagnum-1]+"\".+\">>[a-z]+\\([a-zA-z]*\\)", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
    }
    
    //どのコマンドが使われているか調べる
    int comnum = -1;
    for(int j = 0; j < commands.length; j++)
      if(Pattern.compile(commands[j]).matcher(lines[i]).find())  comnum = j+1;
    
    if(error("そのようなコマンドは存在しません", comnum, i, true))  return true;
    
    //オブジェクト名取得
    int number = getnum(code, 0, "(");
    object = getword(code, number, ")");
    
    //どのオブジェクトを指しているか調べる
    int objectnum = -1;
    for(int j = 0; j < objects.length; j++)
      if(object.equals(objects[j]))  objectnum = j+1;
    
    if(object.equals(""))  objectnum = 0;
    if(error("そのようなオブジェクトは存在しません"+object, objectnum, i, true))  return true;
    
    //ファイル名取得
    number = getnum(code, 0, "\"");
    if(error("ファイル名を「\"\"」付きで書いてください", number, i, true))  return true;
    
    filename = getword(code, number, "\"");
    
    //ファイルが存在するかの確認
    if(conffile(filename, i))  return true;
    
    //音楽セット
    if(comnum == 1 || comnum == 3){
      if(objectnum > 0)                  db.setsound(objects[objectnum-1], commands[comnum-1], filename);
      else     for(String obj: objects)  db.setsound(obj, commands[comnum-1], filename);
    }
    else if(comnum == 2){
      if(objectnum > 0){
        println("オブジェクトの情報は必要ありません　行数: "+(i+1));
        return true;
      }
      db.oriplayer.erase = minim.loadSample(filename);
    }
    
    //行数とタグを記憶
    ds.line = i;
    ds.tag = tagnum;
    
    nsecline.add(ds);
    
    return false;
  }
  
  //*****************************************************************************************************************
  
  //appearタグの処理
  boolean appearpro(Datasaver ds, String code, int tagnum, int i){
    if(!Pattern.matches(tags[tagnum-1]+"[A-Z][a-z]+(:[0-9]+,[0-9]+){0,1}:[0-9]+s+(,[0-9]+s)*", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
    }
    
    //秒数取得
    Matcher m = Pattern.compile("[0-9]+s").matcher(code);
    
    int freq = 0;
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
    
    //秒数の数だけdsを生成、保存
    ds.dss = new Datasaver[freq];
    
    //dscの[intdata]    0:x座標 1:y座標
    //dscの[stringdata] 0:オブジェクト名
    
    for(int j = 0; j < freq; j++){
      Datasaver dsc = new Datasaver();
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
      ds.dss[j] = dsc;
      //println(dsc.sec);
    }
    
    ds.tag = tagnum;
    ds.line = i;
    
    //秒数が複数指定されていないなら、その秒数を行の順番を考えるときの行数にする
    if(ds.dss.length > 1)  ds.sec = 0;
    else                ds.sec = ds.dss[0].sec;
    secline.add(ds);
      
    return false;
  }
  
  //*****************************************************************************************************************
  
  //bgmタグの処理
  boolean bgmpro(Datasaver ds, String code, int tagnum, int i){
    String filename;
    int ifcount = 0;
    
    //書式通りに記入されてなかった場合の処理
    if(!Pattern.matches(tags[tagnum-1]+"\".+\":[0-9]+s", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
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
    if(conffile(filename, i))  return true;
    
    //データ保存
    //[stringdata]  0:ファイル名
    
    ds.stringdata = new String[1];
    
    ds.tag = tagnum;
    ds.line = i;
    ds.sec = Integer.parseInt(code.substring(nums[0], nums[1]));
    ds.stringdata[0] = filename;
    
    secline.add(ds);
    
    return false;
  }
  
  //*****************************************************************************************************************
  
  //bsタグの処理
  boolean bspro(Datasaver ds, String code, int tagnum, int i){
    
    //書式通りに記入されてなかった場合の処理
    if(!Pattern.matches(tags[tagnum-1]+"[0-9]+", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
    }
    
    //弾速取得
    db.bs = Integer.parseInt(code.substring(0, code.length()));
    
    ds.tag = tagnum;
    ds.line = i;
    nsecline.add(ds);
    
    return false;
  }
  
  //*****************************************************************************************************************
  
  //秒数ごとに指定されたことを実行
  void checksec(){
    for(int i = 0; i < secline.size(); i++){
      Datasaver ds = secline.get(i);
      if(counter/60.0 >= ds.sec && ds.dss == null){
        switch(ds.tag){
          case 4:
            if(bgm != null)  bgm.close();
            bgm = minim.loadFile(ds.stringdata[0]);
            bgm.loop();
            secline.remove(i);
            i--;
            break;
        }
      }
      
      
      if(ds.dss != null){
        for(int j = 0; j < ds.dss.length; j++){
          if(ds.dss[j] != null){
            if(counter/60.0 >= ds.dss[j].sec){
              
              switch(ds.tag){
                case 3:
                  checksecparts(ds.dss[j]);
                  ds.dss[j] = null;
                  break;
              }
            }
          }
        }
        
        //dssのうち、一つでも描画されてないオブジェクトがあったらflag = false
        boolean flag = true;
        for(int j = 0; j < ds.dss.length; j++){
          //println(ds.dss[j].flag);
          if(ds.dss[j] != null)  flag = false;
        }
        if(flag){
          secline.remove(0);
          i--;
        }
      }
    }
    
    counter++;
  }
  
  void checksecparts(Datasaver ds){
    if(ds.stringdata[0].equals("Attacker")){ 
      if(ds.intdata[1] != -10000 && ds.intdata[2] != -10000)  enemys.add(new Attacker(ds.intdata[1], ds.intdata[2]));
      else                                                    enemys.add(new Attacker());
    }
    if(ds.stringdata[0].equals("Sin"))
      if(ds.intdata[1] != -10000 && ds.intdata[2] != -10000)  enemys.add(new Sin(ds.intdata[1], ds.intdata[2]));
      else                                                    enemys.add(new Sin());
    if(ds.stringdata[0].equals("Tangent"))
      if(ds.intdata[1] != -10000 && ds.intdata[2] != -10000)  enemys.add(new Tangent(ds.intdata[1], ds.intdata[2]));
      else                                                    enemys.add(new Tangent());
    if(ds.stringdata[0].equals("Parachuter")){
      if(ds.intdata[1] != -10000 && ds.intdata[2] != -10000)  enemys.add(new Parachuter(ds.intdata[1], ds.intdata[2]));
      else                                                    enemys.add(new Parachuter());
    }
  }
  
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
  
  //Settings.txtへの書き込み
  void writetext(){
    int asterisk = 0;    //アスタリスクの行数-1  アスタリスクの行がない場合は1行目に作られる
    
    for(int i = 0; i < blines.length; i++){
      if(Pattern.compile("\\*{10}").matcher(blines[i]).find()){
        asterisk = i;
      }
    }
    
    //書き込む行を入れるようの配列　定義の+1は空白の行を入れる用
    String[] writelines = new String[asterisk+1+secline.size()+1+nsecline.size()+1+misprintline.size()];
    
    //アスタリスクの行がない場合にそれを作成する
    if(asterisk == 0){
      String a = "";
      for(int j = 0; j < 120; j++)  a += "*";
      writelines[0] = a;
    }
    
    //書き込む行を一行ずつ配列に入れていく
    for(int i = 0; i < writelines.length; i++){
      if(asterisk != 0 && i <= asterisk)  writelines[i] = blines[i];
    }
    
    writelines[asterisk+1] = "";
    
    //スクリプトの行を入れていく
    //iがasterisk+2なのはアスタリスクとスクリプトの行の間に一行開けるため
    //finishnumは処理が一段落したときの行+1
    int finishnum = 100;
    for(int i = asterisk+2; i < writelines.length; i++){
      int beginnum = i - (asterisk+2);                //アスタリスクの行の1行下が0から始まるようにした変数
      int beginnum2 = i - finishnum - (asterisk+2);   //同じく
      
      //初期設定系スクリプトの書き込み
      if(beginnum < nsecline.size())        writelines[i] = blines[nsecline.get(beginnum).line];
      else if(beginnum == nsecline.size()){
        writelines[i] = "";                        //空白挿入
        finishnum = beginnum+1;
      }
      
      //秒数関連スクリプトの書き込み
      else if(beginnum2 >= 0 && beginnum2 < secline.size()){
        Datasaver ds = secline.get(beginnum2);
        writelines[i] = blines[ds.line]; 
      }
      else if(beginnum2 == secline.size()){
        writelines[i] = "";                        //空白挿入
        finishnum = i+1;
      }
    }
    
    //誤字脱字ありスクリプトの書き込み
    for(int i = 0; i < misprintline.size(); i++){
      writelines[finishnum+i] = blines[misprintline.get(i)];
    }
    
    //ファイルに書き込み
    saveStrings(".\\data\\settings.txt", writelines);
  }
}

//Datasaverが入った配列を並べ替えるためのクラス
class MyComparator implements Comparator<Datasaver>{
  public int compare(Datasaver a, Datasaver b){
    if(a.sec != -10000 && b.sec != -10000)  return a.sec - b.sec;
    else                                    return a.tag - b.tag;
  }
}

//一時保存用クラス
class Datasaver{
  int tag;
  int line;
  int sec;
  int[] intdata;
  String[] stringdata;
  
  Datasaver[] dss;
  
  Datasaver(){
    sec = -10000;
  }
}
