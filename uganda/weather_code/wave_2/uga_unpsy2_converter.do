* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* reads in Uganda, wave 2 .csv files
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
	*global user "jdmichler" // global user set in masterdo

* define paths
	loc root = "G:/My Drive/weather_project/weather_data/uganda/wave_2/raw"
	loc export = "G:/My Drive/weather_project/weather_data/uganda/wave_2/daily"
	loc logout = "G:/My Drive/weather_project/weather_data/uganda/logs"

* open log
	log using "`logout'/uga_unpsy2_converter", replace


* **********************************************************************
* 1 - converts rainfall data
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "UNPSY2_rf*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder	
		loc fileList : dir "`root'/`folder'" files "*.csv"
		
	* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`root'/`folder'/`file'", varnames (1)   ///
			encoding(Big5) stringcols(1) clear

		* define locals to govern file naming
			loc dat = substr("`file'", 1, 6)
			loc ext = substr("`file'", 8, 2)
			loc sat = substr("`file'", 11, 3)

		* save file
		customsave , idvar(hhid) filename("`dat'_`ext'_`sat'_daily.dta") ///
			path("`export'/`folder'") dofile(UGA_UNPSY2_converter) user($user)
	}
}


* **********************************************************************
* 2 - converts temperature data
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "UNPSY2_t*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder	
		loc fileList : dir "`root'/`folder'" files "*.csv"
		
	* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`root'/`folder'/`file'", varnames (1)   ///
			encoding(Big5) stringcols(1) clear

		* define locals to govern file naming
			loc dat = substr("`file'", 1, 6)
			loc ext = substr("`file'", 8, 2)
			loc sat = substr("`file'", 11, 3)

		* save file
		customsave , idvar(hhid) filename("`dat'_`ext'_`sat'_daily.dta") ///
			path("`export'/`folder'") dofile(UGA_UNPSY2_converter) user($user)
	}
}

* close the log
	log	close

/* END */
