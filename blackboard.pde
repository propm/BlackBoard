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
//import codeanticode.syphon.*;

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
//SyphonServer server;

ArrayList<Enemy>     enemys;
ArrayList<Bullet>    bullets;
ArrayList<Wall>      walls;
Boss boss;
Player[] player;
Home home;
MyObj title;

final int MAXchoke = 11100;
final int[] times = {-1, -1, 60*60, -1, 60*60, -1, 60*20, 60*23};    //sceneと対応　　　-1は時間制限なし
final int sendframes = 2;      //_bossappearなどの変数の中身を外部プログラムに送るときの信号の長さ
final int Scoretime  = 60*1;   //scoreの数字を何秒間変化させるか
final int scorePertime = 5;    //残り時間1フレームあたり何点もらえるか
final int scoremarginf = 10;   //スコアを表示するときの間の時間

boolean firstinitial;
boolean backspace, space;    //backspace、spaceが押されている間true
boolean isStop;
boolean isDebag;             //デバッグモードならtrue
boolean isMouse;             //mouseでプレイヤーを操作するときはtrue
boolean sendable;
boolean isPlaying;           //バトル中ならtrue
boolean isGameOver;          //ゲームオーバーならtrue
boolean gameoveronce;        
boolean darkerfinish;        //ゲームオーバー時に暗くなるのが終わったらtrue
boolean soundstop;           //効果音を止めたいときにtrueにする

int time;            //次のシーンに入るまでの時間を入れる
int score, choke;    //普通のスコア、現在の粉エネルギー
int timescore;       //ボス面の残り時間によるボーナススコア
int bscore, benergy;
int wholecount;      //道中が始まってからのカウント
int scene;           //1:タイトル　2:難易度選択　3:道中　4:ボス登場　5:ボス　6:ボス破滅　7:スコア画面  8:ゲームオーバー
int debagcounter;    //どこが重いか確認する用
int combo;
int backalpha;       //ゲームオーバー時の徐々に暗くなってくときの不透明度

PFont font;

int _reflect;
int _damaged;
int _kill;
int _bossappear;

//*************************↓初期設定など↓***************************

void settings(){
  isMouse = true;
  isDebag = false;
  
  minim = new Minim(this);    //音楽・効果音用
  osc = new OscP5(this, 12345);
  address = new NetAddress("172.23.5.5", 12345);
  
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
  //PJOGL.profile = 1;
  noSmooth();
  
  if(!isMouse)  kinectinit();
}

void setup(){
  //server = new SyphonServer(this, "processing Syphon");
  
  db.settitle();        //settingではdataが読み込まれていないからか、素材が読み込めない
  db.scwhrate = width/1600.0;
  
  db.setobjects();
  firstinitial = true;
  backspace = space = false;
  
  font = createFont("あんずもじ", 48);
  textFont(font);
  textAlign(CENTER);
  
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
  
  player = new Player[isMouse ? 1:2 ];
  for(int i = 0; i < player.length; i++){
    player[i] = new Player(i);
  }
  
  home = new Home();
  
  try{
    bgm = minim.loadFile("bbtitle.mp3");
    bgm.loop();
  }catch(Exception e){}
  
  score = 0;
  choke = MAXchoke;
  isStop = false;
  
  scene = 1;
  time = times[scene-1];
  wholecount = 0;
  backalpha = 0;
  combo = 0;
  sendable = true;
  gameoveronce = true;
  isPlaying = false;
  isGameOver = false;
  darkerfinish = false;
  soundstop = false;
  
  _reflect = _damaged = _bossappear = 0;
}

//*************************↓ループ関数↓***************************

void draw(){
  if(!isStop){
    process();
    //server.sendScreen();
    if(scene != 2)  drawing();
  }
  
}

