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

Minim minim;
AudioPlayer bgm;

Client myClient;

ArrayList<MyObj>   enemys;
ArrayList<Bullet>  bullets;
ArrayList<Wall>    walls;
Player player;
Home home;

void setup(){
  rt = new ReadText();
  
  minim = new Minim(this);    //音楽・効果音用
  db = new DataBase();        //データベース
  
  db.screenw = 1600;          //スクリーンwidth
  
  tm = new TimeManager();
  db.setobjectnames();
  
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
  player = new Player();
  
  home = new Home();
  
  //myClient = new Client(this, "172.23.6.216", 5204);
}

void draw(){
  process();    //処理
  drawing();    //描画
}

//処理用関数
void process(){
  
  tm.checksec();
  sm.move();
  
  //プレイヤーの動きの処理
  player.move();
  
  //敵の動きの処理
  for(int i = 0; i < enemys.size(); i++){
    MyObj enemy = enemys.get(i);
    enemy.move();
    
    if(enemy.isDie){
      enemys.remove(i);
      i--;
    }
  }
  
  //弾の処理
  for(int i = 0; i < bullets.size(); i++){
    Bullet bullet = bullets.get(i);
    bullet.move();
    
    if(bullet.isDie){
      bullets.remove(i);
      i--;
    }
  }
  
  //壁の処理
  for(int i = 0; i < walls.size(); i++){
    Wall wall = walls.get(i);
    wall.die();
    
    if(wall.isDie){
      walls.remove(i);
      i--;
    }
  }
  
  //自陣の処理
  home.move();
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
  
  noStroke();
  fill(255, 100, 100);
  for(int i = 0; i < walls.size(); i++){
    Wall wall = walls.get(i);
    println(wall.x+", "+wall.y+" "+walls.size());
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
}

void keyReleased(){
  player.key = 0;
}

int readInt(){
  int a = myClient.read();
  int b = myClient.read();
  int c = myClient.read();
  int d = myClient.read();
  int e = (a<<24)|(b<<16)|(c<<8)|d;
  return e;
}



















