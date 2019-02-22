int cellDimm = 1;
int cellDimmMax;
int COLS, ROWS;
int szDimm;
final float[] ks = {0.0625,0.06, 0.0475, .055};
final float[] fs = {0.035, 0.0118, .025};
// Fix the diffusion rate constants for u and v
// to ru = 0.082 and rv = 0.041.
final float ru = 0.082, rv = 0.041;
float k = ks[0];  // kill rate
float f = fs[0]; // feed
Boolean bShowInstructions = false, bPaused = false, bColor = false, bResize=false, 
        bOnlyDiffusion = false, bspatiallyVarying = false, bDrawU = true, bDrawV = false, bSetStepMode = false;
final int drawRecFill = 0, drawRecBdr = 1, drawCirlceFill = 2, drawCircleBdr = 3, draw1Cell = 4, drawRandom = 5;
final int lClass = 0, lex = 1, lPearson = 2;
String[] laplaceNames = {"-4 No diag","-8 with diags","Pearson"};
String[] drawModeNames = {"Rec fill","Rec Bdr","Circle Fill", "Circle Bdr", "(debug) draw 1 Cell", "Random"};
final int drawTypeMax = drawRandom, laplacianTypeMax = lPearson;
int drawType = drawRandom, laplacianType = lClass;
float[][] U,V,dU,dV; 
float[] kHorzArr, fVertArr;
int currentMode = 1;

   void setup() {
     szDimm = 400;
     size(400, 400);
     //surface.setResizable(true);
     updateCellDimm();
   }
   void mousePressed() {
    if (mouseX<width && mouseX >0 && mouseY <height && mouseY > 0) 
    {
      int msX = mouseX/cellDimm;
      int msY = mouseY/cellDimm;
      println("u: "+ U[msX][msY] + " v: "+ V[msX][msY]);
      if(bspatiallyVarying) {
        println("k: "+ kHorzArr[msX] + " f: "+ fVertArr[msY]);
      }
    }
   }
   void updateCellDimm() {
     cellDimmMax = szDimm/10;
     if(cellDimm > cellDimmMax) {
       cellDimm = cellDimmMax;
     }
     COLS = width/cellDimm;
     ROWS = height/cellDimm;
     U = new float[COLS][ROWS];
     V = new float[COLS][ROWS];
     dU = new float[COLS][ROWS];
     dV = new float[COLS][ROWS];
     initVaryingParams();
     resetUV();
   }
   void initVaryingParams() {
     kHorzArr = new float[COLS];
     fVertArr = new float[ROWS];
     for(int i = 0; i < kHorzArr.length;i++) {
       // The parameter k should vary across the x direction (horizontally), 
       // and should take on values between 0.03 and 0.07. 
       kHorzArr[i] = map(i, 0, kHorzArr.length, .03, .07);
     }
     for(int i = 0, n = fVertArr.length-1; i < fVertArr.length;i++, n--) {
        // The parameter f should vary in the vertical (y) direction
        // from f = 0.0 at the bottom to f = 0.08 at the top.
        fVertArr[n] = map(i, 0, fVertArr.length, 0.0, .08);
     }
   }
   void drawRecFill(int sCol, int eCol, int sRow, int eRow) {
     for (int i = sCol; i < eCol; i++) {
        for (int j = sRow; j < eRow; j++) {
          U[i][j] = .5;
          V[i][j] = .25;
        }
      }
   }
   void drawCirlceFill(int i, int j, int radius) {
     U[i][j] = .5;
     V[i][j] = .25;
     for(int n = 1; n < radius;n++) {
       drawCirlceBdr(i,j,n);
     }
   }
   void drawCirlceBdr(int i, int j, int radius) {
    int x = radius-1;
    int y = 0;
    int dx = 1;
    int dy = 1;
    int err = dx - (radius << 1);
     while (x >= y)
    {
        U[i + x][j + y] = .5;
        U[i + y][j + x] = .5;
        U[i - y][j + x] = .5;
        U[i - x][j + y] = .5;
        U[i - x][j - y] = .5;
        U[i - y][j - x] = .5;
        U[i + y][j - x] = .5;
        U[i + x][j - y] = .5;
        V[i + x][j + y] = .25;
        V[i + y][j + x] = .25;
        V[i - y][j + x] = .25;
        V[i - x][j + y] = .25;
        V[i - x][j - y] = .25;
        V[i - y][j - x] = .25;
        V[i + y][j - x] = .25;
        V[i + x][j - y] = .25;

        if (err <= 0)
        {
            y++;
            err += dy;
            dy += 2;
        }
        
        if (err > 0)
        {
            x--;
            dx += 2;
            err += dx - (radius << 1);
        }
    }

   }
   void drawRecBdr(int sCol, int eCol, int sRow, int eRow) {
     for (int i = sCol; i < eCol; i++) {
          U[i][sRow] = .5;
          V[i][sRow] = .25;
          U[i][eRow] = .5;
          V[i][eRow] = .25;
        }
        for (int j = sRow; j < eRow; j++) {
          U[sCol][j] = .5;
          V[sCol][j] = .25;
          U[eCol][j] = .5;
          V[eCol][j] = .25;
        }
   }
   void drawRandom() {
     // You should feel free to 
     // create more than one such block if you want to break up 
     // the symmetry of the patterns that will form.
     for (int c = 0; c < 10; c++) {
       int starti = min(int(random(10, COLS-10)),COLS-10);
       int startj = min(int(random(10, ROWS-10)),ROWS-10);
       // Then, within a  10 by 10 block of pixels, set
       // the cell values to be u = 0.5, v = 0.25.
       for (int i = starti; i < starti+10; i++) {
         for (int j = startj; j < startj+10; j ++) {
           U[i][j] = .5;
           V[i][j] = .25;
         }
       }
     }
   }
   void resetUV() {
     //To initialize your grid of cells, first set each cell
     // to have values u = 1, v = 0. 
     for (int i = 0; i < COLS; i++) {
       for (int j = 0; j < ROWS; j++) { 
          U[i][j] = 1;
          dU[i][j] = 1;
          V[i][j] = 0;
        }
     }
      int col4th = (COLS/4);
      int colhalf = (COLS/2);
      int rowhalf = (ROWS/2);
      int col34th = (3*COLS)/4;
      int row4th = (ROWS/4);
      int row34th = (3*ROWS)/4;
      switch(drawType) {
        case drawRecFill:
         drawRecFill(col4th, col34th, row4th, row34th);
         break;
        case drawRecBdr:
          drawRecBdr(col4th, col34th, row4th, row34th);
          break;
        case drawCirlceFill: 
          drawCirlceFill(colhalf, rowhalf, row4th);
          break;
        case drawCircleBdr:
          drawCirlceBdr(colhalf, rowhalf, row4th);
          break;
        case drawRandom: 
          drawRandom();
          break;
        case draw1Cell:
           U[colhalf][rowhalf] = 1;//.5;
           V[colhalf][rowhalf] = 1;//.25;
           break;
      }
   }

  void swapgrids() {
    swapUs();
    swapVs();
  }

  void swapUs() {
    float[][] tmp = U;
    U = dU;
    dU = U;
  }

  void swapVs() {
    float[][] tmp = V;
    V = dV;
    dV = tmp;
  }
  
