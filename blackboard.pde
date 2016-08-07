import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;


ArrayList<Enemy> enemys;
Player player;
Home home;
ScrollManager sm;
ReadText rt;
Minim minim;
AudioPlayer bgm;
float widthrate, heightrate;

//効果音の敵種別ファイル名
String attacker_die, sin_die, tangent_die, parachuter_die;
String attacker_attack, sin_attack, tangent_attack, parachuter_attack;
String erase;

void setup(){
  size(1600, 800);
  
  minim = new Minim(this);
  enemys = new ArrayList<Enemy>();
  player = new Player();
  
  rt = new ReadText();
  rt.read();
  rt.readCommands();
  
  widthrate = 1600.0/width;
  heightrate = 800.0/height;
  
  sm = new ScrollManager();
  
  enemys.add(new Attacker());
  enemys.add(new Sin());
  enemys.add(new Tangent());
  enemys.add(new Parachuter());
  home = new Home();
}

void draw(){
  
  process();    //処理
  drawing();    //描画
}

//処理用関数
void process(){
  
  if(rt.counter%60 == 0)  println(rt.counter/60);
  rt.checksec();
  
  sm.move();
  
  //プレイヤーの動きの処理
  player.move();
  
  //敵の動きの処理
  for(int i = 0; i < enemys.size(); i++){
    Enemy enemy = enemys.get(i);
    
    if(enemy.dieflag){
      enemys.remove(i);
      i--;
    }
    
    enemy.move();
  }
}

//描画用関数
void drawing(){
  background(255);
  sm.drawView();
  
  //敵
  for(int i = 0; i < enemys.size(); i++){
    Enemy enemy = enemys.get(i);
    enemy.draw();
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

void setsound(String objectname, String command, String filename){
  
  if(objectname.equals("Attacker")){
    if(command.equals("die"))       attacker_die = filename;
    if(command.equals("attacked"))  attacker_attack = filename;
    
  }else if(objectname.equals("Sin")){
    if(command.equals("die"))       sin_die = filename;
    if(command.equals("attacked"))  sin_attack = filename;
    
  }else if(objectname.equals("Tangent")){
    if(command.equals("die"))       tangent_die = filename;
    if(command.equals("attacked"))  tangent_attack = filename;
    
  }else if(objectname.equals("Parachuter")){
    if(command.equals("die"))       parachuter_die = filename;
    if(command.equals("attacked"))  parachuter_attack = filename;
  }
}

void mousePressed(){
  player.attackflag = true;
}























