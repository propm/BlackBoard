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
  
  Polygon pol, oripol;
  AudioSample die;
  
  String diename;
  
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
      if(!soundstop && die != null)  die.trigger();
    }
  }
  
  void soundclose(){
    //if(die != null)  die.close();
  }
}

//******************************************************************************************************

//敵
class Enemy extends MyObj{
  /* x, y:  画像左上(playerの場合は中心)の座標
     w, h:  画像の大きさ
     v:     衝突すると変化する、移動速度
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
  boolean isCrasher;     //壁に補正されないならtrue
  
  AudioSample AT;   //物理攻撃するときの音
  AudioSample bul;  //弾で攻撃するときの音
  
  String ATname;
  String bulname;
  
  Enemy(){
    onceinitial = true;
  }
  
  //******処理系関数******//
  
  //初期設定
  void initial(int num){
    charanum = num;
    copy();
    
    if(onceinitial && charanum == 1)  y = height-h;
    imgx = x - marginx;
    imgy = y - marginy;
    
    movePolygon(imgx, imgy);
    v = pol.v.copy();
    
    count = Bcount = 0;
    Acount = -1;
    
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
      case 3:  energy = 300;  break;        //タンジェント
      case 5:                               //固定砲台
      case 6:  isMoveobj = false;  break;   //忍者
    }
  }
  
  //初期設定をコピーする関数
  void copy(){
    Enemy oe = db.oriEnemys.get(charanum-1);
    
    die = db.setsound(oe.diename);
    AT  = db.setsound(oe.ATname);
    bul = db.setsound(oe.bulname);
    
    imgs = new ArrayList<PImage>(oe.imgs.size());
    for(int i = 0; i < oe.imgs.size(); i++){
      imgs.add(oe.imgs.get(i).copy());
    }
    
    image = imgs.get(0);
    pol   = new Polygon(oe.pol.ver);
    pol.Init();
    pol.owner = this;
    
    w = oe.w;
    h = oe.h;
    bulletflag = oe.bulletflag;
    
    maxhp = bhp = hp = oe.hp;
    Bi = oe.Bi;
    rank = oe.rank;
    
    pol.v = oe.v.copy();
    damage = oe.damage;
    
    marginx = oe.marginx;
    marginy = oe.marginy;
    
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
    }catch(Exception e){
      e.printStackTrace();
    }
    
    return o;
  }
  
  //多角形更新     vx, vy: 多角形をどれだけ移動させるか
  void movePolygon(float vx, float vy){
    for(int i = 0; i < pol.ver.size(); i++){
      pol.ver.get(i).add(new PVector(vx, vy));
    }
  }
  
  void setPolygon(){
    if(isCrasher)  movePolygon(v.x, v.y);
    else           pol.Update();
  }
  
  //動く
  void move(){
    setPolygon();
    
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
  }
  
  //追加したい処理を記入する
  void plus(){}
  
  //攻撃
  void attack(){
    if(bullet() && bul != null && !soundstop)  bul.trigger();
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
          case 4:
            Parachuter p = (Parachuter)this;
            if(p.change)  break;
          case 2:
            bullets.add(new Bullet(x, y+h/2, new PVector(-3*db.scwhrate, random(-1, 1), 0)));
            wasAttack = true;
            break;
          //タンジェント
          case 3:
            bullets.add(new Beam(this));
            break;
          //固定砲台
          case 5:
            Cannon c = (Cannon)this;
            bullets.add(new Laser(c.chargexy.x, c.chargexy.y, new PVector(-6*db.scwhrate, 0, 0), this));
            wasAttack = true;
            break;
          //忍者
          case 6:
            bullets.add(new Shuriken(x, y+h/2));
            break;
        }
      }
      Bcount = 0;
    }
    
    return wasAttack;
  }
  
  void soundclose(){
    super.soundclose();
    if(AT != null)  AT.close();
    if(bul != null)  bul.close();
  }
  
  //描画
  void draw(){
    tint(255, alpha);
    image(image, imgx, imgy);
    noTint();
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
  AudioSample AT;  //壁に当たったときになる音
  
  String ATname;
  
  int[] col;       //色
  boolean bisOver;
  //boolean isOver;
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
    
    copy();
    
    energy = 25;
    maxhp = hp = 1;
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
  
  void copy(){
    Bullet b = (Bullet)db.otherobj.get(3);
    AT = db.setsound(b.ATname);
  }
  
  //普通の弾のinitial
  void sinitial(){
    col[0] = 255;
    col[1] = 255;
    col[2] = 255;
    
    h = (int)(4*db.scwhrate);
    damage = 2;
    
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
    outdicision();
    setBver();
    plus();
  }
  
  //上下の画面外に出たらこのインスタンスを削除
  void outdicision(){
    //どんな角度でもこれを満たせば外に出ている
    if(y+length.mag() < 0 || y-length.mag() > height)  isDie = true;
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
  
  void soundclose(){
    if(AT != null)  AT.close();
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