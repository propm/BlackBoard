import oscP5.*;
import netP5.*;
import processing.opengl.*;
import codeanticode.syphon.*;  //Syphon用


OscP5 osc;
NetAddress address;
OscMessage message;

SyphonServer server;

ArrayList<Circle> CircleList;
ArrayList<Line> lines;

PFont myFont;

int reflected,damaged,killed,beforeboss;

void settings(){
  size(1200,600, P3D);
  PJOGL.profile = 1;
}

void setup(){
  
  background(0);
  
  myFont = loadFont("Bradley.vlw"); //文字のフォントを設定

  textSize(30);
  textFont(myFont);
  
  osc = new OscP5(this, 1234);
  
  osc.plug(this,"getData","/text");
  
  lines = new ArrayList<Line> ();
  
  CircleList = new ArrayList<Circle>();
  
  server = new SyphonServer(this, "BlackBoardFrame");
  
  for (int i = 0; i < 80; i++)
  {
    lines.add(new Line(80*i));
  }
}

void draw(){
  update();  //数値の更新
  display();  //描画
  
  server.sendImage(g);  //Syphonで画面を送信  
}

void update(){
  CheckData();
  UpdateBackground();
  UpdateNum();
}

void display(){
  DisplayBackground();
  UpdateCircle();
  DisplayNum();
  bossDisplay();
  
  println(damaged);
}

public void getData(int _score, int _choke, int _hp,int _reflected, int _damaged,int _killed, int _beforeboss){
  score = _score;
  choke = _choke;
  hp = _hp;
  reflected = _reflected;
  damaged = _damaged;
  killed = _killed;
  beforeboss = _beforeboss;
  
}

void CheckData(){
  if(killed != 0){
    CircleList.add(new Circle(width/2, height/2, 50));
  }else if(damaged != 0){
    red = 200;
  }else if(reflected != 0){
    red = 250;
    grn = 250;
  }
}


  