//処理用関数
void process(){
  wholecount++;
  
  //座標の取得
  if(!isMouse)  kinectupdate();
  
  if(isGameOver && gameoveronce){
    gameoveronce = false;
    scene = 8;
    wholecount = 0;
    time = times[scene-1];
    soundsstop();
    soundstop = true;
    bgm.close();
  }
  
  //時間によってシーン変更
  if(time > 0){
    if(wholecount >= time){
      changeScene();
      process();
      wholecount--;
      return;
    }
  }
  
  if(scene < 3 || scene > 5)  for(int i = 0; i < player.length; i++)  player[i].update();
  
  switch(scene){
    case 1:
      break;
    case 2:
      changeScene();
      break;
    case 3:
    case 4:
    case 5:
    case 6:
      battle();
      break;
    case 7:
      if(!expressfinish)  scoreprocess();
      else{
        score = 0;
        for(int i = 0; i < variousnum; i++)
          score += Maxscore[i];
        send();
      }
      break;
    case 8:
      soundstop = true;
      if(!darkerfinish)  battle();
      
      if(backalpha == 256){
        darkerfinish = true;
        scoreinitial();
        backalpha++;
      }
      if(darkerfinish){
        scoreprocess();
      }
      break;
  }
  
  if(sendable)  send();
  else          sendable = true;
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
      break;
    case 3:
      buttledraw();
      break;
    case 4:
    case 5:
    case 6:
      buttledraw();
      if(boss != null)  boss.draw();
      break;
    case 7:
      background(0);
      textSize(60);
      fill(255);
      for(int i = 0; i <= vsn; i++){
        int a = i;
        if(i == variousnum-1)  a++;
        if(isGameOver && i >= 1)  continue;
        text(scoretext[i]+(int)exscore[i]+"pt", (int)((float)width/2), (int)((float)height/14*(a*2+3)));
      }
      
      text((times[scene-1]- wholecount)/60, (float)width/30*2, (float)height/10*2);
      break;
    case 8:
      gameoverdraw();
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

//ゲームオーバー時の表示
void gameoverdraw(){
  if(backalpha <= 255){
    fill(0, backalpha++);
    rect(0, 0, width, height);
  }else{
    background(0);
    fill(255);
    textSize(90);
    text("Game Over", width/2, height/14*5);
    textSize(60);
    text("score: "+(int)exscore[0], width/2, height/14*8);
  }
  
  text((times[scene-1]- wholecount)/60, (float)width/30*2, (float)height/10*2);
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
        boss = new Boss(width/8.0*7, height/2.0);
        
        bgm.close();
        try{
          bgm = minim.loadFile("Exothermic-boss.wav");
        }catch(Exception e){}
        if(bgm != null)  bgm.loop();
      }
      
      if(boss != null)  boss.update();
      break;
    
    case 5:    //ボス面
    case 6:    //ボス倒される
      
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
}

final int variousnum = 5;          //表示する数字がいくつあるか
final String[] scoretext = {"敵撃破点: ", "残り時間ボーナス: ", "残りhpボーナス: ", "ボス撃破ボーナス: ", "合計: "};
final int bossdestroyscore = 10000;

int[] Maxscore;

int remaintime;       //ボス面の残りタイム
int scorecount;       //score表示用カウント
int vsn;              //変化するスコアがどれか　　1:敵・弾撃破によるスコア　2:残り時間によるボーナススコア　3:合計
float[] exscore;      //表示するスコア
float plusscore;      //1フレームで追加するスコア

boolean scorescrollfinish;    //スクロールが終わっていたらtrue
boolean expressfinish;        //表示が終わったらtrue

//スコア表示の処理
void scoreprocess(){
  scorecount++;
  
  if(scorecount <= Scoretime){
    exscore[vsn] += plusscore;         //表示するスコアの変更
  }else{
    if(exscore[vsn] != Maxscore[vsn])  exscore[vsn] = Maxscore[vsn];    //表示したいスコアを越えていたら戻す
    if(vsn >= variousnum-1){
      expressfinish = true;
      return;
    }
    
    vsn++;
    plusscore = (float)Maxscore[vsn]/Scoretime;                         //次のスコアの準備
    scorecount = 0;
  }
  
}

//*************************↓その他汎用関数↓***************************

