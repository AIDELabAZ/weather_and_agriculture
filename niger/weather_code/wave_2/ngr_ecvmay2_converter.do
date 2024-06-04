* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Niger, wave 2 .csv files
	* outputs .dta file ready for processing by the weather program
	* does the above for both rainfall and temperature data

* assumes


* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc root = "$data/weather_data/niger/wave_2/raw"
	loc export = "$data/weather_data/niger/wave_2/daily"
	loc logout = "$data/weather_data/niger/logs"

* open log
	log using "`logout'/ngr_ecvmay2_converter", replace


* **********************************************************************
* 1 - converts rainfall data
* **********************************************************************

* define local with all sub-folders in it
loc folderList : dir "`root'" dirs "ECVMAY2_rf*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder	
		loc fileList : dir "`root'/`folder'" files "*.csv"
		
	* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`root'/`folder'/`file'", varnames (1) clear

	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 

	* save file
		compress
		save			"`export'/`dat'_daily.dta", replace
	}
}


* **********************************************************************
* 2 - converts temperature data
* **********************************************************************

* define local with all sub-folders in it
loc folderList : dir "`root'" dirs "ECVMAY2_t*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder	
		loc fileList : dir "`root'/`folder'" files "*.csv"
		
	* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`root'/`folder'/`file'", varnames (1) clear

	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 

	* save file
		compress
		save			"`export'/`dat'_daily.dta", replace
	}
}

* close the log
	log	close

/* END */
