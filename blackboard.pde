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
final int bosstime = 60;  //ボス戦が始まる時間

boolean firstinitial;
boolean backspace, space;    //backspace、spaceが押されている間true
boolean isStop;
boolean isDebag;             //デバッグモードならtrue
int score, choke;
int bscore, benergy;
int wholecount;      //道中が始まってからのカウント
int scene;            //1:タイトル　2:難易度選択　3:道中　4:ボス　5:スコア画面  6:ランキング
int debagcounter;    //どこが重いか確認する用
int combo;

void settings(){
  minim = new Minim(this);    //音楽・効果音用
  osc = new OscP5(this, 1234);
  address = new NetAddress("172.23.5.84", 1234);
  client = new Client(this, "172.23.6.216", 50005);
  
  rt = new ReadText();
  db = new DataBase();        //データベース
  tm = new TimeManager();
  
  db.screenw = 1600;          //スクリーンwidth
  db.initial();
  
  if(rt.check())  System.exit(0);
  rt.readCommands();
  db.screenh = (int)(db.screenw*db.boardrate);
  
  size(db.screenw, db.screenh);
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

void draw(){
  if(!isStop){
    process();    //処理
    drawing();    //描画
  }
}

//処理用関数
void process(){
  bscore = score;
  benergy = choke;
  wholecount++;
  
  switch(scene){
    case 3:
      if(wholecount >= bosstime){
        changeScene();
        process();
        break;
      }
    
      tm.checksec();
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
      
      //プレイヤーの動きの処理
      player.update();
      
      //自陣の処理
      home.update();
      
      //死んだオブジェクトの処理
      cadaver(enemys);
      cadaver(bullets);
      cadaver(walls);
        
      break;
      
    case 4:
      sm.update();
        
      //プレイヤーの動きの処理
      player.update();
        
      //弾の処理
      for(int i = 0; i < bullets.size(); i++){
        bullets.get(i).update();
      }
      
      //壁の処理
      for(int i = 0; i < walls.size(); i++){
        walls.get(i).update();
      }
      
      //ボスの処理
      boss.update();
      
      //自陣の処理
      home.update();
      
      //死体の処理
      cadaver(bullets);
      cadaver(walls);
      boss.cadaver();
      
      break;
    }
  
  if(bscore != score || benergy != choke)  println("score: "+score+"  choke: "+choke);    
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
  
  if(scene == 4){
    boss.draw();
  }else if(scene == 3){
    //敵
    for(int i = 0; i < enemys.size(); i++){
      Enemy enemy = enemys.get(i);
      enemy.draw();
    }
  }
  
  for(int i = 0; i < bullets.size(); i++){
    Bullet bullet = bullets.get(i);
    bullet.draw();
  }
  
  //プレイヤー
  fill(255, 134, 0);
  player.draw();

}

//やり直し
void allInitial(){
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
  wholecount = 0;
  combo = 0;
}

void changeScene(){
  scene++;
  switch(scene){
    case 4:
      boss = new Boss(width/8.0*7, height/2.0);
      for(int i = 0; i < enemys.size(); i++)
        enemys.remove(0);
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
  osc.send(mes, address);
}