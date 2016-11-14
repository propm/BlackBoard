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

Minim       minim;
AudioPlayer bgm;
OscP5       osc;
NetAddress address;

Client client;
KinectClient kinect;
//SyphonServer server;

ArrayList<Enemy>     enemys;    //敵
ArrayList<Bullet>    bullets;   //弾
ArrayList<Wall>      walls;     //壁
ArrayList<AudioSample> dies;    //死ぬときの音を一時的に保持し、数秒後にclose()するためのもの
ArrayList<Integer> diescount;   //死ぬときの音がcloseされるまでカウントする
Boss boss;
Player[] player;
Home home;
MyObj title;

final int MAXchoke = 11100;
final int[] times = {-1, -1, 60*60, -1, 60*60, -1, 60*20, 60*18};    //sceneと対応　　　-1は時間制限なし
final int sendframes = 2;      //_bossappearなどの変数の中身を外部プログラムに送るときの信号の長さ
final int Scoretime  = 60*1;   //scoreの数字を何秒間変化させるか
final int scorePertime = 5;    //残り時間1フレームあたり何点もらえるか
final int scoremarginf = 10;   //スコアを表示するときの間の時間
final int dietime = 60*2;      //dieが鳴る時間の長さ
final boolean isMouse = true;    //mouseでプレイヤーを操作するときはtrue
final boolean isDebag = true;    //デバッグモードならtrue

boolean firstinitial;
boolean backspace, space;    //backspace、spaceが押されている間true
boolean isStop;
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
  
  if(!isMouse)  kinect = new KinectClient(this);
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
  
  //一回目以外
  if(!firstinitial){
    stop(true);
    tm = new TimeManager();    //sizeを変更するのがsettingの中でしかできないため、1回目はallInitialにいれることができない
    rt.readCommands();
  }else{
    firstinitial = false;
  }
  
  sm = new ScrollManager();
  
  enemys = new ArrayList<Enemy>();
  bullets = new ArrayList<Bullet>();
  walls = new ArrayList<Wall>();
  dies = new ArrayList<AudioSample>();
  diescount = new ArrayList<Integer>();
  
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
  if(!isMouse)  kinect.update();
  
  //ゲームオーバーになったときに、シーンを変更する
  if(isGameOver && gameoveronce){
    gameoveronce = false;
    scene = 8;
    wholecount = 0;
    time = times[scene-1];
    soundsclose();
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
  
  //バトル中以外のプレイヤーの更新
  if(scene < 3 || scene > 6)  for(int i = 0; i < player.length; i++)  player[i].update();
  
  switch(scene){
    
    //難易度変更（欠番）
    case 2:
      changeScene();  //シーン変更
      break;
      
    //道中
    case 3:
      tm.checksec();  //秒数に応じて敵の追加
    
    //ボス
    case 4:
    case 5:
    case 6:
      battle();
      break;
      
    //スコア表示
    case 7:
      if(!expressfinish)  scoreprocess();
      else{
        score = 0;
        for(int i = 0; i < scoretext.length; i++)
          score += Maxscore[i];
        send();
      }
      break;
      
    //ゲームオーバー
    case 8:
      soundstop = true;             //音を止める
      if(!darkerfinish)  battle();  //暗くなっている最中なら敵や弾を動かす
      
      //暗くなった瞬間なら、暗くなったことを変数に持たせ、スコアの初期化
      if(backalpha == 256){
        darkerfinish = true;
        scoreinitial();
        backalpha++;
      }
      
      //十分暗くなっているなら
      if(darkerfinish){
        scoreprocess();    //スコアの表示
      }
      break;
  }
  
  //このフレームでまだsendしてないなら
  if(sendable)  send();
  
  sendable = true;
}

