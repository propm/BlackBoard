//プレイヤー
class Player extends MyObj{
  final float abledifference = 10.0;    //壁を作るときに許容される誤差
  final int   ATbframe       = 5;       //攻撃するときに現在と角度を比べるベクトルが何フレーム前のものか
  final float eraseablelen   = 30;      //角度を変えたときにもう一度消したと認識される長さ
  final int NotCreateFrame = 3*60;  //
  
  float bx, by;            //1フレーム前の座標
  
  float z;
  float gap;       //angleに対して黒板消しの四隅の点がどれだけの角度ずれているか
  float dist;      //黒板消しの中心から四隅の点までの長さ
  int energy;      //壁作成に必要なエネルギー
  
  int count;
  int notCreatableCount;   //壁が作れない間 +1される
  float radian;    //黒板消しが横向きになっているとき0、時計回りが正方向(-π < radian <= π)
  int key;         //回転方向を持つ
  
  boolean ATflag;     //マウスクリック時true
  boolean bATflag;
  boolean createflag;       //壁を作っている間true
  boolean out;                  //
  
  ArrayList<PVector> bver;  //前フレームのpol.ver
  PVector createxy;         //壁を作り始めたときの座標
  
  AudioSample create;   //壁を作るときの音
  Polygon bpol;         //前のpol
  
  String createname;
  int side;
  
  
  Player(){}
  
  Player(int side){
    initial();
    this.side = side;
  }
  
  //コピー
  void copy(){
    Player p = (Player)db.otherobj.get(0);
    
    create = db.setsound(p.createname);
    pol    = new Polygon(p.pol.ver);
  }
  
  //初期化
  void initial(){
    copy();
    radian = 0;
    key = 0;
    energy = 0;
    x = y = z = 0;
    bframecount = 0;
    notCreatableCount = 0;
    
    gap = atan(db.eraserh/db.eraserw);
    
    float distx = width/db.boardw*db.eraserw/2;
    float disty = height/db.boardh*db.eraserh/2;
    
    dist = (float)Math.sqrt(distx*distx + disty*disty);
    
    w = (int)(distx*2);
    h = (int)(disty*2);
    
    setPolygonAngle();
    createxy = new PVector(x, y);
    bframedirs = new ArrayList<Float>(ATbframe);
    
    bver = new ArrayList<PVector>();
    for(int i = 0; i < pol.ver.size(); i++)
      bver.add(pol.ver.get(i));
      
    radian = PI/2;
    out = true;
  }
  
  //動作
  void update(){
    move();
    
    outdicision();
    setBver();
    setPolygonAngle();  //多角形設定
    
    //壁作成・攻撃
    switch(scener.scenenum){
      case 0:
        titleAttack();
        break;
      case 2:
      case 3:
      case 4:
        ATorCreate();
        break;
      default:  break;
    }
  }
  
  void move(){
    bx = x;
    by = y;
    
    if(isMouse){
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
    }else{
      readXY();    //キネクトから座標を読み込む
    }
  }
  
  void outdicision(){
    out = (x < home.border || x > width || y < 0 || y > height);
  }
  
  //現在の位置を前フレームの位置として残す
  void setBver(){
    for(int i = 0; i < pol.ver.size(); i++)
      bver.set(i, pol.ver.get(i));
  }
  
  //キネクトから座標を受け取る
  void readXY(){
    x = kinect.getX(side);
    y = kinect.getY(side);
  }
  
  //タイトルを消す
  void titleAttack(){
    if(ATflag){
      if(judge(pol, db.title.pol)){
        scener.changeScene();
      }
    }
  }
  
  //攻撃するか壁を作るか判定
  void ATorCreate(){
    notCreatableCount++;    //ゲームが始まって5秒間は壁が作れない
    
    if(!isMouse)  ATflag = true;      //mouseで操作してない場合はATflagの判定は不要
    if(!ATflag)  bframecount = 0;
    
    if(abs(x - createxy.x) <= abledifference && abs(y - createxy.y) <= abledifference){
      if(ATflag){
        if(notCreatableCount > NotCreateFrame)
          if(!out)  createwall();
      }
      else        count = 0;
    }else{
      createflag = false;
      count = 0;
      if(ATflag)  attack();
    }
    
    if(!createflag)  createxy = new PVector(x, y);
    bATflag = ATflag;
  }
  
