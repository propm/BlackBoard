//背景色に関係するプログラム

float red,grn,ble;  //背景色

void UpdateBackground(){
  //ダメージを受けたとき
  if(red>=0 && grn <= 0 && ble <= 0){
    red -=(red*0.05);
  }
  //反射した時
  if(red>=0 && grn>= 0 && ble <= 0){
      red-=(red*0.04);
      grn-=(grn*0.04);//エフェクトの持続時間
  }
}

void DisplayBackground(){
  //描画
  background(red,grn,ble,200);
}
