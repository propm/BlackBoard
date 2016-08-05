

ArrayList<Enemy> enemys;
Player player;
Home home;
ScrollManager sm;
ReadText rt;

void setup(){
  size(1600, 800);
  
  enemys = new ArrayList<Enemy>();
  player = new Player();
  
  sm = new ScrollManager();
  
  enemys.add(new Attacker(sm));
  enemys.add(new Sin(sm));
  enemys.add(new Tangent(sm));
  enemys.add(new Parachuter(sm));
  home = new Home(sm);
  
  rt = new ReadText();
  rt.read();
  rt.readCommands();
}

void draw(){
  
  process();    //処理
  drawing();    //描画
}

//処理用関数
void process(){
  
  sm.move();
  
  //プレイヤーの動きの処理
  player.move();
  
  //敵の動きの処理
  for(int i = 0; i < enemys.size(); i++){
    Enemy enemy = enemys.get(i);
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

void mousePressed(){
  player.attackflag = true;
}
























