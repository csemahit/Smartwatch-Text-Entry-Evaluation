import java.util.Arrays;
import java.util.Collections;
import java.util.Random;

int selectedLetterIndex = -1; // Tracks the index of the currently selected letter (-1 means no selection)

int checking=1;
boolean isBlinking = false; // To track if we are currently blinking
int blinkColor = color(0, 255, 0, 150); // Default to green (match)
long blinkStartTime = 0; // Start time of the blink
final int BLINK_DURATION = 150; // Duration of the blink in milliseconds

String[] phrases; //contains all of the phrases
int totalTrialNum = 10; //the total number of phrases to be tested - set this low for testing. Might be ~10 for the real bakeoff!
int currTrialNum = 0; // the current trial number (indexes into trials array above)
float startTime = 0; // time starts when the first letter is entered
float finishTime = 0; // records the time of when the final trial ends
float lastTime = 0; //the timestamp of when the last trial was completed
float lettersEnteredTotal = 0; //a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0; //a running total of the number of letters expected (correct phrases)
float errorsTotal = 0; //a running total of the number of errors (when hitting next)
String currentPhrase = ""; //the current target phrase
String currentTyped = ""; //what the user has typed so far
final int DPIofYourDeviceScreen = 120; //you will need to look up the DPI or PPI of your device to make sure you get the right scale. Or play around with this value.
final float sizeOfInputArea = DPIofYourDeviceScreen*1; //aka, 1.0 inches square!
PImage watch;
PImage finger;

//Variables for my silly implementation. You can delete this:
//char currentLetter;

//You can modify anything in here. This is just a basic implementation.
void setup()
{
  //noCursor();
  watch = loadImage("watchhand3smaller.png");
  //finger = loadImage("pngeggSmaller.png"); //not using this
  phrases = loadStrings("phrases2.txt"); //load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases), new Random()); //randomize the order of the phrases with no seed
  //Collections.shuffle(Arrays.asList(phrases), new Random(100)); //randomize the order of the phrases with seed 100; same order every time, useful for testing

  orientation(LANDSCAPE); //can also be PORTRAIT - sets orientation on android device
  size(800, 800); //Sets the size of the app. You should modify this to your device's native size. Many phones today are 1080 wide by 1920 tall.
  textFont(createFont("Arial", 20)); //set the font to arial 24. Creating fonts is expensive, so make difference sizes once in setup, not draw
  noStroke(); //my code doesn't use any strokes
}

