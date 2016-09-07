class Polygon {
  ArrayList<PVector> ver; //時計回りに定義
  boolean isConvex; //凸多角形であるか
  PVector center; // 中心点
  float square; // 面積
  
  Polygon() {
    ver = new ArrayList<PVector>();
    isConvex = true;
  }
  
  Polygon(ArrayList<PVector> po) {
    ver = new ArrayList<PVector>(po);
    isConvex = CheckConvex();
  }
  
  void Add(PVector point) {
    ver.add(new PVector(point.x, point.y, point.z));
  }
  
  void Add(float x, float y, float z) {
    ver.add(new PVector(x, y, z));
  }
  
  void Init() {
    isConvex = CheckConvex();
    this.center = Center();
    this.square = Square();
  }
  
  void Reverse(int w){
    for(int i = 0; i < ver.size(); i++){
      ver.set(i, new PVector(w - ver.get(i).x, ver.get(i).y));
    }
  }
  
  // 凸多角形かどうか調べる
  boolean CheckConvex() {
    if (ver.size() <= 2) return false;
    
    PVector v1 = sub(ver.get(1), ver.get(0));
    PVector v2;
    for (int i = 1; i < ver.size(); i++) {
      v2 = sub(ver.get((i + 1) % ver.size()), ver.get(i));
      if (v1.dot(v2) < -EPS) return false;
      v1 = v2;
    }
    return true;
  }
  
  // 中心点を求める
  PVector Center() {
    float x = 0.0, y = 0.0;
    for (int i = 0; i < ver.size(); i++) {
      x += ver.get(i).x;
      y += ver.get(i).y;
    }
    
    return new PVector(x / ver.size(), y / ver.size(), 0.0);
  }
  
  // 面積を求める(先にcenterを設定しなければならない)
  float Square() {
    float res = 0.0;
    for (int i = 0; i < ver.size(); i++) {
      res += square(ver.get(i), ver.get((i + 1) % ver.size()), center);
    }
    return res;
  }
  
  void Draw() {
    for (int i = 0; i < ver.size(); i++) {
      PVector p1 = ver.get(i);
      PVector p2 = ver.get((i + 1) % ver.size());
      
      stroke(255, 255, 0);
      line(p1.x, p1.y, p2.x, p2.y);
    }
  }
}

/////////

final float EPS = 0.04;

// p1 + p2
PVector add(PVector p1, PVector p2) {
  return new PVector(p1.x + p2.x, p1.y + p2.y, p1.z + p2.z);
}

// p1 - p2
PVector sub(PVector p1, PVector p2) {
  return new PVector(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);
}

// p1 cross p2
float cross(PVector p1, PVector p2) {
  return p1.x * p2.y - p1.y * p2.x;
}

float length(PVector v) {
  return sqrt(v.x*v.x + v.y*v.y);
}

// p1, p2, p3で構成された三角形の面積を求める
float square(PVector p1, PVector p2, PVector p3) {
  float a = length(sub(p2, p1));
  float b = length(sub(p3, p2));
  float c = length(sub(p1, p3));
  
  float s = (a + b + c) / 2.0;
  return sqrt(s * (s - a) * (s - b) * (s - c));
}

// 二つの線分が交差しているか(境界含まない)
boolean isIntersectSS(PVector a1, PVector a2, PVector b1, PVector b2) {
  return  cross(sub(a2, a1), sub(b1, a1)) * cross(sub(a2, a1), sub(b2, a1)) <= EPS &&
          cross(sub(b2, b1), sub(a1, b1)) * cross(sub(b2, b1), sub(a2, b1)) <= EPS;
}

// 凸多角形同士の判定 境界は含まない(辺が交差したときのみ判定あり)
// polygon2内にpolygon1が完全に含まれている場合は判定あり(polygon1 = 自機 polygon2 = 敵)
boolean judge(Polygon polygon1, Polygon polygon2) {
    ArrayList<PVector> p1 = polygon1.ver;
    ArrayList<PVector> p2 = polygon2.ver;
    
    // 片方または両方が凸多角形ではない場合
    if (!polygon1.isConvex || !polygon2.isConvex) {
      for (int i = 0; i < p1.size(); i++) {
        for (int j = 0; j < p2.size(); j++) {
          if (isIntersectSS(p1.get(i), p1.get((i + 1) % p1.size()), p2.get(j), p2.get((j + 1) % p2.size())))
            return true;
        }
      }
      
      //polygon1 の中心点とpolygon2の各点で計算した面積？
      float s = 0.0;

      for (int i = 0; i < p2.size(); i++)
        s += square(p2.get(i), p2.get((i + 1) % p2.size()), polygon1.center);
      
      if (abs(polygon2.square - s) < EPS) return true;
      
      return false;
    }
    else { // 凸多角形同士の判定
      // なんかこれでいけた（ちょいはやめ？）「理解不能」
      for (int i = 0; i < p1.size(); i++) {
        PVector[] vec = new PVector[2];
        boolean flag = true;
        
        vec[0] = sub(p1.get((i + 1) % p1.size()), p1.get(i));
        
        for (int j = 0; j < p2.size(); j++) {
          vec[1] = sub(p2.get(j), p1.get(i));
          PVector tmp = vec[0].cross(vec[1]);
          if (tmp.z > EPS) { flag = false; break; }
        }
        if (flag) return false;
        
      }
      return true;
    }
}
