import oscP5.*;
import netP5.*;
import java.nio.ByteBuffer;

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;
import processing.net.*;

ScrollManager sm;
ReadText rt;
DataBase db;
TimeManager tm;
CheckText ct;

Minim       minim;
AudioPlayer bgm;
OscP5       osc;
NetAddress address;

Client client;

ArrayList<Enemy>     enemys;
ArrayList<Bullet>    bullets;
ArrayList<Wall>      walls;
Boss boss;
Player[] player;
Home home;
MyObj title;

final int MAXchoke = 11100;
final int[] times = {-1, -1, 60*1, 60*5, -1, 60*10, 60*10};    //sceneと対応　　　-1は時間制限なし
final int sendframes = 2;

boolean firstinitial;
boolean backspace, space;    //backspace、spaceが押されている間true
boolean isStop;
boolean isDebag;             //デバッグモードならtrue

int time;            //次のシーンに入るまでの時間を入れる
int score, choke;
int bscore, benergy;
int wholecount;      //道中が始まってからのカウント
int scene;           //1:タイトル　2:難易度選択　3:道中　4:ボス登場　5:ボス　6:ボス破滅　7:スコア画面  8:ランキング
int debagcounter;    //どこが重いか確認する用
int combo;

int _reflect;
int _damaged;
int _kill;
int _bossappear;

//*************************↓初期設定など↓***************************

void settings(){
  minim = new Minim(this);    //音楽・効果音用
  osc = new OscP5(this, 1234);
  address = new NetAddress("172.23.5.84", 1234);
  //client = new Client(this, "172.23.6.216", 50005);
  
  rt = new ReadText();
  db = new DataBase();        //データベース
  tm = new TimeManager();
  
  db.screenw = 1600;               //スクリーンwidth(仮)
  if(rt.check())  System.exit(0);  //settings.txtのエラーチェック
  rt.readCommands();
  db.screenh = (int)(db.screenw*db.boardrate);

  //databaseセット
  db.initial();
  
  size(db.screenw, db.screenh, P2D);
  noSmooth();
  
  //kinectinit();
}

void setup(){
  db.settitle();        //settingではdataが読み込まれていないからか、素材が読み込めない
  db.scwhrate = width/1600.0;
  
  db.setobjects();
  firstinitial = true;
  isDebag = true;
  backspace = space = false;
  
  textSize(36);
  allInitial();
}

//やり直し
void allInitial(){
  stop(true);
  
  //一回目以外
  if(!firstinitial){
    tm = new TimeManager();
    rt.readCommands();
  }else{
    firstinitial = false;
  }
  
  sm = new ScrollManager();
  
  enemys = new ArrayList<Enemy>();
  bullets = new ArrayList<Bullet>();
  walls = new ArrayList<Wall>();
  
  player = new Player[1];
  player[0] = new Player(0);
  //player[1] = new Player(1);
  home = new Home();
  
  try{
    //bgm = minim.loadFile("bbtitle.mp3");
    //bgm.loop();
  }catch(Exception e){}
  
  score = choke = 0;
  isStop = false;
  
  scene = 1;
  time = times[scene-1];
  wholecount = 0;
  combo = 0;
  
  _reflect = _damaged = _bossappear = 0;
}

//*************************↓ループ関数↓***************************

void draw(){
  if(!isStop){
    process();
    if(scene != 2)  drawing();
  }
}

//処理用関数
void process(){
  
  //座標の取得
  //kinectupdate();
  
  //時間によってシーン変更
  if(time > 0){
    if(wholecount++ >= time){
      changeScene();
      process();
      wholecount--;
      return;
    }
  }
  
  switch(scene){
    case 1:
      for(int i = 0; i < player.length; i++)  player[i].update();
      break;
    case 2:
      changeScene();
      break;
    case 3:
    case 4:
    case 5:
      battle();
      drawing();
      break;
    case 6:
      if(boss != null)  boss = null;
      break;
  }
}

//描画用関数
void drawing(){
  
  switch(scene){
    case 1:
      background(0);
      if(title != null && title.image != null){
        image(title.image, title.x, title.y);
        title.pol.Draw();
      }
      break;
    
    case 2:
      changeScene();
      break;
      
    case 5:
      buttledraw();
      boss.draw();
      break;
    case 3:
    case 4:
      buttledraw();
      break;
  }
  
  //プレイヤー
  for(int i = 0; i < player.length; i++){
    fill(255, 134, 0);
    player[i].draw();
  }
}

