//あらゆる初期設定を保存するクラス
class DataBase{
  
  final float eraserw = 5;          //数字がでかいほうが横とする
  final float eraserh = 2;
  final float boardh  = 35;
  final float boardw  = 79.8913*2;
  
  final float boardrate = boardh/boardw;
  
  String[] objects;              //オブジェクトの名前
  float scwhrate;                //width/1600.0
  int screenw, screenh;
  
  //多角形の点を保持
  float[][][] vectors = {{{29.0/40, 133.0/800}, {141.0/160, 31.0/40}, {61.0/81, 17.0/20}, {13.0/40, 33.0/40}, 
                          {1/4.0, 3/4.0}, {5.0/16, 3.0/8}, {7.0/16, 27.0/160}}, 
                         {{33.0/160, 9.0/40}, {9.0/10, 49.0/160}, {9.0/10, 5.0/8}, {11.0/20, 59.0/80},
                          {1.0/4, 29.0/40}, {27.0/160, 41.0/80}},
                         {{0.59925, 0.109}, {0.74725, 0.1378}, {0.84925, 0.2834}, {0.72725, 0.4388},
                          {0.80225, 0.6672}, {0.60825, 0.9946}, {0.41925, 0.665}, {0.47325, 0.4262}, 
                          {0.33525, 0.331}, {0.45725, 0.1466}},
                         {{0.37325, 1.0/4}, {1.0, 1.0/4}, {1.0, 1.0/4*3}, {0.37325, 1.0/4*3}}
                         };
  
  //効果音のファイル名
  String erase;
  
  HashMap<String, Enemy> oriEnemys;    //敵種別設定用のオブジェクト
                                       //1:突撃兵  2:サイン  3:タンジェント  4:パラシュート
                                       //5:大砲　　6:忍者
  Player oriplayer;
  Shuriken orishuriken;
  
  //中身を入れる
  void initial(){
    objects = rt.objects.clone();
    oriEnemys = new HashMap<String, Enemy>(objects.length);
    oriplayer = new Player();
    orishuriken = new Shuriken();
    
    for(int i = 0; i < objects.length; i++){
      oriEnemys.put(objects[i], new Enemy());
    }
  }
  
  //敵の効果音を設定
  void setsound(String object, String command, String filename){
  
    if(oriEnemys.containsKey(object)){
      for(int i = 0; i < oriEnemys.size(); i++){
        if(objects[i].equals(object)){
          if(command.equals("die"))       oriEnemys.get(object).die = minim.loadSample(filename);
          if(command.equals("attack"))    oriEnemys.get(object).AT  = minim.loadSample(filename);
        }
      }
    }
  }
  
