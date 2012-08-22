// Makes use of Arduino code and basic Galvanic Skin Response sensor
// as created by Che-Wei Wang for ITP studies, 2008
// http://cwwang.com/2008/04/13/gsr-reader/
// Inspired by http://theanthillsocial.co.uk/projects/biosensing

void setup(){
  Serial.begin(9600);
}
 
void loop(){
  int a=analogRead(5);
  if (Serial.available() > 0) {
    Serial.write
 
    byte inbyte=Serial.read();
    if(inbyte=='a'){
      Serial.write(a);
 
    }
  }
}