//戦闘時のdraw
void buttledraw(){
  sm.drawView();
  
  //自陣
   home.draw();
  
   //壁
   fill(255, 100, 100);
   for(int i = 0; i < walls.size(); i++){
     Wall wall = walls.get(i);
     wall.draw();
   }
   
   //敵
   for(int i = 0; i < enemys.size(); i++){
     Enemy enemy = enemys.get(i);
     enemy.draw();
   }
   
   for(int i = 0; i < bullets.size(); i++){
     Bullet bullet = bullets.get(i);
     bullet.draw();
   }
}

//********************************↓シーンごとの処理↓*********************************

//戦闘　    該当シーン：道中、ボス出現、ボス
void battle(){
  bscore = score;
  benergy = choke;
  _damaged--;
  _reflect--;
  _kill--;
  if(_reflect < 0)  _reflect = 0;
  if(_damaged < 0)  _damaged = 0;
  if(_kill < 0)  _kill = 0;
  
  if(scene == 3)  tm.checksec();
  sm.update();
  
  //敵の動きの処理
  for(int i = 0; i < enemys.size(); i++){
    enemys.get(i).update();
  }
  
  //弾の処理
  for(int i = 0; i < bullets.size(); i++){
    bullets.get(i).update();
  }
  
  //壁の処理
  for(int i = 0; i < walls.size(); i++){
    walls.get(i).update();
  }
  
  //シーンごとの処理
  switch(scene){
    
    //ボスの出現シーン
    case 4:
      if(wholecount == 60*3){
        _bossappear = 0;
      }
      break;
      
    //ボス面
    case 5:
      //ボスの処理
      boss.update();
      break;
  }
  
  //プレイヤーの動きの処理
  for(int i = 0; i < player.length; i++)  player[i].update();
  
  //自陣の処理
  home.update();
  
  //死んだオブジェクトの処理
  cadaver(enemys);
  cadaver(bullets);
  cadaver(walls);
  if(boss != null)  boss.cadaver();
  
  send();
}

//*************************↓その他汎用関数↓***************************

void changeScene(){
  scene++;
  wholecount = 0;
  time = times[scene-1];
  
  switch(scene){
    //ボス出現
    case 4:
      _bossappear = 1;
      if(db.warning != null)  db.warning.trigger();
      
      break;
    
    //ボス面
    case 5:
      boss = new Boss(width/8.0*7, height/2.0);
      break;
  }
}

//画像反転用関数
PImage reverse(PImage img){
  
  color[][] pixel = new color[img.width][img.height];
  
  for(int i = 0; i < img.width; i++){
    for(int j = 0; j < img.height; j++){
      pixel[i][j] = img.get(i, j);
    }
  }
      
  for(int i = 0; i < img.width; i++){
    for(int j = 0; j < img.height; j++){
      img.set(i, j, pixel[img.width - 1 - i][j]);
    }
  }

  return img;
}

int score(Enemy e){
  switch(e.rank){
    case 1:
      return 1000;
    case 2:
      return 1200;
    case 3:
      return 1500;
    case 4:
      return 3000;
  }
  
  return 0;
}

//死んだオブジェクトの処理
void cadaver(ArrayList<?> obj){
  for(int i = 0; i < obj.size(); i++){
    MyObj o = (MyObj)obj.get(i);
    o.die();
    
    if(o.isDie){
      obj.remove(i);
      i--;
    }
  }
}

//*************************↓イベント処理・送信・受信↓***************************

void mousePressed(){
  player[0].ATflag = true;
}

void mouseReleased(){
  player[0].ATflag = false;
}

void keyPressed(){
  switch(keyCode){
    case RIGHT:
      player[0].key = 1;
      break;
    case LEFT:
      player[0].key = 2;
      break;
  }
  
  if(key == BACKSPACE && !backspace){
    allInitial();
    backspace = true;
    println("やり直し");
  }
  
  if(key == ' ' && !space){
    if(!isStop)  isStop = true;
    else         isStop = false;
    space = true;
    println("一時停止");
  }
}

void keyReleased(){
  switch(keyCode){
    case RIGHT:
    case LEFT:
      player[0].key = 0;
      break;
  }
  
  if(key == BACKSPACE)  backspace = false;
  if(key == ' ')        space = false;
}

