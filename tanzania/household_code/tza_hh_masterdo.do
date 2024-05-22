* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* Executes all wave specific Tanzania hh .do files
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
	loc dofile = "$code/tanzania/household_code"


* **********************************************************************
* 1 - run individual HH and AG cleaning .do files
* **********************************************************************

* loops through four waves of tza hh code

* starting with running all individual hh data files
* define local with all sub-folders in it
	loc folderList : dir "`dofile'" dirs "wave_*"

* define local with all files in each sub-folder
	foreach folder of loc folderList {

	* loop through each HHSEC file in the folder local
		loc HHfile : dir "`dofile'/`folder'" files "*hhsec*.do"
	
	* loop through each file in the above local
		foreach file in `HHfile' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"	
	}
	* loop through each HHSEC file in the folder local
		loc GEOfile : dir "`dofile'/`folder'" files "*geo*.do"
	
	* loop through each file in the above local
		foreach file in `GEOfile' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"	
	}
	* loop through each AGSEC file in the folder local
		loc AGfile : dir "`dofile'/`folder'" files "*agsec*.do"
	
	* loop through each file in the above local
		foreach file in `AGfile' {
	    
		* run each individual file
			do "`dofile'/`folder'/`file'"		
	}		
}


* **********************************************************************
* 2 - run individual HH and AG cleaning .do files
* **********************************************************************

* run panel key cleaning file
	do			"`dofile'/tza_sdd_panel_key.do"				// panel key

	
* **********************************************************************
* 3 - run wave specific .do files to merge hh data together
* **********************************************************************

* merge each cleaned file together
	do 			"`dofile'/wave_1/npsy1_merge.do"			//	merges wv 1 hh datasets
	do 			"`dofile'/wave_2/npsy2_merge.do"			//	merges wv 2 hh datasets
	do 			"`dofile'/wave_3/npsy3_merge.do"			//	merges wv 3 hh datasets
	do 			"`dofile'/wave_4/npsy4_merge.do"			//	merges wv 4 hh datasets
	do 			"`dofile'/wave_5/npsy4xp_merge.do"			//	merges wv 5 hh datasets
	do 			"`dofile'/wave_6/npsy5sdd_merge.do"			//	merges wv 6 hh datasets
	do 			"`dofile'/wave_7/npsy5_merge.do"			//	merges wv 7 hh datasets


* **********************************************************************
* 4 - run wave specific .do files to merge with weather
* **********************************************************************

* merge weather data into cleaned household data
	do 			"`dofile'/wave_1/npsy1_build.do"			//	merges NPSY1 to weather
	do 			"`dofile'/wave_2/npsy2_build.do"			//	merges NPSY2 to weather
	do 			"`dofile'/wave_3/npsy3_build.do"			//	merges NPSY3 to weather
	do 			"`dofile'/wave_4/npsy4_build.do"			//	merges NPSY4 to weather
	do 			"`dofile'/wave_5/npsy4xp_build.do"			//	merges NPSY4xp to weather
	do 			"`dofile'/wave_6/npsy5sdd_build.do"			//	merges NPSY5-SDD to weather
	do 			"`dofile'/wave_7/npsy5_build.do"			//	merges NPSY5 to weather


* **********************************************************************
* 5 - run .do file to append each wave
* **********************************************************************

	do			"`dofile'/tza_append_built.do"				// append waves
	
/* END */

