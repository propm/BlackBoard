
//あらゆる初期設定を保存するクラス
class DataBase{
  
  final float eraserw = 5;          //数字がでかいほうが横とする
  final float eraserh = 2;
  final float boardh  = 35;
  final float boardw  = 79.8913*2;
  
  final float boardrate = boardh/boardw;
  
  String[] objects;              //オブジェクトの名前
  float scwhrate;                //width/1600.0
  int bs;                        //弾速
  int screenw, screenh;
  
  //多角形の点を保持
  float[][][] vectors = {{{29.0/40, 133.0/800}, {141.0/160, 31.0/40}, {61.0/81, 17.0/20}, {13.0/40, 33.0/40}, 
                          {1/4.0, 3/4.0}, {5.0/16, 3.0/8}, {7.0/16, 27.0/160}}, 
                         {{33.0/160, 9.0/40}, {9.0/10, 49.0/160}, {9.0/10, 5.0/8}, {11.0/20, 59.0/80},
                          {1.0/4, 29.0/40}, {27.0/160, 41.0/80}}};
  
  //効果音のファイル名
  String erase;
  
  HashMap<String, Enemy> oriEnemys;    //敵種別設定用のオブジェクト
                                       //1:突撃兵  2:サイン  3:タンジェント  4:パラシュート
                                       //5:大砲　　6:忍者
  Player oriplayer;
  Shuriken orishuriken;
  