  float dirx, diry;        //角度が変わったとき、もしくは当たり判定に入ったときの座標
  int bframecount;         //値がATbframe(現在の移動方向と比べる移動方向が何フレーム前のものか)になるまで++
  boolean alleover;        //どの敵とも重なっていなかったらfalse
  ArrayList<Float> bframedirs;
  
  //攻撃判定
  void attack(){
    alleover = false;
    
    //ザコ敵との判定
    for(int i = 0; i < enemys.size(); i++){
      Enemy e = enemys.get(i);
      if(e.charanum != 6)  dicisionEnemy(e);    //忍者以外なら判定
    }
    
    //ボスとの判定
    if(boss != null){
      if(boss.isStan){
        dicisionEnemy(boss);
      }
    }
    
    //どの敵とも重なっていなければ、記憶していた移動方向をすべて消去
    if(!alleover){
      dirx = diry = -1;
      bframedirs = new ArrayList<Float>(ATbframe);
      bframecount = 0;
    }
    
    //弾との判定
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      switch(b.num){
        case 0:  //普通弾
        case 4:  //通常弾
        case 5:  //反射弾
          if(bdicision(b)){
            if(!b.bisOver){
              b.hp--;
              b.bisOver = true;
              if(hp == 0){
                choke += b.maxhp*b.energy;
              }
            }
          }else{
            b.bisOver = false;
          }
          break;
      }
    }
    
  }
  
  //敵と自機が重なっているかどうかの判定:  戻り値→変更前のisOver
  void overlap(Enemy e){
    e.bisOver = e.isOver;
      
    if(e.charanum != 3){
      if(judge(pol, e.pol))  e.isOver = true;
      else                   e.isOver = false;
    }else{
      Tangent t = (Tangent)e;
      if(judge(new PVector(t.x, t.y), t.r, pol))  e.isOver = true;
      else                                        e.isOver = false;
    }
  }
  
  //敵との判定
  void dicisionEnemy(Enemy e){
    
    //重なっているかどうかの判定
    overlap(e);
    
    //重なっていなければ何もしない
    if(e.isOver){
      alleover = true;
      
      float cframedir = atan2(y-by, x-bx);  //現在動いた方向（角度）を求める
      float bframedir;                      //一定フレーム前の角度
      
      //角度設定
      bframedirs.add(cframedir);
      bframedir = bframedirs.get(0);
      
      if(bframecount++ > ATbframe)
        bframedirs.remove(0);
      
      //消すときtrue
      boolean eraseable = false;
      
      //前フレームでクリックしていなかったか、重なっていない場合
      if(!bATflag || !e.bisOver){
        eraseable = true;
      }
      
      //前回ダメージを与えた点から一定距離以上離れていて、かつ角度が変わっているかどうか判定
      float length = sqrt((x-dirx)*(x-dirx)+(y-diry)*(y-diry));
      if(length >= eraseablelen){
        if(abs(cframedir - bframedir) >= PI/2){
          eraseable = true;
        }
      }
      
      //消す
      if(eraseable){
        dirx = x;
        diry = y;
        erase(e);
      }
    }
  }
  
  //ダメージを与える
  void erase(Enemy e){
    e.hp--;
    
    if(e.hp <= 0){
      score += getscore(e);
      choke += e.maxhp*e.energy;
      _kill = sendframes;
      if(choke > MAXchoke)  choke = MAXchoke;
    }
  }
  
  //弾との判定
  boolean bdicision(Bullet b){
    
    boolean result = false;
    Polygon convex = createConvex(pol.ver, bver);
    
    if(b.num == 0 || b.num == 4){
      Polygon bconvex = createConvex(b.pol.ver, b.bver);
    
      if(judge(convex, bconvex))  result = true;
    }else{
      Reflect ref = (Reflect)b;
      if(judge(new PVector(ref.x, ref.y), ref.r, convex))  result = true;
    }
    
    return result;
  }
  
  //radianが0のとき、右上が0
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
    
    if(choke >= energy){
      createflag = true;
      if(count/60 >= 1){
        walls.add(new Wall(x, y, height/2.0, h*2, PI/2));
        if(create != null && !soundstop)  create.trigger();
        choke -= energy;
        count = 0;
      }
    }
  }
  
  void soundclose(){
    super.soundclose();
    if(create != null)  create.close();
  }
  
  void draw(){
    noStroke();
    pushMatrix();
    translate(x, y);
    rotate(radian);
    rect(-w/2, -h/2, w, h);
    popMatrix();
    
    textSize(36);
    //text(combo, x+width/60.0, y-height/80.0);
    
    pol.Draw();
  }
}

