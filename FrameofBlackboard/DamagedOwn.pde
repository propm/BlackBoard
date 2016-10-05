float red;  //背景の赤み

void UpdateDamaged(){
  //ダメージを受けたときの背景色の数値の処理
  if(red>=0){
    red -=(red*0.05);
  }
}

void DisplayDamaged(){
  //描画
  background(red,0,0,200);
}
