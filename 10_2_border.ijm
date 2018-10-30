var myBox, myRealMask, myTess;
        
var width, length, bigwidth, biglength;
var cellarea, diam, nall, nreal, ncorn, nbord, nfake;
var realx, realy, realfx, realfy;
var bordx, bordy, bordfx, bordfy;
var fakex, fakey, fakefx, fakefy;
var length_before, length_after, width_before, width_after, dlength, dwidth;
var xCen, yCen,typeCen, restCen;
var xFor, yFor;
var xcenter, ycenter;

var mu, pi

var dt, vi, vx, nmoving, filename;   //add vy and angle later
;


//
// PREPROCESSING
//
//
//
//
// Step-wise Description:
//
//    1. Initialize dimensions of containing box
//    2. Import real cell ROIs (renames by index)
//    3. Set up real cell centers and calculate average area and diameter.
//    4. Using real_cell values place fake cells in corners, borders, and between border and real cells.
//    5. Run simulation to allow fake cells on border to move toward equi-distant positions.
//        a. calculate forces based on simple repulsive spring between cell centers on boundary.
//        b. move cells along border according to langevin-equation.
//            i. do not move corner cells or real cells.
//            ii. border cells constrained to border.
//    6. Run simulation to allow fake cells in_tissue and on borders (but not corners or real cell)
//       to move toward equi-distant positions.
//        a. calculate forces based on simple repulsive spring between all cell centers.
//        b. move cells according to langevin-equation.
//            i. do not move corner cells or other designated 'fixed' cells
//            ii. border cell movement constrained to border.
//            iii. fake cells are free to move in any direction.
//        c. if fake cells move out of the box - move them to new random position.
//
//
// POST PROCESSING
//
//
//
//


function initbox(biglength, bigwidth)
{
    
    newImage("ForTile", "8-bit black", biglength, bigwidth, 1);
    myBox = getTitle();
    
}

function initTess(biglength, bigwidth)
{
    
    newImage("TesselateTile", "8-bit black", biglength, bigwidth, 1);
    myTess = getTitle();
    
}

function importROI()
{
    roiManager("Open", "/home/davidson/Downloads/RoiSet3cells.zip");
}

function recenterROI()
{
    run("Select None");
    
    wid = getWidth();
    hei = getHeight();
    
    maxx = 0;
    maxy = 0;
    
    minx = wid;
    miny = hei;
    
    
    ncount = roiManager("Count");
    
    for (i=0; i<ncount; i++)
    {
        roiManager("Select", i);
        getSelectionBounds(x, y, w, h);
//        roiManager("deselect")
        
        midx = x + w/2;
        midy = y + h/2;
        
        if (midx < minx) minx = midx;
        if (midx > maxx) maxx = midx;
        
        if (midy < miny) miny = midy;
        if (midy > maxy) maxy = midy;    
    }
    
//
//    what is the best offset to center the ROI?
//

    halfX = (minx + maxx)/2;
    
    halfY = (miny + maxy)/2;
    
    offsetx = (wid/2) - halfX;
    offsety = (hei/2) - halfY;
    
    
    for (i=0; i<ncount; i++)
    {
        roiManager("Select", i);
        getSelectionBounds(x, y, w, h);
        
        if ((x+offsetx > wid || x+offsetx < 0) || (y+offsety > hei || y+offsety < 0))
        {

            showMessage("Real cell ROIs are out of bounds... need larger container");
            exit;
                
        }
        setSelectionLocation(x+offsetx, y+offsety);
        
        
        roiManager("Update");
//        roiManager("deselect")

    }
    
}


function makeAreaMask()
{
    selectWindow(myBox);
    
    setForegroundColor(255,255,255);
    
    wid = getWidth();
    hei = getHeight();
    
    newImage("realMask", "8-bit black", wid, hei, 0);
    
    myRealMask = getTitle();
    
    for (i=1; i<=nreal; i++)
    {
        index = i-1;

        roiManager("select", index);
//        run("Enlarge...", "enlarge="+0.1*diam);
        run("Enlarge...", "enlarge=1");
        run("Fill", "slice");
    }
    selectWindow(myBox);
}