//シーン変更
void changeScene(){
  scene++;
  if(scene > times.length-1){
    
    allInitial();
  }
  time = times[scene-1];
  
  switch(scene){
    
    //道中
    case 3:
      isPlaying = true;
      break;
    
    //ボス出現
    case 4:
      _bossappear = 1;
      if(db.warning != null && !soundstop)  db.warning.trigger();
      
      break;
    
    //ボス面
    case 5:
      boss.bossscene = 1;
      break;
      
    case 6:
      boss.bossscene = 2;
      remaintime = wholecount;
      break;
      
    //スコア表示画面
    case 7:
      boss = null;
      scoreinitial();
      send();                //変更前のスコアを送る
      sendable = false;      //ここでsendしたので、processのsendは呼ばない
      isPlaying = false;     //プレイ終了
      
      _bossappear = _kill = _damaged = _reflect = 0;
      break;
  }
  
  wholecount = 0;
}

void scoreinitial(){
  exscore = new float[variousnum];
  for(int i = 0; i < variousnum; i++){
    exscore[i] = 0;
  }
  
  scorecount = 0;
  vsn = 0;
  
  Maxscore = new int[variousnum];
  Maxscore[0] = score;                                            //敵・弾撃破スコア
  Maxscore[1] = scorePertime* (times[4] - remaintime);            //残り時間
  Maxscore[2] = home.hp;                                          //残りhp
  Maxscore[3] = bossdestroyscore;                                 //ボス撃破スコア
  Maxscore[4] = Maxscore[0]+Maxscore[1]+Maxscore[2]+Maxscore[3];  //合計
  
  //for(int i = 0; i < Maxscore.length; i++)
    //plusscore[i] = (float)Maxscore[i]/Scoretime;
  
  plusscore = (float)score/Scoretime;
  
  expressfinish = false;
  
  score = Maxscore[4];
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

int getscore(Enemy e){
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
  
  if(key == ENTER && scene == 1)  changeScene();
  
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
  mes.add(isPlaying ? 1:0);
  
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
  //soundsstop();
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
  float Ly1 = 0.0, Lz1 = 0.0, Ly2 = 0.0, Lz2 = 0.0;

  Client Ry1client, Ry2client, Rz1client, Rz2client;
  float Ry1 = 0.0, Rz1 = 0.0, Ry2 = 0.0, Rz2 = 0.0;

  String LIP;
  String RIP;
  
  void kinectinit(){
    LIP = "172.23.9.217";
    RIP = "172.23.2.59";
    
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
  
  float getPositionX1(int side){
    float rateX = 0;
    if(side == 0)       rateX = Lz1;
    else if(side == 1)  rateX = Rz1;
    else{
      println("引数が間違っています");
      return 0;
    }
    
    if(rateX <= 1.0){
      if(side == 0)       return (width*rateX)/2.0;
      else if(side == 1)  return (width*(1.0-rateX))/2.0 + width/2.0;
    }
    
    return -100;
  }
  
  float getPositionY1(int side){
    float rateY = 0;
    if(side == 0)       rateY = Ly1;
    else if(side == 1)  rateY = Ry1;
    else{
      println("引数が間違っています");
      return 0;
    }
    
    if(rateY <= 1.0)  return height*(1.0-rateY);
    else              return 0;
  }
  
void GetLeft(){
 while(Ly1client.available() +Ly2client.available() +Lz1client.available() +Lz2client.available() >=24){
   if(Ly1client.available() >= 4)
     {
         Ly1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly1client.readBytes(4)).getInt())/10000.0;
     }
     
     if(Ly2client.available() >= 4)
     {
         Ly2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly2client.readBytes(4)).getInt())/10000.0;
     }
     
     if(Lz1client.available() >= 4)
     {
         Lz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz1client.readBytes(4)).getInt())/10000.0;
     }
     
     if(Lz2client.available() >= 4)
     {
         Lz2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz2client.readBytes(4)).getInt())/10000.0;
     }
 }
}

void GetRight(){
 while(Ry1client.available()+ Ry2client.available() +Rz1client.available()+Rz2client.available() >=24){
   if(Ry1client.available() >= 4)
     {
         Ry1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry1client.readBytes(4)).getInt())/10000.0;
     }
     
     
     if(Ry2client.available() >= 4)
     {
         Ry2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry2client.readBytes(4)).getInt())/10000.0;
     }
     
     if(Rz1client.available() >= 4)
     {
         Rz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz1client.readBytes(4)).getInt())/10000.0;
     }
     
     if(Rz2client.available() >= 4)
     {
         Rz2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz2client.readBytes(4)).getInt())/10000.0;
     }
 }
}