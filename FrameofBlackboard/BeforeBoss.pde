float a;

class Line {
  int x;

  Line(int _x) {
    x= _x;
  }

  void Draw() {
    strokeWeight(35);
    line(x, 0 - 50, x-width/3, height + 100);
  }

  boolean Move() {
    x--;
    if (x+width/12 < 0) return true;
    return false;
  }
}  

void bossDisplay(){
  stroke(abs(int(sin(a)*255)), abs(int(sin(a)*255)), 0);
  a+=0.06;
  if(keyPressed){
    if(beforeboss != 0){
      dataDisplay = false;
      for (int i = 0; i < lines.size(); i++) {
        Line now = lines.get(i);
        now.Draw();
        if (now.Move())
        {
          lines.remove(i);
        }
      }
    }
  }else{
    dataDisplay = true;
    }
}

  