void send(){
  OscMessage mes = new OscMessage("/text");
  mes.add(score);
  mes.add(choke);
  mes.add(home.hp);
  mes.add(_reflect);
  mes.add(_damaged);
  mes.add(_kill);
  mes.add(_bossappear);
  osc.send(mes, address);
}

//*************************↓終了時↓***************************

//スケッチ終了時に呼ばれる関数
void stop(){
  stop(true);
  minim.stop();
  super.stop();
}

void stop(boolean a){
  if(bgm != null)  bgm.close();
  soundsstop();
}

void soundsstop(){
  if(enemys != null)
    for(int i = 0; i < enemys.size(); i++){
      enemys.get(i).soundstop();
    }
  
  if(walls != null)
    for(int i = 0; i < walls.size(); i++){
      walls.get(i).soundstop();
    }
  
  if(bullets != null)
    for(int i = 0; i < bullets.size(); i++){
      bullets.get(i).soundstop();
    }
  
  if(boss != null)  boss.soundstop();
  if(player != null)
    for(int i = 0; i < player.length; i++)
      if(player != null)  player[i].soundstop();
    
  if(home != null)  home.soundstop();
}

//************************************************************************************::

Client Ly1client, Ly2client, Lz1client, Lz2client;
  float Ly1 = 0.0,Lz1 = 0.0, Ly2 = 0.0,Lz2 = 0.0;

  Client Ry1client,Ry2client,Rz1client,Rz2client;
  float Ry1 = 0.0,Rz1 = 0.0, Ry2 = 0.0,Rz2 = 0.0;

  String LIP;
  String RIP ;
  
  void kinectinit(){
    LIP = "10.0.1.204";
    RIP = "10.0.1.186";
    
    Ly1client = new Client(this, LIP, 50005);
    Ly2client = new Client(this, LIP, 60006);
    Lz1client = new Client(this, LIP, 40004);
    Lz2client = new Client(this, LIP, 30003);
    
    Ry1client = new Client(this, RIP, 50002);
    Ry2client = new Client(this, RIP, 60002);
    Rz1client = new Client(this, RIP, 40002);
    Rz2client = new Client(this, RIP, 30002);
    
  }
  
  
  void kinectupdate(){
    GetLeft();
    GetRight();
  }
  
  float GetLeftPositionX(){
    if(Lz1 <= 1.0){
      return (width*Lz1)/2.0;
    }else{
      return 0;
    }
  }
  
  float GetLeftPositionY(){
    if(Lz1 <= 1.0){
      return height*(1.0-Ly1);
    }else{
      return 0;
    }
  }
  
  float GetRightPositionX(){
    if(Lz1 <= 1.0){
      return width-(width*Rz1)/2;
    }else{
      return 0;
    }
  }
  
  float GetRightPositionY(){
    if(Lz1 <= 1.0){
      return height*(1.0-Ry1);
    }else{
      return 0;
    }
  }
  
  float GetLeftPositionX2(){
    if(Lz1 <= 1.0){
      return (width*Lz1)/2.0;
    }else{
      return 0;
    }
  }
  
  float GetLeftPositionY2(){
    if(Lz1 <= 1.0){
      return height*(1.0-Ly1);
    }else{
      return 0;
    }
  }
  
  float GetRightPositionX2(){
    if(Lz1 <= 1.0){
      return width-(width*Rz1)/2;
    }else{
      return 0;
    }
  }
  
  float GetRightPositionY2(){
    if(Lz1 <= 1.0){
      return height*(1.0-Ry1);
    }else{
      return 0;
    }
  }
  
  
  
  void GetLeft(){
    if(Ly1client.available() >= 4){
      Ly1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly1client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Ly2client.available() >= 4){
      Ly2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly2client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Lz1client.available() >= 4){
      Lz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz1client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Lz2client.available() >= 4){
      Lz2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz2client.readBytes(4)).getInt())/10000.0;
    }
    
  }
  
  void GetRight(){
    if(Ry1client.available() >= 4){
      Ry1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry1client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Ry2client.available() >= 4){
      Ry2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry2client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Rz1client.available() >= 4){
      Rz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz1client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Rz2client.available() >= 4){
      Rz2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz2client.readBytes(4)).getInt())/10000.0;
    }
    
  }