function initreal()
{

    selectWindow(myBox);
    nreal = roiManager("count");
    
    run("Set Measurements...", "area centroid redirect=None decimal=3");

    print("There are ",nreal," real cell ROIs in the box");
    
    total = 0;
    
    recenterROI();
    
    for (i=1; i<=nreal; i++)
    {
        index = i-1;
        
        roiManager("select", index);
        run("Measure");
        area = getResult("Area", index);
        x = getResult("X",index);
        y = getResult("Y",index);

        xCen[i] = x;
        yCen[i] = y;
//        typeCen[i] = "real";
        typeCen[i] = "real mark fix";

        
        restCen[i] = 1;

//        print("Cell: ", i," has Area: ", area," and position (", x, ", ", y,")");

        total = total + area;
    }
    
    cellarea = total/(nreal);
    
//
//    diameter of cells -- assume hexagonal packing
//
    pi = 4*atan(1.);
        
//    diam = 2*sqrt(cellarea/pi);
        
//    diam = 2*sqrt(cellarea / (2*sqrt(3)));

    diam = 2*sqrt(2*cellarea / (3*sqrt(3)));

        
    makeAreaMask();
    
    print(nreal," Cells have an average area: ", cellarea, " and a diameter:, ", diam);
    
    nall = nall + nreal;

}    

function freeRealCells()
{
    print("Freeing ",nreal," real cells to allow movement in the box");
    
    for (i=1; i<=nreal; i++)
    {
        index = i-1;
        typeCen[i] = "real mark free cell";
    }
}    

function randRest()
{
    base = random();
    
    value = 0.6 + base*0.8;

    return value;
}

function initfakeCORN()
{

    offset = 0;
    // upper lefthand corner
    xCen[1+offset] = ((bigwidth-width)/2);
    yCen[1+offset] = ((biglength-length)/2);
    typeCen[1+offset] = "upperleft";
    restCen[1+offset] = randRest();
    //print("Upperleft corner initialized");
    //lower lefthand corner
    xCen[2+offset] = ((bigwidth-width)/2);
    yCen[2+offset] = (((biglength-length)/2)+length);
    typeCen[2+offset] = "lowerleft";
    restCen[2+offset] = randRest();

    //upper righthand corner
    xCen[3+offset] = (((bigwidth-width)/2)+width);
    yCen[3+offset] = ((biglength-length)/2);
    typeCen[3+offset] = "upperright";
    restCen[3+offset] = randRest();

    //lower righthand corner
    xCen[4+offset] = (((bigwidth-width)/2)+width);
    yCen[4+offset] =  (((biglength-length)/2)+length);
    typeCen[4+offset] = "lowerright";
    restCen[4+offset] = randRest();
    
    nall = nall + 4;
    
}
    
function initfakeBORD()
{

    offset = nall;

// how many cells on length and width sides?
    
    nlength = nbord *length/(length+width);
    nlength = floor(nlength/2) +1;
    
    nwidth = nbord * width /(length+width);
    nwidth = floor(nwidth/2) + 1;
    
    dlen = length-diam;
    dwid = width-diam;
    
    //print ("In initfakeBORD, dlen: ", dlen, " dwid: ", dwid, " diam: ", diam);

    for (i=1; i<=nwidth; i++)
    {
        ypos = (((biglength-length)/2));
        xpos = (((bigwidth-width)/2))+((i/nwidth)*width);
        xCen[i + offset] = xpos;
        yCen[i + offset] = ypos;
        typeCen[i + offset] = "topborder";
        restCen[i + offset] = randRest();
        
    }
    
    for (i=1; i<=nwidth; i++)
    {
        ypos =  (((biglength-length)/2)+length);
                
        xpos = ((bigwidth-width)/2) + ((i/nwidth)*width);
        
        xCen[i + nwidth + offset] = xpos;
        yCen[i + nwidth + offset] = ypos;
        typeCen[i + nwidth + offset] = "bottomborder";
        restCen[i + nwidth + offset] = randRest();
        

    }

    for (i=1; i<=nlength; i++)
    {
        xpos =  (((bigwidth-width)/2));
        
        ypos = (((biglength-length)/2)) + ((i/nlength)*length);
        
        xCen[i + 2*nwidth + offset] = xpos;
        yCen[i + 2*nwidth + offset] = ypos;
        typeCen[i + 2*nwidth + offset] = "leftborder";
        restCen[i + 2*nwidth + offset] = randRest();
        
    }

    for (i=1; i<=nlength; i++)
    {
        xpos =  (((bigwidth-width)/2)+width);
                
        ypos = (((biglength-length)/2)) + ((i/nlength)*length);
        
        xCen[i + 2*nwidth + nlength + offset] = xpos;
        yCen[i + 2*nwidth + nlength + offset] = ypos;
        typeCen[i + 2*nwidth + nlength + offset] = "rightborder";
        restCen[i + 2*nwidth + nlength + offset] = randRest();
        
    }

    nbord = 2*nwidth + 2*nlength;
    nall = nbord+ncorn;
    
}

