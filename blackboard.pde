import oscP5.*;
import netP5.*;

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

Client myClient;

ArrayList<MyObj>     enemys;
ArrayList<Bullet>    bullets;
ArrayList<Wall>      walls;
ArrayList<Shuriken>  shurikens;
Player player;
Home home;

boolean isStop;
int score, choke;
int bscore, benergy;
final int maxEnergy = 11100;

void setup(){
  minim = new Minim(this);    //音楽・効果音用
  osc = new OscP5(this, 1234);
  address = new NetAddress("172.23.5.84", 1234);
  
  rt = new ReadText();
  db = new DataBase();        //データベース
  tm = new TimeManager();
  
  db.screenw = 1600;          //スクリーンwidth
  db.initial();
  
  //if(rt.check())  System.exit(0);
  rt.readCommands();
  db.screenh = (int)(db.screenw*db.boardrate);
  
  size(db.screenw, db.screenh);
  db.scwhrate = width/1600.0;
  
  sm = new ScrollManager();
  db.setobjects();
  
  enemys = new ArrayList<MyObj>();
  bullets = new ArrayList<Bullet>();
  walls = new ArrayList<Wall>();
  shurikens = new ArrayList<Shuriken>();
  
  
  
  player = new Player();
  
  home = new Home();
  
  //myClient = new Client(this, "172.23.6.216", 5204);
  
  score = choke = 0;
  isStop = false;
}

void draw(){
  process();    //処理
  drawing();    //描画
}

//処理用関数
void process(){
  bscore = score;
  benergy = choke;
  
  if(!isStop){
    tm.checksec();
    sm.update();
    
    //プレイヤーの動きの処理
    player.update();
    
    //敵の動きの処理
    for(int i = 0; i < enemys.size(); i++){
      enemys.get(i).update();
    }
    
    //弾の処理
    for(int i = 0; i < bullets.size(); i++){
      bullets.get(i).update();
    }
    
    for(int i = 0; i < shurikens.size(); i++){
      shurikens.get(i).update();
    }
    
    //壁の処理
    for(int i = 0; i < walls.size(); i++){
      walls.get(i).update();
    }
    
    //自陣の処理
    home.update();
    
    //死んだオブジェクトの処理
    cadaver(enemys);
    cadaver(bullets);
    cadaver(shurikens);
    
    if(bscore != score || benergy != choke)  println("score: "+score+"  choke: "+choke);    
    send();
  }           
}

//描画用関数
void drawing(){
  sm.drawView();
  
  //自陣
  home.draw();
  
  //敵
  for(int i = 0; i < enemys.size(); i++){
    MyObj enemy = enemys.get(i);
    enemy.draw();
  }
  
  for(int i = 0; i < bullets.size(); i++){
    Bullet bullet = bullets.get(i);
    bullet.draw();
  }
  
  for(int i = 0; i < shurikens.size(); i++){
    Shuriken s = shurikens.get(i);
    s.draw();
  }
  
  fill(255, 100, 100);
  for(int i = 0; i < walls.size(); i++){
    Wall wall = walls.get(i);
    wall.draw();
  }
  
  //プレイヤー
  fill(255, 134, 0);
  player.draw();

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

int score(MyObj e){
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
  
  if(key == ' ' ){
    if(!isStop)  isStop = true;
    else         isStop = false;
  }
}

void keyReleased(){
  switch(keyCode){
    case RIGHT:
    case LEFT:
      player.key = 0;
      break;
  }
}

int readInt(){
  int a = myClient.read();
  int b = myClient.read();
  int c = myClient.read();
  int d = myClient.read();
  int e = (a<<24)|(b<<16)|(c<<8)|d;
  return e;
}

void send(){
  OscMessage mes = new OscMessage("/text");
  mes.add(score);
  mes.add(choke);
  osc.send(mes, address);
}




















