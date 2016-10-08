void UpdateCircle(){
  //敵を倒したときの円の描画
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
  public float elx=0; //円の横幅
  public float ely=0;  //円の縦幅
  final int r = 100;  //円の色
  final int g = 100;
  final int b = 250;
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
    strokeWeight(1);
    for(int i = -30;i < 0; i++){
      stroke(r + i*5,g + i*5,b + i*5);
      ellipse(x, y, elx + i*3, ely + i*3);
    }
  }
  
  float getElx(){
    return elx;
  }
}
    
