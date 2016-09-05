final float EPS = 0.0000001;

// p1 + p2
PVector add(PVector p1, PVector p2) {
  return new PVector(p1.x + p2.x, p1.y + p2.y, p1.z + p2.z);
}

// p1 - p2
PVector sub(PVector p1, PVector p2) {
  return new PVector(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);
}


class Polygon {
  ArrayList<PVector> ver;    //各頂点を表すベクトルを格納する
  
  Polygon() {
    ver = new ArrayList<PVector>();
  }
  
  Polygon(ArrayList<PVector> po) {
    ver = new ArrayList<PVector>(po);
  }
  
  //頂点追加
  void Add(PVector point) {
    ver.add(new PVector(point.x, point.y, point.z));
  }
  
  void Add(float x, float y, float z) {
    ver.add(new PVector(x, y, z));
  }
  
  //描画
  void Draw() {
    for (int i = 0; i < ver.size(); i++) {
      PVector p1 = ver.get(i);
      PVector p2 = ver.get((i + 1) % ver.size());
      
      line(p1.x, p1.y, p2.x, p2.y);
    }
  }
}

// 多角形同士の判定 境界は含まない(辺が交差したときのみ判定あり)
boolean judge(Polygon polygon1, Polygon polygon2) {
    ArrayList<PVector> p1 = polygon1.ver;
    ArrayList<PVector> p2 = polygon2.ver;
    
    // なんかこれでいけた（たぶん処理早め）「理解不能」
    //NOになる条件：jのループにおいて、全て外積が左回りの頂点が少なくとも一つはあること
    
    for (int i = 0; i < p1.size(); i++) {
      PVector[] vec = new PVector[2];
      boolean flag = true;
      
      vec[0] = sub(p1.get((i + 1) % p1.size()), p1.get(i));
      
      for (int j = 0; j < p2.size(); j++) {
        vec[1] = sub(p2.get(j), p1.get(i));
        PVector tmp = vec[0].cross(vec[1]);            //vec[0]とvec[1]の外積代入
        
        println(tmp.z);
        if (tmp.z > EPS) { flag = false; break; }      //z軸は画面の奥側が正 一つでも右回りがあればjのループ終了
      }
      if (flag) return false;
      
    }
    
    return true;
}
