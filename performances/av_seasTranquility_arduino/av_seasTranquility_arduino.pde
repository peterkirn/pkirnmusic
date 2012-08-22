import processing.opengl.*;

import com.noisepages.nettoyeur.processing.*;
import processing.serial.*;

Serial mPort;

float currReading, lastReading, gsrAverage, prevGsrAverage;
int gsrValue, gsrZeroCount;
float baseLine=0;
long lastFlatLine=0;
int baselineTimer=10000;
boolean go, gogo, sawed;
long goTime;
PureDataP5Jack pd;

float[] graphArray = new float[300];


void setup() {
  size(1440, 900, OPENGL);
  noCursor();
  mPort = new Serial(this, Serial.list()[0], 9600);
  currReading = 0;
  lastReading = 0;
  gsrAverage = 0;
  //smooth();
  background(0);

  pd = new PureDataP5Jack(this, 0, 2, "system", "system");
  pd.openPatch(dataFile("bio.pd"));
  pd.subscribe("timeSymbol");
  pd.subscribe("currFreq");
  pd.start();
  rectMode(CENTER);
  go = true;
  gogo = true;
  pd.sendBang("go");
}

void draw() {
  int s = round(millis()/1000);
  println(s);
  background(0);
  noStroke();
  rectMode(CORNER);
  rect(0, 0, width, height);
  rectMode(CENTER);
  delay(50);
  fill(255);
  println("gsr: " + gsrValue + " / ave : " + gsrAverage + " / curr " + currReading + " / flat " + lastFlatLine);
  if (gsrValue<15 && gsrValue>-15) {
    if (gsrZeroCount>10) {
      currReading = 0;
      gsrAverage = 0;
      baseLine = 0;
      lastFlatLine = millis();
      gsrZeroCount = 0;
    }
    gsrZeroCount++;
  }
  else {
    currReading=gsrValue-baseLine;
    gsrZeroCount=0;
  }
  if (millis()-lastFlatLine>baselineTimer) {
    baseLine=gsrAverage;
  }
  gsrAverage=smooth(currReading, .97, gsrAverage);


  mPort.write('a');
  float freq, freq2;
  if (gsrValue == 0) {
    freq = 0;
  } 
  else {
    freq = 100 + (gsrValue*2);
    freq2 = 50 + gsrValue*2;
  }
  //println(freq);

  if (gogo) {

    pd.sendFloat("freq", freq+200+random(-10, 10));
    pd.sendFloat("freq2", freq);
  }
  float spread = 0;
  float spread2 = 0;
  if (gsrAverage > 15) {
    spread = map(gsrAverage, 0, 100, 0.1, 500);
    spread2 = map(gsrAverage, 0, 100, 400, 0.1);
  } 
  else {
    spread = 0.1;
  }
  if (gogo) {
    pd.sendFloat("spread", spread);
    pd.sendFloat("spread2", spread);
  }


  pd.readArray(graphArray, 0, "graph", 0, 300);
  for (int i=0;i<graphArray.length;i++) {
    float x = map(i, 0, 300, 0, width);
    float y = map(graphArray[i], 1, -1, 0, height-height/3);
    fill(255);
    //noStroke();
    stroke(255, 170);
    noFill();
    rect(x, y, 5, 5);
    rect(width-x, y, 5, 5);
    noFill();
    stroke(255, 40);
    if (i%2==0) {
      rect(width/2, height/2, x, y);
      rect(width/2, height/2, y, x);
    }
  }


  if (s > 60 && !sawed) {
    pd.sendBang("sinToSaw");
    sawed = true;
  }

  if (!go) {
    background(0);
  }
}

void serialEvent (Serial mPort) {
  int inByte=mPort.read();
  //0-255
  gsrValue=inByte;
}

int smooth(float data, float filterVal, float smoothedVal) {
  if (filterVal > 1) {      // check to make sure param's are within range
    filterVal = .99;
  }
  else if (filterVal <= 0) {
    filterVal = 0;
  }
  smoothedVal = (data * (1 - filterVal)) + (smoothedVal  *  filterVal);
  return (int)smoothedVal;
}

void receiveFloat(String s, float x) {
  //println(s + ": " + x);
}

void keyPressed() {
  if (keyCode == 32) {
    if (!go) {
      pd.sendBang("go");
      goTime = millis();

      go = true;
    }
  }
  if (key == 'q' || key == 'Q') {
    pd.sendBang("fin");
  }
}

void stop() {
  pd.stop();
  mPort.stop();
}

