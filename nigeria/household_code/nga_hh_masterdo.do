* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Edited on: 29 May 2024
* Edited by: jdm
* Stata v.18

* does
	* Executes all wave specific Nigeria hh .do files
	* outputs finished houshold data set ready to merge with weather

* assumes
	* subsidiary, wave-specific .do files

* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc dofile = "$code/nigeria/household_code"


* **********************************************************************
* 1 - run conversion factor .do files
* **********************************************************************

* merge each cleaned file together
	do 			"`dofile'/wave_1/harvconv_wave_1.do"		//	cleans wv 1 conversions
	do 			"`dofile'/wave_2/harvconv_wave_2.do"		//	cleans wv 2 conversions
	do 			"`dofile'/wave_3/harvconv_wave_3.do"		//	cleans wv 3 conversions

	
* **********************************************************************
* 2 - run individual HH cleaning .do files
************************************************************************

* loops through three waves of nga hh code

* starting with running all individual hh data files
* define local with all sub-folders in it
	loc folderList : dir "`dofile'" dirs "wave_*"

* define local with all files in each sub-folder
	foreach folder of loc folderList {

	* loop through each NGA file in the folder local
		loc NGA : dir "`dofile'/`folder'" files "20*.do"
	
	* loop through each file in the above local
		foreach file in `NGA' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"		
	}		
}

* **********************************************************************
* 3 - run wave specific .do files to merge hh data together
* **********************************************************************

* merge each cleaned file together
	do 			"`dofile'/wave_1/ghsy1_merge.do"			//	merges wv 1 hh datasets
	do 			"`dofile'/wave_2/ghsy2_merge.do"			//	merges wv 2 hh datasets
	do 			"`dofile'/wave_3/ghsy3_merge.do"			//	merges wv 3 hh datasets
	do 			"`dofile'/wave_4/ghsy4_merge.do"			//	merges wv 3 hh datasets


* **********************************************************************
* 4 - run wave specific .do files to merge with weather
* **********************************************************************

* merge weather data into cleaned household data
	do 			"`dofile'/wave_1/ghsy1_build.do"			//	merges NPSY1 to weather
	do 			"`dofile'/wave_2/ghsy2_build.do"			//	merges NPSY2 to weather
	do 			"`dofile'/wave_3/ghsy3_build.do"			//	merges NPSY3 to weather
	do 			"`dofile'/wave_4/ghsy4_build.do"			//	merges NPSY3 to weather

	
* **********************************************************************
* 5 - run .do file to append each wave
* **********************************************************************

	do			"$code/nigeria/household_code/nga_append_built.do"			// append waves
	
	
/* END */
