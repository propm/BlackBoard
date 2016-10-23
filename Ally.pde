//プレイヤー
class Player extends Enemy{
  float z;
  float gap;       //angleに対して黒板消しの四隅の点がどれだけの角度ずれているか
  float dist;      //黒板消しの中心から四隅の点までの長さ
  int energy;      //壁作成に必要なエネルギー
  
  int count;
  float radian;    //黒板消しが横向きになっているとき0、時計回りが正方向(-π < radian <= π)
  int key;
  
  boolean ATflag;     //マウスクリック時true
  boolean bATflag;
  ArrayList<PVector> bver;
  
  AudioSample erase;    //消すときの音
  AudioSample create;   //壁を作るときの音
  Polygon bpol;         //前のpol
  
  Player(){
    if(db.otherobj.size() > 0){
      initial();
    }
  }
  
  //コピー
  void copy(){
    Player p = (Player)db.otherobj.get(0);
    
    erase = p.erase;
    create = p.create;
    pol    = new Polygon(p.pol.ver);
  }
  
  //初期化
  void initial(){
    copy();
    radian = 0;
    key = 0;
    energy = MAXchoke/3;
    x = y = z = 0;
      
    gap = atan(db.eraserh/db.eraserw);
    
    float distx = width/db.boardw*db.eraserw/2;
    float disty = height/db.boardh*db.eraserh/2;
    
    dist = (float)Math.sqrt(distx*distx + disty*disty);
    
    w = (int)(distx*2);
    h = (int)(disty*2);
    
    setPolygonAngle();
    
    bver = new ArrayList<PVector>();
    for(int i = 0; i < pol.ver.size(); i++)
      bver.add(pol.ver.get(i));
  }
  
  //動作
  void update(){
    move();
    
    setBver();
    setPolygonAngle();  //多角形設定
    overlap();          //敵と重なっているかどうかの判定
    
    //壁作成・攻撃
    ATorCreate();
  }
  
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
    
    //readXYZ();
  }
  
  void setBver(){
    for(int i = 0; i < pol.ver.size(); i++)
      bver.set(i, pol.ver.get(i));
  }
  
  //キネクトから座標を受け取る
  void readXYZ(){
    float x1, y1, x2, y2, z1, z2;
    x1 = x2 = y1 = y2 = z1 = z2 = 0;
    
    if(client.available() >= 24){
      x1 = readInt();
      y1 = readInt();
      z1 = readInt();
      x2 = readInt();
      y2 = readInt();
      z2 = readInt();
    }
    
    radian = atan2(y2-y1, x2-x1);
    
    x = abs(x2-x1);
    y = abs(y2-y1);
    z = abs(z2-z2);
  }
  
  //攻撃するか壁を作るか判定
  void ATorCreate(){
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
      Enemy e = enemys.get(i);
      
      if((!bATflag || !e.bisOver) && e.isOver && e.charanum != 6){
        e.hp--;
        combo++;
        
        if(e.hp <= 0){
          score += score(e);
          choke += e.maxhp*e.energy;
        }
      }
    }
    
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      switch(b.num){
        case 0:
        case 4:
        case 5:
        case 6:
          if(bdicision(b)){
            if(!b.bisOver){
              b.hp--;
              combo++;
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
    
    if(erase != null)  erase.trigger();
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
  
  //敵と自機が重なっているかどうかの判定:  戻り値→変更前のisOver
  void overlap(){
    for(int i = 0; i < enemys.size(); i++){
      Enemy e = enemys.get(i);
      
      e.bisOver = e.isOver;
      
      if(e.charanum != 3){
        if(e.charanum != 7){
          if(judge(pol, e.pol))  e.isOver = true;
          else                   e.isOver = false;
        }
      }else{
        Tangent t = (Tangent)e;
        if(judge(new PVector(t.x, t.y), t.r, pol))  e.isOver = true;
        else                                        e.isOver = false;
      }
    }
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
    
    if(count/60 >= 1 && choke >= 0/*energy*/){
      walls.add(new Wall(x, y, height/2.0, h*2, PI/2));
      if(create != null)  create.trigger();
      //choke -= energy;
      count = 0;
    }
  }
  
  void soundstop(){
    super.soundstop();
    create.close();
    erase.close();
  }
  
  void draw(){
    noStroke();
    pushMatrix();
    translate(x, y);
    rotate(radian);
    rect(-w/2, -h/2, w, h);
    popMatrix();
    
    text(combo, x+width/60.0, y-height/80.0);
    
    pol.Draw();
  }
}

//******************************************************************************************************

//自陣
class Home extends MyObj{
  int bhp;
  float border;        //自陣の境界
  
  PImage image;          //画像
  float imgm;          //画像の拡大倍率
  float angle;         //画像回転角度（単位：度）
  float anglev;        //角速度  （単位：度）
  
  AudioSample damaged;
  
  Home(){
    if(db.otherobj.size() > 1){
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
    
    hp = 1000;
    anglev = 3;
    angle = 0;
  }
  
  void copy(){
    Home oh = (Home)db.otherobj.get(1);
    image = oh.image.copy();
    damaged = oh.damaged;
    imgm = oh.imgm;
  }
  
  void update(){
    bhp = hp;
    
    angle += anglev;
    angle %= 360;
    y = sin(angle/180*PI)*4 + height/2;
    
    damage();
    //if(bhp != hp)  println("hp: "+hp);
  }
  
  void damage(){
    
    boolean isDamaged = false;
    for(int i = 0; i < enemys.size(); i++){
      Enemy e = enemys.get(i);
      
      if(e.charanum == 3){
        Tangent t = (Tangent)e;
        if(t.x-t.r/2.0 < border){
          hp -= e.damage;
          e.hp = 0;
          isDamaged = true;
        }
      }else if(e.charanum != 7){
        if(e.x < border && e.charanum != 3){
          hp -= e.damage;
          e.hp = 0;
          isDamaged = true;
        }
      }
    }
    
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      if(b.y+b.h/2 > 0 && b.y-b.h/2 < height){
        isDamaged = true;
        
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
    
    if(damaged != null && isDamaged)  damaged.trigger();
    _damaged = isDamaged;
  }
  
  void soundstop(){
    super.soundstop();
    damaged.close();
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
  AudioSample damaged;
  
  Wall(){}
  
  Wall(float x, float y, float w, float h, float radian){
    this.x = x;
    this.y = y;
    this.w = (int)w;
    this.h = (int)h;
    this.radian = radian;
    isDie = false;
    hp = 100;
    
    copy();
    
    pol = new Polygon();
    for(int i = 0; i < 4; i++)
      pol.Add(new PVector(0, 0, 0));
  }
  
  void copy(){
    Wall ow = (Wall)db.otherobj.get(2);
    die = ow.die;
    damaged = ow.damaged;
    reflect = ow.reflect;
  }
  
  void update(){
    setPolygonAngle();
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
            
            if(damaged != null)  damaged.trigger();
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
                if(damaged != null)  damaged.trigger();
                break;
              
              case 3:
              case 6:
                s.v.set(-s.v.x, -s.v.y, -s.v.z);
                s.x = x+h/2.0+s.r/2.0;
                s.isReflected = true;
                
                if(reflect != null)  reflect.trigger();
                _reflect = true;
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
      if(die != null)  die.trigger();
    }
  }
  
  void soundstop(){
    super.soundstop();
    reflect.close();
    damaged.close();
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