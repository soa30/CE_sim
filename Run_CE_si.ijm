var myBox, myTess;
        
var width, length, bigwidth, biglength;
var cellarea, diam, nall, nreal, ncorn, nbord, nfake;
var realx, realy, realfx, realfy;
var bordx, bordy, bordfx, bordfy;
var fakex, fakey, fakefx, fakefy;
var length_before, length_after, width_before, width_after, dlength, dwidth;
var xCen, yCen, xCen_old, yCen_old, typeCen, restCen, angle;
var xFor, yFor;
var xcenter, ycenter;

var mu, pi;

var filename, free, rando, new, nei, nei_ang, mean_ang ;   


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

function ArrayUnique(array) {
	array 	= Array.sort(array);
	array 	= Array.concat(array, 999999);
	uniqueA = newArray();
	i = 0;	
   	while (i<(array.length)-1) {
		if (array[i] == array[(i)+1]) {
			//print("found: "+array[i]);			
		} else {
			uniqueA = Array.concat(uniqueA, array[i]);
		}
   		i++;
   	}
	return uniqueA;
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

function randomizer()
{

	Table.create("Randomizing");
	new = newArray(3000);
	for (i = 0; i< nall; i++)
	{
		if ( (indexOf(typeCen[i],"free")!=-1) )
		{
			free[i] = i;
			rando[i] = 1000*random(); 
		}
	}
	
	Table.setColumn("Cell ID", free);
	Table.setColumn("Random", rando);
	Table.sort("Random");
	//	Table.update();


	for (i = 0; i < Table.size; i++) 
	{
		if( Table.get("Cell ID", i)!=0 ) 
		{
			new[i] = Table.get("Cell ID", i);
		}
	}
	new = Array.deleteValue(new, 0);

	j = 0;
	for(i = 0 ; i < free.length ; i++)
	{
		if (free[i] !=0)
		{
			free[i] = new[j];
			j++; 
		}
	}

	for (i = 0; i < free.length; i++) 
	{
		if( (free[i] == 0) && (i < nall) )
		{
			free[i] = i+1; //adding 1 bc left corner is 1, offset of 0 + 1 to start indexing 
		}
	}
	Table.reset;
	// replace old values in the typecen vector, too
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
  //  print("delta x is " + deltax + " and delta y is " + deltay);

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
    	if (k > 100 )
    	{
    		neighbors(center);
    		xCen[center] = xCen[center] + ( (cos(mean_ang*(PI/180))) );
    		yCen[center] = yCen[center] + ( (sin(mean_ang*(PI/180))) );
    	}
    	else if (k <= 100)
    	{
        	xCen[center] =  xCen[center] + deltax*mu;
        	yCen[center] =  yCen[center] + deltay*mu;
    	}
        
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

function neighbors(i)
{
	makeOval(xCen[i], yCen[i], 150, 150);
	updateDisplay();
	nei = newArray;
 	num = 0;
 	for (cell = 0 ; cell <nall ; cell++)
 	{
		for(y=0; y<nall; y++) { 
    		for(x=0; x<nall; x++) { 
    			// Need to exclude corner and border cells from neighbors list 
        		if( (Roi.contains(xCen[cell], yCen[cell])==1) && (indexOf(typeCen[cell],"free")!=-1) )
        		{ 
            		nei[num] = cell; 
            		num++;
        		} 
        		else {}
    		} 
		} 
 	}
 		nei = ArrayUnique(nei);
	//	Array.show(nei);

	// Make an array of the angles of all the neighbors (including center cell) 
	nei_ang = newArray;

	for (k = 0; k < nei.length; k++) 
	{
		nei_ang[k] = angle[nei[k]];
	}
	//Array.show(nei_ang);

	if (nei.length ==0)
	{
		mean_ang = 360*random();
	}

	// Take average of all the angles 
	Array.getStatistics(nei_ang, min, max, mean, stdDev);
	mean_ang = mean;
	//print("The mean angle is " + mean_ang);
	//run("Select None");
	
}

function moveAllCenters()
{
	// Move number of centers equal to number of cells

	// move centers in order of new order vector (after equilibration), not looping thru nall 
	if (k>=100)
	{
		//Array.show(free);
		for (j= 0; j<free.length; j++)
    	{
    		if (free[j] !=0)
    		{
    			i = free[j];
    			xCen_old[i] = xCen[i];
   				yCen_old[i] = yCen[i];
        		moveCenter(i);
        		//print("Moved center" + j + " of " + nall);
    		}
		}
	}
	else
	{
		for (i= 1; i<=(nall); i++)
    	{
    		xCen_old[i] = xCen[i];
   			yCen_old[i] = yCen[i];
        	moveCenter(i);
		}
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
        x_old = xCen_old[i];
        y_old = yCen_old[i];

        if (((indexOf(typeCen[i], "upperleft"))!=-1) || ((indexOf(typeCen[i], "upperright"))!=-1) || ((indexOf(typeCen[i], "lowerleft"))!=-1) || ((indexOf(typeCen[i], "lowerright"))!=-1))   
        {
            moveTo(x-osize, y-osize);
            setColor(255,0,0);
            drawOval(x-osize, y-osize, 4*osize, 4*osize);    
            fillOval(x-osize, y-osize, 4*osize, 4*osize);        
        }
        else if ( ((indexOf(typeCen[i], "rightborder"))!=-1) || ((indexOf(typeCen[i], "leftborder"))!=-1) || ((indexOf(typeCen[i], "topborder"))!=-1) || ((indexOf(typeCen[i], "bottomborder"))!=-1) )
        {
            moveTo(x-osize, y-osize);
            setColor(255,255,255);
            setLineWidth(1);
            drawOval(x-osize, y-osize, 2*osize, 2*osize);    
        }
        else {
        	//setLineWidth(2);
        	//drawLine(x_old, y_old, x, y);
        	//run("Arrow Tool...", "width=1 size=1 color=White style=Open");
        	makeArrow(x_old, y_old, x, y, "Small Open");
        	Roi.setStrokeWidth(1);
        	Roi.setStrokeColor("white");
        	run("Add Selection...");
        	updateDisplay();
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
				typeCen[i] = "fake free cell";
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
   		angle[i] = (180/PI) * ( atan2(yCen_old[i]-yCen[i], xCen_old[i]-xCen[i]) );
   		if (angle[i] < 0) {
   			angle[i] = angle[i] + 360;
   		}
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
        roiManager("save", "/Users/Lab/Documents/IJM/CE_sim_ROIs/ROIset"+k+".zip");
        roiManager("reset");

}

function tesselate(k)
{
	selectWindow(myTess);
	run("Add Slice");
	if (File.exists("/Users/Lab/Documents/IJM/CE_sim_ROIs/ROIset"+k+".zip") ==1)
	{
	//	print("Checked to see if file for step "+k+" was open.");
	roiManager("Open", "\Users\Lab\Documents\IJM\CE_sim_ROIs\ROIset"+k+".zip");
	setForegroundColor(255, 255, 255);
	run("Delaunay Voronoi", "mode=Voronoi interactive");
	setLineWidth(2);
	run("Delaunay Voronoi", "mode=Voronoi");
	
	setTool("wand");
	run("Set Measurements...", "area centroid center redirect=None decimal=3");
	
	ncells = roiManager("count");

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
//		print("cell: ", i," xcenter: ", xcenter[i], "ycenter: ", ycenter[i]);
	
	}

	roiManager("reset");
	}
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


macro "Run CE"
{

//    Initialize the arrays and fill with zeros
//
    setBatchMode(true);
    setOption("ExpandableArrays", true); 
    nsize = 3000;    // maximum number of cells
    nscale = 1.0    // multiplier for area of real cells to fake cells

    xCen = newArray(nsize);
    yCen = newArray(nsize);
    xCen_old = newArray(nsize);
    yCen_old = newArray(nsize);
    angle = newArray(nsize);
    typeCen = newArray(nsize);
    restCen = newArray(nsize);
    xcenter = newArray(nsize);
    ycenter = newArray(nsize);
    xFor = newArray(nsize);
    yFor = newArray(nsize);
    filename = newArray(nsize);
    free = newArray(nsize); 
    rando = newArray(nsize);
    new = newArray(nsize);

    
    for (i=0; i<nsize; i++)
    {
    
        xCen[i] = 0;
        yCen[i] = 0;
        xCen_old[i] = 0;
        yCen_old[i] = 0;
        angle[i] = 0;
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
    
// initialize cell bounding box and vornoi tesselation window
    initbox(biglength,bigwidth);
  //  initTess(biglength,bigwidth);
    
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
    
//    number of fake cells in tissue
    print("Done with initialization: width is: ", width, " length is: ", length);
    
    initfakeCORN();    
    
    initfakeBORD(); // can adjust the number of border cells based on fitting and rounding...
    
    nfake = (length*width/cellarea) - nreal - 0.5*nbord - 0.25*ncorn;

//     put fake interior cells under 15% isotropic compressive strain
//    
    nfake = (1.4*nfake);
    
    nfake = floor(nfake)+1;    
    print("Initialize fake cells.");
    initfakeCELL();
    print("There are", nbord," border cells, and ", nfake, " fake cells between real and border.");
    print("There are", nfake+nbord+ncorn, "total cells");
    
    mu = 30;

    print("Enter loop to initialize and equilibrate cells within borders");
    
    for (k=0 ; k < 100; k++)
    {
    	moveAllCenters();
    	checkIfOutside(k);
    	print("On timestep: ",k);

    }
	// Save centers from "previous" time step to draw vectors 
   	//Array.show(xCen_old, yCen_old, typeCen, angle);

   print("Enter loop to change size of playground and observe convergence extension");
   print("Make sure you set a file for ROIs to save to in the tesselate function.");
   print("Clear this folder if you change the number of timesteps. Tesselation takes a long time.");

	roiManager("reset");
    for (k=100 ; k < 110; k++)
    {
    	   	if (File.exists("/Users/Lab/Documents/IJM/CE_sim_ROIs/ROIset"+k+".zip") ==1)
   				{
   					File.delete("/Users/Lab/Documents/IJM/CE_sim_ROIs/ROIset" +k+".zip"); 
   					//print("Cleared old file "+k);
   				}
        playground();
        randomizer();
        moveAllCenters();
        drawAllCenters();
        reportCenters();
        Array.show(xCen, xCen_old, yCen, yCen_old, typeCen, angle);
      
        // need to convert centers to ROIs in each loop
        //centers2roisSAVE(k);
        //tesselate(k);
        print("On timestep: ",k);
        
    }
    print("Stretching complete at time", k);
 //Array.show(xCen, xCen_old, yCen, yCen_old, typeCen, angle);
    print("The final length is:  ", length, " & the final width is:  ", width);

    setBatchMode("exit and display");

  selectWindow(myBox);
   run("Select None");
 //selectWindow(myTess);
    print("Exit loop to move all cells.");

   // print("Report centers of all cells");
   // reportCenters();

    
}




