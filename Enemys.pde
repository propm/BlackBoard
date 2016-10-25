
//突撃隊
class Attacker extends Enemy{
  boolean flag = false;
  
  Attacker(){
    if(db.oriEnemys.size() >= 7){
      x = random(width)+width/3*2;
      initial();
    }
  }
  
  Attacker(int x, int y){
    this.x = x;
    initial();
  }
  
  void attack(){
    if(charanum == 4){
      super.attack();
      return;
    }
    
    if(Acount == 10)  image = imgs.get(0);
    if(Acount == 30)  Acount = -1;
    if(Acount == 0){
      image = imgs.get(1);
      if(AT != null)  AT.trigger();
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
  boolean once;
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
    if(db.oriEnemys.size() >= 7){
      initial(3);  //初期設定をコピー
      
      float imgw = imgs.get(0).width;
      image = imgs.get(0);
      r = imgw/5.0*4;
      marginx = imgw/100.0*49;
      marginy = imgw/100.0*47;
      isCrasher = true;
      
      once = true;
    }
  }
  
  void plus(){
    angle += 8;
    angle %= 360;
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
  
  Parachuter(){
    if(db.oriEnemys.size() >= 7){
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
    
    change = false;
    stopy = random(height/3.0*2-h)+height/3.0;
  }
  
  void plus(){
    formChange();
  }
  
  //形態変化
  void formChange(){
    if(y >= stopy && !change){
      change = true;
      isCrasher = true;
      
      initial(1);
      charanum = 4;
      y = stopy;
      image = imgs.get(1);
      v.set(v.x*5, 0);
      pol.v = v.copy();
    }
  }
}

//******************************************************************************************************

//大砲
class Cannon extends Enemy{
  int     chargeframe;  //何フレームチャージするか
  boolean once;
  
  ArrayList<Enemy> chargeeffect;
  
  AudioSample charge;    //チャージするときの音
  AudioSample appear;    //召喚時の音
  
  Cannon(){
    if(db.oriEnemys.size() >= 7){
      x = random(width/4)+width/8*3;
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
  final float ALPHA = 200;  //最大不透明度
  float alphav;             //不透明度の増減の速さ(1フレームにどれだけ不透明度が変化するか)
  boolean isStealth;        //透明化するときtrue
  
  Ninja(){
    this(random(width/4)+width/8*3, random(height));
  }
  
  Ninja(float x, float y){
    if(db.oriEnemys.size() >= 7){
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
    
    alpha = ALPHA;
    alphav = 5;
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
  final float rapidi  = 60/7.0;           //interbal
  final int lashtime  = 60*3;
  final int standardi = 60*1;
  final int reflecti  = 60*5;
  final float standardbs = 1.5*db.scwhrate;
  final int rbs = 20;
  final float reffreq = 2.5;
  final int stantime  = 60*5;
  
  float basicy;
  int sc;     //通常弾count
  int rc;     //反射系弾count
  float theta;            //単位:度
  float plustheta;
  boolean isStrong;     //次に発射するのが反射可能弾ならtrue
  boolean isStan;       //気絶中ならtrue
  
  Boss(){}
  
  //受け取るのは中心座標
  Boss(float x, float y){
    charanum = 7;
    copy();
    
    image = imgs.get(0);
    
    marginx = w/2;
    marginy = h/2;
    
    this.y = basicy = y;
    this.x = x;
    
    imgx = x - marginx;
    imgy = y - marginy;
    movePolygon(imgx, imgy);
    
    plustheta = 360.0/width*7.0*standardbs;
    
    sc = rc = 0;
    theta = 0;
    alpha = 255;
    isStrong = false;
    isStan = false;
    isMoveobj = true;
    isCrasher = true;
  }
  
  void move(){
    theta += plustheta;
    theta %= 360;
    float ay = (height-h)/2.0*sin(PI/180*theta) + basicy;
    v.set(v.x, ay-y);
    
    super.move();
  }
  
  void alpha(){}
  
  //跳ね返された手裏剣との判定
  void dicision(){
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      if(b.num == 6){
        Strong s = (Strong)b;
        if(s.isReflected){
          if(judge(new PVector(s.x, s.y), s.r/2, pol)){
            isStan = true;
            s.hp = 0;
          }
        }
      }
    }
  }
  
  void attack(){
    if(++sc <= lashtime){
      if(sc%rapidi < 1)  bullets.add(new Standard(x-w/4.0, random(height), -standardbs));
    }else if(sc >= lashtime + standardi)  sc = 0;
    
    if(++rc >= reflecti){
      if(isStrong){
        bullets.add(new Reflect(x, y, new PVector(-rbs*cos(45*PI/180.0), rbs*sin(45*PI/180.0))));
        bullets.add(new Reflect(x, y, new PVector(-rbs*cos(-45*PI/180.0), rbs*sin(-45*PI/180.0))));
      }
      else{
        bullets.add(new Strong(x, y));
      }
      isStrong = !isStrong;
      rc = 0;
    }
  }
  
  void update(){
    move();
    attack();
    dicision();
  }
  
  //死処理
  void cadaver(){
    if(hp <= 0){
      changeScene();
      isDie = true;
    }
  }
  
  void draw(){
    super.draw();
    fill(255, 20, 147);
    ellipse(x, y, 20, 20);
  }
}