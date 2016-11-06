class Polygon {
  ArrayList<PVector> ver; //時計回りに定義
  boolean isConvex; //凸多角形であるか
  PVector center; // 中心点
  float square; // 面積
  boolean isCollide;  //前フレームに衝突したかどうか

  PVector v;       // 方向ベクトル(衝突しても変化しない）
  int wallside;    //壁のどの辺に衝突しているか  右の辺なら1    範囲：1～4
  int collidenum;  //衝突した多角形の辺の番号
  PVector wallxy;  //衝突した壁の座標
  PVector bv;      //1フレーム前の方向ベクトル
  Polygon convex;  //凸包保存
  
  MyObj owner;     //当たり判定の持ち主

  Polygon() {
    ver = new ArrayList<PVector>();
    isConvex = true;
  }

  Polygon(ArrayList<PVector> po) {
    ver = new ArrayList<PVector>(po.size());
    
    for(int i = 0; i < po.size(); i++){
      ver.add(po.get(i).copy());
    }
    
    isConvex = CheckConvex();
    Init();
  }

  Polygon clone() {
    Polygon pol = new Polygon();

    try {
      pol.ver = new ArrayList<PVector>(ver);
      pol.center = center.copy();
    }
    catch(Exception e) {
      e.printStackTrace();
    }

    return pol;
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
    this.v = new PVector(0, 0, 0);
    this.isCollide = false;
    this.wallside = 0;
    bv = new PVector(-1, -1, -1);    //v以外ならなんでもいい
  }

  void Reverse(int w) {
    for (int i = 0; i < ver.size(); i++) {
      ver.set(i, new PVector(w - ver.get(i).x, ver.get(i).y));
    }
  }

  //判定用のx, y座標とw,hを取得
  float[] getWH() {

    float xmin, xmax, ymin, ymax;
    xmin = xmax = ver.get(0).x;
    ymin = ymax = ver.get(0).y;
    for (int i = 1; i < ver.size(); i++) {
      float x = ver.get(i).x;
      float y = ver.get(i).y;
      if (xmin > x)  xmin = x;
      if (xmax < x)  xmax = x;
      if (ymin > y)  ymin = y;
      if (ymax < y)  ymax = y;
    }

    float[] a = {xmax - xmin, ymax - ymin, xmin, ymin};

    return a;
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
    if(isDebag){
      strokeWeight(1);
      stroke(255, 255, 0);
      for (int i = 0; i < ver.size(); i++) {
        PVector p1 = ver.get(i);
        PVector p2 = ver.get((i + 1) % ver.size());

        line(p1.x, p1.y, p2.x, p2.y);
      }
    }
  }

  void Draw(PVector center, float r) {
    if(isDebag){
      strokeWeight(1);
      stroke(255, 255, 0);
      noFill();
      ellipse(center.x, center.y, r, r);
    }
  }
  
  void Update() {
    
    //ぶつかる可能性がある辺を取得
    int a = 0, b = 0;
    if(v.x > 0)  a = 3;
    if(v.x < 0)  a = 1;
    if(v.y > 0)  b = 4;
    if(v.y < 0)  b = 2;
    
    // 移動先の状態
    ArrayList<PVector> next = new ArrayList<PVector>(ver.size());
    
    for (int j = 0; j < ver.size(); j++)
      next.add(add(ver.get(j), v));

    // 判定用　移動前と移動後の凸包
    // 方向ベクトルが変わってないなら形は変化しない(衝突していなければその形のまま移動する)
    if(bv.x != v.x || bv.y != v.y){
      convex = createConvex(ver, next);
    }else if(!isCollide){
      for(int i = 0; i < convex.ver.size(); i++)
        convex.ver.get(i).add(v);
    }
    convex.Draw();

    float mint = 1000;
    
    //すべての壁について調べる
    for (int i = 0; i < walls.size(); i++) {
      Polygon polygon1 = walls.get(i).pol;

      // ここで衝突する壁があれば調べる
      if (judge(convex, polygon1)) {
        if(isCollide)  break;    //前フレームで衝突していたならこのあとの処理はなし

        for (int j = 0; j < ver.size(); j++) {
          // 移動前の辺と移動後の辺でできる多角形
          ArrayList<PVector> spol = new ArrayList<PVector>();

          //移動前の辺
          PVector as = ver.get(j);
          PVector ae = ver.get((j + 1) % ver.size());

          spol.add(as);
          spol.add(ae);
          spol.add(next.get(j));
          spol.add(next.get((j + 1) % next.size()));
          spol = createConvex(spol).ver;

          //壁の各辺について調べる
          for (int k = 0; k < polygon1.ver.size(); k++) {
            int sidenum = (k+1)%4+1;
            if(sidenum != a && sidenum != b)  continue;    //ぶつかる可能性がない辺ならとばす
            
            PVector bs = polygon1.ver.get(k);
            PVector be = polygon1.ver.get((k + 1) % polygon1.ver.size());
            boolean isCross = false;

            for (int l = 0; l < spol.size(); l++) {
              if (isIntersectSS(spol.get(l), spol.get((l + 1) % spol.size()), bs, be)) {
                isCross = true;
                break;
              }
            }

            if (isCross) {
              float bmint = mint;
              mint = min(mint, culct(as, ae, v, bs, be));
              
              if(mint != bmint){
                wallside = sidenum;
                wallxy = new PVector(walls.get(i).x, walls.get(i).y);
              }
            }
          }
        }
      }
      
      if(i == walls.size()-1)  isCollide = false;
    }
    if(walls.size() == 0)  isCollide = false;

    if(wallside == 1 || wallside == 3)      owner.v.set(0, v.y, 0);
    else if(wallside == 2 || wallside == 4) owner.v.set(v.x, 0, 0);

    // もし衝突する壁があったら
    if (abs(mint - 1000) >= EPS && !isCollide) {
      for (int i = 0; i < ver.size(); i++) {
        PVector nv = ver.get(i);
        nv.x += v.x * mint;
        nv.y += v.y * mint;
      }
      
      owner.v.set(v.x*mint, v.y*mint);
      isCollide = true;
    } else {
      
      //このフレームでどの辺も衝突してないなら
      if(!isCollide){
        owner.v = v.copy();
        wallxy = new PVector(-1, -1);
      }
      
      //多角形の移動
      for (int i = 0; i < ver.size(); i++) {
        ver.get(i).add(owner.v);
      }
    }
    
    bv = v.copy();
  }
}