function initfakeCELL()
{

    offset = nall;
    
    nlength = nbord *length/(length+width);
    nlength = floor(nlength/2);
    
    nwidth = nbord * width /(length+width);
    nwidth = floor(nwidth/2);
    
    dsp = diam;
    
    dlen = length - 2*dsp;
    dwid = width - 2*dsp;

    
    for (i=1;i<=nfake;i++)
    {
        xpos =  0.5*width + random()*dwid + dsp;
        ypos = 0.5*length + random()*dlen + dsp;
        
        xCen[i + offset] = xpos;
        yCen[i + offset] = ypos;
        typeCen[i + offset] = "fake free cell";
        restCen[i + offset] = randRest();
    }
    

    nall = nall + nfake;

}

// Create a function to create a few fake cells to which to assign a velocity
function initMOVINGcell()
{
    offset = nreal + nfake + ncorn + nbord;
    
    nlength = nbord *length/(length+width);
    nlength = floor(nlength/2);
    
    nwidth = nbord * width /(length+width);
    nwidth = floor(nwidth/2);
    
    dsp = diam;
    
    dlen = length - 2*dsp;
    dwid = width - 2*dsp;


    for (i=1;i<=nmoving; i++)
    {
        xpos = 0.5*width + random()*dwid + dsp;
        ypos = 0.5*length + random()*dlen + dsp;
        
        xCen[i + offset] = xpos;
        yCen[i + offset] = ypos;
        typeCen[i + offset] = "fake moving cell";
        restCen[i + offset] = randRest();
        print(typeCen[i+offset]);
        print("Velocity cell", i+offset, "initialized at", xCen[i+offset],yCen[i+offset]);
    }
    nall= nall + nmoving;
}


