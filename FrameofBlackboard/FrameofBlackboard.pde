import processing.opengl.*;
import codeanticode.syphon.*;

SyphonServer server;

ArrayList<Circle> CircleList;

void setup(){
  size(1200,600, OPENGL);
  background(0);
  
  textSize(30);
  
  CircleList = new ArrayList<Circle>();
  server = new SyphonServer(this, "BlackBoardFrame");
}

void draw(){
  update();
  display();
  
  server.sendImage(g);
}

void update(){
  UpdateDamaged();
  UpdateNum();
}

void display(){
  DisplayDamaged();
  UpdateCircle();
  DisplayNum();
}

void keyPressed(){
  if(key == 'A' || key == 'a'){
    CircleList.add(new Circle(width/2, height/2, 50));
  }else if(key == 's' || key == 'S'){
    red = 200;
  }
  
}
