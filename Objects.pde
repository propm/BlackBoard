//敵
class Enemy{
  float x, y;                 //画像左上の座標
  float w, h;                 //画像の大きさ
  int energy;                 //粉エネルギー
  int hp;                     //体力(何回消されたら消えるか)
  boolean dieflag;            //死んでいるならtrue
  ArrayList<PImage> imgs;     //画像
  ScrollManager sm;
  
  Enemy(){
    dieflag = false;
    imgs = new ArrayList<PImage>();    //アニメーションさせるために10枚ほど絵が必要
    x = -random(10);
    
  }
  
  void move(){}
  
  void reSize(){
    for(int i = 0; i < imgs.size(); i++){
      imgs.get(i).resize((int)w, (int)h);
    }
  }
  
  //描画
  void draw(){
    image(imgs.get(0), x - sm.x, y - sm.y);
  }
  
}

//突撃隊
class Attacker extends Enemy{
  
  Attacker(ScrollManager sm){
    this.sm = sm;
    initial();
    reSize();
  }
  
  Attacker(){
    initial();
  }
  
  void initial(){
    imgs.add(loadImage("attacker.png"));
    w = imgs.get(0).width/20;
    h = imgs.get(0).height/20;
    
    hp = 2;
    y = height - h;
  }
  
  void move(){
    x++;
  }
}

//フライングタコ
class Flys extends Enemy{
  
  Flys(){
    imgs.add(loadImage("flyattacker.png"));
    w = imgs.get(0).width/20;
    h = imgs.get(0).height/20;
    hp = 1;
  }

}

//正弦タコ
class Sin extends Flys{
  float basicy;    //角度が0のときの高さ
  int theta;       //角度(ラジアンではない);
  
  Sin(ScrollManager sm){
    this.sm = sm;
    initial();
    reSize();
  }
  
  Sin(){
    initial();
  }
  
  void initial(){
    theta = 0;
    basicy = random(height/3*2) + h/2 + height/6;
  }
  
  void move(){
    theta+=2;
    y = basicy - sin(theta*PI/180)*height/6;
    x = theta;
  }
}

//タンジェントタコ
class Tangent extends Sin{
  
  Tangent(ScrollManager sm){
    this.sm = sm;
    reSize();
  }
  
  void move(){
    theta+=2;
    y = basicy - tan(theta*PI/180)*100;
    x += 5;
  }
}

//パラシュートタコ
class Parachuter extends Attacker{
  boolean parachuterflag;      //地面に着地するまではパラシュート状態：true
  
  Parachuter(ScrollManager sm){
    this.sm = sm;
    
    parachuterflag = true;
    y = -random(100);
    x = random(500);
    
    reSize();
  }
  
  void move(){
    if(parachuterflag){
      y += 6;
      x++;
      
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
  ScrollManager sm;
    
  Home(ScrollManager sm){
    this.sm = sm;
    
    x = (int)((float)width/50*6);
    y = (int)((float)height/2);
    
    img = reverse(loadImage("cleaner.png"));
    imgm = (float)1/3;
    
    w = (int)(img.width * imgm);
    h = (int)(img.height * imgm);
    
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
