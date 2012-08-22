import processing.opengl.*;
import codeanticode.glgraphics.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;

PImage img;
GLTexture tex, mtex;
GLTexture[] tiles;
ImageThread imgLoad;
GLTexture bloomMask, destTex;
GLTexture tex0, tex2, tex4, tex8, tex16;
boolean moving = true;
boolean backed = false;
float amount = 0;
float origin = 0;
float moveamount = 0;
int polynum = 4;
float angle = 90;

GLTextureFilter extractBloom, blur, blend4, toneMap;

String[] files = new String[49];
int currImg = 0;
int mode = 0;
float mX = 0.3;
float texY = 1;
float drawalpha = 255;
float amt = 0;
int orig = 0;
float fx = 1;
float fy = 1;
float fxr = 0.1;
float fyr = 0.1;

void setup() {
  noCursor();
  size(1024, 768, GLConstants.GLGRAPHICS);
  for (int i=0;i<49;i++) {
    int num = i;
    String f = "img" + num + ".jpg";
    files[i] = f;
  }
  imgLoad = new ImageThread(10000, files[0]);  // new thread every N milliseconds
  imgLoad.start();  // start that thread
  tex = new GLTexture(this, width, height);
  tiles = new GLTexture[16];
  for (int i=0;i<16;i++) {
    tiles[i] = new GLTexture(this, width/4, height/4);
  }
  extractBloom = new GLTextureFilter(this, "ExtractBloom.xml");
  blur = new GLTextureFilter(this, "Blur.xml");
  blend4 = new GLTextureFilter(this, "Blend4.xml");  
  toneMap = new GLTextureFilter(this, "ToneMap.xml");
  int polynum = 4;

  int w = width;
  int h = height;
  smooth();

  destTex = new GLTexture(this, w, h);
  // Initializing bloom mask and blur textures.
  bloomMask = new GLTexture(this, w, h, GLTexture.FLOAT);
  tex0 = new GLTexture(this, w, h, GLTexture.FLOAT);
  tex2 = new GLTexture(this, w / 2, h / 2, GLTexture.FLOAT);
  tex4 = new GLTexture(this, w / 4, h / 4, GLTexture.FLOAT);
  tex8 = new GLTexture(this, w / 8, h / 8, GLTexture.FLOAT);
  tex16 = new GLTexture(this, w / 16, h / 16, GLTexture.FLOAT);
  oscP5 = new OscP5(this, 12000);

  noStroke();
}

void draw() {
  //TODO: map to OSC




  if (imgLoad.available()) {
    img = imgLoad.getImage();
  }
  if (img != null) {
    amt = map(amount, 0.0f, 1.0f, 0, img.height);
    orig = round(map(origin, 0, 1, 0, img.height/2));
  }
  tint(255, drawalpha);

  switch(mode) {
  case 0:

    if (img != null) {
      int x = 0;
      if (moving) {
        x = round(frameCount%img.width)+round(random(0, 20*amount));
      } 
      else {
        x = round(map(moveamount, 0, 1, 0, img.width-2))+round(random(0, 20*amount));
      }
      tex.putPixelsIntoTexture(img, x, orig, round(texY), img.height);
      image(tex, 0, 0, width, height);
    }
    break;

  case 1:
    if (img != null) {
      tex.putPixelsIntoTexture(img, 
      round(random(orig, amt)), 
      round(random(orig, amt)), 
      round(random(img.width-amt, img.width)), 
      round(random(img.width-amt, img.width)));

      // Extracting the bright regions from input texture.
      extractBloom.setParameterValue("bright_threshold", fx);
      extractBloom.apply(tex, tex0);

      // Downsampling with blur.
      tex0.filter(blur, tex2);
      tex2.filter(blur, tex4);    
      tex4.filter(blur, tex8);    
      tex8.filter(blur, tex16);     

      // Blending downsampled textures.
      blend4.apply(new GLTexture[] {
        tex2, tex4, tex8, tex16
      }
      , new GLTexture[] {
        bloomMask
      }
      );

      // Final tone mapping into destination texture.
      toneMap.setParameterValue("exposure", fy+random(-0.1*fyr, 0.1*fyr));
      toneMap.setParameterValue("bright", fx+random(-0.1*fxr, 0.1*fxr));
      toneMap.apply(new GLTexture[] {
        tex, bloomMask
      }
      , new GLTexture[] {
        destTex
      }
      );



      image(destTex, 0, 0, width, height);
      //image(tex, 0, 0, width, height);
    }
    break;

  case 2:
    int num =0;

    for (int i=0;i<4;i++) {
      for (int j=0;j<4;j++) {
        tiles[num].putPixelsIntoTexture(img, 
        round(random((img.width/4)*i, (img.width/4)*i+img.width/4)), 
        round(random((img.height/4)*j, (img.height/4)*j+img.height/4)), 
        round(random(0, img.width/4)), 
        round(random(0, img.height/4)));
        image(tiles[num], (width/4)*i, (height/4)*j, width/4, height/4);
        num++;
      }
    }

    break;

  case 3:
    if (backed) {
      background(0);
    } 
    translate(width/2, height/2);
    for (int i=0;i<polynum;i++) {
      tiles[i].putPixelsIntoTexture(img, 
      round(random(orig, (img.width/4)*amount)), 
      round(random(orig, (img.height/4)*amount)), 
      round(random(orig+img.width/4, orig+img.width/4+(img.width/4)*amount)), 
      round(random(orig+img.height/4, orig+img.height/4+(img.height/4)*amount)));
      rotate(radians(angle));
      image(tiles[i], width*mX, height*mX, 300, 300);
    }

    break;
  }
}

