import java.util.ArrayList;
import java.util.Collections;

//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window, set later
int trialCount = 10; //WILL BE MODIFIED FOR THE BAKEOFF
 //this will be set higher for the bakeoff
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 1.0f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done
int inputState = 0; // 0 = Position, 1 = Rotation & Scale

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!
float logoX = 500;
float logoY = 500;
float logoZ = 50f;
float logoRotation = 0;

private class Destination
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Destination> destinations = new ArrayList<Destination>();

void setup() {
  size(1000, 800);  
  rectMode(CENTER);
  textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
  textAlign(CENTER);
  rectMode(CENTER); //draw rectangles not from upper left, but from the center outwards
  
  //don't change this! 
  border = inchToPix(2f); //padding of 1.0 inches

  println("creating "+trialCount + " targets");
  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Destination d = new Destination();
    d.x = random(border, width-border); //set a random x with some padding
    d.y = random(border, height-border); //set a random y with some padding
    d.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    d.z = ((j%12)+1)*inchToPix(.25f); //increasing size from .25 up to 3.0" 
    destinations.add(d);
    println("created target with " + d.x + "," + d.y + "," + d.rotation + "," + d.z);
  }

  Collections.shuffle(destinations); // randomize the order of the button; don't change this.
}



void draw() {
  if (userDone) {
    background(40);
  } else {
    Destination d = destinations.get(trialIndex);
    boolean isCorrect = false;

    if (inputState == 0) {
      isCorrect = dist(d.x, d.y, logoX, logoY) < inchToPix(.05f); 
    } else if (inputState == 1) {
      boolean rotCorrect = calculateDifferenceBetweenAngles(d.rotation, logoRotation) <= 5;
      boolean zCorrect = abs(d.z - logoZ) < inchToPix(.1f);
      isCorrect = rotCorrect && zCorrect;
    }

    if (isCorrect) {
      background(80, 140, 80);
    } else {
      background(40);
    }
  }

  fill(200);
  noStroke();
  fill(200);
  noStroke();
  
  //Test square in the top left corner. Should be 1 x 1 inch
  //rect(inchToPix(0.5), inchToPix(0.5), inchToPix(1), inchToPix(1));

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchToPix(.4f));
    text("User had " + errorCount + " error(s)", width/2, inchToPix(.4f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per destination", width/2, inchToPix(.4f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per destination inc. penalty", width/2, inchToPix(.4f)*4);
    return;
  }

  //===========DRAW DESTINATION SQUARES=================
//===========DRAW DESTINATION SQUARES=================
  for (int i=trialIndex; i<trialCount; i++) {
    pushMatrix();
    Destination d = destinations.get(i);
    translate(d.x, d.y);
    
    rotate(radians(d.rotation));
    
    noFill();
    strokeWeight(3f);
    
    if (trialIndex==i) {
      stroke(255, 0, 0, 192);
    } else {
      stroke(128, 128, 128, 128);
    }
    
    rect(0, 0, d.z, d.z);
    
    if (trialIndex == i) {
      fill(255, 0, 0, 192);
      noStroke();    
      circle(0, 0, inchToPix(0.05f));
    }
    
    popMatrix();
  }

  //===========DRAW LOGO SQUARE=================
  pushMatrix();
  translate(logoX, logoY); //translate draw center to the center oft he logo square
  rotate(radians(logoRotation)); //rotate using the logo square as the origin
  noStroke();
  fill(60, 60, 192, 192);
  rect(0, 0, logoZ, logoZ);
  popMatrix();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  scaffoldControlLogic(); //you are going to want to replace this!
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
}

//my example design for control, which is terrible
void scaffoldControlLogic()
{
  fill(255);
  
  if (inputState == 0) {
    text("Step 1: Move mouse to position. Click to lock.", width/2, inchToPix(.8f) + 30);
    logoX = mouseX;
    logoY = mouseY;
  } 
  else if (inputState == 1) {
    text("Step 2: Drag to rotate (Left/Right) and scale (Up/Down). Click to submit!", width/2, inchToPix(.8f) + 30);
    
    float rotationSensitivity = 0.5f; 
    logoRotation += (mouseX - pmouseX) * rotationSensitivity;
    
    float scaleSensitivity = 0.01f; 
    logoZ += (pmouseY - mouseY) * scaleSensitivity * screenPPI;
    
    logoZ = constrain(logoZ, .01, inchToPix(4f)); 
  }
}

void mousePressed()
{
  if (startTime == 0) {
    startTime = millis();
    println("time started!");
  }

  if (inputState == 0) {
    inputState = 1;
  } 
  else if (inputState == 1) {
    if (userDone == false && !checkForSuccess()) {
      errorCount++;
    }
    
    trialIndex++;

    if (trialIndex == trialCount && userDone == false) {
      userDone = true;
      finishTime = millis();
    }
    
    inputState = 0;
  }
}

void mouseReleased()
{

}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  Destination d = destinations.get(trialIndex);	
  boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logoRotation)<=5;
  boolean closeZ = abs(d.z - logoZ)<inchToPix(.1f); //has to be within +-0.1"	

  println("Close Enough Distance: " + closeDist + " (logo X/Y = " + d.x + "/" + d.y + ", destination X/Y = " + logoX + "/" + logoY +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(d.rotation, logoRotation)+")");
  println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ +")");
  println("Close enough all: " + (closeDist && closeRotation && closeZ));

  return closeDist && closeRotation && closeZ;
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
  double diff=abs(a1-a2);
  diff%=90;
  if (diff>45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
  return inch*screenPPI;
}
