
import java.nio.ByteBuffer;

/*class KinectClient{
  Client Ly1client, Ly2client, Lz1client, Lz2client;
  float Ly1 = 0.0,Lz1 = 0.0, Ly2 = 0.0,Lz2 = 0.0;

  Client Ry1client,Ry2client,Rz1client,Rz2client;
  float Ry1 = 0.0,Rz1 = 0.0, Ry2 = 0.0,Rz2 = 0.0;

  String LIP;
  String RIP ;
  
  //kinecttest ... 参照元のクラス名
  Object WhereThis;
  
  KinectClient(Object _WhereThis){
    WhereThis = _WhereThis;
    init();
    
  }
  
  void init(){
    LIP = "10.0.1.204";
    RIP = "10.0.1.186";
    
    Ly1client = new Client(WhereThis, LIP, 50005);
    Ly2client = new Client(WhereThis, LIP, 60006);
    Lz1client = new Client(WhereThis, LIP, 40004);
    Lz2client = new Client(WhereThis, LIP, 30003);
    
    Ry1client = new Client(WhereThis, RIP, 50002);
    Ry2client = new Client(WhereThis, RIP, 60002);
    Rz1client = new Client(WhereThis, RIP, 40002);
    Rz2client = new Client(WhereThis, RIP, 30002);
    
  }
  
  
  void update(){
    GetLeft();
    GetRight();
  }
  
  float GetLeftPositionX(){
    if(Lz1 <= 1.0){
      return (width*Lz1)/2.0;
    }else{
      return 0;
    }
  }
  
  float GetLeftPositionY(){
    if(Lz1 <= 1.0){
      return height*(1.0-Ly1);
    }else{
      return 0;
    }
  }
  
  float GetRightPositionX(){
    if(Lz1 <= 1.0){
      return width-(width*Rz1)/2;
    }else{
      return 0;
    }
  }
  
  float GetRightPositionY(){
    if(Lz1 <= 1.0){
      return height*(1.0-Ry1);
    }else{
      return 0;
    }
  }
  
  
  
  void GetLeft(){
    if(Ly1client.available() >= 4){
      Ly1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly1client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Ly2client.available() >= 4){
      Ly2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ly2client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Lz1client.available() >= 4){
      Lz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz1client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Lz2client.available() >= 4){
      Lz2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Lz2client.readBytes(4)).getInt())/10000.0;
    }
    
  }
  
  void GetRight(){
    if(Ry1client.available() >= 4){
      Ry1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry1client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Ry2client.available() >= 4){
      Ry2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Ry2client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Rz1client.available() >= 4){
      Rz1 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz1client.readBytes(4)).getInt())/10000.0;
    }
      
    if(Rz2client.available() >= 4){
      Rz2 = (float)Integer.reverseBytes(ByteBuffer.wrap(Rz2client.readBytes(4)).getInt())/10000.0;
    }
    
  }
}

*/
  