/////////

final float EPS = 0.05;

// p1 + p2
PVector add(PVector p1, PVector p2) {
  return new PVector(p1.x + p2.x, p1.y + p2.y, p1.z + p2.z);
}

// p1 - p2
PVector sub(PVector p1, PVector p2) {
  return new PVector(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);
}

// p1 dot p2
float dot(PVector p1, PVector p2) {
  return p1.x * p2.x + p1.y * p2.y + p1.z * p2.z;
}

// p1 cross p2
float cross(PVector p1, PVector p2) {
  return p1.x * p2.y - p1.y * p2.x;
}

// 大きさを求める
float length(PVector v) {
  return sqrt(dot(v, v));
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
  return  cross(sub(a2, a1), sub(b1, a1)) * cross(sub(a2, a1), sub(b2, a1)) < -EPS &&
    cross(sub(b2, b1), sub(a1, b1)) * cross(sub(b2, b1), sub(a2, b1)) < -EPS;
}

//2つのベクトルの外積のz座標の正負を調べる（正なら1、負なら0、２つのベクトルが平行なら0）
int directionCross(PVector a, PVector b) {
  float direction = a.cross(b).z;
  if (direction > EPS)  return 1;
  else if (direction < -EPS)  return -1;
  else  return 0;
}

//三角形に点が含まれるかどうか調べる(線上も含まれる)  v1, v2, v3は三角形の頂点の座標
boolean isinTriangle(PVector v1, PVector v2, PVector v3, PVector point) {
  PVector[] vertex = {v1, v2, v3};
  float[] z = new float[3];
  for (int i = 0; i < 3; i++) {
    PVector vertextopoint = sub(point, vertex[i]);
    PVector side          = sub(vertex[(i+1)%vertex.length], vertex[i]);
    z[i] = directionCross(side, vertextopoint);
  }
  boolean result = ((z[0] >= 0 && z[1] >= 0 && z[2] >= 0) || (z[0] <= 0 && z[1] <= 0 && z[2] <= 0));
  return result;
}

