
class ScrollManager{
  
  float x, y;      //画面左上端の座標
  float vx, vy;    //スクロール速度
  PImage view;     //背景
  float viewx;     //画像のx座標
  float viewx2;    //画像のx座標2
  float m;         //画像の拡大倍率
  
  ScrollManager(){
    x = y = vy = 0;
    vx = 1;
    view = loadImage("space.jpg");
    
    m = 2;
    view.resize((int)(view.width*m), (int)(view.height*m));
    
    viewx = 0;
    viewx2 = view.width;
  }
  
  void move(){
    x += vx;
    
    viewx -= vx;
    viewx2 -= vx;
    
    if(viewx2 + view.width < 0 && width >= viewx + view.width)  viewx2 = viewx + view.width;
    if(viewx + view.width < 0 && width >= viewx2 + view.width)   viewx = viewx2 + view.width;
  }
  
  void drawView(){
    image(view, viewx, 0);
    image(view, viewx2, 0);
  }
}

class RandomCreate{
 
 
  
}












