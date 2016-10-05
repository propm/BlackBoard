float red;

void UpdateDamaged(){
  if(red>=0){
    red -=(red*0.05);
  }
}

void DisplayDamaged(){
  background(red,0,0,200);
}
