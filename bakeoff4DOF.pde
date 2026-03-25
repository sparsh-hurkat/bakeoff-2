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

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch.

//These variables are for my example design. Your input code should modify/replace these!
float logoX = 500;
float logoY = 500;
float logoZ = 50f;
float logoRotation = 0;

// Phase: 0=position, 1=rotation, 2=size
int phase = 0;

float anchorMouseY   = 0;
float anchorLogoZ    = 0;
float anchorRotation = 0;

final float rotScale  = 0.5f;  // degrees per px of vertical mouse travel
final float sizeScale = 0.5f;  // px of size per px of vertical mouse travel

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
  noCursor();
}



void draw() {

  background(40); //background is dark grey
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
  for (int i=trialIndex; i<trialCount; i++) // reduces over time
  {
    pushMatrix();
    Destination d = destinations.get(i); //get destination trial
    translate(d.x, d.y); //center the drawing coordinates to the center of the destination trial

    rotate(radians(d.rotation)); //rotate around the origin of the destination trial
    noFill();
    strokeWeight(3f);
    if (trialIndex==i)
      stroke(255, 0, 0, 192);
    else
      stroke(128, 128, 128, 128);
    rect(0, 0, d.z, d.z);
    popMatrix();

    // Green circle at target center showing position tolerance (iteration 2)
    if (trialIndex == i) {
      noStroke();
      fill(0, 220, 0, 180);
      ellipse(d.x, d.y, inchToPix(.05f) * 2, inchToPix(.05f) * 2);
    }
  }

  //===========DRAW LOGO SQUARE=================
  pushMatrix();
  translate(logoX, logoY); //translate draw center to the center of the logo square
  rotate(radians(logoRotation)); //rotate using the logo square as the origin
  noStroke();
  fill(60, 60, 192, 192);
  rect(0, 0, logoZ, logoZ);
  popMatrix();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  scaffoldControlLogic(); //you are going to want to replace this!
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
  drawCursor();
}

void scaffoldControlLogic()
{
  if (trialIndex >= trialCount) return;

  Destination d = destinations.get(trialIndex);

  if (phase == 0) {
    // Cursor tracks position
    logoX = mouseX;
    logoY = mouseY;

    boolean inZone = dist(d.x, d.y, logoX, logoY) < inchToPix(.05f);
    if (inZone) {
      noStroke();
      fill(0, 220, 0, 80);
      rect(width/2, height/2, width, height);
    }

  } else if (phase == 1) {
    // Y-up = clockwise, Y-down = CCW
    logoRotation = anchorRotation + (anchorMouseY - mouseY) * rotScale;

    float nearest  = findNearestEquivalentAngle(d.rotation, anchorRotation);
    boolean inZone = (float)calculateDifferenceBetweenAngles(d.rotation, logoRotation) <= 5;
    boolean needsUp = nearest > logoRotation;
    if (inZone) {
      noStroke();
      fill(0, 220, 0, 80);
      rect(width/2, height/2, width, height);
    }

  } else if (phase == 2) {
    // Y-up = bigger, Y-down = smaller
    logoZ = constrain(anchorLogoZ + (anchorMouseY - mouseY) * sizeScale, .01, inchToPix(4f));

    boolean inZone = abs(d.z - logoZ) < inchToPix(.1f);
    if (inZone) {
      noStroke();
      fill(0, 220, 0, 80);
      rect(width/2, height/2, width, height);
    }
  }
}

float findNearestEquivalentAngle(float target, float reference) {
  float best = target;
  float bestDiff = Float.MAX_VALUE;
  for (int k = -4; k <= 4; k++) {
    float candidate = target + k * 90;
    float d = abs(candidate - reference);
    if (d < bestDiff) { bestDiff = d; best = candidate; }
  }
  return best;
}

void drawCursor() {
  float arm = 7;

  // Directional arrows for phase 1 and 2
  if (phase == 1 || phase == 2) {
    Destination d = destinations.get(trialIndex);
    boolean needsUp;
    if (phase == 1) {
      float nearest = findNearestEquivalentAngle(d.rotation, logoRotation);
      needsUp = nearest > logoRotation;
    } else {
      needsUp = d.z > logoZ;
    }
    noStroke();
    fill(255, 255, 255, 200);
    // Arrow triangle above or below crosshair
    if (needsUp) {
      triangle(mouseX, mouseY - arm - 10, mouseX - 5, mouseY - arm - 4, mouseX + 5, mouseY - arm - 4);
    } else {
      triangle(mouseX, mouseY + arm + 10, mouseX - 5, mouseY + arm + 4, mouseX + 5, mouseY + arm + 4);
    }
  }

  // Crosshair
  strokeCap(ROUND);
  noFill();
  stroke(0, 0, 0, 160);
  strokeWeight(3);
  line(mouseX - arm, mouseY, mouseX + arm, mouseY);
  line(mouseX, mouseY - arm, mouseX, mouseY + arm);
  stroke(255, 255, 255, 220);
  strokeWeight(1.5f);
  line(mouseX - arm, mouseY, mouseX + arm, mouseY);
  line(mouseX, mouseY - arm, mouseX, mouseY + arm);
}

void mousePressed()
{
  if (startTime == 0)
  {
    startTime = millis();
    println("time started!");
  }

  if (trialIndex >= trialCount) return;

  if (phase == 0) {
    // Lock position, enter rotation phase
    anchorMouseY   = mouseY;
    anchorRotation = logoRotation;
    phase = 1;

  } else if (phase == 1) {
    // Lock rotation, enter size phase
    anchorMouseY = mouseY;
    anchorLogoZ  = logoZ;
    phase = 2;

  } else if (phase == 2) {
    // Submit trial
    phase = 0;
    submitTrial();
  }
}

void submitTrial()
{
  if (userDone == false && !checkForSuccess())
    errorCount++;

  trialIndex++;

  if (trialIndex == trialCount && userDone == false)
  {
    userDone = true;
    finishTime = millis();
  }
}

void mouseReleased()
{
  // Phase transitions handled in mousePressed
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