//描画用関数
void drawing(){
  
  switch(scene){
    
    //タイトル
    case 1:
      background(0);
      //タイトルの描画
      if(title != null)
        if(title.image != null){
          image(title.image, title.x, title.y);
          title.pol.Draw();
        }
      break;
    
    //難易度選択（欠番）
    case 2:
      break;
    
    //道中・ボス
    case 3:
    case 4:
    case 5:
    case 6:
      buttledraw();
      if(boss != null)  boss.draw();
      break;
      
    //スコア画面
    case 7:
      background(0);
      textSize(60);
      fill(255);
      for(int i = 0; i <= vsn; i++){
        int a = i;
        if(i == scoretext.length-1)  a++;
        if(isGameOver && i >= 1)  continue;
        text(scoretext[i]+(int)exscore[i]+"pt", (int)((float)width/2), (int)((float)height/14*(a*2+3)));
      }
      
      text((times[scene-1]- wholecount)/60, (float)width/30*2, (float)height/10*2);
      break;
   
    //ゲームオーバー
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
   
   //弾
   for(int i = 0; i < bullets.size(); i++){
     Bullet bullet = bullets.get(i);
     bullet.draw();
   }
}

//ゲームオーバー時の表示
void gameoverdraw(){
  
  //if 徐々に暗くする or Gameoverと表示し、scoreを表示する
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

//戦闘　    該当シーン：道中、ボス出現、ボス、ボス破滅
void battle(){
  bscore = score;
  benergy = choke;
  _damaged--;
  _reflect--;
  _kill--;
  if(_reflect < 0)  _reflect = 0;
  if(_damaged < 0)  _damaged = 0;
  if(_kill < 0)  _kill = 0;
  
  //背景の更新
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


//******スコア用変数・定数群*******
final String[] scoretext = {"敵撃破点: ", "残り時間ボーナス: ", "残りhpボーナス: ", "ボス撃破ボーナス: ", "合計: "};
final int bossdestroyscore = 10000;       //ボス撃破ボーナス

int[] Maxscore;       //各点数

int remaintime;       //ボス面の残りタイム
int scorecount;       //score表示用カウント
int vsn;              //変化するスコアがどれか　scoretextに対応
float[] exscore;      //表示するスコア
float plusscore;      //1フレームで追加するスコア  各スコアごとに変更される

boolean scorescrollfinish;    //スクロールが終わっていたらtrue
boolean expressfinish;        //表示が終わったらtrue

//*********************************

//スコア表示の処理
void scoreprocess(){
  scorecount++;
  
  //if スコアを表示している最中 ?  表示するスコアの更新 : 表示したスコアの補正と次に表示するスコアの準備
  if(scorecount <= Scoretime){
    exscore[vsn] += plusscore;         //表示するスコアの変更
  }else{
    if(exscore[vsn] != Maxscore[vsn])  exscore[vsn] = Maxscore[vsn];    //表示したいスコアと違っていたら戻す
    
    //スコアをすべて表示したら、そのことを保持し、終了
    if(vsn >= scoretext.length-1){
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
  
  //スコアシーンでシーン変更したなら、最初に戻す
  if(scene >= times.length-1){
    allInitial();
    scene--;
  }
  
  scene++; //<>//
  time = times[scene-1];  //次のシーンまでの時間を更新
  
  switch(scene){
    
    //道中
    case 3:
      isPlaying = true;
      break;
    
    //ボス出現
    case 4:
      _bossappear = 1;
      if(db.warning != null && !soundstop)  db.warning.trigger();    //警戒音を鳴らす
      
      break;
    
    //ボス面
    case 5:
      boss.bossscene = 1;
      break;
      
    case 6:
      boss.bossscene = 2;
      bullets = new ArrayList<Bullet>();
      remaintime = wholecount;
      break;
      
    //スコア表示画面
    case 7:
      boss = null;
      scoreinitial();
      send();                //変更前のスコアを送る
      isPlaying = false;     //プレイ終了
      
      _bossappear = _kill = _damaged = _reflect = 0;
      break;
  }
  
  wholecount = 0;    //シーン用カウントの初期化
}

//スコア系初期化
void scoreinitial(){
  
  //表示するスコア（徐々に変化する）の初期化
  exscore = new float[scoretext.length];
  for(int i = 0; i < scoretext.length; i++){
    exscore[i] = 0;
  }
  
  //scoreprocessでつかうカウントと最初にどのスコアを表示するかを初期化
  scorecount = 0;
  vsn = 0;
  
  Maxscore = new int[scoretext.length];
  Maxscore[0] = score;                                            //敵・弾撃破スコア
  Maxscore[1] = scorePertime* (times[4] - remaintime);            //残り時間
  Maxscore[2] = home.hp;                                          //残りhp
  Maxscore[3] = bossdestroyscore;                                 //ボス撃破スコア
  Maxscore[4] = Maxscore[0]+Maxscore[1]+Maxscore[2]+Maxscore[3];  //合計
  
  //for(int i = 0; i < Maxscore.length; i++)
    //plusscore[i] = (float)Maxscore[i]/Scoretime;
  
  plusscore = (float)score/Scoretime;
  
  expressfinish = false;
  
  score = Maxscore[4];    //scoreをボーナスも含めたスコアにする
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
    
    //死んでいるなら参照削除
    if(o.isDie){
      if(o.die != null){
        dies.add(o.die);        //死ぬときの音を保持、音がcloseされるまでを数えるカウントをセット
        diescount.add(0);
      }
      o.soundclose();
      obj.remove(i);
      i--;
    }
  }
  
  //死ぬ音の処理
  for(int i = 0; i < dies.size(); i++){
    diescount.set(i, diescount.get(i)+1);
    if(diescount.get(i) > dietime){
      dies.get(i).close();
      dies.remove(i);
      diescount.remove(i);
      i--;
    }
  }
}

//*************************↓イベント処理・送信・受信↓***************************

void mousePressed(){
  if(isMouse)  player[0].ATflag = true;
}

void mouseReleased(){
  if(isMouse)  player[0].ATflag = false;
}

void keyPressed(){
  if(isMouse){
    switch(keyCode){
    
      case RIGHT:
        player[0].key = 1;
        break;
      case LEFT:
        player[0].key = 2;
        break;
    }
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
  if(isMouse){
    switch(keyCode){
      case RIGHT:
      case LEFT:
        player[0].key = 0;
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
  sendable = false;
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
  if(boss != null)  boss = null;
  if(home != null)  home = null;
  if(player != null)  player = null;
  if(enemys != null)  enemys = null;
  if(walls != null)   walls = null;
  if(bullets != null)  bullets = null;
  
  soundsclose();
}

//音を止める
void soundsclose(){
  if(enemys != null)
    for(int i = 0; i < enemys.size(); i++){
      enemys.get(i).soundclose();
    }
  
  if(walls != null)
    for(int i = 0; i < walls.size(); i++){
      walls.get(i).soundclose();
    }
  
  if(bullets != null)
    for(int i = 0; i < bullets.size(); i++){
      bullets.get(i).soundclose();
    }
  
  if(boss != null)  boss.soundclose();
  if(player != null)
    for(int i = 0; i < player.length; i++)
      if(player != null)  player[i].soundclose();
    
  if(home != null)  home.soundclose();
}

  