//You can modify anything in here. This is just a basic implementation.
void draw() {
  background(255); // Clear background

  // Check if the user finished. You can't change the score computation.
  if (finishTime != 0) {
    fill(0);
    textAlign(CENTER);
    text("Trials complete!", 400, 200); // Output
    text("Total time taken: " + (finishTime - startTime), 400, 220); // Output
    text("Total letters entered: " + lettersEnteredTotal, 400, 240); // Output
    text("Total letters expected: " + lettersExpectedTotal, 400, 260); // Output
    text("Total errors entered: " + errorsTotal, 400, 280); // Output
    float wpm = (lettersEnteredTotal / 5.0f) / ((finishTime - startTime) / 60000f); // Raw WPM
    text("Raw WPM: " + wpm, 400, 300); // Output
    float freebieErrors = lettersExpectedTotal * .05; // No penalty if errors are under 5%
    text("Freebie errors: " + nf(freebieErrors, 1, 3), 400, 320); // Output
    float penalty = max(errorsTotal - freebieErrors, 0) * .5f;
    text("Penalty: " + penalty, 400, 340);
    text("WPM w/ penalty: " + (wpm - penalty), 400, 360); // Adjusted WPM
    return;
  }

  drawWatch(); // Draw the watch background
  fill(100);
  rect(width / 2 - sizeOfInputArea / 2, height / 2 - sizeOfInputArea / 2, sizeOfInputArea, sizeOfInputArea); // Input area

  textAlign(CENTER, CENTER);
  float startX = width / 2 - sizeOfInputArea / 2;
  float startY = height / 2 - sizeOfInputArea / 2;
  float cellWidth = sizeOfInputArea / 6;
  float cellHeight = sizeOfInputArea / 5;

  char[] alphabet = "abcdefghijklmnopqrstuvwxyz".toCharArray();
  int index = 0;

  for (int row = 0; row < 5; row++) {
    for (int col = 0; col < 6; col++) {
      float x = startX + col * cellWidth;
      float y = startY + row * cellHeight;

      // Check if we have letters left in the alphabet
      if (index < alphabet.length) {
        if (index == selectedLetterIndex) {
          fill(200, 200, 255); // Highlight color
          stroke(0, 0, 0, 100); // Semi-transparent black border
          strokeWeight(2); // Thickness of the border
          rect(x, y, cellWidth, cellHeight); // Highlight background
          fill(0);
          textSize(24); // Bigger font size for the selected letter
          text(alphabet[index], x + cellWidth / 2, y + cellHeight / 2);
        } else {
          fill(100); // Default background color
          stroke(0, 0, 0, 50); // Transparent black border
          strokeWeight(1);
          rect(x, y, cellWidth, cellHeight);
          fill(0);
          textSize(16); // Default font size
          text(alphabet[index], x + cellWidth / 2, y + cellHeight / 2);
        }
        index++;
      } else {
        // Handle "SPACE" and "DEL" buttons
        if (row == 4 && col == 2) {
          textSize(16);
          fill(100, 110, 0);
          stroke(0, 0, 0, 50); // Transparent black border
          strokeWeight(1);
          rect(x, y, cellWidth+20, cellHeight);
          fill(255);
          text("|__|", x + cellWidth, y + cellHeight / 2);
        }
        if (row == 4 && col == 4) {
          fill(100, 0, 0);
          stroke(0, 0, 0, 50); // Transparent black border
          strokeWeight(1);
          rect(x, y, cellWidth+20, cellHeight);
          fill(255);
          text("DEL", x + cellWidth, y + cellHeight / 2);
        }
      }
    }
  }

  // Apply the blinking effect as a transparent overlay
  if (isBlinking) {
    fill(blinkColor); // Semi-transparent blinking color
    noStroke();
    rect(width / 2 - sizeOfInputArea / 2, height / 2 - sizeOfInputArea / 2, sizeOfInputArea, sizeOfInputArea);

    // Stop blinking after duration
    if (millis() - blinkStartTime > BLINK_DURATION) {
      isBlinking = false;
    }
  }

  if (startTime == 0 & !mousePressed) {
    fill(128);
    textAlign(CENTER);
    text("Click to start time!", 280, 150); // Display this message until the user clicks!
  }

  if (startTime == 0 & mousePressed) {
    nextTrial(); // Start the trials!
  }

  if (startTime != 0) {
    textSize(24);
    textAlign(LEFT); // Align text left
    fill(128);
    text("Phrase " + (currTrialNum + 1) + " of " + totalTrialNum, 70, 50); // Draw trial count
    fill(128);
    text("Target:   " + currentPhrase, 70, 100); // Draw target string
    text("Entered:  " + currentTyped + "_", 70, 140); // Draw typed string so far

    // Draw very basic next button
    fill(255, 0, 0);
    rect(700, 200, 150, 100); // Draw next button
    fill(255);
    text("NEXT > ", 700, 240, 100, 100); // Draw next label

    // Current letter inside input area
    //textAlign(CENTER);
    //fill(200);
    //text("" + currentLetter, width / 2, height / 2 - sizeOfInputArea / 4); // Draw current letter
  }
}



//my terrible implementation you can entirely replace
boolean didMouseClick(float x, float y, float w, float h) //simple function to do hit testing
{
  return (mouseX > x && mouseX<x+w && mouseY>y && mouseY<y+h); //check to see if it is in button bounds
}

