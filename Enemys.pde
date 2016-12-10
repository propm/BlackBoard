
//突撃隊
class Attacker extends Enemy{
  
  Attacker(){
    if(db.isFinishInitial){
      x = random(width)+width/3*2;
      initial();
    }
  }
  
  Attacker(int x, int y){
    this.x = x;
    initial();
  }
  
  //攻撃（パラシュートなら弾発射、突撃兵ならimage変更と音を出す
  void attack(){
    if(charanum == 4){
      super.attack();
      return;
    }else{
      if(Acount == 10)  image = imgs.get(0);
      if(Acount == 30)  Acount = -1;
      if(Acount == 0){
        image = imgs.get(1);
        if(AT != null && !soundstop)  AT.trigger();
      }
    }
  }
  
  void update(){
    if(charanum == 1 && image == imgs.get(1) && !pol.isCollide){
      image = imgs.get(0);
      Acount = -1;
    }
    super.update();
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
  float ay;
  
  Sin(){
    isSin = false;
    initial();
  }
  
  Sin(boolean sin){
    isSin = true;
    
    x = random(width)+width/3*2;
    y = basicy = random(height/3*2) + h/2 + height/6;
    initial();
  }
  
  Sin(int x, int y){
    this.x      = x;
    this.y = basicy = y;
    
    initial();
  }
  
  void initial(){
    if(isSin)  initial(2);  //初期設定をコピー
    
    ay = basicy;
    theta = 0;
  }
  
  void move(){
    
    //壁の左右の辺と衝突していなければ、y軸方向の速度を設定
    if(!pol.isCollide || !(pol.wallside == 2 || pol.wallside == 4)){
      theta += 2;
      theta %= 360;
      setvy(charanum == 2? sin(theta*PI/180) : tan(theta*PI/180));
    }
    
    super.move();
  }
  
  void setvy(float s_t){
    ay = basicy - s_t*height/6;
    pol.v.set(pol.v.x, ay-y);
    v = pol.v.copy();
  }
}

//******************************************************************************************************

//タンジェント
class Tangent extends Sin{
  //  x, yは中心座標
  boolean once, out;
  int angle;
  float r;
  
  Tangent(){
    this(random(width/4.0)+width, random(height/4.0)+height/8.0*3);
  }
  
  Tangent(float x, float y){
    this.x = x;
    this.basicy = y;
    initialize();
  }
  
  //初期化
  void initialize(){
    if(db.isFinishInitial){
      initial(3);  //初期設定をコピー
      
      float imgw = imgs.get(0).width;
      image = imgs.get(0);
      r = imgw/5.0*4;
      marginx = imgw/100.0*49;
      marginy = imgw/100.0*47;
      isCrasher = true;
      
      once = true;
      out = true;    //出現時に音を鳴らすため、trueにしておく
      dicision();
    }
  }
  
  void plus(){
    angle += 8;
    angle %= 360;
    
    dicision();
  }
  
  //画面内にいるかどうかの判定
  void dicision(){
    if(y > height-r/2)  out = true;
    if(y < height-r/2 && out){
      if(bul != null && !soundstop)  bul.trigger();
      out = false;
    }
    if(y < r/2) if(bul != null)  bul.stop();
  }
  
  void attack(){
    if(x < width && once){
      bullet();
      once = false;
    }
  }
  
  void draw(){
    pushMatrix();
    translate(x, y);
    rotate(angle/180.0*PI);
    tint(255, alpha);
    image(image, -marginx, -marginy);
    tint(255, 255);
    popMatrix();
    
    pol.Draw(new PVector(x, y), r);
  }
}

//******************************************************************************************************

//パラシュート
class Parachuter extends Attacker{
  float stopy;           //ジェットパックを使い始めるy座標
  boolean change;
  int changecount;
  
  Parachuter(){
    if(db.isFinishInitial){
      x = random(width/2)+width/3*2;
      y = -height/3;
      initialize();
    }
  }
  
