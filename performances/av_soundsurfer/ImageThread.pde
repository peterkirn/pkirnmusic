public class ImageThread extends Thread {

  // Threading code adapted from Dan Shiffman
  // Allows loading of images in the background
  // http://shiffman.net/

  boolean running;  
  int wait;      
  String file;  
  private boolean available; 
  PImage img;

  // Constructor creates the thread
  public ImageThread (int w, String file) {
    wait = w;
    running = false;
    this.file = file;
    img = new PImage();
  }

  void start () {
    running = true;
    super.start();
  }

  // Mandatory code initiates the actual thread
  void run () {
    while (running) {
      loader();
      try {
        sleep((long)(wait));
      } 
      catch (Exception e) {
      }
    }
  }

  private synchronized void loader() {
    img = loadImage(file);
    available = true;
    notifyAll(); // notifies that the file has been loaded
  }

  // Retrieves the image
  public synchronized PImage getImage() {
    available = false;
    notifyAll(); 
    return img;
  }

  void quit() {
    running = false;  
    interrupt();
  }

  public boolean available() {
    return available;
  }
}

