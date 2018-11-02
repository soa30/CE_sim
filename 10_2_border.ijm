var myBox, myTess;
        
var width, length, bigwidth, biglength;
var cellarea, diam, nall, nreal, ncorn, nbord, nfake;
var realx, realy, realfx, realfy;
var bordx, bordy, bordfx, bordfy;
var fakex, fakey, fakefx, fakefy;
var length_before, length_after, width_before, width_after, dlength, dwidth;
var xCen, yCen,typeCen, restCen;
var xFor, yFor;
var xcenter, ycenter;

var mu, pi;

var filename;   


// Define all variables
// Define all functions
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
    

function randRest()
{
    base = random();
    
    value = 0.6 + base*0.8;

    return value;
}

function initfakeCORN()
{

    offset = 0; //begin indexing to count nodes and assign identities
    // upper lefthand corner
    xCen[1+offset] = ((bigwidth-width)/2);
    yCen[1+offset] = ((biglength-length)/2);
    typeCen[1+offset] = "upperleft";
    restCen[1+offset] = randRest();
    
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
    
    nall = nall + 4; //adjust total number of cells 
    
}
    
function initfakeBORD()
{

    offset = nall;

// Calculate number of cells to be placed on length and width of bounding box
    
    nlength = nbord *length/(length+width);
    nlength = floor(nlength/2) +1;
    
    nwidth = nbord * width /(length+width);
    nwidth = floor(nwidth/2) + 1;
    
    dlen = length-diam;
    dwid = width-diam;
    
// place cells along length and width with loop for even spacing 
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
    nall = nbord+ncorn; //update nall to include corner and border
    
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

	// fake cells are placed randomly within the borders when initiated    
    for (i=1;i<=nfake;i++)
    {
        xpos =  0.5*width + random()*dwid + dsp;
        ypos = 0.5*length + random()*dlen + dsp;
        
        xCen[i + offset] = xpos;
        yCen[i + offset] = ypos;
        typeCen[i + offset] = "fake free cell";  //assign identity 
        restCen[i + offset] = randRest();
    }
    

    nall = nall + nfake;  // update total number of cells to include fake cells

}

