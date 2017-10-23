
color[][] bossBulletPixels;

//管理用クラス
class ParticleManager{
  final int ParticleSize = 30;   //生み出す（最大の）パーティクルの量
  final float DecayRate = 4;      //光の減衰率
  final float Size = 1;           //大きさ
  final boolean Group   = false;  //固まって渦巻くならtrue
  final boolean Infinity = false;  //無限に吸い込み続けるならtrue
  final float ElimDist = 1;       //無限に吸い込み続ける場合、何ピクセル離れているときにパーティクルを消去するか
  
  boolean reverse = true;  //反時計回りならtrue
  
  int targetx, targety;      //近づく座標
  int r;          //パーティクルが生み出される範囲を円で表したときの半径
  ArrayList<Particle> ps;  //パーティクルを格納
  
  float baseR, baseG, baseB;  //ベースとなるrgb
  int border;                 //一つのパーティクルが描画する範囲
  float lightdistance;        //描画する最大の距離の二乗
  
  boolean isChargeManager;
  
  Enemy owner;                //パーティクル発生元の敵
  
  ParticleManager(){}
  
  //owner, ターゲットの座標、パーティクルが生み出される範囲の直径
  ParticleManager(Enemy e, int x, int y, int r){
    this.r = r;
    this.targetx = x;
    this.targety = y;
    this.owner = e;
    
    border = (int)(Size * width/100.0);
    lightdistance = border*border;
    
    baseR = 255;
    baseG = 134;
    baseB = 50;
    
    initial();
  }
  
  ParticleManager(Enemy e, int x, int y, int r, color c){
    this(e, x, y, r);
    baseR = c >> 16 & 0xFF;
    baseG = c >> 8 & 0xFF;
    baseB = c & 0xFF;
  }
  
  void initial(){
    ps = new ArrayList<Particle>(ParticleSize);
    
    for(int i = 0; i < ParticleSize; i++){
      ps.add(new Particle(this, r));
    }
    
    isChargeManager = true;
  }
  
  //毎フレーム呼ばれる
  void update(){
    
    //無限に吸い込むなら上限まで増やし続ける
    if(Infinity)
      if(ps.size() < ParticleSize)
        for(int i = 0; i < 2; i++)
          ps.add(new Particle(this, r));
    
    //パーティクルの移動
    for(int i = 0; i < ps.size(); i++)  ps.get(i).move();
    
    //中心から一定距離にあればパーティクルを消す
    if(!Infinity)  checkDif();
    
    //loadPixels();
    for(int i = 0; i < ps.size(); i++){
      Particle p = ps.get(i);
      
      int left = max(0, p.x - border);
      int right = min(width, p.x + border);
      int top = max(0, p.y - border);
      int bottom = min(height, p.y + border);
      
      for(int y = top; y < bottom; y++){
        for(int x = left; x < right; x++){
          int index = x + y*width;
          
          int r = pixels[index] >> 16 & 0xFF;
          int g = pixels[index] >> 8 & 0xFF;
          int b = pixels[index] & 0xFF;
          
          //高速化のためと、divideを距離の二乗に比例させるために、
          //distanceは距離の二乗としておく
          int dx = x - p.x;
          int dy = y - p.y;
          int distance = (dx*dx) + (dy*dy);
          
          //現在調べているピクセルと、パーティクルとの距離が一定以内であれば、
          if(distance < lightdistance){
            float divide = distance * DecayRate;
            //0除算の回避（px == x && py == yの場合のみここを通る）
            if(divide == 0){
              divide = 0.1 * DecayRate;
            }
            
            r += baseR*baseR / divide;
            g += baseG*baseG / divide;
            b += baseB*baseB / divide;
          }
          
          pixels[index] = color(r, g, b);
        }
      }
    }
    
    //updatePixels();
  }
  
  //パーティクルとターゲットとの距離が一定距離以内であれば、パーティクルを消す
  void checkDif(){
    for(int i = 0; i < ps.size(); i++){
      if(ps.get(i).dif.mag() < ElimDist){
        ps.remove(i);
        i--;
      }
    }
  }
  
  void reverse(){
    reverse = !reverse;
    for(int i = 0; i < ps.size(); i++)  ps.get(i).setVA();
  }
  
  void explode(){
    for(int i = 0; i < ps.size(); i++)  ps.get(i).explode();
  }
}

//****************************************************************************************

//円のパーティクル
class Particle{
  final float Friction = 0.95;    //摩擦
  final float EPS = 0.0005;       //計算誤差
  
  int x, y;          //中心座標
  float force;       //向心力
  float m;           //質量
  PVector v;         //速度
  PVector a;         //向心加速度
  PVector dif;       //中心との差
  
  ParticleManager pm;  //オーナー
  
  //x, y:近づく対象の座標   r:パーティクルが生み出される範囲を円で表したときの直径
  Particle(ParticleManager pm, int r){
    this.pm = pm;
    
    //パーティクルの位置をランダムに指定
    if(pm.Group){
      this.x = (int)random(width/4)+width/4*3;
      this.y = (int)random(height/4*3);
    }else{
      this.x = (int)(random(r) - r/2.0 + pm.targetx);
      this.y = (int)(random(r) - r/2.0 + pm.targety);
    }
    
    initial();
  }
  
