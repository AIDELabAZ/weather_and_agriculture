* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* reads in Niger, wave 2 .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			http://www.fao.org/giews/countrybrief/country.jsp?code=NER
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-we define the relevant months as 1 June - 30 November */

* assumes
	* NGR_ECVMAY2_converter.do
	* weather_command.ado
	* customsave.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* set global user
*	global user "jdmichler"

* define paths	
	loc root = "G:/My Drive/weather_project/weather_data/niger/wave_2/daily"
	loc export = "G:/My Drive/weather_project/weather_data/niger/wave_2/refined"
	loc logout = "G:/My Drive/weather_project/weather_data/niger/logs"

* open log	
	log using "`logout'/ngr_ecvmay2_weather", replace


* **********************************************************************
* 1 - run command for rainfall
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "ECVMAY2_rf*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder
		loc fileList : dir "`root'/`folder'" files "*.dta"
	
	* loop through each file in the above local
	foreach file in `fileList' {
		
		* import the daily data file
		use "`root'/`folder'/`file'", clear
		
		* define locals to govern file naming
			loc dat = substr("`file'", 1, 7)
			loc ext = substr("`file'", 9, 2)
			loc sat = substr("`file'", 12, 3)
		
		* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(6) fin_month(12) day_month(1) keep(hhid_y2)
		
		* save file
		customsave , idvar(hhid_y2) filename("`dat'_`ext'_`sat'.dta") ///
			path("`export'/`folder'") dofile(NGR_ECVMAY2_weather) user($user)
	}
}


* **********************************************************************
* 2 - run command for temperature
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "ECVMAY2_t*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"

	* define local with all files in each sub-folder	
	loc fileList : dir "`root'/`folder'" files "*.dta"
	
	* loop through each file in the above local
	foreach file in `fileList' {
		
		* import the daily data file		
		use "`root'/`folder'/`file'", clear
		
		* define locals to govern file naming
			loc dat = substr("`file'", 1, 7)
			loc ext = substr("`file'", 9, 2)
			loc sat = substr("`file'", 12, 2)
		
		* run the user written weather command - this takes a while		
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(6) fin_month(12) day_month(1) keep(hhid_y2)
		
		* save file
		customsave , idvar(hhid_y2) filename("`dat'_`ext'_`sat'.dta") ///
			path("`export'/`folder'") dofile(NGR_ECVMAY2_weather) user($user)
		}
}

* close the log
	log	close

/* END */