function moveCenter(center)
{
    
    i = center;

    xFor[i] = 0.;
    yFor[i] = 0.;
    dt= 1;
    vx=vi;
    for (j= 1; j<=nall; j++)
    {
        dx = xCen[j] - xCen[i];
        dy = yCen[j] - yCen[i];
        
        dist = sqrt(dx*dx + dy*dy);
            
        rest = (restCen[i]+restCen[j])*diam/2.;
        
        if ((dist<(1.0*rest)) && (dist != 0))
        {
            xFor[i] = xFor[i] + ((dist - rest)/rest)*(dx/dist);
            yFor[i] = yFor[i] + ((dist - rest)/rest)*(dy/dist);

        
        }
    }
 //   if  (i>=124)
   // {
     //   typeCen[i]= "fake free cell";
  //  }
    deltax = xFor[i];
    deltay = yFor[i];
    
//    print("MoveCenter: x = ", xCen[i], " y = ", yCen[i]);
//    print("   In moveCenter: dFx = ", deltax*mu, " dFy = ", deltay*mu);
    
//    print(center, "LOOK AT THIS");
	if ((indexOf(typeCen[center], "upperleft")!=-1))
	{
		xCen[center] = ((bigwidth-width)/2);
    	yCen[center] = ((biglength-length)/2);
    //	print("Upperleft corner moved");

	}
	 else if ((indexOf(typeCen[center], "lowerleft")!=-1))
    {
         xCen[center] = ((bigwidth-width)/2);
    	yCen[center] = (((biglength-length)/2)+length);
    }
     else if ((indexOf(typeCen[center], "upperright")!=-1))
    {
         xCen[center] = (((bigwidth-width)/2)+width);
    	yCen[center] = ((biglength-length)/2);
    }
     else if ((indexOf(typeCen[center], "lowerright")!=-1))
    {
          xCen[center] = (((bigwidth-width)/2)+width);
    	yCen[center] =  (((biglength-length)/2)+length);
    }
    else if ((indexOf(typeCen[center], "rightborder")!=-1))
    {
        yCen[center] = yCen[center] + 0.1*(deltay*mu);
        xCen[center] = xCen[center] + (dwidth/2); 
     //   print(center, "moved");
    }
	else if  ((indexOf(typeCen[center], "leftborder")!=-1))
    {
    	yCen[center] = yCen[center] + 0.1*(deltay*mu);
    	xCen[center] = xCen[center] - (dwidth/2);
    }
    else if  ((indexOf(typeCen[center],"topborder")!= -1)) 
    {
       xCen[center] = xCen[center] + 0.1*(deltax*mu);
       yCen[center] = yCen[center] - (dlength/2);
       //ypos = (((biglength-length)/2))
     //print("in moveCenter: top border");
    }
    else if  ((indexOf(typeCen[center], "bottomborder")!= -1))
    {
       xCen[center] = xCen[center] + 0.1*(deltax*mu);
       yCen[center] = yCen[center] + (dlength/2);
    }
    else if (indexOf(typeCen[center],"free")!=-1)
    {
        xCen[center] =  xCen[center] + deltax*mu;
        yCen[center] =  yCen[center] + deltay*mu;
        
//        print("in movecenter: fake cells");
    }
    else if  ((indexOf(typeCen[center], "moving")!=-1))
    {
        xCen[center] = xCen[center] + deltax*mu + vx*dt;
        yCen[center] = yCen[center] + deltay*mu ;
//        print("velocity cell", i, "moved to", xCen[i], yCen[i]);
    }
    else
    {
        z=(typeCen[i]);
      //  w=(typeCen[i-1]);
        // should not be here
        bigstring = "Cannot decide what to do with cells:" + typeCen[center];
        print("Cannot decide what to do with cell #:", i, "   typecen= " , z);
      //  print("previous type cen:  ",w);
        showMessage(bigstring);
        roiManager("reset");
        exit;
    }
}

// Use Vicsek model to assign velocity to moving cells


function moveAllCenters()
{

    for (i= 1; i<=(nall); i++)
    {
        moveCenter(i);
     //   print("In move centers ",i);

    }

}


function drawAllCenters()
{
    selectWindow(myBox);
    run("Add Slice");
    
    xsize = 4;
    osize = 3;

    for (i= 1; i<=nall; i++)
    {
        x = xCen[i];
        y = yCen[i];
        
        if ((indexOf(typeCen[i], "mark"))!=-1)
        {
            moveTo(x-osize, y-osize);
            setColor(255,255,255);
            drawOval(x-osize, y-osize, 2*osize, 2*osize);    
            fillOval(x-osize, y-osize, 2*osize, 2*osize);        
        }
        else if (((indexOf(typeCen[i], "upperleft"))!=-1) || ((indexOf(typeCen[i], "upperright"))!=-1) || ((indexOf(typeCen[i], "lowerleft"))!=-1) || ((indexOf(typeCen[i], "lowerright"))!=-1))   
        {
            moveTo(x-osize, y-osize);
            setColor(255,0,0);
            drawOval(x-osize, y-osize, 4*osize, 4*osize);    
            fillOval(x-osize, y-osize, 4*osize, 4*osize);        
        }
        else if ((indexOf(typeCen[i], "moving"))!=-1)
        {
            moveTo(x-osize, y-osize);
            setColor(255,0,0);
            drawOval(x-osize, y-osize, 4*osize, 4*osize);    
            fillOval(x-osize, y-osize, 4*osize, 4*osize);        
        }
        else //this is what the moving cells are being classified as
        {
            moveTo(x-osize, y-osize);
            setColor(255,255,255);
            drawOval(x-osize, y-osize, 2*osize, 2*osize);    
        }
      }
      // add another loop to make the moving cells a different color (red)

}


function isInside(x,y)
{
    selectWindow(myRealMask);
    
    
result = false;

    thispix = getPixel(x,y);
    
    if (thispix == 255)
    {
        result = true;
    }
    return result;
}

