* Project: WB Weather
* Created on: Aug 2020
* Created by: jdm
* Edtied by: ek
* Stata v.16

* does
	* Executes all wave specific Uganda hh .do files
	* outputs finished houshold data set ready to merge with weather

* assumes
	* customsave.ado 
	* subsidiary, wave-specific .do files

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc dofile = "$code/uganda/household_code"

* **********************************************************************
* 1 - run individual HH cleaning .do files
* **********************************************************************

* do each GSEC1 household cleaning files
	do 			"`dofile'/wave_1/2009_gsec1.do"			//	clean location information wv1 
	do 			"`dofile'/wave_2/2010_gsec1.do"			//	clean location information wv2 
	do 			"`dofile'/wave_3/2011_gsec1.do"			//	clean location information wv3 
	do 			"`dofile'/wave_5/2015_gsec1.do"			//	clean location information wv3 
	do 			"`dofile'/wave_8/2019_gsec1.do"			//	clean location information wv8 


* do each GSEC1 household cleaning files
	do 			"`dofile'/wave_1/2009_geovars.do"		//	clean location information wv1 
	do 			"`dofile'/wave_2/2010_geovars.do"		//	clean location information wv2 
	do 			"`dofile'/wave_3/2011_geovars.do"		//	clean location information wv3 

* loops through three waves of uga hh code

* starting with running all individual hh data files
* define local with all sub-folders in it
	loc folderList : dir "`dofile'" dirs "wave_1"

* define local with all files in each sub-folder
	foreach folder of loc folderList {

	* loop through each NGA file in the folder local
		loc uga : dir "`dofile'/`folder'" files "20*_a*.do"
	
	* loop through each file in the above local
		foreach file in `uga' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"		
	}		
}

* starting with running all individual hh data files
* define local with all sub-folders in it
	loc folderList : dir "`dofile'" dirs "wave_2"

* define local with all files in each sub-folder
	foreach folder of loc folderList {

	* loop through each NGA file in the folder local
		loc uga : dir "`dofile'/`folder'" files "20*_a*.do"
	
	* loop through each file in the above local
		foreach file in `uga' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"		
	}		
}
* starting with running all individual hh data files
* define local with all sub-folders in it
	loc folderList : dir "`dofile'" dirs "wave_3*"

* define local with all files in each sub-folder
	foreach folder of loc folderList {

	* loop through each NGA file in the folder local
		loc uga : dir "`dofile'/`folder'" files "20*_a*.do"
	
	* loop through each file in the above local
		foreach file in `uga' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"		
	}		
}
* starting with running all individual hh data files
* define local with all sub-folders in it
	loc folderList : dir "`dofile'" dirs "wave_5*"

* define local with all files in each sub-folder
	foreach folder of loc folderList {

	* loop through each NGA file in the folder local
		loc uga : dir "`dofile'/`folder'" files "20*_a*.do"
	
	* loop through each file in the above local
		foreach file in `uga' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"		
	}		
}
* starting with running all individual hh data files
* define local with all sub-folders in it
	loc folderList : dir "`dofile'" dirs "wave_8*"

* define local with all files in each sub-folder
	foreach folder of loc folderList {

	* loop through each NGA file in the folder local
		loc uga : dir "`dofile'/`folder'" files "20*_a*.do"
	
	* loop through each file in the above local
		foreach file in `uga' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"		
	}		
}
* run harvest month file
	do			"`dofile'/wave_2/harvmonth.do"				//	generates harvest season
	do			"`dofile'/wave_4/harvmonth.do"				//	generates harvest season
	do			"`dofile'/wave_5/harvmonth.do"				//	generates harvest season

	
* **********************************************************************
* 2 - run wave specific .do files to merge hh data together
* **********************************************************************

* merge each cleaned file together
	do 			"`dofile'/wave_1/unps1_merge.do"			//	merges wv 1 hh datasets
	do 			"`dofile'/wave_2/unps2_merge.do"			//	merges wv 2 hh datasets
	do 			"`dofile'/wave_3/unps3_merge.do"			//	merges wv 3 hh datasets
	do 			"`dofile'/wave_4/unps4_merge.do"			//	merges wv 4 hh datasets
	do 			"`dofile'/wave_5/unps5_merge.do"			//	merges wv 5 hh datasets
	do 			"`dofile'/wave_8/unps8_merge.do"			//	merges wv 8 hh datasets

	
* **********************************************************************
* 3 - run wave specific .do files to merge with weather
* **********************************************************************

* merge weather data into cleaned household data
	do 			"`dofile'/wave_1/unps1_build.do"			//	merges unps1 to weather
	do 			"`dofile'/wave_2/unps2_build.do"			//	merges unps2 to weather
	do 			"`dofile'/wave_3/unps3_build.do"			//	merges unps3 to weather
	do 			"`dofile'/wave_4/unps4_build.do"			//	merges unps4 to weather
	do 			"`dofile'/wave_5/unps5_build.do"			//	merges unps5 to weather
	do 			"`dofile'/wave_8/unps8_build.do"			//	merges unps8 to weather

	
* **********************************************************************
* 5 - run .do file to append each wave
* **********************************************************************

	do			"$code/uganda/household_code/uga_append_built.do"			// append waves
	
/* END */
