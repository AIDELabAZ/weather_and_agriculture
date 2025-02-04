* Project: WB Weather
* Created on: Feb 2025
* Created by: jdm
* Edited on: 4 Feb 2025
* Edited by: jdm
* Stata v.18

* does
	* reads in Mali, wave 1 .csv files
	* outputs .dta file ready for processing by the weather program
	* does the above for both rainfall and temperature data

* assumes
	* raw updated weather data

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc root = "$data/weather_data/mali/wave_1/raw/eaciy1_up"
	loc export = "$data/weather_data/mali/wave_1/daily/eaciy1_up"
	loc logout = "$data/weather_data/mali/logs"

* open log
	cap log		close
	log using "`logout'/mli_eaciy1_converter", replace


* **********************************************************************
* 1 - converts weather data
* **********************************************************************
	
* define local with all files in each sub-folder	
	loc fileList : dir "`root'" files "*.csv"
		
* loop through each file in the above local	
	foreach file in `fileList' {
		
	* import the .csv files - this takes time	
		import delimited "`root'/`file'", varnames (1) clear

	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 

	* save file
		compress
		save			"`export'/`dat'_daily.dta", replace
}

* close the log
	log	close

/* END */
