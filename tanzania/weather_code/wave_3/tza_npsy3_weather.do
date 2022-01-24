* Project: weather
* Created: April 2020
* Stata v.16

* does
	* reads in Tanzania, wave 1 .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			http://www.fao.org/giews/countrybrief/country.jsp?code=TZA
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-Tanzania has unimodal and bimodal regions. 70% of crop production occurs in regions that are unimodal, so we focus on those
		-We define the relevant months as Nov 1 - April 30 */

* assumes
	* weather_command.ado
	* TZA_NPSY3_converter.do

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* set global user
	*global user "jdmichler" // global user set in TZA_NPS_masterdo

* define paths	
	loc root = "G:/My Drive/weather_project/weather_data/tanzania/wave_3/daily"
	loc export = "G:/My Drive/weather_project/weather_data/tanzania/wave_3/refined"
	loc logout = "G:/My Drive/weather_project/weather_data/tanzania/logs"

* open log	
	log using "`logout'/tza_npsy3_weather", replace


* **********************************************************************
* 1 - run command for rainfall
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "NPSY3_rf*"

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
		loc dat = substr("`file'", 1, 5)
		loc ext = substr("`file'", 7, 2)
		loc sat = substr("`file'", 10, 3)
		
		* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(1) fin_month(7) day_month(1) keep(y3_hhid)
		
		* save file
		customsave , idvar(y3_hhid) filename("`dat'_`ext'_`sat'.dta") ///
			path("`export'/`folder'") dofile(TZA_NPSY3_weather) user($user)
	}
}


* **********************************************************************
* 2 - run command for temperature
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "NPSY3_t*"

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
		loc dat = substr("`file'", 1, 5)
		loc ext = substr("`file'", 7, 2)
		loc sat = substr("`file'", 10, 2)
		
		* run the user written weather command - this takes a while		
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(1) fin_month(7) day_month(1) keep(y3_hhid)
		
		* save file
		customsave , idvar(y3_hhid) filename("`dat'_`ext'_`sat'.dta") ///
			path("`export'/`folder'") dofile(TZA_NPSY3_weather) user($user)
		}
}

* close the log
	log	close

/* END */
