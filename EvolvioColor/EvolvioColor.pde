Board evoBoard;
final int SEED = 48;                  // random seed
final float NOISE_STEP_SIZE = 0.1;    // not sure
final int BOARD_WIDTH = 100;          // board width (in tiles)
final int BOARD_HEIGHT = 100;         // board height (in tiles)

final int WINDOW_WIDTH = 1920;
final int WINDOW_HEIGHT = 1080;

final float SCALE_TO_FIX_BUG = 100;
final float GROSS_OVERALL_SCALE_FACTOR = ((float)WINDOW_HEIGHT)/BOARD_HEIGHT/SCALE_TO_FIX_BUG;

final double TIME_STEP = 0.001;       // simulation timestep (set really low for maximum processing powa!
final float MIN_TEMPERATURE = -0.5;   // minimum temperature scale factor
final float MAX_TEMPERATURE = 1.0;    // maximum temperature scale factor

final int ROCKS_TO_ADD = 100;         // number of rocks in the world
final int CREATURE_MINIMUM = 60;      // the minimum number of creatures that inhibit our world, also starting number

float cameraX = BOARD_WIDTH*0.5;      // set start camera X to center
float cameraY = BOARD_HEIGHT*0.5;     // set start camera Y to center
float cameraR = 0;                    // camera rotation
float zoom = 1;                       // the current zoom level of the camera
PFont font;                           // the font we will use
int dragging = 0;                     // 0 = no drag, 1 = drag screen, 2 and 3 are dragging temp extremes.
float prevMouseX;                     // used when calculating mouse dragging and other actions
float prevMouseY;                     // used when calculating mouse dragging and other actions
boolean draggedFar = false;           // not sure
final String INITIAL_FILE_NAME = "DEFAULT";    // not sure

// setup the window and board
void setup() {
  // colors will use HSB values
  colorMode(HSB,1.0);
  // load neat font
  font = loadFont("Jygquip1-48.vlw");
  // determine window size
  size(1920, 1080);
  // init board
  evoBoard = new Board(BOARD_WIDTH, BOARD_HEIGHT, NOISE_STEP_SIZE, MIN_TEMPERATURE, MAX_TEMPERATURE, 
  ROCKS_TO_ADD, CREATURE_MINIMUM, SEED, INITIAL_FILE_NAME, TIME_STEP);
  // lastly recalculate camera zoom
  resetZoom();
}

// called each frame
void draw() {
  // fill the frame with board processing
  for (int iteration = 0; iteration < evoBoard.playSpeed; iteration++) {
    evoBoard.iterate(TIME_STEP);
  }
  // determine if the user has dragged the mouse "far" this frame
  if (dist(prevMouseX, prevMouseY, mouseX, mouseY) > 5) {
    draggedFar = true;
  }
  // drag handling
  if (dragging == 1) {
    // for screen drag determine the camera 
    cameraX -= toWorldXCoordinate(mouseX, mouseY)-toWorldXCoordinate(prevMouseX, prevMouseY);
    cameraY -= toWorldYCoordinate(mouseX, mouseY)-toWorldYCoordinate(prevMouseX, prevMouseY);
  } else if (dragging == 2) { //UGLY UGLY CODE.  Do not look at this
    // min temp slider dragging
    if (evoBoard.setMinTemperature(1.0-(mouseY-30)/660.0)) {
      dragging = 3;
    }
  } else if (dragging == 3) {
    // max temp slider dragging
    if (evoBoard.setMaxTemperature(1.0-(mouseY-30)/660.0)) {
      dragging = 2;
    }
  }
  // center selected creature
  if (evoBoard.userControl && evoBoard.selectedCreature != null) {
    cameraX = (float)evoBoard.selectedCreature.px;
    cameraY = (float)evoBoard.selectedCreature.py;
    cameraR = -PI/2.0-(float)evoBoard.selectedCreature.rotation;
  } else {
    cameraR = 0;
  }
  
  // start matrix
  pushMatrix();
  
  // scale
  scale(GROSS_OVERALL_SCALE_FACTOR);
  
  // draw blank board
  evoBoard.drawBlankBoard(SCALE_TO_FIX_BUG);
  
  // translate and scale camera
  translate(BOARD_WIDTH*0.5*SCALE_TO_FIX_BUG, BOARD_HEIGHT*0.5*SCALE_TO_FIX_BUG);
  scale(zoom);
  
  if (evoBoard.userControl && evoBoard.selectedCreature != null) {
    // rotate if creature is selected
    rotate(cameraR);
  }
  
  // translate camera again to ajust offset?
  translate(-cameraX*SCALE_TO_FIX_BUG, -cameraY*SCALE_TO_FIX_BUG);
  
  // draw board
  evoBoard.drawBoard(SCALE_TO_FIX_BUG, zoom, (int)toWorldXCoordinate(mouseX, mouseY), (int)toWorldYCoordinate(mouseX, mouseY));
  popMatrix();
  // done with camera stuff
  
  // draw the right-side UI pane 
  evoBoard.drawUI(SCALE_TO_FIX_BUG, TIME_STEP, WINDOW_HEIGHT, 0, WINDOW_WIDTH, WINDOW_HEIGHT, font);

  // save board file for later loading
  evoBoard.fileSave();
  
  // for mouse dragging
  prevMouseX = mouseX;
  prevMouseY = mouseY;
}