  Parachuter(int x, int y){
    this.y = y;
    this.x = x;
    initialize();
  }
  
  void initialize(){
    initial(4);      //初期設定をコピー
    
    changecount = 0;
    change = false;
    stopy = random(height/3.0*2-h)+height/3.0;
  }
  
  void plus(){
    formChange();
  }
  
  //形態変化
  void formChange(){
    if(!change){
      
      //傘回す
      if(changecount++ > 20){
        if(image == imgs.get(0))  image = imgs.get(1);
        else if(image == imgs.get(1))  image = imgs.get(0);
        changecount = 0;
      }
    
      //突撃形態へ
      if(y >= stopy){
        change = true;
        isCrasher = true;
        if(AT != null && !soundstop)  AT.trigger();
        
        initial(1);
        formCopy();
        charanum = 4;
        y = stopy;
        v.set(v.x*5, 0);
        pol.v = v.copy();
      }
    }
  }
  
  //突撃形態になるときに画像を変更
  void formCopy(){
    Parachuter para = (Parachuter)db.oriEnemys.get(8-1);
    w = para.w;
    h = para.h;
    image = para.imgs.get(0).copy();
    pol = new Polygon(para.pol.ver);
    pol.Init();
    movePolygon(imgx, imgy);
    
    imgs.remove(1);
    imgs.set(0, image);
  }
}

//******************************************************************************************************

//大砲
class Cannon extends Enemy{
  final int chargeframe = 60*3;  //何フレームチャージするか
  final int effectnum   = 6;     //一つの円でいくつの弾を表示するか
  boolean isCharge;              //現在チャージ中かどうか（ParticleManagerの方で使う）
  
  int laserX;        //発射されるレーザーのx座標（EllipseManagerにいれてもらう）
  
  AudioSample charge;    //チャージするときの音
  AudioSample appear;    //召喚時の音
  
  String chargename, appearname;
  
  Cannon(){
    if(db.isFinishInitial){
      x = random(width/11.0*9)+ width/11.0;
      y = random(height);
      initial();
    }
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
    float bimgy = imgy;
    imgy = y - marginy;
    movePolygon(0, imgy-bimgy);
    
    isCharge = true;
    
    //最初にlaserXを代入してもらうためにEllipseManagerを作り、すぐに破棄する
    pms.add(new EllipseManager(this, (int)x, (int)y+h/2, (int)(5*db.scwhrate)));
    pms.remove(pms.size()-1);
    
    if(appear != null && !soundstop)  appear.trigger();
  }
  
  void copy(){
    super.copy();
    
    Cannon c = (Cannon)db.oriEnemys.get(charanum - 1);
    charge = db.setsound(c.chargename);
    appear = db.setsound(c.appearname);
  }
  
  void copyplus(Enemy oe){
    Cannon c = (Cannon)oe;
    charge = c.charge;
    appear = c.appear;
  }
  
  //ボスが登場したら上に飛んでって死ぬ
  void plus(){
    if(scene >= 4){
      isMoveobj = true;
      isCrasher = true;
      v.add(new PVector(0, -1));
      if(y < -h)  isDie = true;
    }
  }
  
  void attack(){
    super.attack();
    
    //チャージ開始
    if(Bcount == Bi - chargeframe){
      if(charge != null)  charge.trigger();
      pms.add(new ParticleManager(this, (int)x, (int)y+h/2, (int)(200*db.scwhrate)));
      isCharge = true;
      
    //発射
    }else if(Bcount == 0){
      if(charge != null) charge.stop();
      pms.add(new EllipseManager(this, (int)x, (int)y+h/2, (int)(5*db.scwhrate)));
      isCharge = false;
    }
  }
  
  void soundclose(){
    super.soundclose();
    if(charge != null)  charge.close();
    if(appear != null)  appear.close();
  }
}

//******************************************************************************************************

//忍者
class Ninja extends Enemy{
  final float ALPHA = 120;  //最大不透明度
  final int stealfreq = 30; //透明度が変わる方向が何フレームで変化するか
  float alphav;             //不透明度の増減の速さ(1フレームにどれだけ不透明度が変化するか)
  boolean isStealth;        //透明化するときtrue
  