//線分と点との距離を求める
float distanceSP(PVector st, PVector ed, PVector p) {
  PVector a = sub(p, st), b = sub(p, ed);
  PVector c = sub(ed, st);

  if (dot(c, a) < -EPS) return length(a);
  if (dot(c, a) > dot(c, c) + EPS) return length(b);
  return abs(cross(c, a)) / length(c);                //平行四辺形の面積/底辺
}

// 円と多角形（接している場合は判定なし） rは半径
boolean judge(PVector center, float r, Polygon polygon) {
  ArrayList<PVector> p = polygon.ver;

  //デバッグ用
  if (p.size() < 3) {
    println("多角形じゃない！！");
    println("circle x polygon");
    return false;
  }
  ////////////

  float s = 0.0; // 円の中心点とpolygonの各点で計算した面積

  for (int i = 0; i < p.size(); i++)
    s += square(p.get(i), p.get((i + 1) % p.size()), center);
  if (abs(polygon.square - s) < EPS) return true;

  for (int i = 0; i < p.size(); i++) {
    if (distanceSP(p.get(i), p.get((i + 1) % p.size()), center) < r - EPS)
      return true;
  }

  return false;
}

// 凸多角形同士の判定 境界は含まない(辺が交差したときのみ判定あり)
// polygon2内にpolygon1が完全に含まれている場合は判定あり(polygon1 = 自機 polygon2 = 敵)
boolean judge(Polygon polygon1, Polygon polygon2) {
  ArrayList<PVector> p1 = polygon1.ver;
  ArrayList<PVector> p2 = polygon2.ver;

  //デバッグ用
  if (p1.size() < 3 || p2.size() < 3) {
    //println("多角形じゃない！！");
    if (p1.size() < 3) println("polygon1");
    //if (p2.size() < 3) println("polygon2");
    return false;
  }
  ////////////

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
  } else { // 凸多角形同士の判定
    // なんかこれでいけた（ちょいはやめ？）「理解不能」
    for (int i = 0; i < p1.size(); i++) {
      PVector[] vec = new PVector[2];
      boolean flag = true;

      vec[0] = sub(p1.get((i + 1) % p1.size()), p1.get(i));

      for (int j = 0; j < p2.size(); j++) {
        vec[1] = sub(p2.get(j), p1.get(i));
        PVector tmp = vec[0].cross(vec[1]);
        if (tmp.z > EPS) { 
          flag = false; 
          break;
        }
      }
      if (flag) return false;
    }
    return true;
  }
}


// 線分aを方向ベクトルvの方向に移動し線分bに衝突するようなvの比率を求める(前提条件:tは1以下)
float culct(PVector as, PVector ae, PVector v, PVector bs, PVector be) {

  boolean isChange = false; // 線分a からみた 線分b の方向を調べるようにする(デフォルト：線分bからみた線分aの方向)
  boolean isRight; // 線分bからみた線分aが右にあるか(isChangeがtrueのときは線分a,bが逆)

  int d1 = directionCross(sub(be, bs), sub(as, bs));
  int d2 = directionCross(sub(be, bs), sub(ae, bs));

  // ここにひっかかるのは別の辺で必ずtが計算されるので処理しない
  if (d1 == 0 && d2 == 0) return 1000;

  if (d1 != 0 && d2 != 0 && d1 == d2) {
    isRight = (d1 == 1);
  } else {
    isChange = true;
    d1 = directionCross(sub(ae, as), sub(bs, as));
    d2 = directionCross(sub(ae, as), sub(be, as));


    if (d1 == 0) d1 = d2;
    //if (d2 == 0) d2 = d1;

    isRight = (d1 == 1);
  }

  float l = 0.0, r = 1.0;
  for (int i = 0; i < 15; i++) {
    float m = (l + r) / 2.0;
    boolean isrdc; // 範囲を狭める向き(true: lを更新 false: rを更新)
    PVector ns = new PVector(as.x + v.x * m, as.y + v.y * m, 0.0);
    PVector ne = new PVector(ae.x + v.x * m, ae.y + v.y * m, 0.0);

    PVector temp;
    if (isChange) {
      temp = ns;
      ns = bs;
      bs = temp;

      temp = ne;
      ne = be;
      be = temp;
    }

    d1 = directionCross(sub(be, bs), sub(ns, bs));
    d2 = directionCross(sub(be, bs), sub(ne, bs));

    if (d1 != 0 && d2 != 0 && d1 != d2) {
      isrdc = false;
    } else {
      if (d1 == 0) d1 = d2;
      isrdc = (d1 == 1) == isRight;
    }

    if (isrdc) l = m;
    else r = m;

    if (isChange) {
      temp = ns;
      ns = bs;
      bs = temp;

      temp = ne;
      ne = be;
      be = temp;
    }
  }

  return (l + r) / 2.0;
}

