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
    
    imgs = new ArrayList<PImage>(oe.imgs);
    image = imgs.get(0);
    oripol = new Polygon(oe.pol.ver);
    pol    = new Polygon(oe.pol.ver);
    oripol.Init();
    
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
    collision();
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
    o.debagnum = 1;
    o.move();
    o.setPolygon(o.imgx, o.imgy);
    
    //凸包作成
    Polygon convex = createConvex(pol.ver, o.pol.ver);
    if(convex == null)  return;
    convex.Draw();
    
    //補正
    //correction(o);
    
  }
  
  //補正
  /*void correction(Enemy o){
    
    //ぶつかる可能性がある壁の検出
    final int RIGHT = 1;
    PVector move = sub(o.pol.ver.get(0), pol.ver.get(0));
    int a, b;    //右側を1として時計回り
    a = b = 0;
    ArrayList<PVector> vers = new ArrayList<PVector>(pol.ver);
    
    if(move.x > 0)  a = 1;
    if(move.x < 0)  a = 3;
    if(move.y > 0)  a = 4;
    if(move.y < 0)  a = 2;
    
    if(a == 0 && b == 0)  return;
    
    ArrayList<float[]> wallside = new ArrayList<float[]>(vers.size());  //要素1: どの辺にぶつかっているか
                                                                        //要素2: その辺との距離
    if(a == 0 || b == 0){
      if(b != 0)  a = b;
      int element = a%walls.get(0).pol.vers.size();
      for(int i = 0; i < walls.size(); i++){
        ArrayList<PVector> wallvs = new ArrayList<PVector>(walls.get(i).pol.ver);
        for(int j = 0; j < vers.size(); j++){
          float[] f = new float[2];    //1つ目の要素が1なら壁の横の辺、2なら壁の縦の辺
          
          if(isIntersectSS(wallvs.get(element), wallvs.get((element+1)%wallvs.size()), pol.ver.get(j), o.pol.ver.get(j)){
            f[0] = 1;
            f[1] = distance(wallvs.get(element), wallvs.get((element+1)%wallvs.size()), pol.ver.get(j), o.pol.ver.get(j), move);
          }else{
            a[0] = a[1] = 0;
          }
          
          wallside.add(a);
        }
      }
      
    }else{
      int element1 = a%walls.get(0).pol.vers.size();
      int element2 = b%walls.get(0).pol.vers.size();
      for(int i = 0; i < walls.size(); i++){
        ArrayList<PVector> wallvs = new ArrayList<PVector>(walls.get(i).pol.ver);
        for(int j = 0; j < vers.size(); j++){
          float[] f = new float[2];    //1つ目の要素が1なら壁の横の辺、2なら壁の縦の辺
          
          if(isIntersectSS(wallvs.get(element1), wallvs.get((element1+1)%wallvs.size()), pol.ver.get(j), o.pol.ver.get(j)){
            f[0] = 1;
            f[1] = distance(wallvs.get(element1), wallvs.get((element1+1)%wallvs.size()), pol.ver.get(j), o.pol.ver.get(j), move);
          }else if(isIntersectSS(wallvs.get(element2), wallvs.get((element2+1)%wallvs.size()), pol.ver.get(j), o.pol.ver.get(j)){
            f[0] = 2;
            f[1] = distance(wallvs.get(element2), wallvs.get((element2+1)%wallvs.size()), pol.ver.get(j), o.pol.ver.get(j));
          }else{
            a[0] = a[1] = 0;
          }
          
          wallside.add(a);
        }
      }
    }
    
    //緑線の取得
    ArrayList<Float> distance = new ArrayList<Float>();
    boolean throughIf = false;
    for(int i = 0; i < wallside.size(); i++){
      PVector ss1, ss2, point1, point2;
      if(wallside.get(i)[0] == 0){
        if(wallside.get((i+1)%wallside.size())[0] == 1){  
          ss2 = vers.get((i+1)%wallside.size());
        }
        if(wallside.get((i-1+wallside.size())%wallside.size())[0] == 1){  
          ss2 = vers.get((i-1+wallside.size())%wallside.size());
        }
        if(ss2 != null){
          point1 = 
        }
      }
  }
  
  //緑線取得  a, b: ぶつかる可能性がある壁の辺の番号（右が1）
  void getGreen(int a, int b, ArrayList<float[]> wallside){
    boolean isTwoside = true;    //ぶつかる可能性がある壁が2つならtrue
    if(b == 0){
      a = b;
      isTwoside = false;
    }
    
    ArrayList<Float> distance = new ArrayList<Float>();
    boolean throughIf = false;
    for(int i = 0; i < wallside.size(); i++){
      PVector ss1, ss2, point1, point2;
      if(wallside.get(i)[0] == 0){
        if(wallside.get((i+1)%wallside.size())[0] == 1 && !throughIf){  
          ss2 = vers.get((i+1)%wallside.size());
          i--;
          throughIf = true;
        }
        if(wallside.get((i-1+wallside.size())%wallside.size())[0] == 1 && throughIf){  
          ss2 = vers.get((i+1)%wallside.size());
          throughIf = false;
        }
        if(ss2 != null){
          point1 = 
        }
      }
    }
  }
  
  void getGreen(int a){
    getGreen(a, 0);
  }*/
  
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
  int   damage;    //与えるダメージ
  int   num;       //bulletなら0、laserなら1、beamなら2、shurikenなら3、
                   //standardなら4、reflectなら5、strongなら6
  int[] col;       //色
  
  PVector length;       //弾の長さ
  
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
    if(num == 2)  return;
    
    num = 0;
    die = minim.loadSample("normalbullet_hit.mp3");
    
    col[0] = 255;
    col[1] = 134;
    col[2] = 0;
    
    length = v.copy();
    length.setMag(50*db.scwhrate);
    
    h = (int)(4*db.scwhrate);
    damage = 2;
    hp = 1;
    radian = atan2(v.y, v.x);
    isDie = false;
    
    pol = new Polygon();
    for(int i = 0; i < 4; i++)
      pol.Add(new PVector(0, 0, 0));
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
  }
  
  void move(){
    x += v.x;
    y += v.y;
  }
  
  void update(){
    move();
    plus();
  }
  
  void plus(){
    if(radian == PI)  setPolygon();
    else              setPolygonAngle();
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