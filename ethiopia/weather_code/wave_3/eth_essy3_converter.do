* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* reads in Ethiopia, wave 3 .csv files
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
	loc root = "$data/weather_data/ethiopia/wave_3/raw"
	loc export = "$data/weather_data/ethiopia/wave_3/daily"
	loc logout = "$data/weather_data/ethiopia/logs"

* open log
	cap log		close
	log using "`logout'/eth_essy3_converter", replace


* **********************************************************************
* 1 - deal with missing values
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "ESSY3_rf*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder	
		loc fileList : dir "`root'/`folder'" files "*.csv"
		
	* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`root'/`folder'/`file'", varnames (1)  ///
			stringcols(_all) clear
 
		* drop duplicates
			duplicates 		drop
			drop if 		household_id2 == ""
			drop if			rf_19830101 == "NA"

		* define locals to govern file naming	
			loc dat = substr("`file'", 1, 5)
			loc ext = substr("`file'", 7, 2)
			loc sat = substr("`file'", 10, 3)

		* save file
		export delimited using "`export'/`folder'/`dat'_`ext'_`sat'_daily.csv", replace
	}
}


* **********************************************************************
* 2 - converts rainfall data
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "ESSY3_rf*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder	
		loc fileList : dir "`root'/`folder'" files "*.csv"
		
	* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`export'/`folder'/`file'", varnames (1)  ///
			encoding(Big5) stringcols(1) clear
			
		* drop missing ids
			drop if household_id2 == ""

		* define locals to govern file naming	
			loc dat = substr("`file'", 1, 5)
			loc ext = substr("`file'", 7, 2)
			loc sat = substr("`file'", 10, 3)

		* save file
		customsave , idvar(household_id2) filename("`dat'_`ext'_`sat'_daily.dta") ///
			path("`export'/`folder'") dofile(ETH_ESSY3_converter) user($user)
	}
}



* **********************************************************************
* 3 - deal with missing values
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "ESSY3_t*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder	
		loc fileList : dir "`root'/`folder'" files "*.csv"
		
	* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`root'/`folder'/`file'", varnames (1)  ///
			stringcols(_all) clear
 
		* drop duplicates
			duplicates 		drop
			drop if 		household_id2 == ""
			drop if			tmp_19830101 == "NA"

		* define locals to govern file naming	
			loc dat = substr("`file'", 1, 5)
			loc ext = substr("`file'", 7, 2)
			loc sat = substr("`file'", 10, 2)

		* save file
		export delimited using "`export'/`folder'/`dat'_`ext'_`sat'_daily.csv", replace
	}
}


* **********************************************************************
* 4 - converts temperature data
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "ESSY3_t*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder	
		loc fileList : dir "`root'/`folder'" files "*.csv"
		
	* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`export'/`folder'/`file'", varnames (1)  ///
			encoding(Big5) stringcols(1) clear
			
		* drop missing ids
			drop if household_id2 == ""

		* define locals to govern file naming	
			loc dat = substr("`file'", 1, 5)
			loc ext = substr("`file'", 7, 2)
			loc sat = substr("`file'", 10, 2)

		* save file
		customsave , idvar(household_id2) filename("`dat'_`ext'_`sat'_daily.dta") ///
			path("`export'/`folder'") dofile(ETH_ESSY3_converter) user($user)
	}
}

* close the log
	log	close

/* END */