// handle mouse wheel event
void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  if (delta >= 0.5) {
    setZoom(zoom*0.90909, mouseX, mouseY);
  } else if (delta <= -0.5) {
    setZoom(zoom*1.1, mouseX, mouseY);
  }
}

// handle mouse pressed event
void mousePressed() {
  if (mouseX < WINDOW_HEIGHT) {
    dragging = 1;
  } else {
    // select creature
    if (abs(mouseX-(WINDOW_HEIGHT+65)) <= 60 && abs(mouseY-147) <= 60 && evoBoard.selectedCreature != null) {
        cameraX = (float)evoBoard.selectedCreature.px;
        cameraY = (float)evoBoard.selectedCreature.py;
        zoom = 4;
    }
    else if (mouseY >= 95 && mouseY < 135 && evoBoard.selectedCreature == null) {
      // reset zoom button
      if (mouseX >= WINDOW_HEIGHT+10 && mouseX < WINDOW_HEIGHT+230) {
        resetZoom();
      }
      // sort creature button
      else if (mouseX >= WINDOW_HEIGHT+240 && mouseX < WINDOW_HEIGHT+460) {
        evoBoard.creatureRankMetric = (evoBoard.creatureRankMetric+1)%8;
      }
    }
    // control buttons (under creature width)
    else if (mouseY >= 570) {
      float x = (mouseX-(WINDOW_HEIGHT+10));
      float y = (mouseY-570);
      boolean clickedOnLeft = (x%230 < 110);
      if (x >= 0 && x < 2*230 && y >= 0 && y < 4*50 && x%230 < 220 && y%50 < 40) {
        int mX = (int)(x/230);
        int mY = (int)(y/50);
        int buttonNum = mX+mY*2;
        if (buttonNum == 0) {
          evoBoard.userControl = !evoBoard.userControl;
        } else if (buttonNum == 1) {
          if (clickedOnLeft) {
            evoBoard.creatureMinimum -= evoBoard.creatureMinimumIncrement;
          } else {
            evoBoard.creatureMinimum += evoBoard.creatureMinimumIncrement;
          }
        } else if (buttonNum == 2) {
          evoBoard.prepareForFileSave(0);
        } else if (buttonNum == 3) {
          if (clickedOnLeft) {
            evoBoard.imageSaveInterval *= 0.5;
          } else {
            evoBoard.imageSaveInterval *= 2.0;
          }
          if (evoBoard.imageSaveInterval >= 0.7) {
            evoBoard.imageSaveInterval = Math.round(evoBoard.imageSaveInterval);
          }
        } else if (buttonNum == 4) {
          evoBoard.prepareForFileSave(2);
        } else if (buttonNum == 5) {
          if (clickedOnLeft) {
            evoBoard.textSaveInterval *= 0.5;
          } else {
            evoBoard.textSaveInterval *= 2.0;
          }
          if (evoBoard.textSaveInterval >= 0.7) {
            evoBoard.textSaveInterval = Math.round(evoBoard.textSaveInterval);
          }
        }else if(buttonNum == 6){
          if (clickedOnLeft) {
            if(evoBoard.playSpeed >= 2){
              evoBoard.playSpeed /= 2;
            }else{
              evoBoard.playSpeed = 0;
            }
          } else {
            if(evoBoard.playSpeed == 0){
              evoBoard.playSpeed = 1;
            }else{
              evoBoard.playSpeed *= 2;
            }
          }
        }
      }
    }
    // sorted creature list
    else if (mouseX >= height+10 && mouseX < width-50 && evoBoard.selectedCreature == null) {
      int listIndex = (mouseY-150)/70;
      if (listIndex >= 0 && listIndex < evoBoard.LIST_SLOTS) {
        evoBoard.selectedCreature = evoBoard.list[listIndex];
        cameraX = (float)evoBoard.selectedCreature.px;
        cameraY = (float)evoBoard.selectedCreature.py;
        zoom = 4;
      }
    }
    // high and low temp
    if (mouseX >= width-50) {
      float toClickTemp = (mouseY-30)/660.0;
      float lowTemp = 1.0-evoBoard.getLowTempProportion();
      float highTemp = 1.0-evoBoard.getHighTempProportion();
      if (abs(toClickTemp-lowTemp) < abs(toClickTemp-highTemp)) {
        dragging = 2;
      } else {
        dragging = 3;
      }
    }
  }
  
  // reset dragging far
  draggedFar = false;
}
void mouseReleased() {
  if (!draggedFar) {
    if (mouseX < WINDOW_HEIGHT) { // DO NOT LOOK AT THIS CODE EITHER it is bad
      dragging = 1;
      float mX = toWorldXCoordinate(mouseX, mouseY);
      float mY = toWorldYCoordinate(mouseX, mouseY);
      int x = (int)(floor(mX));
      int y = (int)(floor(mY));
      evoBoard.unselect();
      cameraR = 0;
      if (x >= 0 && x < BOARD_WIDTH && y >= 0 && y < BOARD_HEIGHT) {
        for (int i = 0; i < evoBoard.softBodiesInPositions[x][y].size (); i++) {
          SoftBody body = (SoftBody)evoBoard.softBodiesInPositions[x][y].get(i);
          if (body.isCreature) {
            float distance = dist(mX, mY, (float)body.px, (float)body.py);
            if (distance <= body.getRadius()) {
              evoBoard.selectedCreature = (Creature)body;
            }
          }
        }
      }
    }
  }
  dragging = 0;
}