function isOutside(x,y)
{
    result = false;
    
    if (x >= (((bigwidth-width)/2)+width) || x < 0 || y >= (((biglength-length)/2)+length) || y < 0 || x <= ((bigwidth-width)/2) || y <= ((biglength-length)/2)    )
    {
        result = true;
    }
    
    return result;
}

function checkIfInside(k)
{
    for (i= 1; i<=nall; i++)
    {
        x = xCen[i];
        y = yCen[i];
        
        if (indexOf(typeCen[i],"free")!=-1)
        {
            // if inside the masked real cell area then move to a random location


            while (isInside(x,y))
            {

                dwid = width - 2*diam;
                dlen = length - 2*diam;
                
                xpos = random()*dwid + diam;
                ypos = random()*dlen + diam;

                xCen[i] = xpos + (((bigwidth-width)/2));
                yCen[i] = ypos + (((biglength-length)/2));
                
                print ("DANGER -- cell ", i, " moved from REAL_CELL area at time ", k," was at ", x, " and ", y);
                x = xCen[i];
                y = yCen[i];
            }

        }
        if (indexOf(typeCen[i],"moving")!=-1)
        {
            // if inside the masked real cell area then move to a random location


            while (isInside(x,y))
            {

                dwid = width - 2*diam;
                dlen = length - 2*diam;
                
                xpos = random()*dwid + diam;
                ypos = random()*dlen + diam;
                
                xCen[i] = xpos + (((bigwidth-width)/2));
                yCen[i] = ypos + (((biglength-length)/2));
                
                print ("MOVING cell ", i, " moved from REAL_CELL area at time ", k," was at ", x, " and ", y);
                x = xCen[i];
                y = yCen[i];
            }

        }
    }
}





function checkIfOutside(k)
{
    for (i= 1; i<=nall; i++)
    {
        x = xCen[i];
        y = yCen[i];
        
        if (indexOf(typeCen[i],"free")!=-1)
        {
            // if outside the play space then move to a random location


            while (isOutside(x,y))
            {

                dwid = width - 2*diam;
                dlen = length - 2*diam;
                
                xpos = random()*dwid + diam;
                ypos = random()*dlen + diam;

                xCen[i] = xpos + (((bigwidth-width)/2));
                yCen[i] = ypos + (((biglength-length)/2));
                
    //            print ("DANGER -- cell ", i, " moved from OUTSIDE_THE_BOX at time ", k," was at ", x, " and ", y);
                x = xCen[i];
                y = yCen[i];
            }

        }
        if (indexOf(typeCen[i],"moving")!=-1)
        {
            // if inside the masked real cell area then move to a random location


            while (isOutside(x,y))
            {

                dwid = width - 2*diam;
                dlen = length - 2*diam;
                
                xpos = random()*dwid + diam;
                ypos = random()*dlen + diam;

                xCen[i] = xpos;
                yCen[i] = ypos;
                
                print ("MOVING cell ", i, " moved from OUTSIDE area at time ", k," was at ", x, " and ", y);
                x = xCen[i];
                y = yCen[i];
            }

        }
        
      }
}

function fixCenter(center)
{

    x = xCen[center];
    y = yCen[center];

    if (x > width) x = x-width/2;
    if (x <= 0) x = x + width/2;
    if (y > length) y = y-length/2;
    if (y <= 0) y = y+length/2;
    
    xCen[center] = x;
    yCen[center] = y;

}

function reportCenters()
{
    for (i= 1; i<=nall; i++)
    {
        x = xCen[i];
        y = yCen[i];
        tinystr = typeCen[i];
        
//        bigstr = "Cell: "+ i + " of type: " + typeCen[i] + " is at ( "+xCen[i]+", " + yCen[i]+ ")."+" with rest_param "+restCen[i];
        
//        print (bigstr);
      }
}

function centers2roisSAVE(k)
{
    
    
    for (i= 1; i<=nall; i++)
    {
        x = xCen[i];
        y = yCen[i];
        
    //    setKeyDown("shift");
        makePoint(x, y);
        roiManager("Add");
        setKeyDown("shift");
      }
        roiManager("SelectAll");
        roiManager("Combine");
        filename[k]=("ROIset"+ k);
        roiManager("save", "/home/davidson/Downloads/ROITEST/RoiSet"+k+".zip");
        roiManager("reset");

}

