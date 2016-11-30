
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
    
    if(!isTwoKinect){
      if(isKinectLeft)  RIP = LIP;
      else              LIP = RIP;
    }
    
    Ly1client = new Client(This, LIP, 50005);
    Lz1client = new Client(This, LIP, 40004);
    
    Ry1client = new Client(This, RIP, 50002);
    Rz1client = new Client(This, RIP, 40002);
  }
  
  void update(){
    GetLeft();
    GetRight();
  }
  
  float getX(int side){
    float rateX = 0;
    float result = 0;
    if(side == 0)       rateX = Lz1;
    else if(side == 1)  rateX = Rz1;
    else{
      println("引数が間違っています");
      
      return result;
    }
    
    if(rateX <= 1.0){
      if((isTwoKinect && side == 0) || (!isTwoKinect && isKinectLeft))  result = (width*rateX)/2.0;
      else                          result = (width*(1.0-rateX))/2.0;
      
      if(isTwoKinect && side == 1)  result += width/2;
    }else{
      result = -100;
    }
    
    return result;
  }
  
  float getY(int side){
    float rateY = 0;
    float result = 0;
    if(side == 0)       rateY = Ly1;
    else if(side == 1)  rateY = Ry1;
    else{
      println("引数が間違っています");
      return result;
    }
    
    if(rateY <= 1.0)  result = height*(1.0-rateY);
    else              result = 0;
    
    return result;
  }
  
  void GetLeft(){
    while(Ly1client.available() + Lz1client.available() >=8){
      
      if(Ly1client.available() >= 4)
        Ly1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly1client.readBytes(4)).getInt())/10000.0;
      
      if(Lz1client.available() >= 4)
        Lz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz1client.readBytes(4)).getInt())/10000.0;
    }
  }

  void GetRight(){
    while(Ry1client.available() + Rz1client.available() >=8){
      
      if(Ry1client.available() >= 4)
        Ry1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry1client.readBytes(4)).getInt())/10000.0;
        
      if(Rz1client.available() >= 4)
        Rz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz1client.readBytes(4)).getInt())/10000.0;
    }
  }
}
  