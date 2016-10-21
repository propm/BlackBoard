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
  
  ArrayList<Enemy> oriEnemys;    //敵種別設定用のオブジェクト
                                       //1:突撃兵  2:サイン  3:タンジェント  4:パラシュート
                                       //5:大砲　　6:忍者
  ArrayList<MyObj> otherobj;       //敵以外のオブジェクト
  
  //中身を入れる
  void initial(){
    objects = rt.objects.clone();
    oriEnemys = new ArrayList<Enemy>(objects.length);
    
    otherobj = new ArrayList<MyObj>();
    otherobj.add(new Player());
    otherobj.add(new Home());
    otherobj.add(new Wall());
    otherobj.add(new Bullet());
    otherobj.add(new Shuriken());
    
    oriEnemys.add(new Attacker());
    oriEnemys.add(new Sin());
    oriEnemys.add(new Tangent());
    oriEnemys.add(new Parachuter());
    oriEnemys.add(new Cannon());
    oriEnemys.add(new Ninja());
    oriEnemys.add(new Boss());
  }
  
  /*
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
  }*/
  
  //敵・プレイヤーの設定
  void setobjects(){
    for(int i = 1; i <= oriEnemys.size(); i++){
      
      Enemy e = oriEnemys.get(i-1);
      e.pol = new Polygon();
      e.die = setsound("enemydestroyed.mp3");    //死ぬときの音
      e.bul = setsound("");                      //普通弾発射時の音
      
      switch(i){
        case 1:
          //引数は右からオブジェクト、num, hp, rank, bulletflag, Bi, 移動速度, damage, imgfile名
          setEnemys(e, i, 2, 1, false, -1, new PVector(-2, 0), 10, "attacker.png", "attacker_attack.png");
          e.AT = setsound("");    //壁に攻撃するときの音
          break;
        case 2:
          setEnemys(e, i, 1, 2, true, 75, new PVector(-3, 0), 20, "flying1.png", "flying2.png");
          break;
        case 3:
          setEnemys(e, i, 1, 4, true, 0, new PVector(-6, 0), 50, "tangent1.png", "tangent2.png");
          e.bul = setsound("");    //ビームを打っているときずっとなる音
          break;
        case 4:
          setEnemys(e, i, 5, 3, true, 50, new PVector(-2, 2), 30, "attacker.png", "attacker_attack.png");
          e.AT = setsound("");    //突撃し始めるときの音
          break;
        case 5:
          setEnemys(e, i, 5, 3, true, 60*3, new PVector(0, 0), 0, "cannon.png", "cannon_attack.png");
          Cannon c = (Cannon)e;
          c.charge = setsound("");  //チャージ時の音
          c.bul = setsound("");     //レーザーを打つときの音
          c.appear = setsound("");  //召喚時の音
          break;
        case 6:
          setEnemys(e, i, -1, 4, true, 60*4, new PVector(0, 0), 0, "ninja.png", "ninja_attack.png");
          break;
        case 7:
          
      }
    }
    
    //他のオブジェクトの設定
    for(int i = 0; i < otherobj.size(); i++){
      setOtherobj(i);
    }
  }
  
  //敵の設定
  void setEnemys(Enemy e, int num, int hp, int rank, boolean bf, int Bi, 
                  PVector v, int damage, String imgname1, String imgname2){
    e.hp = hp;
    e.rank = rank;
    e.bulletflag = bf;
    e.Bi = Bi;
    e.v = new PVector(v.x*scwhrate, v.y*scwhrate);
    e.damage = damage;
    
    setImage(e, imgname1);
    setImage(e, imgname2);
    setOriPolygon(e, num);
  }
  
  //敵以外のオブジェクトの設定
  void setOtherobj(int num){
    
    switch(num){
      case 0:    //プレイヤー
        setPlayer();
        break;
      case 1:    //自陣
        Home oh = (Home)otherobj.get(num);
        oh.damaged = setsound("");
        oh.image = reverse(loadImage("cleaner.png"));
        oh.imgm = (float)1/3;
        break;
      case 2:
        Wall ow = (Wall)otherobj.get(num);
        ow.die = setsound("");
        ow.damaged = setsound("");
        ow.reflect = setsound("");
        break;
      case 3:    //弾
        Bullet b = (Bullet)otherobj.get(num);
        b.die = setsound("normalbullet_hit.mp3");
        break;
      case 4:    //手裏剣
        MyObj s = otherobj.get(num);
        s.image = loadImage("shuriken.png");
        s.w = (int)(s.image.width/20.0*scwhrate);
        s.h = (int)(s.image.height/20.0*scwhrate);
        s.image = reSize(s.image, (int)s.w, (int)s.h);
        break;
    }
  }
  
  //プレイヤーの設定
  void setPlayer(){
    Player p = (Player)otherobj.get(0);
    p.create = setsound("");
    
    p.pol = new Polygon();
    p.pol.Add(0, 0, 0);
    p.pol.Add(p.w, 0, 0);
    p.pol.Add(p.w, p.h, 0);
    p.pol.Add(0, p.h, 0);
  }
  
  //効果音の設定
  AudioSample setsound(String filename){
    AudioSample sound = null;
    
    try{
      sound = minim.loadSample(filename);
    }catch(Exception e){}
    
    return sound;
  }
  
  //画像設定
  void setImage(Enemy e, String filename){
    setImage(e, filename, 20.0);
  }
  
  //敵の画像の設定
  void setImage(Enemy e, String filename, float divnum){
    e.imgs.add(loadImage(filename));
    int a = e.imgs.size()-1;
    e.w = (int)(e.imgs.get(a).width/divnum*scwhrate);
    e.h = (int)(e.imgs.get(a).height/divnum*scwhrate);
    
    e.imgs.set(a, reSize(e.imgs.get(a), e.w, e.h));
  }
  
  //敵の多角形の設定
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