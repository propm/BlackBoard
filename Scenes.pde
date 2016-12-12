
class SceneManager {
  final int[] times = {-1, 0, 60*60, -1, 60*60, -1, 60*10, 60*10};    //-1は時間制限なし
  final Scene[] scenes = {new Title(), new ChooseDifficulty(), new Battle(), new BossAppear(), 
                          new BossBattle(), new BossDestroy(), new Score(), new GameOver()};

  int framecounter;  //1フレームに1増える
  int time;          //次のシーンに入るまでの時間を入れる
  int scenenum;      //何番目のシーンか
  
  boolean countstop;
  
  Scene scene;  //現在のシーンを入れる
  Scene bscene; //前のシーンを入れる
  Scene score;
  
  void initial(){
    score = scenes[6];
    
    framecounter = 0;
    scenenum = 0;
    scene = scenes[scenenum];
    time = times[scenenum];
    scene.initial();
    
    countstop = false;
  }
  
  void update() {
    if(!countstop)  framecounter++;
    
    checkSceneTime();
    scene.process();
    scene.draw();
  }
  
  //時間によってシーン変更
  void checkSceneTime() {
    
    if(times[scenenum] == -1)  return;
    if(times[scenenum] <= framecounter){
      changeScene();
    }
  }
  
  //シーン変更
  void changeScene() {
    //スコアシーンかゲームオーバーシーンでシーン変更したなら、最初に戻す
    if (scene instanceof Score || scene instanceof GameOver) {
      allInitial();
      return;
    }
    
    bscene = scene;

    scenenum++;
    scene = scenes[scenenum];  //シーンと時間を更新
    time = times[scenenum];
    scene.initial();           //新しいシーンの初期化
    framecounter = 0;          //シーン用カウントの初期化
  }
  
  //gameoverにする
  void JumptoGameOver(){
    scenenum = 7;
    disposal.soundsclose();
    soundstop = true;
    changeScene();
  }
}

abstract class Scene {
  int time;  //次のシーンに移るまでのフレーム数

  abstract void initial();
  abstract void process();
  void draw(){
    //プレイヤー
    for(int i = 0; i < players.length; i++){
      fill(255, 134, 0);
      players[i].draw();
    }
  }
}

class Title extends Scene {
  MyObj title;

  @Override
  void initial() {
    title = db.title;
  }
  
  @Override void process() {
    for(int i = 0; i < players.length; i++)  players[i].update();
  }
  
  @Override void draw() {
    background(0);
    //タイトルの描画
    if(title != null){
      if(title.image != null){
        image(title.image, title.x, title.y);
        title.pol.Draw();
      }
    }
    
    super.draw();
  }
}

class ChooseDifficulty extends Scene{
  @Override void initial(){}
  @Override void process(){}
  @Override void draw()   {}
}

class Battle extends Scene {
  
  @Override void initial() {
    isPlaying = true;
  }
  
  @Override void process() {
    
    //他のプログラムに送る変数の処理
    _damaged--;
    _reflect--;
    _kill--;
    if(_reflect < 0)  _reflect = 0;
    if(_damaged < 0)  _damaged = 0;
    if(_kill < 0)  _kill = 0;
    
    //背景の更新
    scroller.update();
    
    //シーンによって処理が変わる
    plus();
    
    //敵の動きの処理
    for(int i = 0; i < enemys.size(); i++){
      enemys.get(i).update();
    }
    
    //弾の処理
    for(int i = 0; i < bullets.size(); i++){
      bullets.get(i).update();
    }
    
    //壁の処理
    for(int i = 0; i < walls.size(); i++){
      walls.get(i).update();
    }
    
    //プレイヤーの動きの処理
    for(int i = 0; i < players.length; i++)  players[i].update();
    
    //自陣の処理
    home.update();
    
    //死んだオブジェクトの処理
    disposal.cadaver(enemys);
    disposal.cadaver(bullets);
    disposal.cadaver(walls);
    if(boss != null)  boss.cadaver();
  }
  
  //シーンによってこの関数の中身を変える
  void plus(){
    tm.checksec();
  }
  
  @Override void draw() {
    scroller.drawView();
  
    //自陣
    home.draw();
    
    //壁
    fill(255, 100, 100);
    for(int i = 0; i < walls.size(); i++){
      Wall wall = walls.get(i);
      wall.draw();
    }
    
    //敵
    for(int i = 0; i < enemys.size(); i++){
      Enemy enemy = enemys.get(i);
      enemy.draw();
    }
    
    //弾
    for(int i = 0; i < bullets.size(); i++){
      Bullet bullet = bullets.get(i);
      bullet.draw();
    }
    
    if(boss != null)  boss.draw();
    
    particledraw();
    
    super.draw();
  }
}

class BossAppear extends Battle {
  
  @Override void initial() {
    _bossappear = 1;
    if (db.warning != null && !soundstop){
      db.warning.trigger();    //警戒音を鳴らす
    }
  }
  
  @Override void plus() {
    
    if(scener.framecounter == 60*3){
      _bossappear = 0;
      boss = new Boss(width/8.0*7, height/2.0);
      
      bgm.close();
      try{
        bgm = minim.loadFile("Exothermic-boss.wav");
      }catch(Exception e){}
      if(bgm != null)  bgm.loop();
    }
    
    if(boss != null)  boss.update();
  }
  
}

class BossBattle extends Battle {
  @Override void initial() {
    boss.bossscene = 1;
  }
  @Override void plus() {
    boss.update();
  }
  
}