  //初期設定
  void initial(){
    m = 1;
    force = 3;
    
    setVA();
  }
  
  void setVA(){
    setA();
    dif = new PVector(pm.targetx - x, pm.targety - y);
    
    if(dif.y != 0)
      v = new PVector(1, -dif.x/dif.y).normalize();
    else
      v = new PVector(0, 1);
    
    if(pm.reverse){
      if(v.cross(a).z > EPS) v.mult(-1);
    }else{
      if(v.cross(a).z < -EPS) v.mult(-1);
    }
    
    v.mult(sqrt(a.mag()*dif.mag()));
  }
  
  void setA(){
    a = new PVector(pm.targetx - x, pm.targety - y);
    a.normalize().mult((float)force/m);
  }
  
  //移動
  void move(){
    setA();
    
    v.add(a);
    v.mult(Friction);
    
    x += v.x;
    y += v.y;
    
    dif.set(pm.targetx - x, pm.targety - y);
  }
  
  void explode(){
    v.x = random(100) - 50;
    v.y = random(100) - 50;
  }
}

//***********************************************************************************************

class EllipseManager extends ParticleManager{
  final int DecayRate = 3;    //光の減衰率
  final int EllipseSize = 3;
  
  Ellipse[] es;
  
  int[] col;  //ベースの色
  
  EllipseManager(Enemy owner, int x, int y, int size){
    this.owner = owner;
    
    int margin = size*4;
    es = new Ellipse[EllipseSize];
    for(int i = 0; i < es.length; i++)
      es[i] = new Ellipse(x-i*margin, y, size, (int)(size*8*(0.7+0.6*i)));
    
    Cannon c = (Cannon)owner;
    c.laserX = es[EllipseSize-1].x-margin/2;
    
    col = new int[3];
    col[0] = 255;
    col[1] = 134;
    col[2] = 50;
    
    isChargeManager = false;
  }
  
  EllipseManager(Enemy owner, int x, int y, int size, color _col){
    this(owner, x, y, size);
    
    col = colToArray(_col);
  }
  
  void update(){
    
    int[] basePowered = new int[3];  //ベースrgbの二乗
    for(int i = 0; i < basePowered.length; i++)
      basePowered[i] = col[i]*col[i];
    
    for(int i = 0; i < es.length; i++){
      Ellipse e = es[i];
      
      int left = max(0, e.x-e.borderw);
      int right = min(width, e.x+e.borderw);
      int top = max(0, e.y-e.borderh);
      int bottom = min(height, e.y+e.borderh);
      
      for(int y = top; y < bottom; y++){
        for(int x = left; x < right; x++){
          int index = x + y*width;
          
          int r = pixels[index] >> 16 & 0xFF;
          int g = pixels[index] >> 8 & 0xFF;
          int b = pixels[index] & 0xFF;
          
          //楕円の方程式より、x^2/a^2 + y^2/b^2 < 1　なら、x, yは楕円の内側の座標
          int dx = e.x - x;
          int dy = e.y - y;
          float leftside = (float)dx*dx/(e.borderw*e.borderw)
                          +(float)dy*dy/(e.borderh*e.borderh);  //楕円の方程式の左辺
          
          //楕円の内側にあれば
          if(leftside <= 1){
            float divide = leftside * DecayRate*300;
            //0除算の回避（e.x == x && e.y == yの場合のみここを通る）
            if(divide == 0){
              divide = 1;
            }
            
            r += basePowered[0] / divide;
            g += basePowered[1] / divide;
            b += basePowered[2] / divide;
          }
          
          pixels[index] = color(r, g, b);
        }
      }
    }
  }
}

//***********************************************************************************************

//楕円
class Ellipse{
  final int DecayRate = 3;    //光の減衰率
  
  int x, y;    //中心座標
  int w, h;
  
  int borderw, borderh;  //描画範囲(半径)
  
  Ellipse(int x, int y, int w, int h){
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    borderw = w;
    borderh = h;
  }
}


//線（Bulletに使われる）
class BulletEffect{
  
  float DecayRate;
  int drawRange;
  PVector dirmag;          //dirmag, rangeY, rangeXは、傾き、長さが変わらない弾の場合のみ変数として保持する
  int rangeY, rangeX;
  boolean isBossBullet;    //ボスの通常弾はどれも傾き、色などが同じで、流用できるため、判別できるようにしておく
  
  //傾きか長さが変わる弾はこっち（ビーム、レーザーなど）
  BulletEffect(float decayRate){
    this(decayRate, null, false);
  }
  
