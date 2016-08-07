//敵
class Enemy{
  float x, y;                 //画像左上の座標
  float vx;                   //横方向の速度
  int   w, h;                 //画像の大きさ
  int energy;                 //粉エネルギー
  int hp;                     //体力(何回消されたら消えるか)
  boolean dieflag;            //死んでいるならtrue
  ArrayList<PImage> imgs;     //画像
  
  AudioSample diesound, attacksound;
  
  Enemy(){
    dieflag = false;
    imgs = new ArrayList<PImage>();    //アニメーションさせるために10枚ほど絵が必要
  }
  
  void move(){}
  
  void reSize(){
    for(int i = 0; i < imgs.size(); i++){
      imgs.get(i).resize((int)w, (int)h);
    }
  }
  
  void Reverse(){
    for(int i = 0; i < imgs.size(); i++){
      imgs.set(i, reverse(imgs.get(i)));
    }
  }
  
  void die(){
    dieflag = true;
    diesound.trigger();
  }
  
  //描画
  void draw(){
    image(imgs.get(0), x - sm.x, y - sm.y);
  }
  
}

//突撃隊
class Attacker extends Enemy{
  
  Attacker(){
    initial();
    reSize();
  }
  
  Attacker(int x, int y){
    this.x = x+sm.x;
    this.y = y+sm.y;
    initial();
    reSize();
  }
  
  void initial(){
    if(attacker_die != null)  diesound = minim.loadSample(attacker_die);
    if(attacker_attack != null)  attacksound = minim.loadSample(attacker_attack);
    
    imgs.add(loadImage("attacker.png"));
    w = (int)(imgs.get(0).width/20.0);
    h = (int)(imgs.get(0).height/20.0);
    vx = -1;
    
    hp = 2;
    y = height - h;
    
    Reverse();
  }
  
  void move(){
    x += vx;
    if(x - sm.x < width/2)  die();
  }
}

//フライングタコ
class Flys extends Enemy{
  
  Flys(){
    imgs.add(loadImage("flyattacker.png"));
    w = (int)(imgs.get(0).width/20.0);
    h = (int)(imgs.get(0).height/20.0);
    hp = 1;
  }

}

//正弦タコ
class Sin extends Flys{
  
  float basicy;    //角度が0のときの高さ
  int theta;       //角度(ラジアンではない);
  
  Sin(){
    initial();
    basicy = random(height/3*2) + h/2 + height/6;
    reSize();
  }
  
  Sin(int x, int y){
    this.x      = x+sm.x;
    this.basicy = y+sm.y;
    
    initial();
    reSize();
  }
  
  void initial(){
    if(sin_die != null)     diesound = minim.loadSample(sin_die);
    if(sin_attack != null)  attacksound = minim.loadSample(sin_attack);
    
    theta = 0;
    vx = -2;
    Reverse();
  }
  
  void move(){
    theta+=2;
    y = basicy - sin(theta*PI/180)*height/6;
    x += vx;
  }
}

//タンジェントタコ
class Tangent extends Sin{
  
  Tangent(){
    if(tangent_die != null)     diesound = minim.loadSample(tangent_die);
    if(tangent_attack != null)  attacksound = minim.loadSample(tangent_attack);
    vx = -5;
  }
  
  Tangent(int x, int y){
    this.x = x+sm.x;
    this.basicy = y+sm.y;
    if(tangent_die != null)     diesound = minim.loadSample(tangent_die);
    if(tangent_attack != null)  attacksound = minim.loadSample(tangent_attack);
    vx = -5;
  }
  
  void move(){
    theta+=2;
    y = basicy - tan(theta*PI/180)*100;
    x += vx;
  }
}

//パラシュートタコ
class Parachuter extends Attacker{
  
  boolean parachuterflag;      //地面に着地するまではパラシュート状態：true
  
  Parachuter(){
    if(parachuter_die != null)     diesound = minim.loadSample(parachuter_die);
    if(parachuter_attack != null)  attacksound = minim.loadSample(parachuter_attack);
    
    parachuterflag = true;
    y = -random(100);
    x = random(500);
    vx = -0.5;
    
    reSize();
  }
  
  Parachuter(int x, int y){
    if(parachuter_die != null)     diesound = minim.loadSample(parachuter_die);
    if(parachuter_attack != null)  attacksound = minim.loadSample(parachuter_attack);
    
    parachuterflag = true;
    this.y = y+sm.y;
    this.x = x+sm.x;
    vx = -0.5;
    
    reSize();
  }
  
  void move(){
    if(parachuterflag){
      y += 6;
      x += vx;
      
      if(y > height - h){
        y = height - h;
        parachuterflag = false;
      }
      
    }else{
      super.move();
    }
  }
}

//プレイヤー
class Player{
  float x, y;                  //座標
  boolean attackflag = false;  //マウスクリック時true
  AudioSample erasesound;
  
  Player(){
    if(erase != null)  erasesound = minim.loadSample(erase);
  }
  
  void move(){
    x = mouseX;
    y = mouseY;
    
    if(attackflag)  attack();
  }
  
  void attack(){
    
  }
  
  void draw(){
    ellipse(x, y, 20, 20);
  }
}

//自陣
class Home{
  int x, y;            //自陣の中心の座標
  int w, h;
  PImage img;          //画像
  float imgm;          //画像の拡大倍率
  float angle;         //画像回転角度（単位：度）
  int hp;              //体力
    
  Home(){
    
    x = (int)((float)width/50*6);
    y = (int)((float)height/2);
    
    img = reverse(loadImage("cleaner.png"));
    imgm = (float)1/3;
    
    w = (int)(img.width * imgm / widthrate);
    h = (int)(img.height * imgm / heightrate);
    
    img.resize(w, h);
  }
  
  void rotation(){
    
    pushMatrix();
    translate(x - sm.x, y - sm.y);
    rotate(angle/(180/PI));
    
    angle += 2;
    angle %= 360;
  }
  
  void draw(){
    rotation();
    image(img, 0 - w/2, 0-h/2);
    popMatrix();
  }
}