class BossDestroy extends BossBattle {
  @Override void initial() {
    boss.bossscene = 2;
    bullets = new ArrayList<Bullet>();
    ((Score)scener.score).remaintime = scener.framecounter;
  }
  
}

class Score extends Scene {
  final int Scoretime  = 60*1;   //scoreの数字を何秒間変化させるか
  final int scorePertime = 5;    //残り時間1フレームあたり何点もらえるか
  final int scoremarginf = 10;   //スコアを表示するときの間の時間
  
  final String[] scoretext = {"敵撃破点: ", "残り時間ボーナス: ", "残りhpボーナス: ", "ボス撃破ボーナス: ", "合計: "};
  final int bossdestroyscore = 10000;       //ボス撃破ボーナス
  final int Scorem = 10;

  int[] Maxscore;       //各点数

  int remaintime;       //ボス面の残りタイム
  int scorecount;       //score表示用カウント
  int index;            //変化するスコアがどれか　scoretextに対応
  float[] exscore;      //表示するスコア
  float plusscore;      //1フレームで追加するスコア  各スコアごとに変更される

  boolean expressfinish;        //表示が終わったらtrue
  boolean isGameOver;           //ゲームオーバーならtrue

  //********************************
  
  //初期化
  @Override
  void initial() {
    boss = null;
    isGameOver = this instanceof GameOver;

    //表示するスコア（徐々に変化する）の初期化
    exscore = new float[scoretext.length];
    for (int i = 0; i < scoretext.length; i++) {
      exscore[i] = 0;
    }

    //scoreprocessでつかうカウントと最初にどのスコアを表示するかを初期化
    scorecount = 0;
    index = 0;

    Maxscore = new int[scoretext.length];
    Maxscore[0] = score * Scorem;                                            //敵・弾撃破スコア
    Maxscore[1] = scorePertime* (scener.times[4] - remaintime) * Scorem;            //残り時間
    Maxscore[2] = (int)(home.hp * 1/100.0) * Scorem;                                          //残りhp
    Maxscore[3] = Maxscore[1] != 0 ? bossdestroyscore*Scorem : 0;          //ボス撃破スコア
    Maxscore[4] = Maxscore[0]+Maxscore[1]+Maxscore[2]+Maxscore[3];  //合計

    plusscore = Maxscore[0]/Scoretime;

    expressfinish = false;

    score = Maxscore[4];    //scoreをボーナスも含めたスコアに更新する
    
    send();                //変更前のスコアを送る
    isPlaying = false;     //プレイ終了
    
    _bossappear = _kill = _damaged = _reflect = 0;
  }
  
  @Override
  void process(){
    
    for(int i = 0; i < players.length; i++)  players[i].update();
    
    if(!expressfinish)  gradual();
    
    scener.countstop = !expressfinish;  //スコア表示中は時間をカウントしない
  }
  
  //徐々にスコアを表示
  void gradual(){
  
    scorecount++;
    
    //if スコアを表示している最中 ?  表示するスコアの更新 : 表示したスコアの補正と次に表示するスコアの準備
    if (scorecount <= Scoretime) {
      exscore[index] += plusscore;         //表示するスコアの変更
    } else {
      if (exscore[index] != Maxscore[index])  exscore[index] = Maxscore[index];    //表示したいスコアと違っていたら戻す
      
      //スコアをすべて表示したら、そのことを保持し、終了
      if (index >= scoretext.length-1 || (isGameOver && index == 0)) {
        expressfinish = true;
        return;
      }

      index++;
      plusscore = (float)Maxscore[index]/Scoretime;                         //次のスコアの準備
      scorecount = 0;
    }
  }
  
  @Override 
  void draw(){
    plus();
    
    //左上にタイトルに戻るまでの秒数を表示
    if(expressfinish)  text((scener.times[scener.scenenum]- scener.framecounter)/60, (float)width/30*2, (float)height/10*2);
    super.draw();
  }
  
  void plus() {
    
    background(0);
    textSize(60);
    fill(255);
    
    //スコアを一つ一つ表示
    for(int i = 0; i <= index; i++){
      int a = i;
      if(i == scoretext.length-1)  a++;
      text(scoretext[i]+(int)exscore[i]+"pt", (int)((float)width/2), (int)((float)height/14*(a*2+3)));
    }
  }
  
}

class GameOver extends Score {
  
  int backalpha;       //徐々に暗くなってくときの不透明度
  
  boolean darkerfinish;    //暗くなるのが終わったらtrue
  Scene bscene;            //ゲームオーバーになる前のシーン
  
  @Override void initial() {
    backalpha = 0;
    isGameOver = false;
    darkerfinish = false;
    
    bscene = scener.bscene;
    
    super.initial();
  }
  
  @Override void process() {
    soundstop = true;                     //音を止める
    
    //暗くなった瞬間なら、暗くなったことを変数に持たせ、スコアの初期化
    if(backalpha == 256){
      darkerfinish = true;
      backalpha++;
    }
    
    //十分暗くなっているなら
    if(darkerfinish)   gradual();         //スコアの表示
    else               bscene.process();  //暗くなっている最中なら敵や弾を動かす
  }
  
  @Override void plus() {
    
    //if 徐々に暗くする or Gameoverと表示し、scoreを表示する
    if(backalpha <= 255){
      bscene.draw();
      fill(0, backalpha++);
      rect(0, 0, width, height);
    }else{
      background(0);
      fill(255);
      textSize(90);
      text("Game Over", width/2, height/14*5);
      textSize(60);
      text("score: "+(int)exscore[0], width/2, height/14*8);
    }
    
  }
}