//******************************************************************************************************

//自陣
class Home extends MyObj{
  final int MaxHP = 1000000;
  int bhp;
  float border;        //自陣の境界
  
  PImage image;        //画像
  float imgm;          //画像の拡大倍率
  float angle;         //画像回転角度（単位：度）
  float anglev;        //角速度  （単位：度）
  
  AudioSample damaged;
  String damagedname;
  
  Home(){
    if(db.isFinishInitial){
      initial();
    }
  }
  
  void initial(){
    copy();
    border = width/11.0;
    
    w = (int)(image.width * imgm * db.scwhrate);
    h = (int)(image.height * imgm * db.scwhrate);
    
    x = border - w + width/20.0*1.65;
    y = (int)((float)height/2);
    
    image.resize(w, h);
    
    hp = MaxHP;
    anglev = 3;
    angle = 0;
  }
  
  void copy(){
    Home oh = (Home)db.otherobj.get(1);
    image = oh.image.copy();
    damaged = db.setsound(oh.damagedname);
    imgm = oh.imgm;
  }
  
  void update(){
    bhp = hp;
    
    angle += anglev;
    angle %= 360;
    y = sin(angle/180*PI)*4 + height/2;
    
    damage();
    hpupdate();
  }
  
  //hp関係の処理
  void hpupdate(){
    if(bhp != hp){
      _damaged = sendframes;
      if(damaged != null && !soundstop)  damaged.trigger();
      
      if(hp <= 0){
        hp = 0;
        scener.JumptoGameOver();
      }
    }
  }
  
  void damage(){
    
    for(int i = 0; i < enemys.size(); i++){
      Enemy e = enemys.get(i);
      
      if(e.charanum == 3){
        Tangent t = (Tangent)e;
        if(t.x-t.r/2.0 < border){
          hp -= e.damage;
          e.hp = 0;
        }
      }else if(e.charanum != 7){
        if(e.x < border && e.charanum != 3){
          hp -= e.damage;
          e.hp = 0;
        }
      }
    }
    
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      if(b.y+b.h/2 > 0 && b.y-b.h/2 < height){
        
        switch(b.num){
          
          case 4:    //通常弾
          case 0:    //弱弾
            if(b.x <= border){
              hp -= b.damage;
              b.hp = 0;
            }
            break;
            
          //レーザー
          case 1:
            Laser l = (Laser)b;
            if(l.x+abs(l.length.x) >= border){
              
              if(l.x <= border){
                if(l.effect != null)  l.effect.copiable = false;
                l.x = border;
                l.length.setMag(l.length.mag()+l.v.x);
                l.setPolygonAngle();
                if(++l.Hcount%6 == 0){
                  hp -= l.damage;
                  if(l.Hcount >= 6)  l.Hcount = 0;
                }
              }
            }else{
              l.hp = 0;
            }
            break;
            
          //ビーム
          case 2:
            Beam be = (Beam)b;
            if(be.x >= border){
              
              if(be.x-be.length <= border){
                if(++be.Hcount%6 == 0){
                  hp -= be.damage;
                  if(be.Hcount >= 6)  be.Hcount = 0;
                }
              }
            }else{
              be.isDie = true;
            }
            break;
          
          case 3:    //手裏剣
          case 5:    //反射弾
          case 6:    //反射可能弾
            Shuriken s = (Shuriken)b;
            
            if(s.x-s.r/2 <= border){
              hp -= s.damage;
              s.hp = 0;
            }
        }
      }
    }
  }
  
  void soundclose(){
    super.soundclose();
    if(damaged != null)  damaged.close();
  }
  
  void draw(){
    fill(255, 0, 0, 100);
    noStroke();
    rect(0, 0, border, height);
    image(image, (int)x - w/2, (int)y - h/2);
  }
}