function moveCenter(center)
{
    
    i = center;

    xFor[i] = 0.;
    yFor[i] = 0.;
  	//set up equations of motion 
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

    deltax = xFor[i];
    deltay = yFor[i];

	// specify movenment rules for each type of cell
	// Corners are stiff and only move based on "playground" adjustment
	if ((indexOf(typeCen[center], "upperleft")!=-1))
	{
		xCen[center] = ((bigwidth-width)/2);
    	yCen[center] = ((biglength-length)/2);

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

    // borders move with playground adjustment + random motion along line of initialization
    else if ((indexOf(typeCen[center], "rightborder")!=-1))
    {
        yCen[center] = yCen[center] + (deltay*mu);
        xCen[center] = xCen[center] + (dwidth/2); 
    
    }
	else if  ((indexOf(typeCen[center], "leftborder")!=-1))
    {
    	yCen[center] = yCen[center] + (deltay*mu);
    	xCen[center] = xCen[center] - (dwidth/2);
    }
    else if  ((indexOf(typeCen[center],"topborder")!= -1)) 
    {
       xCen[center] = xCen[center] + (deltax*mu);
       yCen[center] = yCen[center] - (dlength/2);
       
    }
    else if  ((indexOf(typeCen[center], "bottomborder")!= -1))
    {
       xCen[center] = xCen[center] + (deltax*mu);
       yCen[center] = yCen[center] + (dlength/2);
    }
    else if (indexOf(typeCen[center],"free")!=-1)
    {
        xCen[center] =  xCen[center] + deltax*mu;
        yCen[center] =  yCen[center] + deltay*mu;
        
    }
    else
    {
        // If there is a cell type not specified, error message will show 
        z=(typeCen[i]);
        bigstring = "Cannot decide what to do with cells:" + typeCen[center];
        print("Cannot decide what to do with cell #:", i, "   typecen= " , z);
        showMessage(bigstring);
        roiManager("reset");
        exit;
    }
}

function moveAllCenters()
{
	// Move number of centers equal to number of cells
    for (i= 1; i<=(nall); i++)
    {
        moveCenter(i);

    }

}


function drawAllCenters()
{
    selectWindow(myBox);
    run("Add Slice");
    
    xsize = 4;
    osize = 3;
	// all cells shown in open white circles except for corner cells
    for (i= 1; i<=nall; i++)
    {
        x = xCen[i];
        y = yCen[i];

        if (((indexOf(typeCen[i], "upperleft"))!=-1) || ((indexOf(typeCen[i], "upperright"))!=-1) || ((indexOf(typeCen[i], "lowerleft"))!=-1) || ((indexOf(typeCen[i], "lowerright"))!=-1))   
        {
            moveTo(x-osize, y-osize);
            setColor(255,0,0);
            drawOval(x-osize, y-osize, 4*osize, 4*osize);    
            fillOval(x-osize, y-osize, 4*osize, 4*osize);        
        }
        else 
        {
            moveTo(x-osize, y-osize);
            setColor(255,255,255);
            drawOval(x-osize, y-osize, 2*osize, 2*osize);    
        }
      }
     

}


function isOutside(x,y)
{
    result = false;
    
    if (x >= ((((bigwidth-width)/2)+width)+20) || x < 0 || y >= ((((biglength-length)/2)+length)+20) || y < 0 || x <= (((bigwidth-width)/2)-20) || y <= (((biglength-length)/2)-20)    )
    {
        result = true;
    }
    
    return result;
}

function checkIfOutside(k)
{
	// border cells initialized in the same spot as corner cells are booted out
	// this does not affect the simulation, but let's put them back in as the equilibration is occurring
    for (i= 1; i<=nall; i++)
    {
        x = xCen[i];
        y = yCen[i];
        
        if ((indexOf(typeCen[i],"topborder")!=-1) || (indexOf(typeCen[i],"bottomborder")!=-1) || (indexOf(typeCen[i],"leftborder")!=-1) || (indexOf(typeCen[i],"rightborder")!=-1))
        {
            // if outside the play space then put them back in 

            while (isOutside(x,y))
            {

                dwid = width - 2*diam;
                dlen = length - 2*diam;
                
                xpos = random()*dwid + diam;
                ypos = random()*dlen + diam;

                xCen[i] = xpos + (((bigwidth-width)/2));
                yCen[i] = ypos + (((biglength-length)/2));
                
  
                x = xCen[i];
                y = yCen[i];
            }

        }
       
      }
}


function reportCenters()
{
    for (i= 1; i<=nall; i++)
    {
    	// keep track of locations
        x = xCen[i];
        y = yCen[i];
        tinystr = typeCen[i];
        
      }
}

function centers2roisSAVE(k)
{
    
    // set a file in which to save ROI information for all centers for each timestep
    for (i= 1; i<=nall; i++)
    {
        x = xCen[i];
        y = yCen[i];
        
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

    selectWindow(myTess);
    run("Add Slice");
    roiManager("Open", "/home/davidson/Downloads/ROITEST/RoiSet"+k+".zip");
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
  
    length = (scale*length)+length;
    length_after = length;
    width = area/length;
    width_after= width;
    dlength = length_after-length_before;
    dwidth = width_after-width_before;
    
}

macro "Run convergence extension"
{

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
    

    initbox(biglength,bigwidth);
    // Set cell properties based on previous data
    cellarea= 2896;
    diam = 66.7734;


    ncorn = 4;

//
//    estimate the number of fake border cells 

    nbord = 2*(length+width)/diam;

//
//     put border cells under massive compressive strain
//
    nbord = 1.6*nbord;

    nbord = floor(nbord)+1;
    
    if (nbord <= 4)
    {
        showMessage("Need to increase size - not enough room for border cells");
        exit;
    }
    
//
//    number of fake cells in tissue
//

    print("Done with initialization: width is: ", width, " length is: ", length);
    
    initfakeCORN();    
    
    initfakeBORD(); // can adjust the number of border cells based on fitting and rounding...
    
    nfake = (length*width/cellarea) - nreal - 0.5*nbord - 0.25*ncorn;

//     put fake interior cells under 15% isotropic compressive strain
//    
    nfake = (1.2*nfake);
    
    nfake = floor(nfake)+1;    
    print("Initialize fake cells.");
    initfakeCELL();
    print("There are", nbord," border cells, and ", nfake, " fake cells between real and border.");
    print("There are", nfake+nbord+ncorn, "total cells");
    

    mu = 30;


    print("Enter loop to initialize and equilibrate cells within borders");


    
    initTess(biglength,bigwidth);
    for (k=0 ; k<= 100; k++)
    {
    	moveAllCenters();
    	checkIfOutside(k);
    }

   print("Enter loop to change size of playground and observe convergence extension");
   print("Make sure you set a file for ROIs to save to in the tesselate function. Clear this folder if you change the number of timesteps. Tesselation takes a long time.");
    for (k=100 ; k<= 400; k++)
    {
        playground();
  
        moveAllCenters();

        drawAllCenters();
      
        // need to convert centers to ROIs in each loop
        centers2roisSAVE(k);
        tesselate(k);
        
    }
    print("Stretching complete at time", k);

    print("The final length is:  ", length, " & the final width is:  ", width);

    setBatchMode("exit and display");

  selectWindow(myBox);
   run("Select None");
 selectWindow(myTess);
    print("Exit loop to move all cells.");

    print("Report centers of all cells");
    reportCenters();

    
}




