
class Laser extends Bullet{
  int count;
  int maxcount;    //レーザーを打つ秒数
  int Hcount;      //自陣に当たったときのカウント

  Enemy   owner;   //この弾を出したオブジェクト
  
  Laser(float x, float y, PVector v, Enemy owner){
    this.x = x;
    this.y = y;
    this.v = v;
    this.owner = owner;
    initial();
  }
  
  void initial(){
    super.initial();
    if(num == 2)  return;
    
    num = 1;
    h = (int)(8*db.scwhrate);
    count = Hcount = 0;
    maxcount = 60 * 1;
    damage = 4;
    
    col[0] = 255;
    col[1] = 20;
    col[2] = 147;
  }
  
  void plus(){
    if(count++ < maxcount && !owner.isDie)  length.setMag(dist(owner.x, owner.y+owner.h/2, x, y));
    setPolygonAngle();
  }
}

//*************************************************************************************
class Beam extends Bullet{
  int Hcount;
  int margin;
  float length;
  Enemy owner;
  AudioSample hit;
  
  Beam(Enemy owner){
    this.owner = owner;
    initial();
  }
  
  void initial(){
    num = 2;
    super.initial();
    
    hit = minim.loadSample("beam_hit.mp3");
    
    h = 6;
    Hcount = 0;
    damage = 5;
    margin = 15;
    length = width;
  }
  
  void update(){
    x = owner.x-margin;
    y = owner.y+owner.h/2;
    
    dicision();
    if(owner.isDie)  isDie = true;
  }
  
  void die(){}
  
  //被防御判定
  void dicision(){
    boolean notprevent = true;  //妨げられていなければtrue
             
    for(int i = 0; i < walls.size(); i++){
      float plength = x - beamdicision(walls.get(i).pol.ver, new PVector(x, y));
      if(plength < x && plength >= 0){
        if(length > plength)  length = plength;
        notprevent = false;
      }
    }
    
    if(notprevent)   length = x - home.border;
  }
  
  void draw(){
    fill(255, 20, 147);
    noStroke();
    rect(x-length, y-h/2, length, h);
    if(x >= home.border)  ellipse(x, y, margin*2, margin*2);
  }
  
  float beamdicision(ArrayList<PVector> pv, PVector point){
    ArrayList<float[]> number = new ArrayList<float[]>(pv.size());
    
    for(int i = 0; i < pv.size(); i++){
      float y1 = pv.get(i).y;
      float y2 = pv.get((i+1)%pv.size()).y;
      
      if(y1 < y2){
        if(y1 <= point.y && y2 >= point.y){
          float[] y = {i, y1, 0};
          number.add(y);
        }
      }else{
        if(y1 >= point.y && y2 <= point.y){
          float y[] = {i, y2, 0};
          number.add(y);
        }
      }
    }
    
    float[] max = null;
    for(int i = 0; i < number.size(); i++){
      int a = (int)number.get(i)[0];
      float x1 = pv.get(a).x;
      float x2 = pv.get((a+1)%pv.size()).x;
      if(x1 > x2)  number.get(i)[2] = x1;
      else         number.get(i)[2] = x2;
      
      if(max == null || max[2] < number.get(i)[2])  max = number.get(i);
    }
    
    if(max == null)  return 0;
    
    float x = 0;
    int a = (int)max[0];
    float ylength = abs(pv.get(a).y - pv.get((a+1) % pv.size()).y);
    float xlength = abs(pv.get(a).x - pv.get((a+1) % pv.size()).x);
    
    x = (point.y - max[1])/ylength * xlength;
    return max[2] - x;
  }
}

//************************************************************************************

class Shuriken extends Enemy{
  float r;        //当たり判定の円の直径
  float angle;    //単位は度　(0 <= angle < 360)
  int damage;
  
  boolean isReflected;
  PImage img;
  
  Shuriken(){}
  
  //x, yは中心座標
  Shuriken(float x, float y){
    initial(x, y);
  }
  
  void initial(float x, float y){
    this.x = x;
    this.y = y;
    
    Shuriken s = db.orishuriken;
    img = s.img;
    w = s.w;
    h = s.h;
    r = 54;
    damage = 20;
    hp = 1;
    
    v = new PVector(-3, 0);
    isReflected = false;
    isDie = false;
    angle = 0;
  }
  
  void update(){
    x += v.x;
    y += v.y;
    
    angle += 0.2;
    angle %= 360;
    
  }
  
  void die(){
    super.die();
    
    if((x+w/2 < 0 || x-w/2 > width || 
        y+h/2 < 0 || y-h/2 > height) || hp == 0)  isDie = true;
  }
  
  void draw(){
    pushMatrix();
    translate(x, y);
    rotate(-angle);
    image(img, -w/2, -h/2);
    popMatrix();
    
    noFill();
    stroke(255, 255, 0);
    ellipse(x, y, r, r);
  }
}

//******************************************************************************

//通常
class Standard extends Bullet{
  float theta;
  float plustheta;
  float basicy;
  
  Standard(float x, float y){
    this.x = x;
    this.basicy = y;
    v = new PVector(-db.bs/20.0*db.scwhrate, 0);
    
    initial();
    
    theta = 0;
    damage = 5;
    hp = 1;
    plustheta = PI/width*7.0*-v.x;  //黒板の1/7進むごとにPIだけ進むようにする
    
    col = new int[3];
    col[0] = 129;
    col[1] = 41;
    col[2] = 139;
  }
  
  void move(){
    x += v.x;
    theta += plustheta;
    theta %= 360;
    y = height/2.0*sin(theta) + basicy;
  }
}

//******************************************************************************

//反射弾
class Reflect extends Bullet{
  
}

//******************************************************************************

//反射可能
class Strong extends Reflect{
  
}





















