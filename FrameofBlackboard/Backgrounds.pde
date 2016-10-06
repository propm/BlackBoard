float red,grn,ble;  //背景色

void UpdateBackground(){
  //ダメージを受けたときの背景色の数値の処理
  if(red>=0 && grn <= 0 && ble <= 0){
    red -=(red*0.05);
  }
  if(red>=0 && grn>= 0 && ble <= 0){
      red-=(red*0.04);
      grn-=(grn*0.04);//エフェクトの持続時間
  }
}

void DisplayBackground(){
  //描画
  background(red,grn,ble,200);
}
