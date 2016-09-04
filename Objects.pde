
//あらゆる初期設定を保存するクラス
class DataBase{
  
  float widthrate, heightrate;
  int bs;                        //弾速
  
  //効果音の敵種別ファイル名
  String at_die, sin_die, tan_die, para_die;
  String at_AT, sin_AT, tan_AT, para_AT;
  String erase;
  
  //敵の効果音を設定
  void setsound(String objectname, String command, String filename){
  
    if(objectname.equals("Attacker")){
      if(command.equals("die"))       at_die = filename;
      if(command.equals("attacked"))  at_AT = filename;
      
    }else if(objectname.equals("Sin")){
      if(command.equals("die"))       sin_die = filename;
      if(command.equals("attacked"))  sin_AT = filename;
      
    }else if(objectname.equals("Tangent")){
      if(command.equals("die"))       tan_die = filename;
      if(command.equals("attacked"))  tan_AT = filename;
      
    }else if(objectname.equals("Parachuter")){
      if(command.equals("die"))       para_die = filename;
      if(command.equals("attacked"))  para_AT = filename;
    }
  }
}

//敵
abstract class Enemy{
  float x, y, vx;             //画像左上の座標、横方向の速度
  int   w, h;                 //画像の大きさ
  int energy;                 //粉エネルギー
  int hp;                     //体力(何回消されたら消えるか)
  boolean dieflag;            //死んでいるならtrue
  ArrayList<PImage> imgs;     //画像
  
  //Polygon pol;                        //当たり判定用多角形
  AudioSample diesound, ATsound;  //効果音
  
  Enemy(){
    //pol = new Polygon();
    dieflag = false;
    imgs = new ArrayList<PImage>();    //アニメーションさせるために10枚ほど絵が必要
  }
  
  //******処理系関数******//
  abstract void move();
  
  void die(){
    dieflag = true;
    diesound.trigger();
  }
  
  //******画像系関数******//
  
  //反転
  void Reverse(){
    for(int i = 0; i < imgs.size(); i++){
      imgs.set(i, reverse(imgs.get(i)));
    }
  }
  
  void reSize(){
    for(int i = 0; i < imgs.size(); i++){
      imgs.get(i).resize((int)w, (int)h);
    }
  }
  
  //描画
  void draw(){
    image(imgs.get(0), x - sm.x, y - sm.y);
  }
  
}

//突撃隊
class Attacker extends Enemy{
  
  Attacker(){
    initial();
    reSize();
  }
  
  Attacker(int x, int y){
    this.x = x+sm.x;
    this.y = y+sm.y;
    initial();
    reSize();
  }
  
  void initial(){
    if(db.at_die != null)  diesound = minim.loadSample(db.at_die);
    if(db.at_AT != null)    ATsound = minim.loadSample(db.at_AT);
    
    imgs.add(loadImage("attacker.png"));
    w = (int)(imgs.get(0).width/20.0);
    h = (int)(imgs.get(0).height/20.0);
    vx = -1;
    
    hp = 2;
    y = height - h;
    
    Reverse();
  }
  
  void move(){
    x += vx;
    if(x - sm.x < width/2)  die();
  }
}

//フライングタコ
abstract class Flys extends Enemy{
  
  Flys(){
    imgs.add(loadImage("flyattacker.png"));
    w = (int)(imgs.get(0).width/20.0);
    h = (int)(imgs.get(0).height/20.0);
    hp = 1;
  }
}

//正弦タコ
class Sin extends Flys{
  
  float basicy;    //角度が0のときの高さ
  int theta;       //角度(ラジアンではない);
  
  Sin(){
    initial();
    basicy = random(height/3*2) + h/2 + height/6;
    reSize();
  }
  
  Sin(int x, int y){
    this.x      = x+sm.x;
    this.basicy = y+sm.y;
    
    initial();
    reSize();
  }
  
  void initial(){
    if(db.sin_die != null)     diesound = minim.loadSample(db.sin_die);
    if(db.sin_AT != null)  ATsound = minim.loadSample(db.sin_AT);
    
    theta = 0;
    vx = -2;
    Reverse();
  }
  