// 移動前の点と移動後の点の集合から凸包を求める
Polygon createConvex(ArrayList<PVector> pol1, ArrayList<PVector> pol2) {
  ArrayList<PVector> pSet = new ArrayList<PVector>(pol1.size() + pol2.size());
  for (int i = 0; i < pol1.size(); i++) pSet.add(pol1.get(i));
  for (int i = 0; i < pol2.size(); i++) pSet.add(pol2.get(i));
  return createConvex(pSet);
}
Polygon createConvex(ArrayList<PVector> pol) {
  ArrayList<PVector> pSet = new ArrayList<PVector>(pol);


  if (pSet.size() > 3) {

    ArrayList<Boolean> isInclude = new ArrayList<Boolean>(pSet.size());
    for (int i = 0; i < pSet.size(); i++)
      isInclude.add(false);

    //総当りで三角形に含まれる点を探す
    for (int i = 0; i < pSet.size(); i++) {
      if (isInclude.get(i))  continue;
      for (int j = i+1; j < pSet.size(); j++) {
        if (isInclude.get(j))  continue;
        for (int k = j+1; k < pSet.size(); k++) {
          if (isInclude.get(k))  continue;
          for (int l = 0; l < pSet.size(); l++) {
            if (l == i || l == j || l == k)  continue;
            if (isInclude.get(l))            continue;
            PVector point = pSet.get(l);

            //三角形に含まれているか判定し、結果を保存
            isInclude.set(l, isinTriangle(pSet.get(i), pSet.get(j), pSet.get(k), point));
          }
        }
      }
    }

    //三角形に含まれていた点を排除
    for (int i = 0; i < pSet.size(); i++) {
      if (isInclude.get(i)) {
        pSet.remove(i);
        isInclude.remove(i);
        i--;
      }
    }

    //残った点を時計回りに並べる  z座標は画面の奥側が正
    ArrayList<float[]> radians = new ArrayList<float[]>(pSet.size() - 1);

    // 凸多角形の中の点
    PVector include = new PVector(0.0, 0.0, 0.0);
    for (int i = 0; i < pSet.size(); i++)
      include.add(pSet.get(i));
    include.x /= pSet.size();
    include.y /= pSet.size();

    PVector first = sub(pSet.get(0), include);

    for (int i = 1; i < pSet.size(); i++) {
      PVector now = sub(pSet.get(i), include);

      float radian = PVector.angleBetween(first, now);
      if (directionCross(first, now) == -1)
        radian = 2*PI - radian;

      float[] a = new float[2];
      a[0] = radian;
      a[1] = i;
      radians.add(a);
    }

    //時計回りにソート
    Collections.sort(radians, new collisionCompa());

    //凸包
    Polygon convex = new Polygon();

    convex.Add(pSet.get(0));
    //時計回りに点を入れていく
    for (int i = 0; i < radians.size(); i++) {
      convex.Add(pSet.get((int)radians.get(i)[1]));
    }
    convex.Init();
    return convex;
  } else {
    println("点が2つ以下です");
    return null;
  }
}

class collisionCompa implements Comparator<float[]> {
  public int compare(float[] a, float[] b) {
    int result;
    if (a[0] + EPS < b[0])  result = -1;
    else if (a[0] - EPS > b[0])  result = 1;
    else                  result = 0;

    return result;
  }
}