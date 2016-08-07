import java.util.regex.*;
import java.util.*;
import java.io.*;

class ReadText{
  
  final String[] tags = {"<size>", "<sound>", "<appear>", "<bgm>"};
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
      
      //文中にタグが存在したら
      if(m.find()){
        
        //半角空白、タブ削除
        lines[i] = Pattern.compile(" ").matcher(blines[i]).replaceAll("");
        lines[i] = Pattern.compile("\t").matcher(lines[i]).replaceAll("");
        
        //どのタグかを取得
        int tagnum = 0;
        for(int j = 0; j < tags.length; j++)  if(Pattern.compile("^"+tags[j]).matcher(lines[i]).find())  tagnum = j+1;
        
        //タグの後の文を取得
        String code = "";
        for(int j = 0; j < lines[i].length(); j++){
          if(lines[i].substring(j, j+1).equals(">")){
            code = lines[i].substring(j+1, lines[i].length());
            break;
          }
        }
        
        Datasaver saver = new Datasaver();
        
        //ファイル名とオブジェクト名保持用の変数
        String object, filename;
        int ifcount = 0;
        
        //タグごとの処理
        switch(tagnum){
          
          case 1:
            if(sizepro(saver, code, tagnum, i)){
              misprintline.add(i);
              continue;
            }
            break;
          
          case 2:
            if(soundpro(saver, code, tagnum, i)){
              misprintline.add(i);
              continue;
            }
            break;
          
          case 3:
            if(appearpro(saver, code, tagnum, i)){
              misprintline.add(i);
              continue;
            }
            break;
            
          case 4:
            if(bgmpro(saver, code, tagnum, i)){
              misprintline.add(i);
              continue;
            }
            break;
        }
      }
    }
    
    //秒数順にソート
    Collections.sort(secline, compa);
    //タグ順にソート
    Collections.sort(nsecline, compa);
    
    println(secline.size());

    //ファイル出力
    writetext();
  }
  
  //sizeタグの処理
  boolean sizepro(Datasaver saver, String code, int tagnum, int i){
    
    if(!Pattern.matches(tags[tagnum-1]+"[0-9]+,[0-9]+", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
    }
    
    int w = 0, h = 0;
    for(int j = 0; j < code.length(); j++){
      if(code.substring(j, j+1).equals(",")){
        w = Integer.parseInt(code.substring(0, j));
        h = Integer.parseInt(code.substring(j+1,code.length()));
      }
    }
    
    size(w, h);
    
    saver.intdata = new int[2];
    saver.intdata[0] = i;
    saver.intdata[1] = tagnum;
    
    nsecline.add(saver);
    return false;
  }
  
  //soundタグの処理
  boolean soundpro(Datasaver saver, String code, int tagnum, int i){
    String object, filename;
    int ifcount = 0;
    
    if(!Pattern.matches(tags[tagnum-1]+"\".+\">>[a-z]+\\([a-zA-z]*\\)", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
    }
    
    int parennum = 0;  // "("がある位置
    for(int j = code.length()-1; j >= 0 ; j--){
      if(code.substring(j, j+1).equals("(")){
        parennum = j;
        break;
      }
    }
    
    //どのコマンドが使われているか調べる
    int comnum = 0;
    for(int j = 0; j < commands.length; j++){
      String s = commands[j]+"\\([a-zA-Z]*\\)$";
      if(Pattern.compile(s).matcher(lines[i]).find())  comnum = j+1;
    }
    
    //どのオブジェクトを指しているか調べる
    int objectnum = 0;
    if(comnum == 0){
      println("そのようなコマンドは存在しません 行数: "+(i+1));
      return true;
    }
    else{
      object = code.substring(parennum+1, code.length()-1);
      for(int j = 0; j < objects.length; j++)  if(object.equals(objects[j]))  objectnum = j+1;
      if(object.length() == 0)  objectnum = -1;
    }
    
    
    if(objectnum == 0){
      println("そのようなオブジェクトは存在しません: "+object+" 行数: "+(i+1));
      return true;
    }
    
    filename = "";
    for(int j = 0; j < code.length(); j++){
      if(code.substring(j, j+1).equals("\"")){
        if(ifcount == 1)  filename = code.substring(1, j);
        ifcount++;
      }
    }
    
    //ファイルが存在するかの確認
    if(conffile(filename, i))  return true;
    
    if(comnum == 1 || comnum == 3){
      if(objectnum > 0)  setsound(objects[objectnum-1], commands[comnum-1], filename);
      else               for(int j = 0; j < 4; j++)  setsound(objects[j], commands[comnum-1], filename);
    }
    else if(comnum == 2){
      if(objectnum > 0){
        println("オブジェクトの情報は必要ありません。 行数: "+(i+1));
        return true;
      }
      erase = filename;
    }
    
    saver.intdata = new int[2];
    saver.intdata[0] = i;
    saver.intdata[1] = tagnum;
    
    nsecline.add(saver);
    
    return false;
  }
  
  //appearタグの処理
  boolean appearpro(Datasaver saver, String code, int tagnum, int i){
    if(!Pattern.matches(tags[tagnum-1]+"[A-Z][a-z]+:[0-9]+,[0-9]+:[0-9]+s", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
    }
    
    //秒数取得
    int[] nums = getsec(code); 
    
    //オブジェクト名取得
    int    number = 0;
    String object = "";
    for(int j = 0; j < code.length(); j++){
      if(code.substring(j, j+1).equals(":")){
        object = code.substring(0, j);
        number = j+1;
        break;
      }
    }
    
    saver.intdata = new int[4];
    saver.stringdata = new String[1];
    
    //座標取得
    for(int j = number; j < nums[0] - 1; j++){
      if(code.substring(j, j+1).equals(",")){
        saver.intdata[1] = Integer.parseInt(code.substring(number, j));
        saver.intdata[2] = Integer.parseInt(code.substring(j+1, nums[0]-1));
      }
    }
    
    //データ保存
    saver.tag = tagnum;
    saver.intdata[0] = i;
    saver.intdata[3] = Integer.parseInt(code.substring(nums[0], nums[1]));
    saver.stringdata[0] = object;
    
    secline.add(saver);
    
    return false;
  }
  
  //bgmタグの処理
  boolean bgmpro(Datasaver saver, String code, int tagnum, int i){
    String filename;
    int ifcount = 0;
    
    //書式通りに記入されてなかった場合の処理
    if(!Pattern.matches(tags[tagnum-1]+"\".+\":[0-9]+s", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      return true;
    }
    
    //秒数取得
    int[] nums = getsec(code);
    
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
    saver.intdata = new int[2];
    saver.stringdata = new String[1];
    
    saver.tag = tagnum;
    saver.intdata[0] = i;
    saver.intdata[1] = Integer.parseInt(code.substring(nums[0], nums[1]));
    saver.stringdata[0] = filename;
    
    secline.add(saver);
    
    return false;
  }
  
  void checksec(){
    
    for(int i = 0; i < secline.size(); i++){
      Datasaver ds = secline.get(i);
      if(counter/60.0 >= ds.intdata[ds.intdata.length-1]){
        switch(ds.tag){
          case 3:
            if(ds.stringdata[0].equals("Attacker"))    enemys.add(new Attacker(ds.intdata[1], ds.intdata[2]));
            if(ds.stringdata[0].equals("Sin"))         enemys.add(new Sin(ds.intdata[1], ds.intdata[2]));
            if(ds.stringdata[0].equals("Tangent"))     enemys.add(new Tangent(ds.intdata[1], ds.intdata[2]));
            if(ds.stringdata[0].equals("Parachuter")){
              enemys.add(new Parachuter(ds.intdata[1], ds.intdata[2]));
            }
            secline.remove(0);
            i--;
            break;
            
          case 4:
            if(bgm != null)  bgm.close();
            bgm = minim.loadFile(ds.stringdata[0]);
            bgm.loop();
            secline.remove(0);
            i--;
            break;
        }
      }
    }
    
    counter++;
  }
  
  int[] getsec(String code){
    //秒数取得、データ保持用のクラスに保存
    int[] nums = {0, 0};
    
    for(int j = code.length() - 1; j >= 0; j--){
      if(nums[0] == 0 && code.substring(j, j+1).equals(":"))  nums[0] = j+1;
      if(nums[1] == 0 && code.substring(j, j+1).equals("s"))  nums[1] = j;
    }
    
    return nums;
  }
  
  //ファイルが存在するかの確認
  boolean conffile(String filename, int i){
    
    if(!filename.equals("")){
      try{
        nullplayer = minim.loadFile(filename);
      }catch(NullPointerException e){
        println("そのようなファイルは存在しません: \""+filename+"\"　行数: "+(i+1));
        return true;
      }
    }
    
    return false;
  }
  
  void writetext(){
    int asterisk = -1;
    
    for(int i = 0; i < blines.length; i++){
      if(Pattern.compile("\\*{10}").matcher(blines[i]).find()){
        asterisk = i;
      }
    }
    
    String[] writelines = new String[asterisk+1+1+secline.size()+1+nsecline.size()+1+misprintline.size()];
    for(int i = 0; i < writelines.length; i++){
      if(i <= asterisk)  writelines[i] = blines[i];
    }
    
    writelines[asterisk+1] = "";
    
    int finishnum = 100;
    for(int i = asterisk+2; i < writelines.length; i++){
      int beginnum = i - (asterisk+2);    //0から始まるようにした変数
      int beginnum2 = i - finishnum - (asterisk+2);
      
      if(beginnum < nsecline.size())        writelines[i] = blines[nsecline.get(beginnum).intdata[0]];
      else if(beginnum == nsecline.size()){
        writelines[i] = "";
        finishnum = beginnum+1;
      }
      else if(beginnum2 >= 0 && beginnum2 < secline.size()){
        Datasaver saver = secline.get(beginnum2);
        writelines[i] = blines[saver.intdata[0]]; 
      }
      else if(beginnum2 == secline.size()){
        writelines[i] = "";
        finishnum = i+1;
      }
    }
    
    for(int i = 0; i < misprintline.size(); i++){
      writelines[finishnum+i] = blines[misprintline.get(i)];
    }
    
    saveStrings(".\\data\\settings.txt", writelines);
  }
}

class MyComparator implements Comparator<Datasaver>{
  public int compare(Datasaver a, Datasaver b){
    return a.intdata[a.intdata.length - 1] - b.intdata[b.intdata.length - 1];
  }
}

class Datasaver{
  int tag;
  int[] intdata;
  String[] stringdata;
}