  //中身を入れる
  void initial(){
    objects = rt.objects.clone();
    oriEnemys = new HashMap<String, Enemy>(objects.length);
    oriplayer = new Player();
    orishuriken = new Shuriken();
    
    for(int i = 0; i < objects.length; i++){
      oriEnemys.put(objects[i], new Enemy());
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
    float[] wh;
    
    for(int i = 1; i <= oriEnemys.size(); i++){
      
      Enemy e = oriEnemys.get(objects[i-1]);
      e.pol = new Polygon();
      
      switch(i){
        case 4:
          e.hp = 5;
          e.rank = 3;
          e.bulletflag = true;
          e.Bi = 50;
          e.v = new PVector(-2*scwhrate, 2*scwhrate);
          e.damage = 30;
          
          
          setImage(e, "突撃兵タコ.png");
          setImage(e, "突撃兵タコ 攻撃.png");
          setOriPolygon(e, i);
          
          
          break;
        case 1:
          e.hp = 2;
          e.rank = 1;
          e.bulletflag = false;
          e.v = new PVector(-2*scwhrate, 0);
          e.damage = 10;
          
          setImage(e, "突撃兵タコ.png");
          setImage(e, "突撃兵タコ 攻撃.png");
          setOriPolygon(e, i);
          
          break;
        case 2:
          e.hp = 1;
          e.rank = 2;
          e.v = new PVector(-3*scwhrate, 0);
          e.bulletflag = true;
          e.Bi = 75;
          e.damage = 20;
          
          setImage(e, "フライングタコ1.png");
          setImage(e, "フライングタコ2.png");
          setOriPolygon(e, i);
          break;
        
        case 3:
          e.hp = 1;
          e.rank = 4;
          e.v = new PVector(-6*scwhrate, 0);
          e.bulletflag = true;
          e.Bi = 0;
          e.damage = 50;
          
          setImage(e, "flyattacker.png", 30.0);
          for(int j = 0; j < e.imgs.size(); j++)
            e.imgs.set(j, Reverse(e.imgs.get(j)));
          
          //多角形設定
          float[][] vectors3 = {{e.w, e.h*3/5, 0}, {e.w*16/21, e.h*100/106, 0}, {e.w/4, e.h, 0}, 
                                {0, e.h*7/10, 0}, {e.w/7, 0, 0}, {e.w*4/5, e.h*4/25, 0}};
          
          for(int j = 0; j < vectors3.length; j++)  e.pol.Add(vectors3[j][0], vectors3[j][1], vectors3[j][2]);
          e.pol.Reverse(e.w);
          
          break;
        case 5:
          e.hp = 5;
          e.rank = 3;
          e.v = new PVector(0, 0);
          e.bulletflag = true;
          e.Bi = 60 * 3;
          
          e.imgs.add(loadImage("cannon.png"));
          e.w = (int)(e.imgs.get(0).width/4.0*scwhrate);
          e.h = (int)(e.imgs.get(0).height/4.0*scwhrate);
          e.imgs.set(0, reSize(e.imgs.get(0), e.w, e.h));
          
          float[][] vectors5 = {{e.w/2, 0, 0}, {e.w*9/10, e.h*3/20, 0}, {e.w, e.h, 0}, 
                                {0, e.h*21/22, 0}, {e.w/5, e.h*3/25, 0}};
          
          for(int j = 0; j < vectors5.length; j++)  e.pol.Add(vectors5[j][0], vectors5[j][1], vectors5[j][2]);
          
          break;
          
        case 6:
          e.hp = -1;
          e.rank = 4;
          e.v = new PVector(0, 0);
          e.bulletflag = true;
          e.Bi = 60 * 4;
          
          setImage(e, "attacker.png", 30.0);
          for(int j = 0; j < e.imgs.size(); j++)
            e.imgs.set(j, Reverse(e.imgs.get(j)));
          
          float[][] vectors6 = {{e.w/2, 0, 0}, {e.w*9/10, e.h*3/20, 0}, {e.w, e.h, 0}, 
                                {0, e.h*21/22, 0}, {e.w/5, e.h*3/25, 0}};
                               
          for(int j = 0; j < vectors6.length; j++)  e.pol.Add(vectors6[j][0], vectors6[j][1], vectors6[j][2]);
          e.pol.Reverse(e.w);
          
          break;
      }
    }
    
    setPlayer();
    
    Shuriken s = orishuriken;
    s.img = loadImage("shuriken.png");
    s.w = (int)(s.img.width/10.0*scwhrate);
    s.h = (int)(s.img.height/10.0*scwhrate);
    s.img = reSize(s.img, (int)s.w, (int)s.h);
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
  void setImage(Enemy e, String filename){
    setImage(e, filename, 40.0);
  }
  
  void setImage(Enemy e, String filename, float divnum){
    e.imgs.add(loadImage(filename));
    int a = e.imgs.size()-1;
    e.w = (int)(e.imgs.get(a).width/divnum*scwhrate);
    e.h = (int)(e.imgs.get(a).height/divnum*scwhrate);
    
    e.imgs.set(a, reSize(e.imgs.get(a), e.w, e.h));
  }
  
  void setOriPolygon(Enemy e, int num){
    float[] wh;
    int vecnum = 0;
    switch(num){
      case 1:
      case 4:  vecnum = 0;  break;
      case 2:  vecnum = 1;  break;
    }
    for(int j = 0; j < vectors[vecnum].length; j++)  e.pol.Add(e.w*vectors[vecnum][j][0], e.h*vectors[vecnum][j][1], 0);
    
    wh = e.pol.getWH();
    e.w = (int)wh[0];
    e.h = (int)wh[1];
    e.marginx = wh[2];
    e.marginy = wh[3];
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
class MyObj implements Cloneable{
  float x, y;
  float imgx, imgy;   //画像左上の座標
  float marginx, marginy;  //画像左上の座標と判定の座標の差分
  int   w, h;
  int   hp;
  boolean isDie;
  PVector v;
  ArrayList<PImage> imgs;
  
  Polygon pol;
  AudioSample die;
  
  MyObj(){
    x = y = 0;
    imgx = imgy = 0;
    w = h = 0;
    hp = 0;
    isDie = false;
    v = new PVector(0, 0);
    imgs = new ArrayList<PImage>(2);
  }
  
  //死判定
  void die(){
    if(hp <= 0){
      isDie = true;
      if(die != null)  die.trigger();
    }
  }
}

//******************************************************************************************************

//敵
class Enemy extends MyObj{
  /* x, y:  画像左上(playerの場合は中心)の座標
     w, h:  画像の大きさ
  */
  int energy;            //粉エネルギー
  int rank;              //この敵のランク
  int bhp;
  int Bcount;            //弾用時間カウント
  int Acount;            //壁に攻撃するカウント
  int count;             //汎用カウント
  int Bi;                //bullet interval
  int charanum;          //どの敵・プレイヤーか(0～5)
  int damage;            //与えるダメージ
  float alpha;
  float minusalpha;      //体力が減るごとに減る不透明度の量
  
  boolean bulletflag;                                      //弾を発射するオブジェクトならtrue
  boolean isOver;        //プレイヤーと重なっているならtrue
  boolean bisOver;       //1フレーム前のisOver
  boolean collidemove;
  boolean onceinitial;   //initialを呼ぶのが一回目ならtrue]
  boolean isMoveobj;     //動くオブジェクトならtrue
  
  Polygon oripol;                 //形のみを保持する多角形
  AudioSample AT;  //効果音
  
  Enemy(){
    onceinitial = true;
  }
  
  //******処理系関数******//
  
  //初期設定
  void initial(int num){
    charanum = num;
    copy();
    
    count = Bcount = Acount = 0;
    
    //initialを呼ぶのが1回目なら
    if(onceinitial){
      isOver = isDie = false;
      
      minusalpha = 255.0/hp;
      alpha = 255;
      onceinitial = false;
    }else{
      minusalpha = alpha/hp;
    }
    
    energy = 100;
    isMoveobj = true;
    
    //敵種ごとの処理
    switch(charanum){
      case 1:  y = height-h;  break;        //突撃兵
      case 3:  energy = 300;  break;        //タンジェント
      case 5:                               //固定砲台
      case 6:  isMoveobj = false;  break;   //忍者
    }
  }
  
  //初期設定をコピーする関数
  void copy(){
    Enemy oe = db.oriEnemys.get(db.objects[charanum-1]);
    
    die = oe.die;
    AT =  oe.AT;
    
    imgs.add(oe.imgs.get(0));
    oripol = new Polygon(oe.pol.ver);
    pol    = new Polygon(oe.pol.ver);
    
    w = oe.w;
    h = oe.h;
    bulletflag = oe.bulletflag;
    
    bhp = hp = oe.hp;
    Bi = oe.Bi;
    rank = oe.rank;
    v = oe.v.get();
    damage = oe.damage;
    
    marginx = oe.marginx;
    marginy = oe.marginy;
  }
  
  //クローン
  Enemy clone(){
    Enemy o = new Enemy();
    try{
      o = (Enemy)super.clone();
      o.imgs = new ArrayList<PImage>(imgs);
      o.pol = pol.clone();
      o.oripol = oripol.clone();
    }catch(Exception e){
      e.printStackTrace();
    }
    
    return o;
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
  void move(){
    if(isMoveobj){
      x += v.x;
      y += v.y;
    }
    imgx = x - marginx;
    imgy = y - marginy;
    
    plus();
  }
  
  //更新
  void update(){
    move();
    alpha();
    attack();
    if(isMoveobj){
      setPolygon(imgx, imgy);
    }
  }
  
  //追加したい処理を記入する
  void plus(){}
  
  //攻撃
  void attack(){
    if(bullet() && AT != null)  AT.trigger();
  }
  
  //hpに応じて不透明度変更
  void alpha(){
    if(bhp != hp)  alpha -= minusalpha;
    bhp = hp;
  }
  
  //壁との衝突判定
  void collision(){
    Enemy o = this.clone();
    o.collidemove = true;
    o.move();
    
    ArrayList<PVector> vers = new ArrayList<PVector>(pol.ver);
    for(int i = 0; i < pol.ver.size(); i++){
      vers.add(pol.ver.get(i));
    }
    
    for(int i = 0; i < o.pol.ver.size(); i++){
      vers.add(o.pol.ver.get(i));
    }
  }
  
  //弾で攻撃
  boolean bullet(){
    boolean wasAttack = false;
    if(++Bcount > Bi){
      if(bulletflag) {
        switch(charanum){
          //フライングとパラシュート形態
          case 2:
          case 4:
            bullets.add(new Bullet(x, y+h/2, new PVector(-db.bs/10.0, random(-1, 1), 0)));
            wasAttack = true;
            break;
          //タンジェント
          case 3:
            bullets.add(new Beam(this));
            wasAttack = true;
            break;
          //固定砲台
          case 5:
            bullets.add(new Laser(x, y+h/2, new PVector(-db.bs/5.0, 0, 0), this));
            wasAttack = true;
            break;
          //忍者
          case 6:
            shurikens.add(new Shuriken(x, y+h/2));
            wasAttack = true;
            break;
        }
      }
      Bcount = 0;
    }
    
    return wasAttack;
  }
  
  //描画
  void draw(){
    tint(255, alpha);
    image(imgs.get(0), imgx, imgy);
    tint(255, 255);
    pol.Draw();
  }
}

//******************************************************************************************************

//突撃隊
class Attacker extends Enemy{
  boolean flag = false;
  
  Attacker(){
    x = random(width)+width/3*2;
    y = random(height-h/2)+h/2;
    initial();
  }
  
  Attacker(int x, int y){
    this.x = x;
    this.y = y;
    initial();
  }
  
  void initial(){
    initial(1);        //初期設定をコピー
  }
}

//******************************************************************************************************

//フライング
class Sin extends Enemy{
  
  float basicy;    //角度が0のときの高さ
  int theta;       //角度(ラジアンではない)
  int omega;       //角速度（ラジアンではない)
  boolean isSin;
  
  Sin(){
    isSin = false;
    initial();
  }
  
  Sin(boolean sin){
    isSin = true;
    initial();
  }
  
  Sin(int x, int y){
    this.x      = x;
    this.basicy = y;
    
    initial();
  }
  
  void initial(){
    x = random(width)+width/3*2;
    basicy = random(height/3*2) + h/2 + height/6;
    if(isSin)  initial(2);  //初期設定をコピー
    
    theta = 0;
  }
  
  void plus(){
    theta += 2;
    if(charanum == 2)       y = basicy - sin(theta*PI/180)*height/6;
  }
}

//******************************************************************************************************

//タンジェント
class Tangent extends Sin{
  boolean once;
  
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
    initial(3);  //初期設定をコピー
    
    once = true;
  }
  
  void plus(){
    super.plus();
    y = basicy - tan(theta*PI/180)*100;
  }
  
  void attack(){
    if(x < width && once){
      bullet();
      once = false;
    }
  }
}

//******************************************************************************************************

//パラシュート
class Parachuter extends Attacker{
  float stopy;           //ジェットパックを使い始めるy座標
  boolean once;
  
  Parachuter(){
    x = random(width/2)+width/3*2;
    y = -height/3;
    initialize();
  }
  
  Parachuter(int x, int y){
    this.y = y;
    this.x = x;
    initialize();
  }
  
  void initialize(){
    initial(4);      //初期設定をコピー
    
    once = true;
    stopy = height - h;
  }
  
  void plus(){
    formChange();
  }
  
  //形態変化
  void formChange(){
    if(y >= stopy && once){
      y = stopy;
      initial(1);
      once = false;
    }
  }
}

//******************************************************************************************************

//大砲
class Cannon extends Enemy{
  int     chargeframe;  //何フレームチャージするか
  boolean once;
  
  ArrayList<Enemy> chargeeffect;
  
  Cannon(){
    x = random(width/4)+width/8*3;
    y = random(height);
    initial();
  }
  
  Cannon(float x, float y){
    this.x = x;
    this.y = y;
    initial();
  }
  
  void initial(){
    initial(5);
    
    if(y < 0)  y = 0;
    if(y > height-h)  y = height-h;
    
    setPolygon(x, y);
  }
  
  void attack(){
    super.attack();
    
    if(Bcount >= 60)  charge();
    else              once = true;
  }
  
  void charge(){
    if(once){
      chargeframe = Bi - Bcount;
      once = false;
    }
    
    
  }
}

//******************************************************************************************************

//忍者
class Ninja extends Enemy{
  final float ALPHA = 100;  //最大不透明度
  float alphav;             //不透明度の増減の速さ(1フレームにどれだけ不透明度が変化するか)
  boolean isStealth;        //透明化するときtrue
  
  Ninja(){
    x = random(width/4)+width/8*3;
    y = random(height);
    initial();
  }
  
  Ninja(float x, float y){
    this.x = x;
    this.y = y;
    initial();
  }
  
  void initial(){
    initial(6);
    
    if(y < 0)         y = 0;
    if(y > height-h)  y = height-h;
    
    alpha = ALPHA;
    alphav = 5;
    isStealth = false;
    setPolygon(x, y);
  }
  
  void plus(){
    stealth();
    dicision();
  }
  
  void die(){
    if(hp == 0)  super.die();
  }
  
  void stealth(){
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
  
  //跳ね返された手裏剣との判定
  void dicision(){
    for(int i = 0; i < shurikens.size(); i++){
      Shuriken s = shurikens.get(i);
      if(s.isReflected){
        if(judge(new PVector(s.x, s.y), s.r/2, pol)){
          hp = 0;
          shurikens.remove(i);
          i--;
        }
      }
    }
  }
}

//******************************************************************************************************

//ボス
class Boss extends Enemy{
  final int rapidi    = 60*1;           //interbal
  final int standardi = 60*4;
  final int reflecti  = 60*5;
  
  int sc;     //通常弾count
  int rc;     //反射系弾count
  int theta;            //単位:度
  boolean isStrong;     //次に発射するのが反射可能弾ならtrue
  
  Boss(){}
  
  Boss(float x, float y){
    this.x = x;
    this.y = y;
    sc = rc = 0;
    theta = 0;
    isStrong = true;
  }
  
  void move(){
    theta += 2;
    theta %= 360;
    y = height/8.0*sin(theta);
  }
  
  void attack(){
    if(++sc >= standardi){
      if(sc%rapidi >= 0)  bullets.add(new Standard(x, y));
      sc = 0;
    }
    
    if(++rc >= reflecti){
      if(isStrong)  bullets.add(new Reflect());
      else          bullets.add(new Strong());
      isStrong = !isStrong;
    }
  }
  
  void update(){
    move();
    attack();
  }
  
  //死処理
  void cadaver(){
    if(hp == 0)  isDie = true;
  }
}




















