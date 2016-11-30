
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
    linitial();
  }
  
  void linitial(){
    num = 1;
    initial();
    
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
  int r;
  float length;
  Tangent owner;
  
  Beam(Enemy owner){
    this.owner = (Tangent)owner;
    binitial();
  }
  
  void binitial(){
    num = 2;
    super.initial();
    
    h = 6;
    Hcount = 0;
    damage = 5;
    margin = (int)(owner.r/2.0);
    r = 30;
    length = width;
  }
  
  void update(){
    x = owner.x-margin;
    y = owner.y;
    
    dicision();
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
    if(owner.isDie)  isDie = true;
  }
  
  void draw(){
    fill(255, 20, 147);
    noStroke();
    rect(x-length, y-h/2, length, h);
    if(x >= home.border)  ellipse(x, y, r, r);
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

class Shuriken extends Bullet{
  float r;        //当たり判定の円の直径
  float angle;    //単位は度　(0 <= angle < 360)
  
  boolean isReflected;
  
  Shuriken(){}
  
  //x, yは中心座標
  Shuriken(float x, float y){
    initial(x, y);
  }
  
  void initial(float x, float y){
    this.x = x;
    this.y = y;
    
    initial();
    
    Shuriken s = (Shuriken)db.otherobj.get(4);
    image = s.image;
    w = s.w;
    h = s.h;
    
    num = 3;
    r = 54;
    damage = 20;
    
    v = new PVector(-3, 0);
    isReflected = false;
    angle = 0;
  }
  
  void plus(){
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
    image(image, -w/2, -h/2);
    popMatrix();
    
    if(num == 3){
      fill(255, 255, 0, 100);
      ellipse(x, y, r, r);
    }
  }
}

//******************************************************************************

//通常
class Standard extends Bullet{
  
  Standard(float x, float y, float v_x){
    this.x = x;
    this.y = y;
    this.v = new PVector(v_x, 0);
    
    initial();
    
    damage = 5;
    hp = 1;
    num = 4;
    energy = 75;
    
    col[0] = 129;
    col[1] = 41;
    col[2] = 139;
  }
}

//******************************************************************************

//反射弾
class Reflect extends Shuriken{
  final int BulletAnimatePieces = 10;
  final float Rdividenum = 4.0;    //reflectの画像の大きさを何で割るか
  final float Sdividenum = 1.2;    //strongの場合
  final PVector imagexyrate = new PVector(20.5/40.0, 32/40.0);  //「画像の中心にしたい場所/全体の大きさ」を設定する
  
  AudioSample reverse;
  String reversename;
  PVector imagexy;
  int imageindex;
  int imagecount;
  
  PVector bv;
  int drawr;    //描画する半径　rは判定用半径
  
  ArrayList<PImage> imgs;
  
  Reflect(){
    imgs = new ArrayList<PImage>();
  }
  
  //x, yは中心座標
  Reflect(float x, float y, PVector v){
    this();
    
    this.x = x;
    this.y = y; 
    this.v = v;
    
    copy();
    
    num = 5;
    initial();
    r = 33;
    drawr = 15;
    maxhp = hp = 2;
    damage = 10;
    
    col[2] = 255;
  }
  
  void initial(){
    super.initial();
    angle = 90;  //画像を時計回りにどれだけ回転させるか
    imagexy = new PVector(imagexyrate.x * image.width, imagexyrate.y * image.height);
    bv = v.copy();
  }
  
  void copy(){
    Reflect ref = (Reflect)db.otherobj.get(5);
    copy(ref);
  }
  
  void copy(Reflect ref){
    reverse = db.setsound(ref.reversename);
    w = ref.w;
    h = ref.h;
    for(int i = 0; i < BulletAnimatePieces; i++)
      imgs.add(ref.imgs.get(i).copy());
      
    imageindex = 0;
    image = imgs.get(imageindex);
  }
  
  //反射できなくなるからこの処理はなし
  void outdicision(){};
  
  void update(){
    super.update();
    
    //6フレームごとに画像を差し替え
    imagecount++;
    if(imagecount >= 6){
      imageindex++;
      imageindex %= 10;
      image = imgs.get(imageindex);
      imagecount = 0;
    }
    
    if(bv.x != v.x || bv.y != v.y)  angle = atan2(v.y, v.x)/PI*180 - 90;
    
    bv = v.copy();
  }
  
  void plus(){
    
    //反射
    boolean reflect = false;
    if(y >= height-r/2){
      y = height-r/2;
      reflect = true;
    }else if(y <= r/2){
      y = r/2;
      reflect = true;
    }
    
    if(reflect){
      v.set(v.x, -v.y);
      if(reverse != null && !soundstop)  reverse.trigger();
    }
  }
  
  void draw(){
    pushMatrix();
    translate(x, y);
    rotate(angle*PI/180);
    image(image, -imagexy.x, -imagexy.y);
    popMatrix();
    fill(col[0], col[1], col[2], 120);
    ellipse(x, y, drawr, drawr);
  }
}

//******************************************************************************

//反射可能
class Strong extends Reflect{
  Strong(){}
  
  //x, yは中心座標
  Strong(float x, float y){
    this.x = x;
    this.y = y;
    v = new PVector(-6*db.scwhrate, 0);
    
    num = 6;
    initial();
    
    maxhp = hp = 7;
    damage = 15;
    r = drawr = 100;
    isReflected = false;
    angle = 90;
    
    col[0] = col[1] = 255;
  }
  
  void copy(){
    Strong st = (Strong)db.otherobj.get(6);
    copy(st);
  }
  
  void plus(){}
}

class Particle extends MyObj{
  
  Particle(float x, float y, PVector v){
    this.x = x;
    this.y = y;
    this.v = v.copy();
    initial();
  }
  
  void initial(){
    
  }
  
  
  void move(){
    x += v.x;
    y += v.y;
  }
}