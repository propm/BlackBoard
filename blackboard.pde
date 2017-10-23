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

import javax.swing.*;
import java.lang.reflect.*;
//import codeanticode.syphon.*;



//クラス群
ScrollManager scroller;    //背景をスクロールさせる
ReadText rt;               //ステージファイルを読み込む
DataBase db;               //dataフォルダから読み込む素材を保存しておく
TimeManager tm;            //時間ごとにイベントを発生させる
SceneManager scener;       //シーン切り替え、シーンごとの処理を実行
Disposal disposal;         //死んだオブジェクトなどの処理

Minim       minim;         //音楽に必須
AudioPlayer bgm;           //bgm
OscP5       osc;           //外部プログラムへの送信に必要
NetAddress address;        //どのIPアドレスに送るかを記憶

Client client;             //kinect_serverとの通信に使う
KinectClient kinect;       //kinectから受け取った値の処理
//SyphonServer server;       //プロジェクターに映すときに使う(Mac限定)

ArrayList<Enemy>     enemys;    //敵
ArrayList<Bullet>    bullets;   //弾
ArrayList<Wall>      walls;     //壁
ArrayList<AudioSample> dies;    //死ぬときの音を一時的に保持し、数秒後にclose()するためのもの
ArrayList<Integer> diescount;   //死ぬときの音がcloseされるまでカウントする
ArrayList<ParticleManager> pms; //チャージエフェクト

Boss boss;
Player[] players;
Home home;



final int MAXchoke = 11100;    //粉エネルギーの最大値
final int sendframes = 2;      //_bossappearなどの変数の中身を外部プログラムに送るときの信号の長さ

final int dietime = 60*2;      //dieが鳴る時間の長さ
final boolean isMouse = true;    //mouseでプレイヤーを操作するときはtrue
final boolean isDebag = true;    //デバッグモードならtrue
final boolean isTwoKinect = false;  //キネクトを2台使うならtrue
final boolean isKinectLeft = false;  //キネクトを1台使う場合にキネクトが置かれている場所が画面の左側ならtrue



boolean backspace, space;    //backspace、spaceが押されている間true
boolean isStop;              //一時停止を司る
boolean alreadySend;         //このフレームで既にoscで送ったならtrue
boolean isPlaying;           //バトル中ならtrue
boolean soundstop;           //効果音を止めたいときにtrueにする

int score, choke;    //普通のスコア、現在の粉エネルギー

PFont font;

//他のプログラムに送るフラグ
int _reflect;
int _damaged;
int _kill;
int _bossappear;

//*************************↓初期設定など↓***************************

void settings(){
  osc     = new OscP5(this, 16666);
  address = new NetAddress("127.0.0.1", 16666);
  rt = new ReadText();        //settings.txtを読み込むクラス
  db = new DataBase();        //データベース
  db.initial();
  
  size(db.screenw, db.screenh, P2D);
  //PJOGL.profile = 1;

  db.scwhrate = width/1600.0;
}

void setup(){
  //server = new SyphonServer(this, "processing Syphon");
  minim   = new Minim(this);    //音楽・効果音用
  
  if(rt.check())  System.exit(0);  //settings.txtのエラーチェック
  
  db.settitle();        //settingではdataが読み込まれていないからか、素材が読み込めない
  db.setobjects();      //敵の設定
  
  if(!isMouse)  kinect = new KinectClient(this);  //キネクトを使うなら、キネクトの準備をする
  disposal = new Disposal();                      //後処理用クラス
  
  //フォントの設定
  font = createFont("あんずもじ", 48);
  textFont(font);
  textAlign(CENTER);
  
  //イベントを保持
  tm = new TimeManager();
  rt.readCommands();
  
  //クラス群
  scener = new SceneManager();
  scroller = new ScrollManager();
  
  //初期化
  allInitial();
}

//やり直し
void allInitial(){
  
  //残っているものを除去
  disposal.dispose();
  
  tm.copy();
  
  //↓オブジェクト類↓
  scroller.initial();
  scener.initial();
  
  enemys = new ArrayList<Enemy>();
  bullets = new ArrayList<Bullet>();
  walls = new ArrayList<Wall>();
  dies = new ArrayList<AudioSample>();
  pms = new ArrayList<ParticleManager>();
  diescount = new ArrayList<Integer>();
  
  players = new Player[isMouse ? 1:2 ];
  for(int i = 0; i < players.length; i++){
    players[i] = new Player(i);
  }
  
  home = new Home();
  
  try{
    bgm = minim.loadFile("bbtitle.mp3");
    bgm.loop();
  }catch(Exception e){}
  
  //*********↓各種グローバル変数初期化↓*************
  
  score = 0;
  choke = MAXchoke;
  isStop = false;
  alreadySend = false;
  
  isPlaying = false;
  soundstop = false;
  backspace = space = false;
  
  _reflect = _damaged = _bossappear = 0;
}

//*************************↓ループ関数↓***************************
void draw(){
  
  //座標の取得
  if(!isMouse)  kinect.update();
  
  //シーンごとの処理
  if(!isStop)  scener.update();
  
  //このフレームでまだsendしてないなら
  if(!alreadySend)  send();
  alreadySend = false;
  
  //server.sendScreen();
}

//パーティクル
void particledraw(){
  loadPixels();
  
   for(Bullet b: bullets){
     if(b.effect != null)  b.drawEffect();
   }
  
   for(int i = 0; i < pms.size(); i++){
     ParticleManager pm = pms.get(i);
     
     boolean isRemove = false;    //このParticleManagerを消すならtrue
     switch(pm.owner.charanum){
       case 5:
         Cannon c = (Cannon)pm.owner;
         
         isRemove = c.isDie || scener.scenenum >= 3;
         if(!isRemove)
           isRemove = pm.isChargeManager^c.isCharge;    //不一致ならtrue
         break;
       case 7:
         Boss b = (Boss)pm.owner;
         isRemove = !b.isCharge || b.isStan || scener.scenenum >= 5;
         break;
     }
     
     //オーナーがチャージ状態でない場合はパーティクルを消す
     if(isRemove){
       pms.remove(i);
       i--;
     }else{
       pm.update();
     }
   }
   
   updatePixels();
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

//*************************↓イベント処理・送信・受信↓***************************

void mousePressed(){
  if(isMouse)  players[0].ATflag = true;
}

void mouseReleased(){
  if(isMouse)  players[0].ATflag = false;
}

void keyPressed(){
  if(isMouse){
    switch(keyCode){
    
      case RIGHT:
        players[0].key = 1;
        break;
      case LEFT:
        players[0].key = 2;
        break;
    }
  }
  
  if(key == BACKSPACE && !backspace){
    allInitial();
    backspace = true;
    println("やり直し");
  }
  
  if(key == ENTER && scener.scenenum == 0)  scener.changeScene();
  
  if(key == ' ' && !space){
    if(!isStop)  isStop = true;
    else         isStop = false;
    space = true;
    println("一時停止");
  }
}

void keyReleased(){
  if(isMouse){
    switch(keyCode){
      case RIGHT:
      case LEFT:
        players[0].key = 0;
        break;
    }
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
  alreadySend = true;
}

//*************************↓終了時↓***************************

//スケッチ終了時に呼ばれる関数
void stop(){
  disposal.dispose();
  minim.stop();
  super.stop();
}

  