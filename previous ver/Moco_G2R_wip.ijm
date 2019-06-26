// For automated batch movement correction using moco.
// Next, use MATLAB to perform recorded coordinate transform on green channel.
// Author: Michael J. Siniscalchi
// Last Revision: 161031 (Halloween!)

// Settings

// Define Directories
root_dir = "C:\\Users\\Michael\\Desktop\\Analysis\\RuleSwitching PV\\for moco\\"; 
data_dir = getFileList(root_dir);

fs = File.separator;
//i =0;
for (i=0; i<data_dir.length; i++){
	run("Close All");
	redpath = root_dir+data_dir[i]+"stitched_redChan"+fs; 
	greenpath = root_dir+data_dir[i]+"stitched"+fs; 
	results_dir = redpath+"moco results"+fs;
	reg_path = greenpath+"registered"+fs;

	
	if (File.exists(results_dir)) {
		print("\n"); print("------------------------------------------------------------------------------------------------------------------------------"); print("\n"); 	
		print("Results directory exists.");
		f_names = getFileList(results_dir);
		for (j=0;j<f_names.length;j++){
			path_name = results_dir+f_names[j];
			File.delete(path_name); print("file deleted: "+f_names[j]);
		};
		if (File.delete(results_dir)){ print("Previous results deleted."); };
	};

	File.makeDirectory(results_dir);
	File.makeDirectory(reg_path);
	
	print("\n"); print("------------------------------------------------------------------------------------------------------------------------------"); print("\n"); 
	print("Directory for raw stacks:"); 	
	print("(red channel):        "+redpath); 
	print("(green channel):     "+greenpath); print("\n");
	print("Results Directory:"); 
	print(results_dir);
	print("Directory for movement-corrected stack:"); 
	print(reg_path);
	
	f_names = getFileList(redpath);
	for(j=0; j<f_names.length; j++){ 
		if(endsWith(f_names[j],"red.tif")){ 
 			f = redpath+f_names[j];
			print("Stack for moco:");
			print(f); print("\n");
        		}; 
	}; 
	
	// load raw stack
	open(f);
	h_rawStack =  getTitle();
	fname_red = f;

	// get avg z-projection
	run("Z Project...", "stop=100 projection=[Average Intensity]");
	h_zProj = getTitle();
	
	// MAKE REFERENCE IMAGE:	get substack-->avg-->moco-->avg-->moco-->avg to make reference image
	selectImage(h_rawStack);
	run("Make Substack...", "  slices=1-1000"); 
	h_newStack = getTitle(); 
	num_repeats = 0;
	do {	sum_errors = 0; row = 0;
		run("moco ", "value=50 downsample_value=0 template=[&h_zProj] stack=[&h_newStack] log=[Generate log file] plot=[Plot RMS]");
		do {	sum_errors += abs(getResult("x",row));
			sum_errors += abs(getResult("y",row));
			row++;
		} while (sum_errors<1 && row<nResults) ;
		num_repeats++;
		
		selectImage(h_newStack); close(); 			
		selectImage(h_zProj); close(); 					
		selectImage("New Stack");
		h_newStack = getTitle();  					
		run("Z Project...", "projection=[Average Intensity]");
		h_zProj = getTitle(); 						
	} while (sum_errors>0);

	selectImage(h_newStack); close();
	print("# reps for ref_img: "+num_repeats);
	print("# Open Images (debug): "+nImages); //debug

	//SAVE REF IMAGE
	selectImage(h_zProj); 
	fname_ref = redpath+"ref_img.tif";
	save(fname_ref);
	run("Close All");
	
	// moco raw stack (RED) using zProj(1-1000moco) as reference **FUNCTIONALIZE, maybe make into independent macro mocoi++(h_zProj, h_stack, results_dir)
	open(fname_red);
	h_newStack = getTitle();  ;	
	open(fname_ref);
	h_zProj = getTitle();

	num_repeats = 0;
	do {	sum_errors = 0; row = 0;
		run("moco ", "value=50 downsample_value=0 template=[&h_zProj] stack=[&h_newStack] log=[Generate log file] plot=[Plot RMS]");
		do {	sum_errors += abs(getResult("x",row));
			sum_errors += abs(getResult("y",row));
			row++;
		} while (sum_errors<1 && row<nResults) ;
		
		print("Repeat #: "+(++num_repeats));
											
		selectImage(h_newStack);   print("Close Stack:   "+h_newStack); //debug
		getDimensions(width, height, channels, slices, frames); //debug
		print("nFrames: "+slices); //debug 
		print("# Open Images (debug): "+nImages); //debug
		close(); 				
		
		selectImage(h_zProj); close(); 					print("close zProj:   "+h_zProj);	
		selectImage("New Stack");
		h_newStack = getTitle();  					print("select newStack:   "+h_newStack);
		run("Z Project...", "projection=[Average Intensity]");
		h_zProj = getTitle(); 						//print("title zProj:   "+h_zProj);

		saveAs("results" , results_dir+"Results"+num_repeats+".txt");
	} while (sum_errors>0);
	run("Close All");
	
	// USE CUMULATIVE TRANSLATION OF RED FOR CORRECTING GREEN CHANNEL
	// 1. get results tables and create array for accumulated frame-by-frame errors
	print("Loading translation results...");	
	results_files = getFileList(results_dir);
	file_path = results_dir+results_files[0];
	run("Results... ", "open=[&file_path]");
	results_vector = newArray(2*nResults); //1D array for x- and y- translations
	
	// 2. store cumulative errors in array, and sum cumulatively with prior tables
	for (j=0; j<results_files.length; j++){ 
		file_path = results_dir+results_files[j];
		run("Results... ","open=[&file_path]");
		for (k=0; k<nResults; k++){ 
			results_vector[k] += getResult("x", k);
			results_vector[nResults+k] += getResult("y", k);
		};
		print(results_files[j]);
	};

	// 3. generate summary results table that defines total translation (x,y) summed from all moco repeats for each frame
	dx = Array.slice(results_vector,0,nResults); 	//array.slice is [begin, end)
	dy = Array.slice(results_vector,nResults,2*nResults); 	
	Array.show("Results (row numbers)", dx, dy);
	saveAs("results" , redpath+"mocoi_Results.txt");
		
	// 3b. apply to raw red stack for proofread
	open(fname_red);
	h_rawStack = getTitle();
		
	ref_img = redpath+"ref_img.tif";
	open(ref_img);
	h_ref =  getTitle();
	
	path_name = redpath+"mocoi_Results.txt";
	run("moco ", "value=50 downsample_value=0 template=[&h_ref] stack=[&h_rawStack] log=[Choose log file] plot=[Plot RMS] choose=[&path_name]");
	
	// 4. apply transformation to green channel
	f_names = getFileList(greenpath);
	for(j=0; j<f_names.length; j++){ 
		if(endsWith(f_names[j],".tif")){ 
 			f = greenpath+f_names[j];
			open(f);
			h_rawStack = getTitle();
			print("Green Stack for Movement Correction:");
			print(f); 
			
			ref_img = redpath+"ref_img.tif";
			open(ref_img);
			h_ref =  getTitle();
			
			path_name = redpath+"mocoi_Results.txt";
			run("moco ", "value=50 downsample_value=0 template=[&h_ref] stack=[&h_rawStack] log=[Choose log file] plot=[Plot RMS] choose=[&path_name]");
 			
			file_path = reg_path+"reg_"+f_names[j];
			saveAs("tiff" , file_path);
			print("Movement-corrected stack:");
			print(file_path);
			
			file_path = reg_path+"Results.txt";
			saveAs("results" , file_path);
			print("Translation results:");
			print(file_path);
		}; 
	}; 
	
	//Save Logfile
	file_path = reg_path+"Log.txt";
	saveAs("text" , file_path);
	
};