  void move(){
    theta+=2;
    y = basicy - sin(theta*PI/180)*height/6;
    x += vx;
  }
}

//タンジェントタコ
class Tangent extends Sin{
  
  Tangent(){
    if(db.tan_die != null)     diesound = minim.loadSample(db.tan_die);
    if(db.tan_AT != null)       ATsound = minim.loadSample(db.tan_AT);
    vx = -5;
  }
  
  Tangent(int x, int y){
    this.x = x+sm.x;
    this.basicy = y+sm.y;
    if(db.tan_die != null)     diesound = minim.loadSample(db.tan_die);
    if(db.tan_AT != null)  ATsound = minim.loadSample(db.tan_AT);
    vx = -5;
  }
  
  void move(){
    theta+=2;
    y = basicy - tan(theta*PI/180)*100;
    x += vx;
  }
}

//パラシュートタコ
class Parachuter extends Attacker{
  
  boolean paraflag;      //地面に着地するまではパラシュート状態：true
  
  Parachuter(){
    if(db.para_die != null)        diesound = minim.loadSample(db.para_die);
    if(db.para_AT != null)  ATsound = minim.loadSample(db.para_AT);
    
    paraflag = true;
    y = -random(100);
    x = random(500);
    vx = -0.5;
    
    reSize();
  }
  
  Parachuter(int x, int y){
    if(db.para_die != null)     diesound = minim.loadSample(db.para_die);
    if(db.para_AT != null)  ATsound = minim.loadSample(db.para_AT);
    
    paraflag = true;
    this.y = y+sm.y;
    this.x = x+sm.x;
    vx = -0.5;
    
    reSize();
  }
  
  void move(){
    if(paraflag){
      y += 6;
      x += vx;
      
      if(y > height - h){
        y = height - h;
        paraflag = false;
      }
      
    }else{
      super.move();
    }
  }
}

//プレイヤー
class Player{
  float bx, by, x, y;  //座標
  boolean ATflag;  //マウスクリック時true
  boolean wallflag;    //壁作ってるときtrue
  int count;
  //Polygon pol;
  
  AudioSample erasesound;
  
  Player(){
    if(db.erase != null)  erasesound = minim.loadSample(db.erase);
    ATflag = wallflag = false;
    //pol = new Polygon();
  }
  
  void move(){
    bx = x;
    by = y;
    
    x = mouseX;
    y = mouseY;
    
    if(x == bx && y == by){
      count++;
      if(count/60 >= 3)  wallflag = true;
    }else{
      count = 0;
      wallflag = false;
      if(ATflag)  attack();
    }
    
  }
  
  void attack(){
    for(int i = 0; i < enemys.size(); i++){
      //judge(pol, enemys.get(i).pol);
    }
  }
  
  void draw(){
    ellipse(x, y, 20, 20);
  }
}

//自陣
class Home{
  int x, y;            //自陣の中心の座標
  int w, h;
  PImage img;          //画像
  float imgm;          //画像の拡大倍率
  float angle;         //画像回転角度（単位：度）
  float anglev;        //角速度  （単位：度）
  boolean positive;    //各加速度が正負どちらに近づくか(trueなら正）
  int hp;              //体力
    
  Home(){
    
    x = (int)((float)width/50*6);
    y = (int)((float)height/2);
    
    img = reverse(loadImage("cleaner.png"));
    imgm = (float)1/3;
    
    w = (int)(img.width * imgm / db.widthrate);
    h = (int)(img.height * imgm / db.heightrate);
    
    img.resize(w, h);
    anglev = angle = 0;
  }
  
  void rotation(){
    pushMatrix();
    translate(x - sm.x, y - sm.y);
    rotate(angle/(180/PI));
    
    if(angle < -15)      positive = true;
    else if(angle > 15)  positive = false;
    
    if(positive)  anglev += 0.3;
    else          anglev -= 0.3;
    
    angle += anglev;
    //println(angle+" , "+anglev);
  }
  
  void draw(){
    rotation();
    image(img, 0 - w/2, 0-h/2);
    popMatrix();
  }
}
