* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* edited on: 20 May 2024
* edited by: jdm
* Stata v.18

* does
	* reads in Uganda, wave 5 .csv files
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
	loc 		root 	= "$data/weather_data/uganda/wave_5/raw/unpsy5_up"
	loc 		export 	= "$data/weather_data/uganda/wave_5/daily/unpsy5_up"
	loc 		logout 	= "$data/weather_data/uganda/logs"

* open log
	cap log		close
	log using 	"`logout'/uga_unpsy5_converter", append

	
* **********************************************************************
* 1 - converts weather data
* **********************************************************************

* define local with all files in each sub-folder	
	loc fileList : dir "`root'" files "*.csv"
		
* loop through each file in the above local	
	foreach file in `fileList' {
		
	* import the .csv files - this takes time	
		import delimited "`root'/`file'", varnames (1)   ///
			encoding(Big5) stringcols(1) clear

	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 

	* save file
		save			"`export'/`dat'_daily.dta", replace
}

* close the log
	log	close

/* END */