//**************************************************************************************

class Wall extends MyObj{
  float radian;    //単位はラジアン　正方向は時計回り
  int count;
  
  AudioSample reflect;
  String reflectname;
  
  Wall(){}
  
  Wall(float x, float y, float w, float h, float radian){
    this.x = x;
    this.y = y;
    this.w = (int)w;
    this.h = (int)h;
    this.radian = radian;
    isDie = false;
    hp = 50;
    
    copy();
    
    pol = new Polygon();
    
    for(int i = 0; i < 4; i++)  pol.Add(0, 0, 0);
    setPolygonAngle();
  }
  
  void copy(){
    Wall ow = (Wall)db.otherobj.get(2);
    die = db.setsound(ow.diename);
    reflect = db.setsound(ow.reflectname);
  }
  
  void update(){
    dicision();
    timer();
  }
  
  void timer(){
    count++;
    if(count/60 >= 1){
      hp -= 5;
      count = 0;
    }
  }
  
  //radianが0のとき、右上から時計回り(右上が0）
  void setPolygonAngle(){
    pol.ver.set(0, new PVector(x+w/2*cos(radian)+h/2*cos(radian-PI/2), y+w/2*sin(radian)+h/2*sin(radian-PI/2), 0));
    pol.ver.set(1, new PVector(x+w/2*cos(radian)+h/2*cos(radian+PI/2), y+w/2*sin(radian)+h/2*sin(radian+PI/2), 0));
    pol.ver.set(2, new PVector(x+w/2*cos(radian+PI)+h/2*cos(radian+PI/2), y+w/2*sin(radian+PI)+h/2*sin(radian+PI/2), 0));
    pol.ver.set(3, new PVector(x+w/2*cos(radian+PI)+h/2*cos(radian-PI/2), y+w/2*sin(radian+PI)+h/2*sin(radian-PI/2), 0));
    pol.Init();
  }
  
  //壁と敵・弾の判定
  void dicision(){
    
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      switch(b.num){
        
        //通常弾・普通弾
        case 4:
        case 0:
          if(judge(pol, b.pol)){
            hp -= b.damage;
            b.hp = 0;
            if(b.AT != null && !soundstop)  b.AT.trigger();
          }
          break;
          
        //レーザー
        case 1:
          if(judge(pol, b.pol))  hp = 0;
          break;
          
        //手裏剣・反射弾・反射可能弾
        case 3:
        case 5:
        case 6:
          Shuriken s = (Shuriken)b;
          
          if(judge(new PVector(s.x, s.y), s.r/2, pol)){
            hp -= s.damage;
            
            switch(b.num){
              case 5:
                s.hp = 0;
                break;
              
              case 3:
              case 6:
                s.v.set(-s.v.x, -s.v.y, -s.v.z);
                s.x = x+h/2.0+s.r/2.0;
                s.isReflected = true;
                
                if(reflect != null && !soundstop)  reflect.trigger();
                _reflect = sendframes;
                break;
            }
          }
      }
    }
    //敵
    for(int i = 0; i < enemys.size(); i++){
      Enemy e = enemys.get(i);
      
      switch(e.charanum){
        case 2:
        case 1:
          if(e.pol.isCollide && e.pol.wallxy.x == x && e.pol.wallxy.y == y){
            e.Acount++;
            if(e.Acount == 0){
              hp -= 1;
            }
          }
          break;
          
        case 4:
          Parachuter p = (Parachuter)e;
          if(!p.change)  break;
        case 3:
          if(judge(pol, e.pol)){
            hp = 0;
          }
          break;
      }
    }
  }
  
  void die(){
    if(hp <= 0){
      isDie = true;
      if(die != null && !soundstop)  die.trigger();
    }
  }
  
  void soundclose(){
    super.soundclose();
    if(reflect != null)  reflect.close();
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