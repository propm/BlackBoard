import processing.opengl.*;
import codeanticode.syphon.*;

SyphonServer server;

ArrayList<Circle> CircleList;

float red;

void setup(){
  size(1200,600, OPENGL);
  background(0);
  
  CircleList = new ArrayList<Circle>();
  server = new SyphonServer(this, "BlackBoardFrame");
}

void draw(){
  DamagedOwn();
  UpdateCircle();
  
  server.sendImage(g);
}


void UpdateCircle(){
  for(int i=0;i < CircleList.size();i++){
    if(CircleList.get(i).getElx() > width * 2){
      CircleList.remove(i);
      i--;
    }else{
      CircleList.get(i).update();
      CircleList.get(i).display();
    }
  }
}

void DamagedOwn(){
  if(red>=0){
    red -=(red*0.05);
  }
  
  background(red,0,0,200);
}

void keyPressed(){
  if(key == 'A' || key == 'a'){
    CircleList.add(new Circle(width/2, height/2, 20));
  }else if(key == 's' || key == 'S'){
    red = 200;
  }
  
}