  int stealthcount;
  
  Ninja(){
    this(random(width/2)+width/8*3, random(height));
  }
  
  Ninja(float x, float y){
    if(db.isFinishInitial){
      this.x = x;
      this.y = y;
      initial();
    }
  }
  
  void initial(){
    initial(6);
    
    if(y < 0)         y = 0;
    if(y > height-h)  y = height-h;
    float bimgy = imgy;
    imgy = y - marginy;
    movePolygon(0, imgy-bimgy);
    
    stealthcount = 0;
    alpha = ALPHA;
    alphav = ALPHA / stealfreq;
    isStealth = false;
  }
  
  void plus(){
    if(scene >= 4){
      fadeout();
    }else{
      stealth();
      dicision();
    }
  }
  
  void die(){
    if(hp == 0)  super.die();
  }
  
  //ボスが登場したらフェードアウト
  void fadeout(){
    alpha -= alphav;
    if(alpha < 0)  isDie = true;
  }
  
  void stealth(){
    //一定周期で点滅
    if(stealthcount++ > stealfreq){
      isStealth = !isStealth;
      stealthcount = 0;
    }
    
    if(isStealth){
      alpha -= alphav;
      if(alpha < 0){
        alpha = 0;
      }
    }else{
      alpha += alphav;
      if(alpha >= ALPHA){
        alpha = ALPHA;
        count = 0;
      }
    }
  }
  
  //跳ね返された手裏剣との判定
  void dicision(){
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      if(b.num == 3){
        Shuriken s = (Shuriken)b;
        if(s.isReflected){
          if(judge(new PVector(s.x, s.y), s.r/2, pol)){
            hp = 0;
            s.hp = 0;
          }
        }
      }
    }
  }
}

//******************************************************************************************************

//ボス
class Boss extends Enemy{
  final float rapidi  = 60/7.0;           //通常弾連射のインターバル
  final int lashtime  = 60*3;             //連射するフレーム数
  final int standardi = 60*1;             //通常弾の連射と連射の間のインターバル
  final int reflecti  = 60*5;             //反射弾のインターバル
  final float standardbs = 1.5*db.scwhrate;  //通常弾の弾速
  final int rbs = 20;                        //反射弾の弾速
  final int chargetime = 60*3;            //チャージするフレーム数
  final PVector ChargeXYrate = new PVector(62/250.0, 165/250.0);
  //↑チャージする位置（右端、下端を1としたときの）
  
  final int stantime  = 60*7;                //気絶する時間
  
  final float ALPHA = 255;  //最大不透明度
  final int stealfreq = 60; //透明度が変わる方向が何フレームで変化するか
  final float alphav = ALPHA/stealfreq;   //不透明度の増減の速さ(1フレームにどれだけ不透明度が変化するか)
  
  boolean isStealth;        //透明化するときtrue
  int stealthcount;
  int Scount;
  
  float basicy;
  int sc;     //通常弾count
  int rc;     //反射系弾count
  float theta;            //単位:度
  float plustheta;
  
  boolean isStrong;     //次に発射するのが反射可能弾ならtrue
  boolean isStan;       //気絶中ならtrue
  boolean bisStan;      //1フレーム前のisStan
  int stancount;        //気絶している最中はカウント
  
  int count;        // ボスが登場or死亡したときからのカウント(毎フレーム1足す) & stan時にも使用
  int bossscene;    // 0: ボス登場 1: ボス攻撃＆スタン　2: ボス死亡
  
  float upspeed = 2;     // 登場するときのスピード(要調整)
  float downspeed = 1.5; // 死んだあとの沈むスピード(要調整)
  
  boolean isCharge;    //チャージ時true
  
  AudioSample strongfire;  //効果音
  AudioSample reflectfire;
  AudioSample charge;
  
  PImage boss1, boss2;
  String strongfirename, reflectfirename, chargename;  //効果音のファイル名
  
