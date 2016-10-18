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
  
  AudioSample erase;    //消すときの音
  
  Player(){
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
      energy = MAXchoke/3;
      x = y = z = 0;
      
      gap = p.gap;
      dist = p.dist;
      ATflag = false;
      
      oripol = new Polygon(p.pol.ver);
      pol    = new Polygon(p.pol.ver);
    }catch(NullPointerException e){}
  }
  
  //動作
  void update(){
    move();
    
    setPolygonAngle();
    overlap();
    
    ATorCreate();
  }
  
  void move(){
    /*x = mouseX;
    y = mouseY;
    
    switch(key){
      case 1:
        radian += PI/180 * 2;
        break;
      case 2:
        radian -= PI/180 * 2;
        break;
    }*/
    
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
    
    println(x1+" "+y1+" "+z1+" "+x2+" "+y2+" "+z2);
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
        choke += e.energy;
        if(e.hp <= 0){
          score += score(e);
        }
      }
    }
    if(erase != null)  erase.trigger();
  }
  
  //敵と自機が重なっているかどうかの判定:  戻り値→変更前のisOver
  void overlap(){
    for(int i = 0; i < enemys.size(); i++){
      Enemy e = enemys.get(i);
      
      e.bisOver = e.isOver;
      
      if(e.charanum != 3 && e.charanum != 7){
        if(judge(pol, e.pol))  e.isOver = true;
        else                   e.isOver = false;
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
    
    if(count/60 >= 1 && choke >= energy){
      walls.add(new Wall(x, y, height/2.0, h*2, PI/2));
      choke -= energy;
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
  float hp;            //体力
  float bhp;
  float border;        //自陣の境界
  
  PImage img;          //画像
  float imgm;          //画像の拡大倍率
  float angle;         //画像回転角度（単位：度）
  float anglev;        //角速度  （単位：度）
  
  Home(){
    border = width/11.0;
    
    img = reverse(loadImage("cleaner.png"));
    imgm = (float)1/3;
    
    w = (int)(img.width * imgm * db.scwhrate);
    h = (int)(img.height * imgm * db.scwhrate);
    
    x = border - w + width/20.0*1.65;
    y = (int)((float)height/2);
    
    hp = 1000;
    img.resize(w, h);
    anglev = 3;
    angle = 0;
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
          case 0:
            if(b.x <= border){
              hp -= b.damage;
              b.hp = 0;
            }
            break;
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
        }
      }
    }
    
    for(int i = 0; i < shurikens.size(); i++){
      Shuriken s = shurikens.get(i);
      
      if(s.x-s.r/2 <= border){
        hp -= s.damage;
        s.hp = 0;
      }
    }
  }
  
  void draw(){
    fill(255, 0, 0, 100);
    noStroke();
    rect(0, 0, border, height);
    image(img, (int)x - w/2, (int)y - h/2);
  }
}

//**************************************************************************************

class Wall extends Enemy{
  float radian;    //単位はラジアン　正方向は時計回り
  
  Wall(float x, float y, float w, float h, float radian){
    this.x = x;
    this.y = y;
    this.w = (int)w;
    this.h = (int)h;
    this.radian = radian;
    isDie = false;
    hp = 100;
    
    pol = new Polygon();
    for(int i = 0; i < 4; i++)
      pol.Add(new PVector(0, 0, 0));
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
  
  void dicision(){
    for(int i = 0; i < bullets.size(); i++){
      Bullet b = bullets.get(i);
      
      if(b.num == 0){
        if(judge(pol, b.pol)){
          hp -= b.damage;
          b.hp = 0;
        }
      }else if(b.num == 1){
        hp = 0;
      }
    }
    
    for(int i = 0; i < shurikens.size(); i++){
      Shuriken s = shurikens.get(i);
      
      if(judge(new PVector(s.x, s.y), s.r/2, pol)){
        s.v.set(-s.v.x, -s.v.y, -s.v.z);
        s.x = x+h/2.0+s.r/2.0;
        s.isReflected = true;
        hp -= s.damage;
      }
    }
    
    for(int i = 0; i < enemys.size(); i++){
      Enemy e = enemys.get(i);
      
      if(judge(pol, e.pol)){
        if(e.Acount++%30 == 0)  hp -= 1;
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