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
int errorFlashStart = -1; //timestamp of last error, -1 means no flash
final int errorFlashDuration = 600; //ms to show error flash

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!
float logoX = 500;
float logoY = 400;
float logoZ = 117f;  // 6.5 * inchToPix(.25f) — average of possible sizes
float logoRotation = 0;

int phase = 0; // 0=position, 1=combined size+rotation (2D)

float anchorMouseX  = 0;
float anchorMouseY  = 0;
float anchorLogoZ   = 0;
float anchorRotation = 0;

final float sizeScale = 1.5f;  // px of size per px of horizontal mouse travel
final float rotScale  = 0.6f;  // degrees per px of vertical mouse travel

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
  cursor(CROSS);
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
    
    rotate(radians(d.rotation)); //rotate around the origin of the Ddestination trial
    noFill();
    strokeWeight(3f);
    if (trialIndex==i)
      stroke(255, 0, 0, 192); //set color to semi translucent
    else
      stroke(80, 80, 80, 60); //set color to semi translucent
    rect(0, 0, d.z, d.z);
    popMatrix();

    // Draw center tolerance circle
    float tol = inchToPix(.05f) * 2; // diameter = tolerance radius * 2
    noStroke();
    if (trialIndex==i)
      fill(0, 220, 0, 200);
    else
      fill(80, 80, 80, 50);
    ellipse(d.x, d.y, tol, tol);
  }

  //===========DRAW LOGO SQUARE=================
  pushMatrix();
  translate(logoX, logoY); //translate draw center to the center oft he logo square
  rotate(radians(logoRotation)); //rotate using the logo square as the origin
  noStroke();
  fill(60, 60, 192, 192);
  rect(0, 0, logoZ, logoZ);
  popMatrix();

  //===========ERROR FLASH=================
  if (errorFlashStart >= 0) {
    float elapsed = millis() - errorFlashStart;
    if (elapsed < errorFlashDuration) {
      float alpha = map(elapsed, 0, errorFlashDuration, 120, 0);
      noStroke();
      fill(220, 0, 0, alpha);
      rect(width/2, height/2, width, height);
    } else {
      errorFlashStart = -1;
    }
  }

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  scaffoldControlLogic(); //you are going to want to replace this!
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
}

void scaffoldControlLogic()
{
  if (trialIndex >= trialCount) return;

  Destination d = destinations.get(trialIndex);

  if (phase == 0) {
    logoX = mouseX;
    logoY = mouseY;
    drawFeedback(dist(d.x, d.y, logoX, logoY) < inchToPix(.05f));

    // Flash the position circle
    float pulse = (sin(millis() * 0.02f) + 1) * 0.5f;
    noStroke();
    fill(0, 255, 0, 30 + pulse * 225);
    ellipse(d.x, d.y, inchToPix(.05f) * 2, inchToPix(.05f) * 2);

    // Fixed preview of where the phase 1 rectangle will be
    float nearestRot    = findNearestEquivalentAngle(d.rotation, logoRotation);
    float predictX      = d.x + (d.z - logoZ) / sizeScale;
    float predictY      = d.y - (nearestRot - logoRotation) / rotScale;
    float tolW          = 2 * inchToPix(.1f) / sizeScale;
    float tolH          = 2 * 5.0f / rotScale;
    noStroke();
    fill(255, 255, 255, 25);
    rect(predictX, predictY, tolW, tolH);

    // Line from cursor to target center
    strokeCap(ROUND);
    stroke(0, 200, 0, 120);
    strokeWeight(1f);
    line(mouseX, mouseY, d.x, d.y);
    strokeCap(SQUARE);

  } else if (phase == 1) {
    // X = size, Y = rotation — both from anchor
    logoZ        = constrain(anchorLogoZ + (mouseX - anchorMouseX) * sizeScale, .01, inchToPix(4f));
    logoRotation = anchorRotation + (anchorMouseY - mouseY) * rotScale;

    // Target point in mouse space
    float nearestRot = findNearestEquivalentAngle(d.rotation, anchorRotation);
    float targetX = anchorMouseX + (d.z - anchorLogoZ) / sizeScale;
    float targetY = anchorMouseY - (nearestRot - anchorRotation) / rotScale;
    float tolW    = 2 * inchToPix(.1f) / sizeScale;
    float tolH    = 2 * 5.0f / rotScale;

    boolean inZone = abs(d.z - logoZ) < inchToPix(.1f) &&
                     (float)calculateDifferenceBetweenAngles(d.rotation, logoRotation) <= 5;
    drawFeedback(inZone);

    // Line from cursor to target
    strokeCap(ROUND);
    stroke(0, 200, 0, 100);
    strokeWeight(1f);
    line(mouseX, mouseY, targetX, targetY);
    strokeCap(SQUARE);

    drawReticle(targetX, targetY, tolW, tolH);

    // Ghost of next trial's position circle
    if (trialIndex + 1 < trialCount) {
      Destination next = destinations.get(trialIndex + 1);
      noStroke();
      fill(255, 255, 255, 100);
      ellipse(next.x, next.y, inchToPix(.05f) * 2, inchToPix(.05f) * 2);
    }
  }

}

void drawReticle(float cx, float cy, float w, float h) {
  float pulse = (sin(millis() * 0.02f) + 1) * 0.5f;
  noStroke();
  fill(0, 255, 0, 30 + pulse * 225);
  rect(cx, cy, w, h);
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

void drawFeedback(boolean correct) {
  if (!correct) return;
  noStroke();
  fill(0, 200, 0, 80);
  rect(width/2, height/2, width, height);
}


boolean rotationNeedsUp(float target, float current) {
  float best = target;
  float bestDiff = Float.MAX_VALUE;
  for (int k = -4; k <= 4; k++) {
    float candidate = target + k * 90;
    float d = abs(candidate - current);
    if (d < bestDiff) {
      bestDiff = d;
      best = candidate;
    }
  }
  return best > current;
}

void mousePressed()
{
  if (startTime == 0)
  {
    startTime = millis();
    println("time started!");
  }

  if (trialIndex >= trialCount) return;

  Destination d = destinations.get(trialIndex);

  if (phase == 0) {
    // Lock position, enter combined size+rotation phase
    logoX        = mouseX;
    logoY        = mouseY;
    anchorMouseX = mouseX;
    anchorMouseY = mouseY;
    anchorLogoZ  = logoZ;
    anchorRotation = logoRotation;
    phase = 1;
    if (dist(d.x, d.y, logoX, logoY) >= inchToPix(.05f))
      errorFlashStart = millis();

  } else if (phase == 1) {
    // Submit trial
    phase = 0;
    submitTrial();
  }
}

void submitTrial()
{
  if (userDone == false && !checkForSuccess()) {
    errorCount++;
    errorFlashStart = millis();
  }

  trialIndex++;

  if (trialIndex == trialCount && userDone == false)
  {
    userDone = true;
    finishTime = millis();
  }

  // Reset to known state so every trial starts the same
  logoX        = width / 2f;
  logoY        = height / 2f;
  logoZ        = 6.5f * inchToPix(.25f);
  logoRotation = 0;
}

void mouseReleased()
{
  // Phase transitions are handled in mousePressed
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