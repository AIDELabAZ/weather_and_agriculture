* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* reads in Niger, wave 1 .csv files
	* outputs .dta file ready for processing by the weather program
	* does the above for both rainfall and temperature data

* assumes
	* customsave.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* set user
*	global user "jdmichler"

* define paths
	loc root = "G:/My Drive/weather_project/weather_data/niger/wave_1/raw"
	loc export = "G:/My Drive/weather_project/weather_data/niger/wave_1/daily"
	loc logout = "G:/My Drive/weather_project/weather_data/niger/logs"

* open log
	log using "`logout'/ngr_ecvmay1_converter", replace


* **********************************************************************
* 1 - converts rainfall data
* **********************************************************************

* define local with all sub-folders in it
loc folderList : dir "`root'" dirs "ECVMAY1_rf*"

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
			loc dat = substr("`file'", 1, 7)
			loc ext = substr("`file'", 9, 2)
			loc sat = substr("`file'", 12, 3)

		* save file
		customsave , idvar(hid) filename("`dat'_`ext'_`sat'_daily.dta") ///
			path("`export'/`folder'") dofile(NGR_ECVMAY1_converter) user($user)
	}
}


* **********************************************************************
* 2 - converts temperature data
* **********************************************************************

* define local with all sub-folders in it
loc folderList : dir "`root'" dirs "ECVMAY1_t*"

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
			loc dat = substr("`file'", 1, 7)
			loc ext = substr("`file'", 9, 2)
			loc sat = substr("`file'", 12, 2)

		* save file
		customsave , idvar(hid) filename("`dat'_`ext'_`sat'_daily.dta") ///
			path("`export'/`folder'") dofile(NGR_ECVMAY1_converter) user($user)
	}
}

* close the log
	log	close

/* END */
