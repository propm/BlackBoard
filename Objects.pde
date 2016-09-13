
//あらゆる初期設定を保存するクラス
class DataBase{
  
  String[] objects;
  float widthrate, heightrate;
  int bs;                        //弾速
  int screenw, screenh;
  
  //効果音の敵種別ファイル名
  String erase;
  
  HashMap<String, MyObj> oriEnemys;    //敵種別設定用のオブジェクト
                                       //1:突撃兵  2:サイン  3:タンジェント  4:パラシュート
  Player oriplayer = new Player();
  
  void setobjectnames(){
    objects = rt.objects.clone();
    oriEnemys = new HashMap<String, MyObj>(objects.length);
    
    for(int i = 0; i < objects.length; i++){
      oriEnemys.put(objects[i], new MyObj());
    }
  }
  
  //敵の効果音を設定
  void setsound(String object, String command, String filename){
  
    if(oriEnemys.containsKey(object)){
      for(int i = 0; i < oriEnemys.size(); i++){
        if(objects[i].equals(object)){
          if(command.equals("die"))       oriEnemys.get(object).die = minim.loadSample(filename);
          if(command.equals("attacked"))  oriEnemys.get(object).AT  = minim.loadSample(filename);
        }
      }
    }
  }
  
  //敵・プレイヤーの設定
  void setobjects(){
    for(int i = 0; i < oriEnemys.size(); i++){
      
      MyObj e = oriEnemys.get(objects[i]);
      
      switch(i){
        case 3:
          e.bulletflag = true;
          e.Bi = 20;
        case 0:
          e.hp = 2;
          
          setImage(e, "attacker.png");
          
          e.pol = new Polygon();
          float[][] vectors1 = {{e.w/2, 0, 0}, {e.w*9/10, e.h*3/20, 0}, {e.w, e.h, 0}, 
                                {0, e.h*21/22, 0}, {e.w/5, e.h*3/25, 0}};
                               
          for(int j = 0; j < vectors1.length; j++)  e.pol.Add(vectors1[j][0], vectors1[j][1], vectors1[j][2]);
          e.pol.Reverse(e.w);
          
          if(i == 0)  e.bulletflag = false;
          break;
        case 1:
        case 2:
          e.hp = 1;
          
          setImage(e, "flyattacker.png");
          
          //多角形設定
          e.pol = new Polygon();
          float[][] vectors2 = {{e.w, e.h*3/5, 0}, {e.w*16/21, e.h*100/106, 0}, {e.w/4, e.h, 0}, 
                                {0, e.h*7/10, 0}, {e.w/7, 0, 0}, {e.w*4/5, e.h*4/25, 0}};
          
          for(int j = 0; j < vectors2.length; j++)  e.pol.Add(vectors2[j][0], vectors2[j][1], vectors2[j][2]);
          e.pol.Reverse(e.w);
          
          e.bulletflag = true;
          e.Bi = 75;
          break;
      }
    }
    
    Player p = oriplayer;
    p.w = width/80;
    p.h = height/45;
    
    p.pol = new Polygon();
    p.pol.Add(0, 0, 0);
    p.pol.Add(p.w, 0, 0);
    p.pol.Add(p.w, p.h, 0);
    p.pol.Add(0, p.h, 0);
  }
  
  //画像設定
  void setImage(MyObj e, String filename){
    
    e.imgs.add(loadImage(filename));
    e.w = (int)(e.imgs.get(0).width/20.0);
    e.h = (int)(e.imgs.get(0).height/20.0);
    
    for(int j = 0; j < e.imgs.size(); j++){
      e.imgs.set(j, reSize(e.imgs.get(j), e.w, e.h));
      e.imgs.set(j, Reverse(e.imgs.get(j)));
    }
  }
  
   //反転
  PImage Reverse(PImage img){
    return reverse(img);
  }
  
  //拡大・縮小
  PImage reSize(PImage img, int w, int h){
    img.resize(w, h);
    return img;
  }
}

//敵
class MyObj{
  float x, y, vx;             //画像左上の座標、横方向の速度
  int   w, h;                                                   //画像の大きさ
  int energy;                 //粉エネルギー
  int hp;                                                       //体力(何回消されたら消えるか)
  int count;                  //時間カウント
  int Bi;                                                       //bullet interval
  boolean dieflag;            //死んでいるならtrue
  boolean bulletflag;                                           //弾を発射するオブジェクトならtrue
  ArrayList<PImage> imgs;     //画像
  
  Polygon pol;                    //当たり判定用多角形
  Polygon oripol;                 //形のみを保持する多角形
  AudioSample die, AT;  //効果音
  