  //敵・プレイヤーの設定
  void setobjects(){
    
    for(int i = 1; i <= oriEnemys.size(); i++){
      
      Enemy e = oriEnemys.get(objects[i-1]);
      e.pol = new Polygon();
      
      switch(i){
        case 4:
          e.hp = 5;
          e.rank = 3;
          e.bulletflag = true;
          e.Bi = 50;
          e.v = new PVector(-2*scwhrate, 2*scwhrate);
          e.damage = 30;
          
          setImage(e, "attacker.png");
          setImage(e, "attacker_attack.png");
          setOriPolygon(e, i);
          
          break;
        case 1:
          e.hp = 2;
          e.rank = 1;
          e.bulletflag = false;
          e.v = new PVector(-2*scwhrate, 0);
          e.damage = 10;
          
          setImage(e, "attacker.png");
          setImage(e, "attacker_attack.png");
          setOriPolygon(e, i);
          
          break;
        case 2:
          e.hp = 1;
          e.rank = 2;
          e.v = new PVector(-3*scwhrate, 0);
          e.bulletflag = true;
          e.Bi = 75;
          e.damage = 20;
          
          setImage(e, "flying1.png");
          setImage(e, "flying2.png");
          setOriPolygon(e, i);
          break;
        
        case 3:
          e.hp = 1;
          e.rank = 4;
          e.v = new PVector(-6*scwhrate, 0);
          e.bulletflag = true;
          e.Bi = 0;
          e.damage = 50;
          
          setImage(e, "tangent1.png");
          setImage(e, "tangent2.png");
          
          break;
        case 5:
          e.hp = 5;
          e.rank = 3;
          e.v = new PVector(0, 0);
          e.bulletflag = true;
          e.Bi = 60 * 3;
          
          setImage(e, "cannon.png");
          setImage(e, "cannon_attack.png");
          setOriPolygon(e, i);
          
          break;
        case 6:
          e.hp = -1;
          e.rank = 4;
          e.v = new PVector(0, 0);
          e.bulletflag = true;
          e.Bi = 60 * 4;
          
          setImage(e, "ninja.png");
          setImage(e, "ninja_attack.png");
          setOriPolygon(e, i);
          /*
          setImage(e, "attacker(kari).png", 30.0);
          for(int j = 0; j < e.imgs.size(); j++)
            e.imgs.set(j, Reverse(e.imgs.get(j)));
          
          float[][] vectors6 = {{e.w/2, 0, 0}, {e.w*9/10, e.h*3/20, 0}, {e.w, e.h, 0}, 
                                {0, e.h*21/22, 0}, {e.w/5, e.h*3/25, 0}};
                               
          for(int j = 0; j < vectors6.length; j++)  e.pol.Add(vectors6[j][0], vectors6[j][1], vectors6[j][2]);
          e.pol.Reverse(e.w);
          */
          break;
      }
    }
    
    setPlayer();
    
    Shuriken s = orishuriken;
    s.image = loadImage("shuriken.png");
    s.w = (int)(s.image.width/20.0*scwhrate);
    s.h = (int)(s.image.height/20.0*scwhrate);
    s.image = reSize(s.image, (int)s.w, (int)s.h);
  }
  
  void setPlayer(){
    Player p = oriplayer;
    
    p.gap = atan(db.eraserh/db.eraserw);
    
    float distx = width/db.boardw*db.eraserw/2;
    float disty = height/db.boardh*db.eraserh/2;
    
    p.dist = (float)Math.sqrt(distx*distx + disty*disty);
    
    p.w = (int)(distx*2);
    p.h = (int)(disty*2);
    
    p.pol = new Polygon();
    p.pol.Add(0, 0, 0);
    p.pol.Add(p.w, 0, 0);
    p.pol.Add(p.w, p.h, 0);
    p.pol.Add(0, p.h, 0);
  }
  
  //画像設定
  void setImage(Enemy e, String filename){
    setImage(e, filename, 20.0);
  }
  
  void setImage(Enemy e, String filename, float divnum){
    e.imgs.add(loadImage(filename));
    int a = e.imgs.size()-1;
    e.w = (int)(e.imgs.get(a).width/divnum*scwhrate);
    e.h = (int)(e.imgs.get(a).height/divnum*scwhrate);
    
    e.imgs.set(a, reSize(e.imgs.get(a), e.w, e.h));
  }
  
  void setOriPolygon(Enemy e, int num){
    float[] wh;
    int vecnum = 0;    //多角形の点の情報が入った配列の添字を表す
    switch(num){
      case 1:
      case 4:  vecnum = 0;  break;
      case 2:  vecnum = 1;  break;
      case 5:  vecnum = 2;  break;
      case 6:  vecnum = 3;  break;
    }
    for(int j = 0; j < vectors[vecnum].length; j++)  e.pol.Add(e.w*vectors[vecnum][j][0], e.h*vectors[vecnum][j][1], 0);
    
    wh = e.pol.getWH();
    e.w = (int)wh[0];
    e.h = (int)wh[1];
    e.marginx = wh[2];
    e.marginy = wh[3];
  }
  
   //反転
  PImage Reverse(PImage img){
    return reverse(img);
  }
  
  //拡大・縮小
  PImage reSize(PImage img, int w, int h){
    img.resize(w, h);
    return img;
  }
}