void keyPressed() {
  if (keyCode == RIGHT) {
    if (currImg<23) {
      currImg++;
    } 
    else {
      currImg = 0;
    }
    imgLoad = new ImageThread(10000, files[currImg]);
    imgLoad.start();  // start that thread
  }
  else if (keyCode ==LEFT) {
    if (currImg>0) {
      currImg--;
    } 
    else {
      currImg = 48;
    }
    imgLoad = new ImageThread(10000, files[currImg]);
    imgLoad.start();  // start that thread
  }
  if (key == '0') {
    mode = 0;
  }
  if (key == '1') {
    mode = 1;
  }
  if (key == '2') {
    mode = 2;
  }
  if (key == '3') {
    mode = 3;
  }
}

void mouseDragged() {
  texY = map(mouseX, 0, width, 1, 100);
  drawalpha = map(mouseY, height, 0, 3, 255);
  mX = map(mouseX, 0, width, 0.1, 0.9);
}

void oscEvent(OscMessage theOscMessage) {
  //troubleshooting OSC receipt
  println(theOscMessage.toString());

  if (theOscMessage.checkAddrPattern("/Sel/x")==true) {
    for (int i=0; i<49; i++) {
      float val = theOscMessage.get(i).floatValue();
      if (val == 1) {
        currImg = i;
        imgLoad = new ImageThread(10000, files[currImg]);
        imgLoad.start();  // start that thread
        break;
      }
    }
  }

  if (theOscMessage.checkAddrPattern("/Mode/x")==true) {
    for (int i=0; i<4; i++) {
      float val = theOscMessage.get(i).floatValue();
      if (val == 1) {
        mode = i;
      }
    }
  }

  if (theOscMessage.checkAddrPattern("/Alpha/x")==true) {
    drawalpha = constrain(map(theOscMessage.get(0).floatValue(), 0, 1, 5, 255), 5, 255);
  }

  if (theOscMessage.checkAddrPattern("/Origin/x")==true) {
    origin = theOscMessage.get(0).floatValue();
    texY = map(origin, 0, 1, 1, 100);
  }
  if (theOscMessage.checkAddrPattern("/Amount/x")==true) {
    amount = theOscMessage.get(0).floatValue();
  }
  if (theOscMessage.checkAddrPattern("/MoveAmount/x")==true) {
    moveamount = theOscMessage.get(0).floatValue();
  }
  if (theOscMessage.checkAddrPattern("/Move/x")==true) {
    if (theOscMessage.get(0).floatValue() == 1) {
      moving = true;
    } 
    else {
      moving = false;
    }
  }
  if (theOscMessage.checkAddrPattern("/Fx/x")==true) {
    fx = theOscMessage.get(0).floatValue();
  }
  if (theOscMessage.checkAddrPattern("/FxRandom/x")==true) {
    fxr = theOscMessage.get(0).floatValue()*4;
    println(fxr);
  }
  if (theOscMessage.checkAddrPattern("/FyRandom/x")==true) {
    fyr = theOscMessage.get(0).floatValue()*4;
    println(fyr);
  }
  if (theOscMessage.checkAddrPattern("/Fy/x")==true) {
    fy = theOscMessage.get(0).floatValue();
  }

  if (theOscMessage.checkAddrPattern("/Poly/x")==true) {
    polynum = round(map(theOscMessage.get(0).floatValue(), 0, 1, 4, 12));
    angle = map(theOscMessage.get(0).floatValue(), 0, 1, 90, 30);
  }
  if (theOscMessage.checkAddrPattern("/Mx/x")==true) {
    mX = map(theOscMessage.get(0).floatValue(), 0.0f, 1.0f, 0, 0.4);
  }

  if (theOscMessage.checkAddrPattern("/Backed/x")==true) {
    if (theOscMessage.get(0).floatValue() == 1) {
      backed = true;
    } 
    else {
      backed = false;
    }
  }
}

