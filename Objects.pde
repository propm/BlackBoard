
//あらゆる初期設定を保存するクラス
class DataBase{
  
  String[] objects;              //オブジェクトの名前
  float scwhrate;                //width/1600.0
  int bs;                        //弾速
  int screenw, screenh;
  
  final float eraserw = 5;          //数字がでかいほうが横とする
  final float eraserh = 2;
  final float boardh  = 35;
  final float boardw  = 79.8913*2;
  
  final float boardrate = boardh/boardw;
  
  //効果音のファイル名
  String erase;
  
  HashMap<String, MyObj> oriEnemys;    //敵種別設定用のオブジェクト
                                       //1:突撃兵  2:サイン  3:タンジェント  4:パラシュート
                                       //5:大砲　　6:忍者
  Player oriplayer;
  
  void setobjectnames(){
    objects = rt.objects.clone();
    oriEnemys = new HashMap<String, MyObj>(objects.length);
    oriplayer = new Player();
    
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
    bs *= scwhrate;
    for(int i = 0; i < oriEnemys.size(); i++){
      
      MyObj e = oriEnemys.get(objects[i]);
      
      switch(i){
        case 3:
          e.bulletflag = true;
          e.Bi = 20;
        case 0:
          e.hp = 2;
          e.vx = -1*scwhrate;
          
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
        case 4:
        
        case 5:
          e.hp = -1;
          
          setImage(e, "attacker.png");
          e.pol = new Polygon();
          float[][] vectors3 = {{e.w/2, 0, 0}, {e.w*9/10, e.h*3/20, 0}, {e.w, e.h, 0}, 
                                {0, e.h*21/22, 0}, {e.w/5, e.h*3/25, 0}};
                               
          for(int j = 0; j < vectors3.length; j++)  e.pol.Add(vectors3[j][0], vectors3[j][1], vectors3[j][2]);
          e.pol.Reverse(e.w);
          e.bulletflag = true;
          e.Bi = 180;
          
          break;
      }
    }
    
    setPlayer();
  }
  
  void setPlayer(){
    Player p = oriplayer;
    
    p.gap = atan(db.eraserh/db.eraserw);
    
    float distx = width/db.boardw*db.eraserw/2;
    float disty = height/db.boardh*db.eraserh/2;
    
    p.dist = (float)Math.sqrt(distx*distx + disty*disty);
    
    p.w = (int)(distx*2);
    p.h = (int)(disty*2);
    
    p.pol = new Polygon();
    p.pol.Add(0, 0, 0);
    p.pol.Add(p.w, 0, 0);
    p.pol.Add(p.w, p.h, 0);
    p.pol.Add(0, p.h, 0);
  }
  
