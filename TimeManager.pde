
class TimeManager{
  PriorityQueue<Datasaver> events;  //イベント
  int counter;                      //秒数をカウントする
  
  TimeManager(){
    counter = 0;
    events = new PriorityQueue<Datasaver>(3, new MyComparator());
  }
  
  void Add(Datasaver ds){
    events.add(ds);
  }
  
  //秒数ごとに指定されたことを実行
  void checksec(){
    if(events.size() > 0){
      
      //カウントがeventに入っている情報の秒数を越えたら、イベント（敵の発生、bgmの再生）を発生させる
      while(counter/60.0 >= events.peek().sec){
        Datasaver ds = events.poll();
          switch(rt.tags[ds.tag-1]){
            case "<appear>":
              checksecparts(ds);
              break;
            case "<bgm>":
              if(bgm != null)  bgm.close();
              bgm = minim.loadFile(ds.stringdata[0]);
              if(bgm != null)  bgm.loop();
              break;
          }
        if(events.size() == 0)  break;
      }
    }
    
    counter++;
  }
  
  //checksecの一部
  void checksecparts(Datasaver ds){
    if(ds.stringdata[0].equals("Attacker"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Attacker(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Attacker());
    if(ds.stringdata[0].equals("Sin"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Sin(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Sin(true));
    if(ds.stringdata[0].equals("Tangent"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Tangent(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Tangent());
    if(ds.stringdata[0].equals("Parachuter"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Parachuter(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Parachuter());
    if(ds.stringdata[0].equals("Cannon"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Cannon(ds.intdata[0], random(height)));
      else                                                    enemys.add(new Cannon());
    if(ds.stringdata[0].equals("Ninja"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Ninja(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Ninja());
  }
}

//Datasaverが入ったリストを並べ替えるためのクラス
class MyComparator implements Comparator<Datasaver>{
  public int compare(Datasaver a, Datasaver b){
    return a.sec - b.sec;
  }
}