  MyObj(){
    dieflag = false;
    imgs = new ArrayList<PImage>();    //アニメーションさせるために10枚ほど絵が必要
  }
  
  //******処理系関数******//
  
  //初期設定をコピーする関数
  void initial(int num){
    MyObj oe = db.oriEnemys.get(db.objects[num]);
    
    die = oe.die;
    AT =  oe.AT;
    
    imgs.add(oe.imgs.get(0));
    oripol = new Polygon(oe.pol.ver);
    pol    = new Polygon(oe.pol.ver);
    
    w = oe.w;
    h = oe.h;
    bulletflag = oe.bulletflag;
    
    hp = oe.hp;
    Bi = oe.Bi;
    count = 0;
  }
  
  //多角形更新
  void setPolygon(float x, float y){
    for(int i = 0; i < pol.ver.size(); i++){
      PVector pv = oripol.ver.get(i);
      pol.ver.set(i, new PVector(x-sm.x+pv.x, y-sm.y+pv.y, 0));
    }
    pol.Init();
  }
  
  //動く
  void move(){}
  
  //弾で攻撃
  void bullet(){
    if(count++ > Bi){
      if(bulletflag)  bullets.add(new Bullet(x, y+h/2, new PVector(-db.bs/10.0, 0)));
      count = 0;
    }
  }
  
  //攻撃
  void attack(){
    bullet();
  }
  
  //死
  void die(){
    if(hp <= 0){
      dieflag = true;
      if(die != null)  die.trigger();
    }
  }
  
  //描画
  void draw(){
    image(imgs.get(0), x - sm.x, y - sm.y);
    //pol.Draw();
  }
}

//突撃隊
class Attacker extends MyObj{
  
  Attacker(){
    x = random(width)+width/2+sm.x;
    y = random(height-h/2)+h/2+sm.y;
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
    
    setPolygon(x, y);
  }
  
  void move(){
    die();
    x += vx;
    setPolygon(x, y);
    
    attack();
  }
}

//正弦タコ
class Sin extends MyObj{
  
  float basicy;    //角度が0のときの高さ
  int theta;       //角度(ラジアンではない);
  
  Sin(){
    x = random(width)+width/2+sm.x;
    basicy = random(height/3*2) + h/2 + height/6+sm.y;
    initial();
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
    Bi = 45;
    
    setPolygon(x, y);
  }
  
  void move(){
    die();
    theta+=2;
    y = basicy - sin(theta*PI/180)*height/6;
    x += vx;
    
    setPolygon(x, y);
    attack();
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
    setPolygon(x, y);
  }
  
  void move(){
    die();
    theta+=2;
    y = basicy - tan(theta*PI/180)*100;
    x += vx;
    
    setPolygon(x, y);
    attack();
  }
}

//パラシュートタコ
class Parachuter extends Attacker{
  
  boolean paraflag;      //地面に着地するまではパラシュート状態：true
  
  Parachuter(){
    x = random(width/2)+width/2;
    y = -height/3;
    initialize();
  }
  
  Parachuter(int x, int y){
    this.y = y+sm.y;
    this.x = x+sm.x;
    initialize();
  }
  
  void initialize(){
    initial(3);      //初期設定をコピー
    
    paraflag = true;
    
    vx = -0.5;
    setPolygon(x, y);
  }
  
  void move(){
    die();
    if(paraflag){
      y += 6;
      x += vx;
      
      setPolygon(x, y);
      attack();
            
      if(y >= height - h){
        y = height - h;
        paraflag = bulletflag = false;
      }
      
    }else{
      super.move();
    }
  }
}

//プレイヤー
class Player extends MyObj{
  float bx, by;  //座標
  boolean ATflag;  //マウスクリック時true
  boolean wallflag;    //壁作ってるときtrue
  int count;
  
  AudioSample erase;
  
  Player(){
    ATflag = wallflag = false;
    initial();
  }
  
  void initial(){
    try{
      Player p = db.oriplayer;
      
      w = p.w;
      h = p.h;
      erase = p.erase;
      
      oripol = new Polygon(p.pol.ver);
      pol    = new Polygon(p.pol.ver);
    }catch(NullPointerException e){}
  }
  
  void move(){
    bx = x;
    by = y;
    
    x = mouseX;
    y = mouseY;
    
    setPolygon(x-w/2+sm.x, y-w/2+sm.y);
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
      if(judge(pol, enemys.get(i).pol))  enemys.get(i).hp--;
    }
    if(erase != null)  erase.trigger();
  }
  
  void draw(){
    ellipse(x, y, w, h);
    //pol.Draw();
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
    length.setMag(40*width/1600);
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
