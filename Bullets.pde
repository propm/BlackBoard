
//敵の弾丸
class Bullet extends Enemy{
  float radian;    //横一直線を0としたときの角度　正方向は時計回り(-π < radian <= π)
  int   damage;    //与えるダメージ
  int num;         //bulletなら0、laserなら1、beamなら2
  
  PVector length;       //弾の長さ
  
  Bullet(){}
  
  Bullet(float x, float y){
    this.x = x;
    this.y = y;
    v = new PVector(-1, 0);
    
    initial();
  }
  
  Bullet(float x, float y, PVector v){
    this.x = x;
    this.y = y;
    this.v = v;
    
    initial();
  }
  
  void initial(){
    num = 0;
    
    length = v.get();
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
  
  void update(){
    x += v.x;
    y += v.y;
    
    if((v.x <= 0 && x+abs(length.x) < 0) ||
        (v.x > 0 && x-abs(length.x) > width))  isDie = true;
        
    if(num == 0)  setPolygonAngle();
    
  }
  
  void die(){
    if(hp <= 0)  isDie = true;
  }
  
  void draw(){
    
    if(num == 0)      fill(255, 134, 0);
    else if(num == 1) fill(255, 20, 147);
    pushMatrix();
    translate(x, y);
    rotate(radian);
    noStroke();
    rect(-length.mag(), -h/2, length.mag(), h);
    popMatrix();
    
    pol.Draw();
  }
}

//*************************************************************************************

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
    
    num = 1;
    h = (int)(8*db.scwhrate);
    count = Hcount = 0;
    maxcount = 60 * 1;
    damage = 4;
  }
  
  void update(){
    super.update();
    
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
  
  Beam(Enemy owner){
    this.owner = owner;
    initial();
  }
  
  void initial(){
    num = 2;
    
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
    ellipse(x, y, margin*2, margin*2);
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
  
  Standard(float x, float y){
    this.x = x;
    this.y = y;
    v = new PVector(-db.bs/10.0, 0);
    
  }
  
  void update(){
    
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





