  PVector chargeXY;  //チャージする位置
  
  Boss(){}
  
  //受け取るのは中心座標
  Boss(float x, float y){
    charanum = 7;
    copy();
    
    //描画するイメージを指定
    image = imgs.get(0);
    
    marginx = w/2;
    marginy = h/2;
    
    basicy = y;
    this.x = x;
    this.y = height - image.height/4.0 + marginy;
    count = 0;
    bossscene = 0;
    
    imgx = x - marginx;
    imgy = y - marginy;
    movePolygon(imgx, imgy);
    
    chargeXY = new PVector(0, 0);
    
    //ボスが上下に動くときの角速度（theta/フレーム）を指定
    plustheta = 360.0/width*7.0*standardbs;
    
    Scount = 0;
    stealthcount = 0;
    alpha = ALPHA;
    isStealth = true;
    isCharge = false;
    
    sc = rc = 0;
    theta = 0;
    stancount = 0;
    alpha = 255;
    isStrong = false;
    isStan = false;
    isMoveobj = true;
    isCrasher = true;
    isDie = false;
  }
  
  void copy(){
    super.copy();
    
    //効果音とイメージをコピー
    Boss bo = (Boss)db.oriEnemys.get(6);
    strongfire = db.setsound(bo.strongfirename);
    reflectfire = db.setsound(bo.reflectfirename);
    charge = db.setsound(bo.chargename);
    
    boss1 = imgs.get(0);
    boss2 = imgs.get(1);
  }
  
  void move(){
    //上下に移動
    theta += plustheta;
    theta %= 360;
    float ay = (height-h)/2.0*sin(PI/180*theta) + basicy;
    v.set(v.x, ay-y);
    
    super.move();
    
    chargeXY.set(imgx+image.width*ChargeXYrate.x, imgy+image.height*ChargeXYrate.y);
  }
  
  void alpha(){}
  
