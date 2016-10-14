long score;
int choke;
int chokeMax = 11100;  //チョークの最大値  
int gageColorBlue = 0;  //ゲージの青成分 
boolean gageup = true;  //ゲージの増減

boolean dataDisplay = true;

public void getData(int _score, int _choke){
  score = _score;
  choke = _choke;
}

void UpdateNum(){
  //ゲージの点滅エフェクト
  if(gageColorBlue <= 0){
    gageup = true;
  }else if(gageColorBlue >= 255){
    gageup = false;
  }
  if(gageup == true){
    gageColorBlue += 5;
  }else{
    gageColorBlue -= 5;
  }
}

void DisplayNum(){
  //描画
  stroke(100,100,250);
  strokeWeight(5);
  
  fill(120,120,255);
  text("SCORE : " + score, 30, 70);
  text("CHOKE", 30, 30);
  
  fill(10,10,gageColorBlue, 200);
  rect(230,5,(width-240)*(float)choke/chokeMax,30);
}