// reset camera zoom
void resetZoom() {
  cameraX = BOARD_WIDTH*0.5;
  cameraY = BOARD_HEIGHT*0.5;
  zoom = 1;
}

// set camera zoom
void setZoom(float target, float x, float y) {
  float grossX = grossify(x, BOARD_WIDTH);
  cameraX -= (grossX/target-grossX/zoom);
  float grossY = grossify(y, BOARD_HEIGHT);
  cameraY -= (grossY/target-grossY/zoom);
  zoom = target;
}

// not sure
float grossify(float input, float total) { // Very weird function
  return (input/GROSS_OVERALL_SCALE_FACTOR-total*0.5*SCALE_TO_FIX_BUG)/SCALE_TO_FIX_BUG;
}

// mouse to world X
float toWorldXCoordinate(float x, float y) {
  float w = WINDOW_HEIGHT/2;
  float angle = atan2(y-w, x-w);
  float dist = dist(w, w, x, y);
  return cameraX+grossify(cos(angle-cameraR)*dist+w, BOARD_WIDTH)/zoom;
}

// mouse to world Y
float toWorldYCoordinate(float x, float y) {
  float w = WINDOW_HEIGHT/2;
  float angle = atan2(y-w, x-w);
  float dist = dist(w, w, x, y);
  return cameraY+grossify(sin(angle-cameraR)*dist+w, BOARD_HEIGHT)/zoom;
}