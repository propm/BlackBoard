
//エラーがないか確認する
class CheckText{
  
  final String[] tags = {"<size>", "<sound>", "<appear>" , "<bgm>", "<bs>"};
  final String[] commands = {"die", "erase", "attacked"};
  final String[] objects = {"Attacker", "Sin", "Tangent", "Parachuter", "Cannon", "Ninja"};
  
  String[] blines;
  String[] lines;
  
  boolean isError;        //エラーがあればtrue
  boolean isInitialized;  //initialがすでに呼ばれていればtrue
  String creg;            //タグのパターン用変数
  
  AudioPlayer nullplayer;
  Datasaver ds;
  
  CheckText(){
    creg = "^(";
    isError = false;
    isInitialized = false;
  }
  
  void read(){}
  
  void initial(){
    read();
    
    //タグのパターン作成
    for(int i = 0; i < tags.length; i++){
      creg = creg + tags[i];
      if(i < tags.length - 1)  creg = creg + "|";
      else                     creg = creg + ")";
    }
    
    //半角空白、タブ削除
    for(int i = 0; i < lines.length; i++){
      lines[i] = Pattern.compile(" ").matcher(blines[i]).replaceAll("");
      lines[i] = Pattern.compile("\t").matcher(lines[i]).replaceAll("");
    }
    
    isInitialized = true;
  }
  
  boolean check(){
    initial();
    
    //1秒ごとに文を読む
    for(int i = 0; i < lines.length; i++){
      Pattern p = Pattern.compile(creg);
      Matcher m = p.matcher(blines[i]);
      
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
        switch(tagnum){
          
          case 1:
            sizeError(code, i);
            break;
          
          case 2:
            soundError(code, 2, i);
            break;
          
          case 3:
            appearError(code, 3, i);
            break;
            
          case 4:
            bgmError(code, 4, i);
            break;
            
          case 5:
            bsError(code, 5, i);
            break;
        }
      }
    }
    
    return isError;
  }
  
  void sizeError(String code, int i){
    //エラー処理
    if(!Pattern.matches(tags[0]+"[0-9]+", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      isError = true;
      return;
    }
    
    //widthの抽出
    int w = 0;
    String a = getword(code, 0, "");
    
    if(a.equals("")){
      println("sizeが書かれていません。　行数: "+(i+1));
      isError = true;
      return;
    }
    
    try{
      w = Integer.parseInt(a);
    }catch(NumberFormatException e){
      println("sizeは数字で記入してください。　行数: "+(i+1));
      isError = true;
      return;
    }
    
    if(w <= 0){
      println("sizeが0になっています。　行数: "+(i+1));
      isError = true; 
      return;
    }
      
  }
  
  void soundError(String code, int tagnum, int i){
    boolean isMatchJ, isMatchK;
    boolean isErase;
    
    isMatchJ = isMatchK = false;
    isErase = false;
    
    //コマンドが正しいかどうかを確認
    //（コマンドがeraseの場合はオブジェクトの情報がかかれているかどうかも確認）
    for(int j = 0; j < commands.length; j++){
      if(Pattern.compile(tags[tagnum-1]+"\".+\">>"+commands[j]).matcher(lines[i]).find()){
        isMatchJ = true;
        if(j == 2){
          isErase = true;
          if(Pattern.matches(tags[tagnum-1]+"\".+\">>"+commands[j]+"\\(\\)", lines[i]))
            isMatchK = true;
        }
      }
    }
    
    //オブジェクトが正しいかどうかを確認
    //（コマンドがeraseの場合にはここを通らない）
    if(!isErase)
      for(int k = 0; k < objects.length; k++)
        if(Pattern.compile("\\("+objects[k]+"\\)").matcher(lines[i]).find())
          isMatchK = true;
    
    if(Pattern.compile("\\(\\)").matcher(lines[i]).find())  isMatchK = true;
    
    if(!(isMatchJ && isMatchK)){
      
      if(!isMatchJ)  println("そのようなコマンドは存在しません。 行数: "+(i+1));
      if(!isMatchK)
        if(isErase)  println("erase()コマンドにオブジェクトの情報は必要ありません。 行数: "+(i+1));
        else         println("そのようなオブジェクトは存在しません。 行数: "+(i+1));
      
      isError = true;
      return;
    }
    
    //ファイル名取得
    int number = getnum(code, 0, "\"");
    String filename = getword(code, number, "\"");
    
    //ファイルが存在するかの確認
    if(conffile(filename, i)){
      isError = true;
      return;
    }
  }
  
  void appearError(String code, int tagnum, int i){
    boolean isMatch = false;
    
    for(int j = 0; j < objects.length; j++)
      if(Pattern.matches(tags[tagnum-1]+objects[j]+"(:[0-9]+,[0-9]+){0,1}:[0-9]+s(,[0-9]+s)*", lines[i]))
        isMatch = true;
    
    if(!isMatch){
      println("書式通り記入してください。 行数： "+(i+1));
      isError = true;
      return;
    }
  }
  
  void bgmError(String code, int tagnum, int i){
    int ifcount = 0;
    
    //書式通りに記入されてなかった場合の処理
    if(!Pattern.matches(tags[tagnum-1]+"\".+\":[0-9]+s", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      isError = true;
      return;
    }
    
    //ファイル名取得
    String filename = "";
    for(int j = 0; j < code.length(); j++){
      if(code.substring(j, j+1).equals("\"")){
        if(ifcount == 1)  filename = code.substring(1, j);
        ifcount++;
      }
    }
    
    //ファイルが存在するかの確認
    if(conffile(filename, i)){
      isError = true;
      return;
    }
  }
  
  void bsError(String code, int tagnum, int i){
    //書式通りに記入されてなかった場合の処理
    if(!Pattern.matches(tags[tagnum-1]+"[0-9]+", lines[i])){
      println("書式通り記入してください。 行数： "+(i+1));
      isError = true;
      return;
    }
  }
  
  int[]     getsec(String code, int begin){
    return null;
  }
  
  // begin: 探し始める位置
  // end:探し終わる部分にある文字（「:」など）
  String    getword(String code, int begin, String end){
    return null;
  }
  
  int       getnum(String code, int begin, String end){
    return  0;
  }
  
  //戻り値1: 抜き出した文字列
  //戻り値2: endが左から数えて何文字目か(1から数える)
  String[]  getnumword(String code, int begin, String end){
    return null;
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
  
   boolean error(String errorcode, int num, int i, boolean flag){
    if((num == -1) == flag){
      println(errorcode+"  行数: "+(i+1));
      return true;
    }else{
      return false;
    }
  }
}