// **to apply transformation to green channel**
// if iterative process is used, results will have to be summed first...
// run("moco ", "value=51 downsample_value=0 template=[AVG_Substack (1-1000)] stack=[Substack (1-1000)] log=[Choose log file] plot=[Plot RMS] choose=[coord_Trans]");

// **populate array with results, then get stats and test for whether to do another round...
//  for (i=0; i<nResults; i++){... getResult("Column", row[i]);
// Array.getStatistics(array, min, max, mean, stdDev) - Returns the min, max, mean, and stdDev of array, which must contain all numbers. 
// 2D indexing from 1D array: value=a[x+y*xmax]

//function myFunction(arg1, arg2. arg3) {
//      statement(s)
//   }

//**FUNCTIONALIZE the loops; maybe make into independent macro mocoi++(h_zProj, h_stack, results_dir)

// (OLD) MAKE REFERENCE IMAGE:	get substack-->avg-->moco-->avg-->moco-->avg to make reference image
	//selectImage(h_rawStack);
	//run("Make Substack...", "  slices=1-1000"); 
	//h_newStack = getTitle(); 
	//for (j=0; j<1; j++){ // test proc; example data converged @ 7th iteration for 1-500f ref, 150930 M14
	//	run("moco ", "value=10 downsample_value=0 template=[&h_zProj] stack=[&h_newStack] log=[Generate log file] plot=[Plot RMS]");
	//									//saveAs("results" , redpath+"Results"+j+".txt");
	//	selectImage(h_newStack); close(); 				//print("close newStack:   "+h_newStack);
	//	selectImage(h_zProj); close(); 					//print("close zProj:   "+h_zProj);	
//
//		selectImage("New Stack");
//		h_newStack = getTitle();  					//print("select newStack:   "+h_newStack);
//		run("Z Project...", "projection=[Average Intensity]");
//		h_zProj = getTitle(); 						//print("title zProj:   "+h_zProj);
//	};

