
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
  
  Enemy owner;                //パーティクル発生元の敵
  
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
    
    loadPixels();
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
    
    updatePixels();
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

class Particle{
  final float Friction = 0.95;    //摩擦
  final float EPS = 0.0005;       //計算誤差
  
  int x, y;          //中心座標
  float slowLevel;   //中心に近づくときの遅延のレベル
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
    slowLevel = 500;
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