  //傾きも長さも変わらない弾はこっち（ボスの通常弾など）
  BulletEffect(float decayRate, PVector _dirmag, boolean _isBossBullet){
    DecayRate = decayRate;
    drawRange = (int)(0.25 / DecayRate);
    dirmag = _dirmag;
    
    if(_dirmag != null){
      rangeY = (int)abs(_dirmag.y) + drawRange;
      rangeX = (int)abs(_dirmag.x) + drawRange;
    }
    
    isBossBullet = _isBossBullet;
  }
  
  //そうでない弾はこっち
  void draw(PVector center, int[] col){
    if(isBossBullet && bossBulletPixels != null)  copyBossBulletPixels(center);
    else                                          setPixels(center, dirmag, col, rangeY, rangeX);
  }
  
  //傾き、長さが変わる弾はこっち
  void draw(PVector center, PVector _dirmag, int[] col){
    int _rangeY = (int)abs(_dirmag.y) + drawRange;
    int _rangeX = (int)abs(_dirmag.x) + drawRange;
    setPixels(center, _dirmag, col, _rangeY, _rangeX);
  }
  
  //ボスの通常弾の場合、プログラムを開始してから一回しか呼ばれない
  private void setPixels(PVector center, PVector _dirmag, int[] col, int _rangeY, int _rangeX){
    
    boolean isSettingBossBullet = false;
    if(isBossBullet){
      isSettingBossBullet = true;
      bossBulletPixels = new color[_rangeX*2][_rangeY*2];
    }
    
    PVector start  = PVector.sub(center, _dirmag);
    PVector end    = PVector.add(center, _dirmag);
    
    int top     = max((int)(center.y - _rangeY), 0);
    int bottom  = min((int)(center.y + _rangeY), height);
    int left    = max((int)(center.x - _rangeX), 0);
    int right   = min((int)(center.x + _rangeX), width);
    
    for(int y = top; y < bottom; y++){
      for(int x = left; x < right; x++){
        
        PVector point = new PVector(x, y);
        
        //距離の算出（点が線の側面にあると仮定する）  ←そうでなければ、あとで変更する
        float dist;
        PVector vecB = PVector.sub(point, center); //中心と点を結ぶベクトルを算出
        float area = vecB.cross(_dirmag).mag();     //方向ベクトルとそれが作る面積を算出
        dist = area / _dirmag.mag();                //面積÷底辺（高さを算出）
        
        int indexX = x - int(center.x - rangeX);
        int indexY = y - int(center.y - rangeY);
        
        //ピクセルを黒で初期化
        if(isSettingBossBullet)
          bossBulletPixels[indexX][indexY] = color(0, 0, 0);
        
        //距離が描画範囲以上なら描画しない
        if(dist > drawRange)  continue;
        
        int index = y*width + x;
        
        //今の点が線分の側面に位置するかどうか
        if(!isSideforLine(start, end, point)){
          dist = min(PVector.sub(end, point).mag(), PVector.sub(start, point).mag());  //近い方の端点
        }
        
        //距離が0の場合（点が線上にある場合）は、距離を正の小数にする
        if(dist <= 0)  dist = 0.1;
        
        float div = DecayRate * dist * dist;
        int red    = (int)(col[0] / div);
        int green  = (int)(col[1] / div);
        int blue   = (int)(col[2] / div);
        
        pixels[index] = addColor(pixels[index], new int[]{red, green, blue});
        
        //ボスの一発目の通常弾の場合のみ、そのピクセル情報をコピー
        if(isSettingBossBullet){
          bossBulletPixels[indexX][indexY] = color(red, green, blue);
        }
      }
    }
  }
  
  private void copyBossBulletPixels(PVector center){
    
    int minY = (int)(center.y - rangeY);
    int maxY = (int)(center.y + rangeY);
    int minX = (int)(center.x - rangeX);
    int maxX = (int)(center.x + rangeX);
    
    int top     = max(minY, 0);
    int bottom  = min(maxY, height);
    int left    = max(minX, 0);
    int right   = min(maxX, width);
    
    for(int y = top; y < bottom; y++){
      for(int x = left; x < right; x++){
        
        int oriX = x - minX;
        int oriY = y - minY;
        int pixelIndex = y*width + x;
        
        pixels[pixelIndex] = addColor(pixels[pixelIndex], bossBulletPixels[oriX][oriY]);
      }
    }
  }
}

boolean isSideforLine(PVector start, PVector end, PVector point){
  PVector sub1 = PVector.sub(point, start);
  PVector sub2 = PVector.sub(point, end);
  float angle = PVector.angleBetween(sub1, sub2);
  
  return (angle > PI/2);
}


//color系便利関数群

int[] colToArray(color col){
  
  int red   = (col >> 16) & 0xFF;
  int green = (col >> 8) & 0xFF;
  int blue  = col & 0xFF;
  
  return new int[]{red, green, blue};
}

color addColor(int[] col1, int[] col2){
  return color(col1[0] + col2[0],   col1[1] + col2[1],   col1[2] + col2[2]);
}

color addColor(color col1, color col2){
  return addColor(colToArray(col1), colToArray(col2));
}

color addColor(color col1, int[] col2){
  return addColor(colToArray(col1), col2);
}