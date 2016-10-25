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
Player player;
Home home;

final int MAXchoke = 11100;
final int[] times = {0, 0, 60*2, 60*1, 60*60*60, 60*10, 60*10};
final int sendframes = 2;

boolean firstinitial;
boolean backspace, space;    //backspace、spaceが押されている間true
boolean isStop;
boolean isDebag;             //デバッグモードならtrue

int time;            //次のシーンに入るまでの時間を入れる
int score, choke;
int bscore, benergy;
int wholecount;      //道中が始まってからのカウント
int scene;            //1:タイトル　2:難易度選択　3:道中　4:ボス登場　5:ボス　6:スコア画面  7:ランキング
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
  
  db.screenw = 1600;          //スクリーンwidth
  db.initial();
  
  if(rt.check())  System.exit(0);  //settings.txtのエラーチェック
  rt.readCommands();
  db.screenh = (int)(db.screenw*db.boardrate);
  
  size(db.screenw, db.screenh, P2D);
  noSmooth();
}

void setup(){
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
  
  player = new Player();
  home = new Home();
  
  score = choke = 0;
  isStop = false;
  scene = 3;
  time = times[scene-1];
  wholecount = 0;
  combo = 0;
  
  _reflect = _damaged = _bossappear = 0;
}

//*************************↓ループ関数↓***************************

void draw(){
  if(!isStop){
    process();    //処理
    drawing();    //描画
  }
}

//処理用関数
void process(){
  //時間によってシーン変更
  if(wholecount++ >= time){
    changeScene();
    process();
    wholecount--;
    return;
  }
  
  switch(scene){
    case 3:
    case 4:
    case 5:
      battle();
      break;
  }
}

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
      if(wholecount == 60*3)  _bossappear = 0;
      break;
      
    //ボス面
    case 5:
      //ボスの処理
      boss.update();
      break;
  }
  
  //プレイヤーの動きの処理
  player.update();
  
  //自陣の処理
  home.update();
  
  //死んだオブジェクトの処理
  cadaver(enemys);
  cadaver(bullets);
  cadaver(walls);
  if(boss != null)  boss.cadaver();
  
  //if(bscore != score || benergy != choke)  println("score: "+score+"  choke: "+choke);    
  send();
}

//描画用関数
void drawing(){
  sm.drawView();
  
  //自陣
  home.draw();
  
  //壁
  fill(255, 100, 100);
  for(int i = 0; i < walls.size(); i++){
    Wall wall = walls.get(i);
    wall.draw();
  }
  
  if(scene == 5){
    boss.draw();
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
  
  //プレイヤー
  fill(255, 134, 0);
  player.draw();

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
  player.ATflag = true;
}

void mouseReleased(){
  player.ATflag = false;
}

void keyPressed(){
  switch(keyCode){
    case RIGHT:
      player.key = 1;
      break;
    case LEFT:
      player.key = 2;
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
      player.key = 0;
      break;
  }
  
  if(key == BACKSPACE)  backspace = false;
  if(key == ' ')        space = false;
}

int readInt()
{
    return Integer.reverseBytes(ByteBuffer.wrap(client.readBytes(4)).getInt());
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
  bgm.close();
  soundsstop();
  minim.stop();
  super.stop();
}

void soundsstop(){
  for(int i = 0; i < enemys.size(); i++){
    enemys.get(i).soundstop();
  }
  
  for(int i = 0; i < walls.size(); i++){
    walls.get(i).soundstop();
  }
  
  for(int i = 0; i < bullets.size(); i++){
    bullets.get(i).soundstop();
  }
  
  if(boss != null)  boss.soundstop();
  if(player != null)  player.soundstop();
  if(home != null)  home.soundstop();
}