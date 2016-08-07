import java.util.regex.*;
import java.util.*;
import java.io.*;

class ReadText{
  
  final String[] tags = {"<appear>", "<bgm>", "<sound>"};
  final String[] commands = {"die", "erase", "attacked"};
  final String[] objects = {"Attacker", "Sin", "Tangent", "Parachuter"};
  
  String[] lines;
  ArrayList<Datasaver> secline;          //秒数が関係するタグの情報を保存する可変長配列
  int counter;                           //60なら1秒
  
  AudioPlayer nullplayer;
  
  //テキストファイルを読む
  void read(){
    lines = loadStrings("settings.txt");
  }
  
  //コマンドを読む
  void readCommands(){
    
    String creg = "^(";                                //タグのパターン用変数
    secline = new ArrayList<Datasaver>();
    
    //タグのパターン作成
    for(int i = 0; i < tags.length; i++){
      creg = creg + tags[i];
      if(i < tags.length - 1)  creg = creg + "|";
      else                     creg = creg + ")";
    }
    
    MyComparator compa = new MyComparator();
    
    //1秒ごとに文を読む
    for(int i = 0; i < lines.length; i++){
      Pattern p = Pattern.compile(creg);
      Matcher m = p.matcher(lines[i]);
      
      //文中にタグが存在したら
      if(m.find()){
        
        //半角空白、タブ削除
        lines[i] = Pattern.compile(" ").matcher(lines[i]).replaceAll("");
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
        
        //秒数取得、データ保持用のクラスに保存
        int num = 0;
        int num2 = 0;
        Datasaver saver = new Datasaver();
        for(int j = code.length() - 1; j >= 0; j--){
          if(num == 0 && code.substring(j, j+1).equals(":"))  num = j+1;
          if(num2 == 0 && code.substring(j, j+1).equals("s"))  num2 = j;
        }
        
        //ファイル名とオブジェクト名保持用の変数
        String object, filename;
        int ifcount = 0;
        
        //タグごとの処理
        switch(tagnum){
          case 1:
            if(!Pattern.matches(tags[0]+"[A-Z][a-z]+:[0-9]+,[0-9]+:[0-9]+s", lines[i])){
              println("書式通り記入してください。 行数： "+(i+1));
              continue;
            }
            
            int number = 0;
            object = "";
            for(int j = 0; j < code.length(); j++){
              if(code.substring(j, j+1).equals(":")){
                object = code.substring(0, j);
                number = j+1;
                break;
              }
            }
            
            saver.intdata = new int[4];
            saver.stringdata = new String[1];
            
            for(int j = number; j < num - 1; j++){
              if(code.substring(j, j+1).equals(",")){
                saver.intdata[1] = Integer.parseInt(code.substring(number, j));
                saver.intdata[2] = Integer.parseInt(code.substring(j+1, num-1));
              }
            }
            
            saver.tag = tagnum;
            saver.intdata[0] = i;
            saver.intdata[3] = Integer.parseInt(code.substring(num, num2));
            saver.stringdata[0] = object;
            println(object);
            
            secline.add(saver);
            
            break;
          case 2:
            if(!Pattern.matches(tags[1]+"\".+\":[0-9]+s", lines[i])){
              println("書式通り記入してください。 行数： "+(i+1));
              continue;
            }

            filename = "";
            for(int j = 0; j < code.length(); j++){
              if(code.substring(j, j+1).equals("\"")){
                if(ifcount == 1)  filename = code.substring(1, j);
                ifcount++;
              }
            }
            
            if(!filename.equals("")){
              try{
                nullplayer = minim.loadFile(filename);
              }catch(NullPointerException e){
                println("そのようなファイルは存在しません: \""+filename+"\"　行数: "+(i+1));
                continue;
              }
            }

            saver.intdata = new int[2];
            saver.stringdata = new String[1];

            saver.tag = tagnum;
            saver.intdata[0] = i;
            saver.intdata[1] = Integer.parseInt(code.substring(num, num2));
            saver.stringdata[0] = filename;
            
            secline.add(saver);
            break;
          case 3:
            
            if(!Pattern.matches(tags[2]+"\".+\">>[a-z]+\\([a-zA-z]*\\)", lines[i])){
              println("書式通り記入してください。 行数： "+(i+1));
              continue;
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
              continue;
            }
            else{
              object = code.substring(parennum+1, code.length()-1);
              for(int j = 0; j < objects.length; j++)  if(object.equals(objects[j]))  objectnum = j+1;
              if(object.length() == 0)  objectnum = -1;
            }
            
            
            if(objectnum == 0){
              println("そのようなオブジェクトは存在しません: "+object+" 行数: "+(i+1));
              continue;
            }
            
            filename = "";
            for(int j = 0; j < code.length(); j++){
              if(code.substring(j, j+1).equals("\"")){
                if(ifcount == 1)  filename = code.substring(1, j);
                ifcount++;
              }
            }
            
            if(!filename.equals("")){
              try{
                nullplayer = minim.loadFile(filename);
              }catch(NullPointerException e){
                println("そのようなファイルは存在しません: \""+filename+"\"　行数: "+(i+1));
                continue;
              }
            }
            
            if(comnum == 1 || comnum == 3){
              if(objectnum > 0)  setsound(objects[objectnum-1], commands[comnum-1], filename);
              else               for(int j = 0; j < 4; j++)  setsound(objects[j], commands[comnum-1], filename);
            }
            else if(comnum == 2){
              if(objectnum > 0){
                println("オブジェクトの情報は必要ありません。 行数: "+(i+1));
                continue;
              }
              erase = filename;
            }
            break;
        }
      }
    }
    
    //秒数順にソート
    Collections.sort(secline, compa);
    
    for(int i = 0; i < secline.size(); i++){
      println(secline.get(i));
    }
  }
  
  void checksec(){
    for(int i = 0; i < secline.size(); i++){
      Datasaver ds = secline.get(i);
      if(counter/60.0 >= ds.intdata[ds.intdata.length-1]){
        switch(ds.tag){
          case 1:
            if(ds.stringdata[0].equals("Attacker"))    enemys.add(new Attacker(ds.intdata[1], ds.intdata[2]));
            if(ds.stringdata[0].equals("Sin"))         enemys.add(new Sin(ds.intdata[1], ds.intdata[2]));
            if(ds.stringdata[0].equals("Tangent"))     enemys.add(new Tangent(ds.intdata[1], ds.intdata[2]));
            if(ds.stringdata[0].equals("Parachuter")){
              enemys.add(new Parachuter(ds.intdata[1], ds.intdata[2]));
            }
            secline.remove(0);
            i--;
            break;
          case 2:
            if(bgm != null)  bgm.close();
            bgm = minim.loadFile(ds.stringdata[0]);
            bgm.loop();
            secline.remove(0);
            i--;
            break;
        }
      }
    }
    
    counter+= 2;
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
