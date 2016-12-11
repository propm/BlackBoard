
//後処理用クラス
class Disposal{
  
  //死んだオブジェクトの処理
  void cadaver(ArrayList<?> obj){
    for(int i = 0; i < obj.size(); i++){
      MyObj o = (MyObj)obj.get(i);
      o.die();
      
      //死んでいるなら参照削除
      if(o.isDie){
        if(o.die != null){
          dies.add(o.die);        //死ぬときの音を保持、音がcloseされるまでを数えるカウントをセット
          diescount.add(0);
        }
        o.soundclose();
        obj.remove(i);
        i--;
      }
    }
    
    //死ぬ音の処理
    for(int i = 0; i < dies.size(); i++){
      diescount.set(i, diescount.get(i)+1);
      if(diescount.get(i) > dietime){
        dies.get(i).close();
        dies.remove(i);
        diescount.remove(i);
        i--;
      }
    }
  }
  
  void dispose(){
    soundsclose();
    
    if(boss != null)  boss = null;
    if(home != null)  home = null;
    if(players != null)  players = null;
    if(enemys != null)  enemys = null;
    if(walls != null)   walls = null;
    if(bullets != null)  bullets = null;
  }
  
  //音を止める
  void soundsclose(){
    if(enemys != null)
      for(int i = 0; i < enemys.size(); i++){
        enemys.get(i).soundclose();
      }
    
    if(walls != null)
      for(int i = 0; i < walls.size(); i++){
        walls.get(i).soundclose();
      }
    
    if(bullets != null)
      for(int i = 0; i < bullets.size(); i++){
        bullets.get(i).soundclose();
      }
    
    if(boss != null)  boss.soundclose();
    if(players != null)
      for(int i = 0; i < players.length; i++)
        if(players != null)  players[i].soundclose();
      
    if(home != null)  home.soundclose();
    soundstop = true;
    if(bgm != null)  bgm.close();
  }
}