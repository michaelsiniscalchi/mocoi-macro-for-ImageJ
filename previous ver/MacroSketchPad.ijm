// For automated batch movement correction using moco.
// Next, use MATLAB to perform recorded coordinate transform on green channel.
// Author: Michael J. Siniscalchi
// Last Revision: 161018 

// Settings

// Define Directories
root_dir = "C:\\Users\\Michael\\Desktop\\Analysis\\for mocoMacro\\test\\";
data_dir = getFileList(root_dir);

fs = File.separator;

//for (i=0; i<data_dir.length; i++){
	i=1;
	path = root_dir+data_dir[i]+"stitched_redChan"+fs; 
	print("data_dir:"); print(path);
	f_names = getFileList(path);

	for(j=0; j<f_names.length; j++){ 
		if(endsWith(f_names[j],"red.tif")){ 
 			f = path+f_names[j];
			print(f);	
        		}; 
	}; 
	
	// load raw stack
	open(f);
	h_rawStack =  getTitle();

	// get avg z-projection
	run("Z Project...", "stop=500 projection=[Average Intensity]");
		//run("Enhance Contrast", "saturated=0.35 normalize"); //contrast/norm did not seem to help...
		//run("Apply LUT");
	h_zProj = getTitle();
	
	// get substack-->avg-->moco-->avg-->moco-->avg to make reference image
	selectImage(h_rawStack);
	run("Make Substack...", "  slices=1-500"); 
	h_newStack = getTitle(); 
	for (k=0; k<2; k++){
		run("moco ", "value=10 downsample_value=0 template=[&h_zProj] stack=[&h_newStack]"); // log=[Generate log file] plot=[Plot RMS]");
		selectWindow("results"); save(path+"Results"+k+".txt");
		selectImage(h_newStack); close(); print("close newStack:   "+h_newStack);
		selectImage(h_zProj); close(); print("close zProj:   "+h_zProj);	

		selectImage("New Stack");
		h_newStack = getTitle();  print("select newStack:   "+h_newStack);
		run("Z Project...", "projection=[Average Intensity]");
		h_zProj = getTitle(); print("title zProj:   "+h_zProj);
	};
	
	// moco raw stack iteratively using zProj(1-1000moco) as reference
//};


// **to apply transformation to green channel**
// if iterative process is used, results will have to be summed first...
// run("moco ", "value=51 downsample_value=0 template=[AVG_Substack (1-1000)] stack=[Substack (1-1000)] log=[Choose log file] plot=[Plot RMS] choose=[coord_Trans]");

