
//エラーがないか確認する
class CheckText{
  
  final String[] tags = {"<appear>", "<bgm>"};
  final String[] objects = {"Attacker", "Sin", "Tangent", "Parachuter", "Cannon", "Ninja"};
  
  String[] lines;         //ファイルの内容を読み込む
  
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
      lines[i] = Pattern.compile(" ").matcher(lines[i]).replaceAll("");
      lines[i] = Pattern.compile("\t").matcher(lines[i]).replaceAll("");
    }
    
    isInitialized = true;
  }
  
  //エラーチェック
  boolean check(){
    initial();
    
    //1秒ごとに文を読む
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
            appearError(code, tagnum, i);
            break;
          case "<bgm>":
            bgmError(code, tagnum, i);
            break;
        }
      }
    }
    
    return isError;
  }
  
  //appearタグのエラー処理
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
  
  //bgmタグのエラー処理
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