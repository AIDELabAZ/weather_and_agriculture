* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Edited on: 7 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Niger, wave 2 .csv files
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
	loc root = "$data/weather_data/niger/wave_2/raw/ecvmay2_up"
	loc export = "$data/weather_data/niger/wave_2/daily/ecvmay2_up"
	loc logout = "$data/weather_data/niger/logs"

* open log
	cap log		close
	log using "`logout'/ngr_ecvmay2_converter", replace


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
