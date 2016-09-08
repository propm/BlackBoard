import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

ScrollManager sm;
ReadText rt;
DataBase db;
Minim minim;
AudioPlayer bgm;

ArrayList<MyObj> enemys;
ArrayList<Bullet> bullets;
Player player;
Home home;

void setup(){
  size(1600, 800);
  
  minim = new Minim(this);
  db = new DataBase();
  
  db.widthrate = 1600.0/width;
  db.heightrate = 800.0/height;
  
  sm = new ScrollManager();
  rt = new ReadText();
  db.setobjectnames();
  
  rt.read();
  rt.readCommands();
  db.setobjects();
  
  enemys = new ArrayList<MyObj>();
  bullets = new ArrayList<Bullet>();
  player = new Player();
  
  home = new Home();
}

void draw(){
  
  process();    //処理
  drawing();    //描画
}

//処理用関数
void process(){
  
  rt.checksec();
  sm.move();
  
  //プレイヤーの動きの処理
  player.move();
  
  //敵の動きの処理
  for(int i = 0; i < enemys.size(); i++){
    enemys.get(i).move();
    
    if(enemys.get(i).dieflag){
      enemys.remove(i);
      i--;
    }
  }
  
  //弾の処理
  for(int i = 0; i < bullets.size(); i++){
    bullets.get(i).move();
    
    if(bullets.get(i).dieflag){
      bullets.remove(i);
      i--;
    }
  }
}

//描画用関数
void drawing(){
  sm.drawView();
  
  //敵
  for(int i = 0; i < enemys.size(); i++){
    MyObj enemy = enemys.get(i);
    enemy.draw();
  }
  
  for(int i = 0; i < bullets.size(); i++){
    bullets.get(i).draw();
  }
  
  //プレイヤー
  noStroke();
  fill(255, 134, 0);
  player.draw();
  
  //自陣
  home.draw();
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























