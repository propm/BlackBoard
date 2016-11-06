//あらゆる初期設定を保存するクラス
class DataBase{
  
  final float eraserw = 5;          //数字がでかいほうが横とする
  final float eraserh = 2;
  final float boardh  = 35;
  final float boardw  = 79.8913*2;
  
  final float boardrate = boardh/boardw;
  final int otherobjsize = 7;
  
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
                         {{0.37325, 1.0/4}, {1.0, 1.0/4}, {1.0, 1.0/4*3}, {0.37325, 1.0/4*3}},
                         {{4/25.0, 57/100.0}, {17/50.0, 9/25.0}, {27/50.0, 8/25.0}, {87/100.0, 31/50.0},
                          {18/25.0, 21/25.0}, {41/100.0, 21/25.0}, {1/5.0, 83/100.0}},
                         {{19/40.0, 3/55.0}, {27/40.0, 4/55.0}, {30/40.0, 22/55.0}, {27/40.0, 28/55.0}, {35/40.0, 34/55.0},
                          {36/40.0, 43/55.0}, {22/40.0, 51/55.0}, {6/40.0, 45/55.0}, {3/40.0, 36/55.0}, {11/40.0, 22/55.0},
                          {10/40.0, 9/55.0}},
                         {{15/50.0, 5/50.0}, {44/50.0, 28/50.0}, {46/50.0, 38/50.0}, {31/50.0, 46/50.0},
                          {15/50.0, 40/50.0}, {2/50.0, 19/50.0}, {6/50.0, 9/50.0}}
                         };
  
  //効果音のファイル名
  String erase;
  
  ArrayList<Enemy> oriEnemys;    //敵種別設定用のオブジェクト
                                       //1:突撃兵  2:サイン  3:タンジェント  4:パラシュート
                                       //5:大砲　　6:忍者
  ArrayList<MyObj> otherobj;       //敵以外のオブジェクト
  
  AudioSample warning;
  
  //中身を入れる
  void initial(){
    objects = rt.objects.clone();
    oriEnemys = new ArrayList<Enemy>(objects.length);
    
    //一度配列に入れているのは、それぞれのインスタンスのコンストラクタ内で
    //if(otherobj.size() > 0)を使って処理をしないようにしたいから
    otherobj = new ArrayList<MyObj>();
    MyObj[] oo = {new Player(), new Home(), new Wall(), new Bullet(), new Shuriken(), new Reflect(), new Strong()};
    for(int i = 0; i < oo.length; i++)
      otherobj.add(oo[i]);
    
    Enemy[] oe = {new Attacker(), new Sin(), new Tangent(), new Parachuter(), new Cannon(), new Ninja(), new Boss(), new Parachuter()};
    for(int i = 0; i < oe.length; i++)
      oriEnemys.add(oe[i]);
    
    warning = setsound("warning.wav");
  }
  
  void settitle(){
    title = new MyObj();
    MyObj t = title;
    
    float m = 3.7;
    try{
      t.image = loadImage("title.png");
      t.w = (int)(t.image.width/m);
      t.h = (int)(t.image.height/m);
      t.image = reSize(t.image, t.w, t.h);
    }catch(Exception e){
      e.printStackTrace();
    }
    
    t.x = width/2.0 - t.w/2.0;
    t.y = height/2.0 - t.h/2.0;
    
    t.pol = new Polygon();
    t.pol.Add(width/2.0+t.w/2.0, height/2.0-t.h/2.0, 0);
    t.pol.Add(width/2.0+t.w/2.0, height/2.0+t.h/2.0, 0);
    t.pol.Add(width/2.0-t.w/2.0, height/2.0+t.h/2.0, 0);
    t.pol.Add(width/2.0-t.w/2.0, height/2.0-t.h/2.0, 0);
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
      e.diename = "enemydestroyed.wav";    //死ぬときの音
      e.bul = setsound("fire.wav");                      //普通弾発射時の音
      String[] imgnames;
      
      switch(i){
        case 1:
          imgnames = new String[2];
          imgnames[0] = "attacker.png";
          imgnames[1] = "attacker_attack.png";
          //引数は右からオブジェクト、num, hp, rank, bulletflag, Bi, 移動速度, damage, imgfile名
          setEnemys(e, i, 2, 1, false, -1, new PVector(-2, 0), 10, imgnames);
          e.ATname = "attacker_attack.mp3";    //壁に攻撃するときの音
          break;
        case 2:
          imgnames = new String[2];
          imgnames[0] = "flying1.png";
          imgnames[1] = "flying2.png";
          setEnemys(e, i, 1, 2, true, 75, new PVector(-3, 0), 20, imgnames);
          break;
        case 3:
          imgnames = new String[2];
          imgnames[0] = "tangent1.png";
          imgnames[1] = "tangent2.png";
          setEnemys(e, i, 1, 4, true, 0, new PVector(-6, 0), 50, imgnames);
          e.bulname = "beam.wav";    //ビームを打っているときずっとなる音
          break;
        case 4:
          imgnames = new String[2];
          imgnames[0] = "parachuter1.png";
          imgnames[1] = "parachuter2.png";
          
          setEnemys(e, i, 5, 3, true, 50, new PVector(-2, 2), 30, imgnames);
          e.ATname = "parachuter_attack.wav";    //突撃し始めるときの音
          break;
        case 5:
          imgnames = new String[2];
          imgnames[0] = "cannon.png";
          imgnames[1] = "cannon_attack.png";
          setEnemys(e, i, 5, 3, true, 60*4, new PVector(0, 0), 0, imgnames);
          Cannon c = (Cannon)e;
          c.chargename = "laser_charge.wav";  //チャージ時の音
          c.bulname = "laser.wav";     //レーザーを打つときの音
          c.appearname = "summon.wav";  //召喚時の音
          break;
        case 6:
          imgnames = new String[2];
          imgnames[0] = "ninja.png";
          imgnames[1] = "ninja_attack.png";
          setEnemys(e, i, -1, 4, true, 60*4, new PVector(0, 0), 0, imgnames);
          break;
        case 7:
          e.hp = 100;
          float bosssize = 6.0;
          setImage(e, "boss1.png", bosssize);
          setImage(e, "boss2.png", bosssize);
          setOriPolygon(e, i);
          
          Boss bo = (Boss)e;
          bo.reflectfirename = "reflect_fire.wav";
          bo.strongfirename = "reflectable_fire.wav";
          bo.diename = "boss_destroyed.wav";
          break;
        case 8:
          String filename = "parachuter_attack.png";
          setImage(e, filename);
          setOriPolygon(e, i);
          break;
      }
    }
    
    //他のオブジェクトの設定
    for(int i = 0; i < otherobj.size(); i++){
      setOtherobj(i);
    }
  }
  
  //敵の設定
  void setEnemys(Enemy e, int num, int hp, int rank, boolean bf, int Bi, 
                  PVector v, int damage, String[] imgnames){
    e.hp = hp;
    e.rank = rank;
    e.bulletflag = bf;
    e.Bi = Bi;
    e.v = new PVector(v.x*scwhrate, v.y*scwhrate);
    e.damage = damage;
    
    for(int i = 0; i < imgnames.length; i++){
      setImage(e, imgnames[i]);
    }
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
        oh.damagedname = "homedamaged.wav";
        oh.image = reverse(loadImage("cleaner.png"));
        oh.imgm = (float)1/3;
        break;
      case 2:
        Wall ow = (Wall)otherobj.get(num);
        ow.diename = "walldestroyed.wav";
        ow.reflectname = "reflect.wav";
        break;
      case 3:    //弾
        Bullet b = (Bullet)otherobj.get(num);
        b.ATname = "bullet_attack(wall).wav";
        break;
      case 4:    //手裏剣
        MyObj s = otherobj.get(num);
        s.image = loadImage("shuriken.png");
        s.w = (int)(s.image.width/20.0*scwhrate);
        s.h = (int)(s.image.height/20.0*scwhrate);
        s.image = reSize(s.image, (int)s.w, (int)s.h);
        break;
      case 5:    //反射弾
        Reflect ref = (Reflect)otherobj.get(num);
        ref.reversename = "reflect_reverse.wav";
      case 6:
        //Strong st = (Strong)otherobj.get(num);
        break;
    }
  }
  
  //プレイヤーの設定
  void setPlayer(){
    Player p = (Player)otherobj.get(0);
    p.createname = "wallcreated.wav";
    p.erasename = "";
    
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
    Polygon pol = e.pol;
    
    switch(num){
      case 1:  vecnum = 0;  break;    //突撃兵
      case 2:  vecnum = 1;  break;    //フライング
      case 5:  vecnum = 2;  break;    //砲台
      case 6:  vecnum = 3;  break;    //忍者
      case 7:  vecnum = 4;  break;    //ボス
      
      case 4:  vecnum = 5;  break;    //パラシュート通常形態
      case 8:  vecnum = 6;  break;    //パラシュート突撃形態
    }
    
    for(int j = 0; j < vectors[vecnum].length; j++)  e.pol.Add(e.w*vectors[vecnum][j][0], e.h*vectors[vecnum][j][1], 0);
    
    if(num != 7){
      wh = e.pol.getWH();
      e.w = (int)wh[0];
      e.h = (int)wh[1];
      e.marginx = wh[2];
      e.marginy = wh[3];
    }
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