function tesselate(k)
{

//    newImage("Untitled", "8-bit Black", width, length, 1);
//    run("ROI Manager...");

    roiManager("Open", "/home/davidson/Downloads/ROITEST/RoiSet"+k+".zip");
    selectWindow(myTess);
    run("Add Slice");
    setForegroundColor(255, 255, 255);
    run("Delaunay Voronoi", "mode=Voronoi interactive");
    setLineWidth(2);
    run("Delaunay Voronoi", "mode=Voronoi");
    
    setTool("wand");
    run("Set Measurements...", "area centroid center redirect=None decimal=3");
    
    ncells = roiManager("count");

//    print("number of ROIs read from file: ",ncells);

    for (i=0; i<ncells; i++)
    {
    
        roiManager("Select",i);
        run("Measure");

        xcenter[i] = getResult('X');
        
        if (xcenter[i] >= (width-1))
        {
            xcenter[i] = width-2;
        }
        else if (xcenter[i] < 1)
        {
            xcenter[i] = 2;
        }
        
        ycenter[i] = getResult('Y');
        
        if (ycenter[i] >= (length-1))
        {
            ycenter[i] = length-2;
        }
        else if (ycenter[i] < 1)
        {
            ycenter[i] = 2;
        }
//        print("cell: ", i," xcenter: ", xcenter[i], "ycenter: ", ycenter[i]);
    
    }

    roiManager("reset");
    
}
    
function playground()
{
    // need to change length and width to elongate field longitudinally while
    // maintaining a constant area
    area = 500*500;
    // need length to increase and width to decrease
	length_before = length;
	width_before = width;
    scale = 0.0005;
    //print ("length was", length);
    length = (scale*length)+length;
    length_after = length;
    width = area/length;
    width_after= width;
    dlength = length_after-length_before;
    dwidth = width_after-width_before;
    //print("new length is", length, ",new width is", width);
}

