
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
  
  void move(){
    theta += 2;
    sety();
    super.move();
  }
  
  void sety(){
    y = basicy - sin(theta*PI/180)*height/6;
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
    
    float imgw = imgs.get(0).width;
    r = imgw/5.0*4;
    marginx = imgw/100.0*49;
    marginy = imgw/100.0*47;
    
    pol = new Polygon();
    pol.isCircle = true;
    pol.owner = this;
    
    once = true;
  }
  
  void sety(){
    y = basicy - tan(theta*PI/180)*100;
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
    image(imgs.get(0), -marginx, -marginy);
    tint(255, 255);
    popMatrix();
    
    pol.Draw();
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
  final int rapidi    = 20;           //interbal
  final int lashtime  = 60*3;
  final int standardi = 60*1;
  final int reflecti  = 60*5;
  final float standardbs = db.bs/20.0*db.scwhrate;
  
  float basicy;
  int sc;     //通常弾count
  int rc;     //反射系弾count
  float theta;            //単位:度
  float plustheta;
  boolean isStrong;     //次に発射するのが反射可能弾ならtrue
  
  Boss(){}
  
  //受け取るのは中心座標
  Boss(float x, float y){
    
    pol = new Polygon();
    pol.isBoss = true;
    
    imgs.add(loadImage("attacker.png"));
    w = (int)(imgs.get(0).width/10.0);
    h = (int)(imgs.get(0).height/10.0);
    imgs.get(0).resize(w, h);
    
    this.x = x-w/2;
    this.basicy = y-h/2;
    plustheta = 360.0/width*7.0*standardbs;
    
    charanum = 7;
    hp = 100;
    sc = rc = 0;
    theta = 0;
    alpha = 255;
    isStrong = true;
    isMoveobj = false;
  }
  
  void move(){
    super.move();
    
    theta += plustheta;
    theta %= 360;
    y = height/2.0*sin(PI/180*theta) + basicy;
  }
  
  void alpha(){}
  
  void attack(){
    if(++sc <= lashtime){
      if(sc%rapidi == 0)  bullets.add(new Standard(x+w/2, y+h/2, new PVector(-standardbs, 0)));
    }else if(sc >= lashtime + standardi)  sc = 0;
    
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




















