
import java.nio.ByteBuffer;

class KinectClient{
  Client Ly1client, Ly2client, Lz1client, Lz2client;
  float Ly1 = 0.0, Lz1 = 0.0, Ly2 = 0.0, Lz2 = 0.0;

  Client Ry1client, Ry2client, Rz1client, Rz2client;
  float Ry1 = 0.0, Rz1 = 0.0, Ry2 = 0.0, Rz2 = 0.0;

  String LIP;
  String RIP;
  
  PApplet This;
  
  KinectClient(PApplet This){
    this.This = This;
    initial();
  }
  
  void initial(){
    LIP = "172.23.9.217";
    RIP = "172.23.2.59";
    
    Ly1client = new Client(This, LIP, 50005);
    Ly2client = new Client(This, LIP, 60006);
    Lz1client = new Client(This, LIP, 40004);
    Lz2client = new Client(This, LIP, 30003);
    
    Ry1client = new Client(This, RIP, 50002);
    Ry2client = new Client(This, RIP, 60002);
    Rz1client = new Client(This, RIP, 40002);
    Rz2client = new Client(This, RIP, 30002);
  }
  
  void update(){
    GetLeft();
    GetRight();
  }
  
  float getX(int side){
    float rateX = 0;
    if(side == 0)       rateX = Lz1;
    else if(side == 1)  rateX = Rz1;
    else{
      println("引数が間違っています");
      return 0;
    }
    
    if(rateX <= 1.0){
      if(side == 0)       return (width*rateX)/2.0;
      else if(side == 1)  return (width*(1.0-rateX))/2.0 + width/2.0;
    }
    
    return -100;
  }
  
  float getY(int side){
    float rateY = 0;
    if(side == 0)       rateY = Ly1;
    else if(side == 1)  rateY = Ry1;
    else{
      println("引数が間違っています");
      return 0;
    }
    
    if(rateY <= 1.0)  return height*(1.0-rateY);
    else              return 0;
  }
  
  void GetLeft(){
    while(Ly1client.available() +Ly2client.available() +Lz1client.available() +Lz2client.available() >=24){
      
      if(Ly1client.available() >= 4)
        Ly1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly1client.readBytes(4)).getInt())/10000.0;
     
      if(Ly2client.available() >= 4)
        Ly2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly2client.readBytes(4)).getInt())/10000.0;
     
      if(Lz1client.available() >= 4)
        Lz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz1client.readBytes(4)).getInt())/10000.0;
     
     if(Lz2client.available() >= 4)
        Lz2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz2client.readBytes(4)).getInt())/10000.0;
    }
  }

  void GetRight(){
    while(Ry1client.available()+ Ry2client.available() +Rz1client.available()+Rz2client.available() >=24){
      
      if(Ry1client.available() >= 4)
        Ry1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry1client.readBytes(4)).getInt())/10000.0;
      
      if(Ry2client.available() >= 4)
        Ry2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry2client.readBytes(4)).getInt())/10000.0;
      
      if(Rz1client.available() >= 4)
        Rz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz1client.readBytes(4)).getInt())/10000.0;
      
      if(Rz2client.available() >= 4)
        Rz2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz2client.readBytes(4)).getInt())/10000.0;
    }
  }
}
  