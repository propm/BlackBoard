//******************************************************************************************************
//オブジェクト
class MyObj implements Cloneable{
  float x, y;
  float imgx, imgy;   //画像左上の座標
  float marginx, marginy;  //画像左上の座標と判定の座標の差分
  int   w, h;
  int   hp, maxhp;    //体力、体力上限
  boolean isDie;
  PVector v;
  ArrayList<PImage> imgs;    //使う画像を保存
  PImage image;              //今使われているimage
  
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
    if(hp == 0){
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
  boolean onceinitial;   //initialを呼ぶのが一回目ならtrue
  boolean isMoveobj;     //動くオブジェクトならtrue
  
  Polygon oripol;                 //形のみを保持する多角形
  AudioSample AT;   //物理攻撃するときの音
  AudioSample bul;  //弾で攻撃するときの音
  
  Enemy(){
    onceinitial = true;
  }
  
  //******処理系関数******//
  
  //初期設定
  void initial(int num){
    charanum = num;
    copy();
    
    imgx = x - marginx;
    imgy = y - marginy;
    setPolygon(imgx, imgy);
    pol.v = v.copy();
    
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
    Enemy oe = db.oriEnemys.get(charanum-1);
    
    die = oe.die;
    AT =  oe.AT;
    
    imgs = new ArrayList<PImage>(oe.imgs);
    image = imgs.get(0);
    oripol = new Polygon(oe.pol.ver);
    pol    = new Polygon(oe.pol.ver);
    oripol.Init();
    pol.Init();
    
    w = oe.w;
    h = oe.h;
    bulletflag = oe.bulletflag;
    
    maxhp = bhp = hp = oe.hp;
    Bi = oe.Bi;
    rank = oe.rank;
    
    v = oe.v.copy();
    damage = oe.damage;
    
    marginx = oe.marginx;
    marginy = oe.marginy;
    
    die = oe.die;
    bul = oe.bul;
    
    copyplus(oe);
  }
  
  void copyplus(Enemy oe){}
  
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
    pol.Update();
    
    if(isMoveobj){
      x += pol.v.x;
      y += pol.v.y;
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
  
  //弾で攻撃
  boolean bullet(){
    boolean wasAttack = false;
    if(++Bcount > Bi){
      if(bulletflag) {
        switch(charanum){
          //フライングとパラシュート形態
          case 2:
          case 4:
            bullets.add(new Bullet(x, y+h/2, new PVector(-3*db.scwhrate, random(-1, 1), 0)));
            wasAttack = true;
            break;
          //タンジェント
          case 3:
            bullets.add(new Beam(this));
            wasAttack = true;
            break;
          //固定砲台
          case 5:
            bullets.add(new Laser(x, y+h/2, new PVector(-6*db.scwhrate, 0, 0), this));
            wasAttack = true;
            break;
          //忍者
          case 6:
            bullets.add(new Shuriken(x, y+h/2));
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
    image(image, imgx, imgy);
    tint(255, 255);
    pol.Draw();
  }
}

//**************************************************************************************************

//敵の弾丸
class Bullet extends MyObj{
  float radian;    //横一直線を0としたときの角度　正方向は時計回り(-π < radian <= π)
  float energy;
  int   damage;    //与えるダメージ
  int   num;       //bulletなら0、laserなら1、beamなら2、shurikenなら3、
                   //standardなら4、reflectなら5、strongなら6            
  
  int[] col;       //色
  boolean bisOver;
  PVector length;       //弾の長さ
  
  ArrayList<PVector> bver;
  
  Bullet(){}
  
  Bullet(float x, float y){
    this(x, y, new PVector(-1, 0));
  }
  
  Bullet(float x, float y, PVector v){
    this.x = x;
    this.y = y;
    this.v = v;
    
    initial();
  }
  
  void initial(){
    col = new int[3];
    col[0] = col[1] = col[2] = 0;
    bver = new ArrayList<PVector>();
    
    energy = 25;
    radian = atan2(v.y, v.x);
    isDie = false;
    bisOver = false;
    
    pol = new Polygon();
    for(int i = 0; i < 4; i++)
      pol.Add(new PVector(0, 0));
    
    length = v.copy();
    length.setMag(50*db.scwhrate);
    
    switch(num){
      case 0:
      case 4:
        sinitial();
        break;
    }
  }
  
  //普通の弾のinitial
  void sinitial(){
    col[0] = 255;
    col[1] = 134;
    col[2] = 0;
    
    h = (int)(4*db.scwhrate);
    damage = 2;
    maxhp = hp = 1;
    
    setPolygon();
    for(int i = 0; i < pol.ver.size(); i++)
      bver.add(pol.ver.get(i));
  }
  
  //radianが0のとき、右上から時計回り（右上が0）
  void setPolygonAngle(){
    pol.ver.set(0, new PVector(x+h/2*cos(radian-PI/2), y+h/2*sin(radian-PI/2), 0));
    pol.ver.set(1, new PVector(x+h/2*cos(radian+PI/2), y+h/2*sin(radian+PI/2), 0));
    pol.ver.set(2, new PVector(x+length.mag()*cos(radian-PI)+h/2*cos(radian+PI/2), y+length.mag()*sin(radian-PI)+h/2*sin(radian+PI/2), 0));
    pol.ver.set(3, new PVector(x+length.mag()*cos(radian-PI)+h/2*cos(radian-PI/2), y+length.mag()*sin(radian-PI)+h/2*sin(radian-PI/2), 0));
    pol.Init();
  }
  
  void setPolygon(){
    pol.ver.set(0, new PVector(x+length.mag(), y-h/2, 0));
    pol.ver.set(1, new PVector(x+length.mag(), y+h/2, 0));
    pol.ver.set(2, new PVector(x, y+h/2, 0));
    pol.ver.set(3, new PVector(x, y-h/2, 0));
    pol.Init();
  }
  
  void move(){
    x += v.x;
    y += v.y;
  }
  
  void update(){
    move();
    setBver();
    plus();
  }
  
  void plus(){
    if(radian == PI)  setPolygon();
    else              setPolygonAngle();
  }
  
  void setBver(){
    switch(num){
      case 0:
      case 4:
        for(int i = 0; i < pol.ver.size(); i++)
          bver.set(i, pol.ver.get(i));
    }
  }
  
  void draw(){
    fill(col[0], col[1], col[2]);
    pushMatrix();
    translate(x, y);
    rotate(radian);
    noStroke();
    rect(-length.mag(), -h/2, length.mag(), h);
    popMatrix();
    
    pol.Draw();
  }
}