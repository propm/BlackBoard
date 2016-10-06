import processing.opengl.*;
import codeanticode.syphon.*;  //Syphon用

SyphonServer server;

ArrayList<Circle> CircleList;

PFont myFont;

void setup(){
  size(1200,600, OPENGL);
  background(0);
  
  myFont = loadFont("Bradley.vlw"); //文字のフォントを設定

  textSize(30);
  textFont(myFont);

  CircleList = new ArrayList<Circle>();
  server = new SyphonServer(this, "BlackBoardFrame");
}

void draw(){
  update();  //数値の更新
  display();  //描画
  
  server.sendImage(g);  //Syphonで画面を送信  
}

void update(){
  UpdateBackground();
  UpdateNum();
}

void display(){
  DisplayBackground();
  UpdateCircle();
  DisplayNum();
}

void keyPressed(){
  if(key == 'A' || key == 'a'){
    CircleList.add(new Circle(width/2, height/2, 50));
  }else if(key == 's' || key == 'S'){
    red = 200;
  }else if(key == 'd' || key == 'D'){
    red = 250;
    grn = 250;
  }
  
}