int getIndex(int index, int modBy) {
  return (index + modBy) % modBy;
}

int getColIndex(int index) {
  return getIndex(index, COLS);
}

int getRowIndex(int index) {
  return getIndex(index, ROWS);
}

  float laplace(int i, int j, float[][] mat) {
    float sum = 0.0;
    for(int x = i-1; x <= i+1; x++) {
      for(int y = j-1; y <= j+1;y++) {
        int xmod = getColIndex(x);
        int ymod = getRowIndex(y);
        switch(laplacianType) {
          case lClass:
            sum += laplaceClass(xmod,ymod,i,j,mat);
            break;
          case lex:
            sum += laplaceEx(xmod,ymod,i,j,mat);
            break;
          case lPearson:
            sum += laplacePearson(xmod,ymod,i,j,mat);
            break;
        };
      }
    }
    return sum;
  }
  // https://homepages.inf.ed.ac.uk/rbf/HIPR2/log.htm
  float laplaceEx(int x, int y, int i, int j,float[][] mat) {
    if(x == i && y==j){ 
      return mat[x][y]*-8;
    }
    return mat[x][y];
  }

  // negative Laplacian
  // https://academic.mu.edu/phys/matthysd/web226/Lab02.htm
  // this is the laplace we covered in class
  float laplaceClass(int x, int y, int i, int j,float[][] mat) {
        if(x == i && y==j){
          return mat[x][y] * -4;
        } else if(x == i || y == j){
          return mat[x][y];
        }
        return 0; // diag
  }

  //"Complex Patterns in a Simple" System (Pearson convolution)
  // http://www.karlsims.com/rd.html
  // https://mrob.com/pub/comp/xmorphia/pearson-classes.html
  // https://mrob.com/pub/comp/xmorphia/
  // The Laplacian is performed with a 3x3 convolution 
  // with center weight -1, adjacent neighbors .2, and diagonals .05.
  float laplacePearson(int x, int y, int i, int j,float[][] mat) {
    if(x == i && y==j){
          return mat[x][y] * -1; // center
    } else if(x == i || y == j){
      return mat[x][y] * 0.2; // sides
    } 
      return mat[x][y] *0.05; // diag
  }

  void update(float timeStep) {
    for (int i = 0; i < COLS; i++) {
          for (int j = 0; j < ROWS; j ++) {
            //du/dt = ru * laplace^2*u -u*v^2 + f(1-u)
            //dv/dt = rv * lapace^2*v + uv^2 - (f+k)v
            float u = U[i][j];
            float v = V[i][j];
            float feed = f;
            float kill = k;
            if(bspatiallyVarying) {
              feed = fVertArr[j];
              kill = kHorzArr[i];
            }
            float diffusionU = ru * laplace(i,j,U);
            float diffusionV = rv * laplace(i,j,V);
            float uvsq = (u*sq(v));
            float dudt,dvdt;
            if(bOnlyDiffusion) {
              dudt = diffusionU;
              dvdt = diffusionV;
            } else {
              dudt = diffusionU - uvsq + (feed * ( 1 - u ));
              dvdt = diffusionV + uvsq - (( feed + kill ) * v);
            }
            dU[i][j] = u + dudt*timeStep;
            dV[i][j] = v + dvdt*timeStep;
            //********DEBUG CODE***********//
            //if(bSetStepMode && i == COLS/2 && j == ROWS/2) {
            //  println("diffusionU: "+ diffusionU);
            //  println("diffusionV: "+ diffusionV);
            //  println("uv^2: " + uvsq);
            //  println("u: " + u);
            //  println("v: " + v);
            //}
            //constrain(dU[i][j],0,1);
            //constrain(dV[i][j],0,1);
          }
    }
  }
  color getColor(float u, float v) {
    if(bColor) {
      if(!bDrawU && bDrawV) { 
        return color(0,0, (int)(v*255));
      } else if(bDrawU && !bDrawV) { 
        return color((int)(u*255),0, 0);
      } else { // true true or false false
        return color((int)(u*255),0, (int)(v*255));
      }
    }else {
      if(!bDrawU && bDrawV) { 
        return color(v*255);
      } else if(bDrawU && !bDrawV) { 
        return color(u*255);
      } else { // true true or false false
        return color((u-v)*255);
      }
    }
  }
  void writeLine(String S, int i) {
    // writes S at line i
    text(S, 30, 25+i*20);
  }
   void drawInstructions() {
     if(bColor) {
       fill(color(255));
     } else {
       fill(color(255,0,0));
     }
     int L=0; // line counter, incremented below for ech line
     if(bShowInstructions) {
        writeLine("(press i) to init rectancle: ",L++);
        writeLine("(press spacebar) Game is: " + (bPaused ? "paused" : "running") , L++);
        writeLine("(press u) draw values for u set to: "+bDrawU.toString(), L++);
        writeLine("(press v) draw values for v set to: "+bDrawV.toString(), L++);
        writeLine("(press b) draw values for u and v.", L++);
        writeLine("(press d) diffusion mode is: " +(bOnlyDiffusion ? "diffusion.": "reaction-diffusion."), L++);
        writeLine("(press p) Toggle spatially-varying params: " + bspatiallyVarying.toString() , L++);
        writeLine("(press 1-4) to change mode. CurrentMode: "+ currentMode ,L++);
        writeLine("(press l) Laplace Mode: "+ laplaceNames[laplacianType] ,L++);
        writeLine("(press t) Draw Mode: " + drawModeNames[drawType] ,L++);
        writeLine("(press q) to hide instructions.",L++);
        writeLine("(press c) to switch color mode.",L++);
        writeLine("(press r) to enter resize " + (!bResize ? "window mode" : "cell dimmensions mode"),L++);
        writeLine("(press +) to increase " + (bResize ? "window size" : "cell dimmensions"),L++);
        writeLine("(press -) to decrease " + (bResize ? "window size" : "cell dimmensions"),L++);
        writeLine("cell dimmensions: " + cellDimm,L++);
        writeLine("window size: " + szDimm + " by " + szDimm,L++);
        writeLine("(press s) step mode: "+bSetStepMode.toString(), L++);
        if(bSetStepMode) {
          writeLine("(press right arrow) to step",L++);
        }
     } else {
        writeLine("(press q) to show instructions.",L++);
     }
   }
   void draw() {
     if(!bPaused) {
       update(1);
     }
     if(cellDimm == 1) {
      loadPixels();
     } else {
       if(!bDrawU && bDrawV) {
         background(color(0));
       } else {
          if(bColor) {
            background(color(255,0,0));
          } else {
            background(color(255));
          }
       }
     }
     for (int i = 0; i < COLS; i++) {
       for (int j = 0; j < ROWS; j ++) {
         float u = dU[i][j];
         float v = dV[i][j];
         color c = getColor(u,v);
         if(cellDimm == 1) {
           int pos = i + j * width;
           pixels[pos] = c;
         } else {
           noStroke();
           fill(c);
           ellipse(i*cellDimm,j*cellDimm,cellDimm,cellDimm);
         }
       }
     }
     if(cellDimm == 1) {
      updatePixels();
     }
     if(!bPaused) {
      swapgrids();
     }
     drawInstructions();
     if(bSetStepMode) {
       bPaused = true;
     }
   }
   
   void keyPressed() {
     if(bSetStepMode && keyCode == RIGHT) {
       bPaused = false;
     }
     switch(key) {
       // i - Initialize the system with a fixed rectangular region that has specific u and v concentrations (more on this below).
       case 'i':
       int tempDrawType = drawType;
       drawType = drawRecFill;
       resetUV();
       drawType = tempDrawType;
       break;
       // space bar - Start or stop the simulation (toggle between these).
       case ' ':
       bPaused = ! bPaused;
       break;
       //u - At each timestep, draw values for u for each cell (default).
       case 'u':
       bDrawU = true;
       bDrawV = false;
       break;
       //v - At each timestep, draw values for v.
       case 'v':
       bDrawV = true;
       bDrawU = false;
       break;
       case 'b':
       bDrawV = true;
       bDrawU = true;
       break;
       //d - Toggle between performing diffusion alone or reaction-diffusion (reaction-diffusion is default).
       case 'd':
       bOnlyDiffusion = !bOnlyDiffusion;
       break;
       //p - Toggle between constant parameters for each cell and spatially-varying parameters f and k (more on this below).
       case 'p':
       bspatiallyVarying = !bspatiallyVarying;
       break;
       //1 - Set parameters for spots (k = 0.0625, f = 0.035)
       case '1':
       k = ks[0];
       f = fs[0];
       currentMode = 1;
       break;
       //2 - Set parameters for stripes (k = 0.06, f = 0.035)
       case '2':
       k = ks[1];
       f = fs[0];
       currentMode = 2;
       break;
       //3 - Set parameters for spiral waves (k = 0.0475, f = 0.0118)
       case '3':
       k = ks[2];
       f = fs[1];
       currentMode = 3;
       break;
       //4 - Parameter settings of your choice, but should create some kind of pattern.  Use your spatially-varying 
       case '4':
       // should cause a picture frame pattern
       k = ks[ks.length-1];
       f = fs[fs.length-1];
       currentMode = 4;
       break;
       case 's':
        bSetStepMode = !bSetStepMode;
        if(!bSetStepMode) {
          bPaused = false;
        }
        break;
       case 'q':
        bShowInstructions = ! bShowInstructions;
        break;
       case 't':
          if(drawType < drawTypeMax) {
            drawType++;
          } else {
            drawType = 0;
          }
          resetUV();
          println("drawType:" + drawType);
          break;
       case 'l':
          if(laplacianType < laplacianTypeMax) {
            laplacianType++;
          } else {
            laplacianType = 0;
          }
          break;
       case 'c':
        bColor = !bColor;
        break;
       case 'r':
        bResize = !bResize;
        szDimm = width;
        break;
       case '+':
       case '=':
       bPaused = true;
       if(bResize) {
         if(szDimm <= 600) {
           szDimm +=100;
           surface.setSize(szDimm,szDimm);
         }
       }else {
        if(cellDimm < cellDimmMax) {
          cellDimm++;
        }
       }
       updateCellDimm();
       bPaused = false;
       break;
      case '-':
      bPaused = true;
      if(bResize) {
         if(szDimm > 100) {
           szDimm -=100;
           surface.setSize(szDimm,szDimm);
         }
       }else {
         if(cellDimm > 1) {
           cellDimm--;
        }
      }
      updateCellDimm();
      bPaused = false;
      break;
     }
   }
