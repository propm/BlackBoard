import java.util.regex.*;


class ScrollManager{
  
  float x, y;      //画面左上端の座標
  float vx, vy;    //スクロール速度
  PImage view;     //背景
  float viewx;     //画像のx座標
  float viewx2;    //画像のx座標2
  float m;         //画像の拡大倍率
  
  ScrollManager(){
    x = y = 0;
    vx = 1;
    view = loadImage("space.jpg");
    
    m = 2;
    view.resize((int)(view.width*m), (int)(view.height*m));
    
    viewx = 0;
    viewx2 = view.width;
  }
  
  void move(){
    x += vx;
    
    viewx -= vx;
    viewx2 -= vx;
    
    if(viewx2 + view.width < 0 && width >= viewx + view.width)  viewx2 = viewx + view.width;
    if(viewx + view.width < 0 && width >= viewx2 + view.width)   viewx = viewx2 + view.width;
  }
  
  void drawView(){
    image(view, viewx, 0);
    image(view, viewx2, 0);
  }
}

class ReadText{
  
  String[] lines;
  
  //テキストファイルを読む
  void read(){
    lines = loadStrings("settings.txt");
  }
  
  //コマンドを読む
  void readCommands(){
    String[] tags = {"<appear>", "<bgm>", "<sound>", "<speed>"};
    String[] commands = {"die", "erase", "attacked"};
    String creg = "^("+tags[0]+"|"+tags[1]+"|"+tags[2]+"|"+tags[3]+")";  //タグのパターン
    
    //1秒ごとに文を読む
    for(int i = 0; i < lines.length; i++){
      Pattern p = Pattern.compile(creg);
      Matcher m = p.matcher(lines[i]);
      
      //文中にタグが存在したら
      if(m.find()){
        
        //タグの直後の文字が何文字目かを取得
        int num = 0;
        for(int j = 0; j < lines[i].length(); j++)  if(lines[i].substring(i, i+1).equals(">"))  num = i+1;
        
        //タグの後の文を取得
        String code = lines[i].substring(num, lines[i].length());
        
        //どのタグかを取得
        int tagnum = 0;
        for(int j = 0; j < tags.length; j++)  if(Pattern.compile(tags[j]).matcher(lines[i]).find())  tagnum = j+1;
        
        //タグごとの処理
        switch(tagnum){
          case 1:
            
            break;
          case 2:
            break;
          case 3:
            break;
          case 4:
            break;
        }
      }
      
    }
  }
  
}
