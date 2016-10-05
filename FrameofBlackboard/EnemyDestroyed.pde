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

class Circle{
  float x,y,speed;
  public float elx=0;
  public float ely=0;
  
  Circle(float _x, float _y, float _speed){
    x = _x;
    y = _y;
    speed = _speed;
  }
  
  void update(){
    elx += speed;
    ely += speed;
  }
  
  void display(){
    noFill();
    stroke(100,100,250);
    strokeWeight(5);
    ellipse(x, y, elx, ely);
  }
  
  float getElx(){
    return elx;
  }
}
    