  //跳ね返された反射可能弾との判定
  void dicision(){
    //気絶しているときの判定
    if(isStan)  stancount++;
    if(stancount > stantime){
      isStan = false;
      image = imgs.get(0);
      stancount = 0;
    }
    
    //跳ね返された反射可能弾との判定
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      if(b.num == 6){
        Strong s = (Strong)b;
        if(s.isReflected){
          if(judge(new PVector(s.x, s.y), s.r/2, pol)){
            isStan = true;
            image = imgs.get(1);
            s.hp = 0;
          }
        }
      }
    }
  }
  
  void attack(){
    
    //通常弾発射
    if(++sc <= lashtime){
      if(sc%rapidi < 1){
        bullets.add(new Standard(x-w/4.0, random(height), -standardbs));
        if(bul != null && !soundstop)  bul.trigger();
      }
    }else if(sc >= lashtime + standardi)  sc = 0;
    
    //チャージし始める瞬間なら
    if(rc == reflecti - chargetime){
      isCharge = true;
      charge.trigger();  //チャージの効果音を鳴らす
      
      //パーティクルを生成
      color col;
      if(isStrong)  col = color(200, 200, 30);
      else          col = color(130, 157, 255);
      pms.add(new ParticleManager(this, (int)chargeXY.x, (int)chargeXY.y, (int)(500*db.scwhrate), col));
    }
    
    //反射弾・反射可能弾発射
    if(++rc >= reflecti){
      isCharge = false;
      if(!isStrong){
        //反射弾
        bullets.add(new Reflect(chargeXY.x, chargeXY.y, new PVector(-rbs*cos(45*PI/180.0), rbs*sin(45*PI/180.0))));
        bullets.add(new Reflect(chargeXY.x, chargeXY.y, new PVector(-rbs*cos(-45*PI/180.0), rbs*sin(-45*PI/180.0))));
        //効果音
        if(reflectfire != null && !soundstop)  reflectfire.trigger();
        
      }else{
        //反射可能弾
        bullets.add(new Strong(chargeXY.x, chargeXY.y));
        if(strongfire != null && !soundstop)  strongfire.trigger();
      }
      isStrong = !isStrong;
      rc = 0;
    }
  }
  
  void stealth(){
    
    //一定周期で点滅
    if(isStealth){
      alpha -= alphav;
      if(alpha < 0){
        isStealth = false;
        alpha = 0;
      }
    }else{
      if(Scount < 15)  Scount++;          //消えている時間
      else             alpha += alphav;
      if(alpha >= ALPHA){
        alpha = ALPHA;
        isStealth = true;
        Scount = 0;
      }
    }
    
    if(isCharge)  alpha = 255;
  }
  
  void update() {
    count++;
    
    switch(bossscene) {
      case 0:
        // 登場時の処理
        y -= upspeed;
        imgy = y - marginy;
        if (imgy + boss1.height / 2 <= height / 2) {
          y = height / 2 - boss1.height / 2 + marginy;
          // 登場完了のときこの処理がくる
          // ボス動き＆攻撃開始
          count = 0;
          changeScene();
        }
        break;
      
      case 1:
        // 攻撃＆スタン
        if (isStan) {
          // スタン状態なら
          // スタン状態のときボス動かないほうがいいかな…
          rc = sc = 0;
          isCharge = false;
          if(charge != null)  charge.stop();
        }else{
          // 戦闘状態
          if(bisStan != isStan)  count = 0;
          
          if(!isCharge)  move();
          attack();
          bisStan = isStan;
          stealth();
        }
        dicision();
        break;
      
      case 2:
        // 死んでからの処理
        y += downspeed;
        imgy = y - marginy;
        if (imgy >= height) {
          y = height+marginy;
          // ボスが死んで画面から見えなくなったときにこの処理がくる
          // この処理がくる少し前からボスは見えなくなっている。
          // result画面にchangeScene()していいと思う。
          
          changeScene();
        }
        break;
    }
    
    imgx = x - marginx;
    imgy = y - marginy;
    
    draw();
  }
  
  //死処理
  void cadaver(){
    if(hp <= 0 && !isDie){
      if(die != null)  die.trigger();
      changeScene();
      
      isDie = true;
    }
  }
  
  void draw() {
    int t;
    switch(bossscene) {
      case 0:
        // ボスが登場した時この処理
        
        //t = int(255 * count / ((height - boss1.height / 4) - (height / 2 - boss1.height / 2)) * upspeed);
        // ↑の簡略版↓
        t = int(255 * count / (height / 2 + boss1.height / 4) * upspeed);
        if (t > 255) t = 255;
        
        // tint(0)で透明 (255)で不透明
        // ボスの描画
        tint(t);
        image(boss1, imgx, imgy);
        noTint();
        
        break;
      case 1:
        // ボス攻撃＆スタン
        
        if(isStan) {
          // スタン状態なら
          int taimin = 60; // 1秒経過後1ピクピク予定(要調整)
          if (count % (taimin * 2) < taimin) {
            int bu = count % (taimin - (taimin * 2)) / (taimin / 8);
            
            if (bu % 2 == 0) {
              // 要調整
              image(boss2, imgx - 2, imgy - 4);
            }else{
              image(boss2, imgx, imgy);
            }
          }else{
            image(boss2, imgx, imgy);
          }
        }else{
          //戦闘状態なら
          tint(255, alpha);
          image(boss1, imgx, imgy);
          noTint();
        }
        
        break;
        
      case 2:
        // ボスが死んだ場合この処理
        float desp = height - boss1.height * 7 / 11; // 消え始める位置
        if (imgy > desp) {
          t = 255 - int(255 * (imgy - desp) / (height - boss1.height / 4 - desp));
          if (t < 0) t = 0;
          tint(t);
        }
        
        if (imgy <= height - boss1.height / 4) image(boss2, imgx + boss1.width / 10 * cos((-90 + count) * 5 * PI/180), imgy);
        noTint();
        
        break;
    }
    
    pol.Draw();
  }
}