//my terrible implementation you can entirely replace
void mousePressed() {
  float startX = width / 2 - sizeOfInputArea / 2;
  float startY = height / 2 - sizeOfInputArea / 2;
  float cellWidth = sizeOfInputArea / 6;
  float cellHeight = sizeOfInputArea / 5;

  char[] alphabet = "abcdefghijklmnopqrstuvwxyz".toCharArray();
  int index = 0;

  for (int row = 0; row < 5; row++) {
    for (int col = 0; col < 6; col++) {
      if (index < alphabet.length) {
        float x = startX + col * cellWidth;
        float y = startY + row * cellHeight;

        if (didMouseClick(x, y, cellWidth, cellHeight)) {
          //if (!(row == 4 && (col == 2 || col == 3 || col == 4 || col == 5))) {
          selectedLetterIndex = index; // Highlight the clicked letter
          char selectedLetter = alphabet[index];
          currentTyped += selectedLetter; // Add the letter to the typed string
          String temp = currentTyped;

          // Determine blink color based on correctness
          if (currentTyped.length() - 1 < currentPhrase.length()) {
            if (currentPhrase.charAt(currentTyped.length() - 1) == selectedLetter) {
              blinkColor = color(0, 255, 0, 150); // Green for correct
            } else {
              blinkColor = color(255, 0, 0, 150); // Red for incorrect
            }
          } else {
            if (checking==1) {
              blinkColor = color(0, 150, 0, 0); // No red or green
              checking = checking + 1;
            } else {
              currentTyped = temp;
              blinkColor = color(255, 0, 0, 150); // Red for incorrect
            }
          }
          isBlinking = true;
          blinkStartTime = millis();
          //}
          return; // Exit after processing
        }
        index++;
      }
    }
  }

  // Handle SPACE key
  if (didMouseClick(width / 2 - sizeOfInputArea / 2 + 2 * (sizeOfInputArea / 6), height / 2 + sizeOfInputArea / 2 - sizeOfInputArea / 5, sizeOfInputArea / 3, sizeOfInputArea / 5)) {
    currentTyped += " ";
    selectedLetterIndex = -1;

    // Blink for correctness
    if (currentTyped.length() - 1 < currentPhrase.length()) {
      if (currentPhrase.charAt(currentTyped.length() - 1) == ' ') {
        blinkColor = color(0, 255, 0, 150); // Green for correct
      } else {
        blinkColor = color(255, 0, 0, 150); // Red for incorrect
      }
    } else {
      blinkColor = color(255, 0, 0, 150); // Red for incorrect
    }
    isBlinking = true;
    blinkStartTime = millis();
    return;
  }

  // Handle DEL key
  if (didMouseClick(width / 2 - sizeOfInputArea / 2 + 4 * (sizeOfInputArea / 6), height / 2 + sizeOfInputArea / 2 - sizeOfInputArea / 5, sizeOfInputArea / 3, sizeOfInputArea / 5)) {
    if (currentTyped.length() > 0) {
      currentTyped = currentTyped.substring(0, currentTyped.length() - 1); // Remove the last character
    }
    selectedLetterIndex = -1; // Reset selection
  }

  // Handle the "NEXT" button
  if (didMouseClick(700, 200, 150, 100)) {
    selectedLetterIndex = -1; // Reset selection
    nextTrial(); // Move to the next trial
  }
}

// Blinking logic
void blinkLight(color c) {
  blinkColor = c;         // Set the color to blink
  isBlinking = true;      // Start blinking
  blinkStartTime = millis(); // Record blink start time
}


void nextTrial()
{
  if (currTrialNum >= totalTrialNum) //check to see if experiment is done
    return; //if so, just return

  if (startTime!=0 && finishTime==0) //in the middle of trials
  {
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
    System.out.println("Target phrase: " + currentPhrase); //output
    System.out.println("Phrase length: " + currentPhrase.length()); //output
    System.out.println("User typed: " + currentTyped); //output
    System.out.println("User typed length: " + currentTyped.length()); //output
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
    System.out.println("Time taken on this trial: " + (millis()-lastTime)); //output
    System.out.println("Time taken since beginning: " + (millis()-startTime)); //output
    System.out.println("==================");
    lettersExpectedTotal+=currentPhrase.trim().length();
    lettersEnteredTotal+=currentTyped.trim().length();
    errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  //probably shouldn't need to modify any of this output / penalty code.
  if (currTrialNum == totalTrialNum-1) //check to see if experiment just finished
  {
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + (finishTime - startTime)); //output
    System.out.println("Total letters entered: " + lettersEnteredTotal); //output
    System.out.println("Total letters expected: " + lettersExpectedTotal); //output
    System.out.println("Total errors entered: " + errorsTotal); //output

    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;

    System.out.println("Raw WPM: " + wpm); //output
    System.out.println("Freebie errors: " + freebieErrors); //output
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
    System.out.println("==================");

    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime==0) //first trial starting now
  {
    System.out.println("Trials beginning! Starting timer..."); //output we're done
    startTime = millis(); //start the timer!
  } else
    currTrialNum++; //increment trial number

  lastTime = millis(); //record the time of when this trial ended
  currentTyped = ""; //clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
  //currentPhrase = "abc"; // uncomment this to override the test phrase (useful for debugging)
}

//probably shouldn't touch this - should be same for all teams.
void drawWatch()
{
  float watchscale = DPIofYourDeviceScreen/138.0; //normalizes the image size
  pushMatrix();
  translate(width/2, height/2);
  scale(watchscale);
  imageMode(CENTER);
  image(watch, 0, 0);
  popMatrix();
}

//probably shouldn't touch this - should be same for all teams.
void drawFinger()
{
  float fingerscale = DPIofYourDeviceScreen/150f; //normalizes the image size
  pushMatrix();
  translate(mouseX, mouseY);
  scale(fingerscale);
  imageMode(CENTER);
  image(finger, 52, 341);
  if (mousePressed)
    fill(0);
  else
    fill(255);
  ellipse(0, 0, 5, 5);

  popMatrix();
}


//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
int computeLevenshteinDistance(String phrase1, String phrase2) //this computers error between two strings
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++)
    distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++)
    distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}