  //画像設定
  void setImage(MyObj e, String filename){
    
    e.imgs.add(loadImage(filename));
    e.w = (int)(e.imgs.get(0).width/30.0*scwhrate);
    e.h = (int)(e.imgs.get(0).height/30.0*scwhrate);
    
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

//******************************************************************************************************

//オブジェクト
class MyObj{
  float x, y, vx;             //画像左上(playerの場合は中心)の座標、横方向の速度
  int   w, h;                                                   //画像の大きさ
  int energy;                 //粉エネルギー
  int hp;                                                       //体力(何回消されたら消えるか)
  int Bcount;                 //弾用時間カウント
  int count;                  //汎用カウント
  int Bi;                                                       //bullet interval
  int charanum;               //どの敵・プレイヤーか(0～5)
  boolean isDie;            //死んでいるならtrue
  boolean bulletflag;                                           //弾を発射するオブジェクトならtrue
  boolean isOver;        //プレイヤーと重なっているならtrue
  boolean bisOver;       //1フレーム前のisOver
  ArrayList<PImage> imgs;                                       //画像
  
  Polygon pol;                    //当たり判定用多角形
  Polygon oripol;                 //形のみを保持する多角形
  AudioSample die, AT;  //効果音
  
  MyObj(){
    isDie = false;
    imgs = new ArrayList<PImage>();    //アニメーションさせるために10枚ほど絵が必要
  }
  
  //******処理系関数******//
  
  //初期設定をコピーする関数
  void initial(int num){
    charanum = num;
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
    isOver = false;
    count = Bcount = 0;
    
    switch(num){
      case 0:
        vx = oe.vx;
        y = height-h;
    }
  }
  
  //多角形更新     x, y: 左上の座標
  void setPolygon(float x, float y){
    for(int i = 0; i < pol.ver.size(); i++){
      PVector pv = oripol.ver.get(i);
      pol.ver.set(i, new PVector(x+pv.x, y+pv.y, 0));
    }
    pol.Init();
  }
  
  //動く
  void move(){}
  
  //弾で攻撃
  void bullet(){
    if(Bcount++ > Bi){
      if(bulletflag) {
        switch(charanum){
          case 1:
          case 2:
          case 3:
            bullets.add(new Bullet(x, y+h/2, new PVector(-db.bs/10.0, random(-1, 1), 0)));
            break;
          case 4:
          case 5:
            break;
        }
      }
      Bcount = 0;
    }
  }
  
  //攻撃
  void attack(){
    bullet();
  }
  
  //死
  void die(){
    if(hp == 0){
      isDie = true;
      if(die != null)  die.trigger();
    }
  }
  
  //描画
  void draw(){
    image(imgs.get(0), x, y);
    pol.Draw();
  }
}

//******************************************************************************************************

//突撃隊
class Attacker extends MyObj{
  boolean flag = false;
  
  Attacker(){
    x = random(width)+width/2;
    y = random(height-h/2)+h/2;
    initial();
  }
  
  Attacker(int x, int y){
    this.x = x;
    this.y = y;
    initial();
  }
  
  void initial(){
    initial(0);        //初期設定をコピー
    setPolygon(x, y);  //座標の位置に多角形を移動
  }
  
  void move(){
    die();      //死んだかどうかの判定
    x += vx+sm.vx;
    setPolygon(x, y);
    
    attack();   //攻撃
  }
}

//******************************************************************************************************

//フライング
class Sin extends MyObj{
  
  float basicy;    //角度が0のときの高さ
  int theta;       //角度(ラジアンではない)
  int omega;       //角速度（ラジアンではない
  
  Sin(){
    x = random(width)+width/2;
    basicy = random(height/3*2) + h/2 + height/6;
    initial();
  }
  
  Sin(int x, int y){
    this.x      = x;
    this.basicy = y;
    
    initial();
  }
  
  void initial(){
    initial(1);  //初期設定をコピー
    
    theta = 0;
    vx = -2 * db.scwhrate;
    
    setPolygon(x, y);
  }
  
  void move(){
    die();
    theta+=2;
    y = basicy - sin(theta*PI/180)*height/6 + sm.vy;
    x += vx+sm.vx;
    
    setPolygon(x, y);
    attack();
  }
}

//******************************************************************************************************

//タンジェント
class Tangent extends Sin{
  
  Tangent(){
    initialize();
  }
  
  Tangent(int x, int y){
    this.x = x;
    this.basicy = y;
    initialize();
  }
  
  //初期化
  void initialize(){
    initial(2);  //初期設定をコピー
    
    vx = -5 * db.scwhrate;
    setPolygon(x, y);
  }
  
  void move(){
    die();
    theta+=2;
    y = basicy - tan(theta*PI/180)*100 + sm.vy;
    x += vx+sm.vx;
    
    setPolygon(x, y);
    attack();
  }
}

//******************************************************************************************************

//パラシュート
class Parachuter extends Attacker{
  float g;               //重力（速度）
  boolean paraflag;      //地面に着地するまではパラシュート状態：true
  
  Parachuter(){
    g = 6;
    x = random(width/2)+width/2;
    y = -height/3;
    initialize();
  }
  
  Parachuter(int x, int y){
    this.y = y;
    this.x = x;
    initialize();
  }
  
  void initialize(){
    initial(3);      //初期設定をコピー
    
    paraflag = true;
    
    vx = -0.5 * db.scwhrate;
    setPolygon(x, y);
  }
  
  void move(){
    die();
    if(paraflag){
      y += g * db.scwhrate+sm.vy;
      x += vx+sm.vx;
      
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

//******************************************************************************************************

//大砲
class Cannon extends MyObj{
  
  Cannon(){
    initial(4);
  }
}

//******************************************************************************************************

//忍者
class Ninja extends MyObj{
  final float ALPHA = 100;  //最大不透明度
  float alpha;              //不透明度
  float alphav;             //不透明度の増減の速さ(1フレームにどれだけ不透明度が変化するか)
  boolean isStealth;        //透明化するときtrue
  
  Ninja(){
    initial();
  }
  
  void initial(){
    initial(5);
    x = width/2 - w/2;
    y = height/2 - h/2;
    alpha = ALPHA;
    alphav = 5;
    isStealth = false;
    setPolygon(x, y);
  }
  
  void move(){
    die();      //死判定
    attack();
    
    //黒板消しが重なっていたら消える
    if(isOver)  isStealth = true;
    
    if(isStealth){
      alpha -= alphav;
      if(alpha < 0){
        isStealth = false;
        alpha = 0;
      }
    }else{
      if(count < 15)  count++;          //消えている時間
      else            alpha += alphav;
      if(alpha >= ALPHA){
        alpha = ALPHA;
        count = 0;
      }
    }
  }
  
  void draw(){
    tint(255, alpha);
    image(imgs.get(0), x, y);
    tint(255, 255);
    pol.Draw();
  }
}

//******************************************************************************************************

//プレイヤー
class Player extends MyObj{
  float x1, x2, y1, y2;    //手の先の座標がx1, x2, 手首の座標がx2, y2
  float gap;               //angleに対して黒板消しの四隅の点がどれだけの角度ずれているか
  float dist;              //黒板消しの中心から四隅の点までの長さ
  
  int count;
  float radian;         //黒板消しが横向きになっているとき0、時計回りが正方向(-π < radian <= π)
  int key;
  
  boolean ATflag;      //マウスクリック時true
  boolean bATflag;
  boolean wallflag;    //壁作ってるときtrue
  
  AudioSample erase;    //消すときの音
  
  Player(){
    ATflag = wallflag = false;
    
    initial();
  }
  
  //初期化
  void initial(){
    try{
      Player p = db.oriplayer;
      
      w = p.w;
      h = p.h;
      erase = p.erase;
      radian = 0;
      key = 0;
      wallflag = true;
      
      gap = p.gap;
      dist = p.dist;
      
      oripol = new Polygon(p.pol.ver);
      pol    = new Polygon(p.pol.ver);
    }catch(NullPointerException e){}
  }
  
  //動作
  void move(){
    x = mouseX;
    y = mouseY;
    
    switch(key){
      case 1:
        radian += PI/180 * 2;
        break;
      case 2:
        radian -= PI/180 * 2;
        break;
    }
    
    /*x1 = readInt();
    y1 = readInt();
    x2 = readInt();
    y2 = readInt();
    
    radian = atan2(y2-y1, x2-x1);
    
    x = abs(x2-x1);
    y = abs(y2-y1);
    */
    
    //setPolygon(x-w/2+sm.x, y-w/2+sm.y);
    
    setPolygonAngle();
    overlap();
    
    if(x == pmouseX && y == pmouseY){
      if(ATflag)  createwall();
      else        count = 0;
    }else{
      count = 0;
      if(ATflag)  attack();
    }
    
    bATflag = ATflag;
  }
  
  //攻撃判定
  void attack(){
    for(int i = 0; i < enemys.size(); i++){
      MyObj e = enemys.get(i);
      
      if((!bATflag || !e.bisOver) && e.isOver && e.hp != -1)  e.hp--;
    }
    if(erase != null)  erase.trigger();
  }
  
  //敵と自機が重なっているかどうかの判定:  戻り値→変更前のisOver
  void overlap(){
    for(int i = 0; i < enemys.size(); i++){
      MyObj e = enemys.get(i);
      
      e.bisOver = e.isOver;
      //if(!e.pol.isConvex)  println(db.objects[e.charanum]);
      
      if(judge(pol, e.pol))  e.isOver = true;
      else                   e.isOver = false;
    }
  }
  
  void setPolygonAngle(){
    
    pol.ver.set(0, new PVector(x+dist*cos(radian-gap), y+dist*sin(radian-gap), 0));
    pol.ver.set(1, new PVector(x+dist*cos(radian+gap), y+dist*sin(radian+gap), 0));
    pol.ver.set(2, new PVector(x-dist*cos(radian-gap), y-dist*sin(radian-gap), 0));
    pol.ver.set(3, new PVector(x-dist*cos(radian+gap), y-dist*sin(radian+gap), 0));
    pol.Init();
  }
  
  //壁作成
  void createwall(){
    count++;
    
    if(count/60 >= 1 && wallflag){
      walls.add(new Wall(x, y, w*2.5, h, radian));
      wallflag = false;
      count = 0;
    }else if(count/60 >= 1){
      wallflag = true;
      count = 0;
    }
  }
  
  void draw(){
    noStroke();
    pushMatrix();
    translate(x, y);
    rotate(radian);
    rect(-w/2, -h/2, w, h);
    popMatrix();
    pol.Draw();
  }
}

//******************************************************************************************************

//自陣
class Home{
  float x, y;          //自陣の中心の座標
  int w, h;
  PImage img;          //画像
  float imgm;          //画像の拡大倍率
  float angle;         //画像回転角度（単位：度）
  float anglev;        //角速度  （単位：度）
  int hp;              //体力
    
  Home(){
    
    x = (int)((float)width/50*2);
    y = (int)((float)height/2);
    
    img = reverse(loadImage("cleaner.png"));
    imgm = (float)1/3;
    
    w = (int)(img.width * imgm * db.scwhrate);
    h = (int)(img.height * imgm * db.scwhrate);
    
    img.resize(w, h);
    anglev = 3;
    angle = 0;
  }
  
  void move(){
    angle += anglev;
    angle %= 360;
    y = sin(angle/180*PI)*4 + height/2;
  }
  
  void draw(){
    image(img, (int)x - w/2, (int)y - h/2);
  }
}

//******************************************************************************************************

//敵の弾丸
class Bullet{
  float x, y;      //弾の進行方向の先端上の座標
  float w, h;      //弾の幅
  float radian;    //横一直線を0としたときの角度　正方向は時計回り(-π < radian <= π)
  PVector v;
  PVector length;
  boolean isDie;
  
  Polygon pol;
  
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
    length.setMag(50*db.scwhrate);
    h = 4*db.scwhrate;
    
    radian = atan2(v.y, v.x);
    isDie = false;
    
    pol = new Polygon();
    for(int i = 0; i < 4; i++)
      pol.Add(new PVector(0, 0, 0));
  }
  
  void setPolygonAngle(){
    pol.ver.set(0, new PVector(x, y, 0));
    pol.ver.set(1, new PVector(x+length.mag()*cos(radian), y+length.mag()*sin(radian), 0));
    pol.ver.set(2, new PVector(x+length.mag()*cos(radian)+h*cos(radian+PI/2), y+length.mag()*sin(radian)+h*sin(radian+PI/2), 0));
    pol.ver.set(3, new PVector(x+h*cos(radian+PI/2), y+h*sin(radian+PI/2), 0));
    pol.Init();
  }
  
  void move(){
    x += v.x+sm.vx;
    y += v.y+sm.vy;
    
    if((v.x <= 0 && x+abs(length.x) < 0) ||
        (v.x > 0 && x-abs(length.x) > width))  isDie = true;
        
    setPolygonAngle();
  }
  
  void draw(){
    pushMatrix();
    translate(x, y);
    rotate(radian);
    noStroke();
    rect(0, 0, length.mag(), h);
    popMatrix();
    
    pol.Draw();
  }
}

//*************************************************************************************

class Wall{
  float x, y;      //中心座標
  float w, h;
  float radian;    //単位はラジアン　正方向は反時計回り
  int count;
  
  boolean isDie;
  
  Polygon pol;
  
  Wall(float x, float y, float w, float h, float radian){
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.radian = radian;
    isDie = false;
    
    pol = new Polygon();
    for(int i = 0; i < 4; i++)
      pol.Add(new PVector(0, 0, 0));
  }
  
  void die(){
    count++;
    
    if(count/60 >= 3)  isDie = true;
  }
  
  void move(){
    setPolygonAngle();
    dicision();
    
    die();
  }
  
  void setPolygonAngle(){
    
    pol.ver.set(0, new PVector(x+w/2*cos(radian+PI)+h/2*cos(radian-PI/2), y+w/2*sin(radian+PI)+h/2*sin(radian-PI/2), 0));
    pol.ver.set(1, new PVector(x+w/2*cos(radian)+h/2*cos(radian-PI/2), y+w/2*sin(radian)+h/2*sin(radian-PI/2), 0));
    pol.ver.set(2, new PVector(x+w/2*cos(radian)+h/2*cos(radian+PI/2), y+w/2*sin(radian)+h/2*sin(radian+PI/2), 0));
    pol.ver.set(3, new PVector(x+w/2*cos(radian+PI)+h/2*cos(radian+PI/2), y+w/2*sin(radian+PI)+h/2*sin(radian+PI/2), 0));
    pol.Init();
  }
  
  void dicision(){
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      if(judge(pol, b.pol)){
        bullets.remove(i);
        i--;
      }
    }
  }
  
  void draw(){
    noStroke();
    pushMatrix();
    translate(x, y);
    rotate(radian);
    rect(-w/2, -h/2, w, h);
    popMatrix();
    
    pol.Draw();
  }
}
