function cleanup()
{
selectWindow(myTess);
x_UL = ((bigwidth-width)/2);
y_UL = ((biglength-length)/2);

x_LL = ((bigwidth-width)/2);
y_LL = (((biglength-length)/2)+length);
 
x_UR = (((bigwidth-width)/2)+width);
y_UR = ((biglength-length)/2);

x_LR = (((bigwidth-width)/2)+width);
y_LR = (((biglength-length)/2)+length);

makePolygon(x_UL, y_UL, x_LL, y_LL,x_LR, y_LR, x_UR, y_UR);
run("Clear Outside", "slice");
}
macro "Run abbrevated"
{
//    run("Close All");
//
//    Initialize the arrays and fill with zeros
//
    setBatchMode(true);

    nsize = 3000;    // maximum number of cells
    nscale = 1.0    // multiplier for area of real cells to fake cells

    xCen = newArray(nsize);
    yCen = newArray(nsize);
    typeCen = newArray(nsize);
    restCen = newArray(nsize);
    xcenter = newArray(nsize);
    ycenter = newArray(nsize);
    xFor = newArray(nsize);
    yFor = newArray(nsize);
    filename = newArray(nsize);

    
    for (i=0; i<nsize; i++)
    {
    
        xCen[i] = 0;
        yCen[i] = 0;
        typeCen[i] = "";
        restCen[i] = 0;
        filename[i]= "";
    }

    nall = 0; // the total number of cell centers, real and fake

    nreal = 0;  // the number of real cells
    ncorn = 0;  // the number of fake cells at corners
    nbord = 0;  // the number of fake cells along borders (but not corners)
    nfake = 0;  // the number of fake cells between real and borders
    nmoving = 0; // the number of cells that will be assigned a velocity
    length = 500;
    width = 500;
    length_before= 0;
    width_before= 0;
    length_after=0;
    width_after=0;
    dlength= 0;
    dwidth=0;
    biglength= 1000;
    bigwidth= 1000;
    
    dt = 1;
    vi = 10;
    //angle = ((2*3.14)*0.0005);  // angle in radians
    vx = vi;
    //vy = vi*sin(angle);

    initbox(biglength,bigwidth);
    
//    importROI();
    
//    initreal();  // initialize the number of real cells
    cellarea= 2896;
    diam = 66.7734;
//    setBatchMode(true);

//
//    initialize the corners of the playspace.
//

    ncorn = 4;

//
//    estimate the number of fake border cells -- do not count include fake corners
//

    nbord = 2*(length+width)/diam;

//
//     put border cells under massive compressive strain
//
    nbord = 1.8*nbord;

    nbord = floor(nbord)+1;
    
    if (nbord <= 4)
    {
        showMessage("Need to increase size - not enough room for border cells");
        exit;
    }
    
   // nbord = nbord - 4;
    
//
//    number of fake cells in tissue
//

    print("Done with initialization: width is: ", width, " length is: ", length);
    
    initfakeCORN();    
    
    initfakeBORD(); // can adjust the number of border cells based on fitting and rounding...
    
    nfake = (length*width/cellarea) - nreal - 0.5*nbord - 0.25*ncorn;

//     put fake interior cells under 15% isotropic compressive strain
//    
    nfake = (1.2*nfake)-nmoving;
    
    nfake = floor(nfake)+1;    
    print("Initialize fake cells.");
    initfakeCELL();
    print("Numbers of real cells = ", nreal, ", 4 fake border cells, and ", nbord," fake border cells, and ", nfake, " fake cells between real and border.");
    print("There are", nfake+nmoving+nbord+ncorn, "total cells");
//    reportCenters();    

    mu = 30;
     
//
//    Begin loops to move cell centers to lowest energy state ?? But have not yet made fake cells between borders and real cell???
//

    print("Enter loop to move fake corner and border cells");

//    print("Width and Length: ", width, length);
    
   // for (k=0 ; k<= 200; k++)
 //   {
//        drawAllCenters();
 //       moveAllCenters();
  //  }

 //   print("Exit loop to move fake corner and border cells.");
//    drawAllCenters();
//    roiManager("Select all");
//    recenterROI();

  //  initMOVINGcell();
   // print("Moving Cells initialized");

//    checkIfInside(0);
    
//    print("Moving out of inside complete");
    
    drawAllCenters();
    print("Enter loop to move border, corner, and fake cells.");
    
    initTess(biglength,bigwidth);
    
    for (k=0 ; k<= 500; k++)
    {
        playground();
       // print("New playground initialized");
        //    ncorn = 4;
        //initfakeCORN();
        // print("New corners initialized");
        //    nbord = 2*(length+width)/diam;
       //     nbord = 1.4*nbord;
         //   nbord = floor(nbord)+1;
         //   nbord=nbord-4;
      //  initfakeBORD();
        //print("nbord= ",nbord);
        //print("new corners and borders initialized");
      //  nall = nfake + ncorn + nbord;
       // print("new total number of cells", nall);
        moveAllCenters();
        //stuck here 
    //  print("centers moved", k);
//        checkIfInside(k);
//        checkIfOutside(k);
        drawAllCenters();
      //  print("Timestep: ",k, "complete");
        // need to convert centers to ROIs in each loop
        centers2roisSAVE(k);
        tesselate(k);
        
    }
    print("Stretching complete at time", k);
//    print("Release real cells so they can move.");
    
//    freeRealCells();

//    print("Enter loop to move corner, border, fake, and real cells.");

 //   drawAllCenters();
    
//    for (k=301 ; k<= 400; k++)
//    {
//        playground();
//            ncorn = 4;
//            nbord = 2*(length+width)/diam;
//            nbord = 1.4*nbord;
//            nbord = floor(nbord)+1;
//            if (nbord <= 4)
//            {
//            showMessage("Need to increase size - not enough room for border cells");
//            exit;
//            }
//            nbord = nbord - 4;
//        initfakeCORN();
//        initfakeBORD();
//        nall = nfake+ncorn+nbord;
//        moveAllCenters();
//        checkIfOutside(k);
    //    drawAllCenters();
      //  centers2roisSAVE(k);
    //   tesselate(k);
//    }
    print("The final length is:  ", length, " & the final width is:  ", width);

    setBatchMode("exit and display");
//   selectWindow(myRealMask);
//    close();
  selectWindow(myBox);
   run("Select None");
 selectWindow(myTess);
//    print("Exit loop to move all cells.");

//    print("Report centers of all cells");
//    reportCenters();

    
}


//
//     To convert these cell centers to input files for Virtual cell requires parsing
//        ROIs into linked-list cell-vertex format.
//
//



