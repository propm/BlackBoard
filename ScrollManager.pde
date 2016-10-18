//画面のスクロールを管理する
class ScrollManager{
  float vx, vy;    //スクロール速度
  PImage view;     //背景
  float viewx;     //画像のx座標
  float viewx2;    //画像のx座標2
  float m;         //画像の拡大倍率
  
  ScrollManager(){
    vy = 0;
    vx = 2 * db.scwhrate;
    view = loadImage("space.jpg");
    
    m = ceil(width/view.width);
    view.resize((int)(view.width*m*db.scwhrate), (int)(view.height*m*db.scwhrate));
    
    viewx = 0;
    viewx2 = view.width;
  }
  
  void update(){
    viewx -= vx;
    viewx2 -= vx;
    
    if(viewx2 + view.width <= 0 && width >= viewx + view.width)  viewx2 = viewx + view.width;
    if(viewx + view.width <= 0 && width >= viewx2 + view.width)  viewx = viewx2 + view.width;
  }
  
  void drawView(){
    image(view, (int)viewx, 0);
    image(view, (int)viewx2, 0);
  }
}