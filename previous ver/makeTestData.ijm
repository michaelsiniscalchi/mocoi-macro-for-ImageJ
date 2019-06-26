// Generate 1000f test data for workflow development
// Author: Michael J. Siniscalchi
// Last Revision: 161018 

root_dir = "C:\\Users\\Michael\\Desktop\\Analysis\\for mocoMacro\\";
data_dir = getFileList(root_dir);

fs = File.separator;

//print(data_dir[0]);

for (i=0; i<data_dir.length; i++){
	path = root_dir+data_dir[i]+"stitched"+fs; print(path);
	f_names = getFileList(path);

		for(j=0; j<f_names.length; j++){ 
			if(endsWith(f_names[j],".tif")){ 
        			f = path+f_names[j];
			sav_name = f_names[j];
			print(sav_name);	
        			}; 
		}; 
	open(f);
	run("Make Substack...", "  slices=1-1000");
	
	sav_dir = root_dir+"test"+fs+data_dir[i]+"stitched"+fs; 
	File.makeDirectory(sav_dir);
	saveAs("Tiff", sav_dir+sav_name);
	closeAll();
};



