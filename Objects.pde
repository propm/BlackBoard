
//あらゆる初期設定を保存するクラス
class DataBase{
  
  float widthrate, heightrate;
  int bs;                        //弾速
  
  //効果音の敵種別ファイル名
  String erase;
  
  Enemy[] oriEnemys = new Enemy[4];    //敵種別設定用のオブジェクト
                                       //1:突撃兵  2:サイン  3:タンジェント  4:パラシュート
  
  DataBase(){
    for(int i = 0; i < oriEnemys.length; i++){
      oriEnemys[i] = new Enemy();
    }
  }
  
  //敵の効果音を設定
  void setsound(String objectname, String command, String filename){
    Enemy[] oe = oriEnemys;
  
    if(objectname.equals("Attacker")){
      if(command.equals("die"))       oe[0].diesound = minim.loadSample(filename);
      if(command.equals("attacked"))  oe[0].ATsound  = minim.loadSample(filename);
      
    }else if(objectname.equals("Sin")){
      if(command.equals("die"))       oe[1].diesound = minim.loadSample(filename);
      if(command.equals("attacked"))  oe[1].ATsound  = minim.loadSample(filename);
      
    }else if(objectname.equals("Tangent")){
      if(command.equals("die"))       oe[2].diesound = minim.loadSample(filename);
      if(command.equals("attacked"))  oe[2].ATsound  = minim.loadSample(filename);
      
    }else if(objectname.equals("Parachuter")){
      if(command.equals("die"))       oe[3].diesound = minim.loadSample(filename);
      if(command.equals("attacked"))  oe[3].ATsound  = minim.loadSample(filename);
    }
  }
  
  void setenemys(){
    for(int i = 0; i < oriEnemys.length; i++){
      
      Enemy e = oriEnemys[i];
      
      switch(i){
        case 0:
        case 3:
          e.hp = 2;
          
          e.imgs.add(loadImage("attacker.png"));
          e.w = (int)(e.imgs.get(0).width/20.0);
          e.h = (int)(e.imgs.get(0).height/20.0);
          
          for(int j = 0; j < e.imgs.size(); j++){
            e.imgs.set(j, reSize(e.imgs.get(j), e.w, e.h));
            e.imgs.set(j, Reverse(e.imgs.get(j)));
          }
          
          break;
          
        case 1:
        case 2:
          e.hp = 1;
          
          e.imgs.add(loadImage("flyattacker.png"));
          e.w = (int)(e.imgs.get(0).width/20.0);
          e.h = (int)(e.imgs.get(0).height/20.0);
          
          for(int j = 0; j < e.imgs.size(); j++){
            e.imgs.set(j, reSize(e.imgs.get(j), e.w, e.h));
            e.imgs.set(j, Reverse(e.imgs.get(j)));
          }
      }
    }
  }
  
   //反転
  PImage Reverse(PImage img){
    return reverse(img);
  }
  
  PImage reSize(PImage img, int w, int h){
    img.resize(w, h);
    return img;
  }
}

//敵
class Enemy{
  float x, y, vx;             //画像左上の座標、横方向の速度
  int   w, h;                 //画像の大きさ
  int energy;                 //粉エネルギー
  int hp;                     //体力(何回消されたら消えるか)
  boolean dieflag;            //死んでいるならtrue
  ArrayList<PImage> imgs;     //画像
  
  Polygon pol;                        //当たり判定用多角形
  AudioSample diesound, ATsound;  //効果音
  
  Enemy(){
    dieflag = false;
    imgs = new ArrayList<PImage>();    //アニメーションさせるために10枚ほど絵が必要
  }
  
  //******処理系関数******//
  
  //初期設定をコピーする関数
  void initial(int num){
    Enemy oe = db.oriEnemys[num];
    diesound = oe.diesound;
    ATsound = oe.ATsound;
    
    imgs.add(oe.imgs.get(0));
    
    w = oe.w;
    h = oe.h;
    
    hp = oe.hp;
  }
  
  void move(){}
  void attack(){
    bullets.add(new Bullet(x, y+h/2, new PVector(-db.bs/10.0, 0)));
  }
  
  void die(){
    dieflag = true;
    if(diesound != null)  diesound.trigger();
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
  }
  
  Attacker(int x, int y){
    this.x = x+sm.x;
    this.y = y+sm.y;
    initial();
  }
  
  void initial(){
    initial(0);  //初期設定をコピー
    vx = -1;
    
    y = height - h;
  }
  
  void move(){
    x += vx;
    if(x - sm.x < width/2)  die();
  }
}

//正弦タコ
class Sin extends Enemy{
  
  float basicy;    //角度が0のときの高さ
  int theta;       //角度(ラジアンではない);
  int count;
  
  Sin(){
    initial();
    basicy = random(height/3*2) + h/2 + height/6;
  }
  
  Sin(int x, int y){
    this.x      = x+sm.x;
    this.basicy = y+sm.y;
    
    initial();
  }
  
  void initial(){
    initial(1);  //初期設定をコピー
    
    theta = 0;
    vx = -2;
    count = 0;
  }
  
  void move(){
    theta+=2;
    y = basicy - sin(theta*PI/180)*height/6;
    x += vx;
    
    if(count++ > 45){
      count = 0;
      attack();
    }
  }
}

//タンジェントタコ
class Tangent extends Sin{
  
  Tangent(){
    initialize();
  }
  
  Tangent(int x, int y){
    this.x = x+sm.x;
    this.basicy = y+sm.y;
    initialize();
  }
  
  void initialize(){
    initial(2);  //初期設定をコピー
    
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
    initialize();
  }
  
  Parachuter(int x, int y){
    initialize();
    
    this.y = y+sm.y;
    this.x = x+sm.x;
  }
  
  void initialize(){
    initial(3);      //初期設定をコピー
    
    y = -random(100);
    x = random(500);
    paraflag = true;
    
    vx = -0.5;
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
  }
  
  void draw(){
    rotation();
    image(img, 0 - w/2, 0-h/2);
    popMatrix();
  }
}

//敵の弾丸
class Bullet{
  float x, y;      //弾の進行方向の先端の座標
  PVector length;
  PVector v;
  boolean dieflag;
  
  Bullet(){
    x = width/2;
    y = height/2;
    v = new PVector(-1, 0);
    initial();
  }
  
  Bullet(float x, float y){
    this.x = x;
    this.y = y;
    v = new PVector(-1, 0);
    initial();
  }
  
  Bullet(float x, float y, PVector v){
    this.x = x;
    this.y = y;
    this.v = v;
    initial();
  }
  
  void initial(){
    length = v.get();
    length.setMag(100*width/1600);
    dieflag = false;
  }
  
  void move(){
    x += v.x;
    y += v.y;
    
    if((v.x <= 0 && x+abs(length.x) < sm.x) || (v.x > 0 && x-abs(length.x) > sm.x+width))  dieflag = true;
  }
  
  void draw(){
    stroke(255, 255, 0);
    line(x-sm.x, y-sm.y, x-sm.x+length.x, y-sm.y+length.y);
  }
}
