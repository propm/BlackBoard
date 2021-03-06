//戦闘時に時間によってイベントを発生させる
class TimeManager{
  PriorityQueue<Datasaver> events;       //イベント（一度入れられたら中身は減らない）
  PriorityQueue<Datasaver> events_copy;  //実際に使われるイベントのリスト（中身は減る）
  
  int counter;                      //秒数をカウントする
  
  TimeManager(){
    events = new PriorityQueue<Datasaver>(3, new Datasaver().new MyComparator());
  }
  
  void Add(Datasaver ds){
    events.add(ds);
  }
  
  //イベントのコピーを作成
  void copy(){
    counter = 0;
    events_copy = new PriorityQueue(events);
  }
  
  //秒数ごとに指定されたことを実行
  void checksec(){
    if(events_copy.size() > 0){
      
      //カウントがeventに入っている情報の秒数を越えたら、イベント（敵の発生、bgmの再生）を発生させる
      while(counter/60.0 >= events_copy.peek().sec){
        Datasaver ds = events_copy.poll();
          switch(rt.tags[ds.tag-1]){
            case "<appear>":
              checksecparts(ds);
              break;
            case "<bgm>":
              if(bgm != null)  bgm.close();
              bgm = minim.loadFile(ds.stringdata);
              if(bgm != null){
                bgm.loop();
                bgm.setGain(-8);
              }
              break;
          }
        if(events_copy.size() == 0)  break;
      }
    }
    
    counter++;
  }
  
  //checksecの一部
  void checksecparts(Datasaver ds){
    if(ds.stringdata.equals("Attacker"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Attacker(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Attacker());
    if(ds.stringdata.equals("Sin"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Sin(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Sin(true));
    if(ds.stringdata.equals("Tangent"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Tangent(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Tangent());
    if(ds.stringdata.equals("Parachuter"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Parachuter(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Parachuter());
    if(ds.stringdata.equals("Cannon"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Cannon(ds.intdata[0], random(height)));
      else                                                    enemys.add(new Cannon());
    if(ds.stringdata.equals("Ninja"))
      if(ds.intdata[0] != -10000 && ds.intdata[1] != -10000)  enemys.add(new Ninja(ds.intdata[0], ds.intdata[1]));
      else                                                    enemys.add(new Ninja());
  }
}