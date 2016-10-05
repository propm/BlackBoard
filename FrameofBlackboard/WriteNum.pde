int score,choke;

void UpdateNum(){
  //数値の更新
  score = 0;
  choke = 0;
}

void DisplayNum(){
  //描画
  text("SCORE : " + score, 30, 30);
  text("CHOKE : " + choke, 30, 60);
}
