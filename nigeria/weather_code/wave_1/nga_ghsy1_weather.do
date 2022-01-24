* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* reads in Nigeria, wave 1 .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			http://www.fao.org/giews/countrybrief/country.jsp?code=NGA
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-Nigeria has a bi-modal distribution so we generate variables for both north and south
		-we define the relevant months for the north as May 1 - September 30 
		-we define the relevant months for the south as March 1 - August 31 */

* assumes
	* NGA_GHSY1_converter.do
	* weather_command.ado
	* customsave.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* set global user
	*global user "jdmichler"	// global user set in masterdo
	
* define paths	
	loc root = "G:/My Drive/weather_project/weather_data/nigeria/wave_1/daily"
	loc export = "G:/My Drive/weather_project/weather_data/nigeria/wave_1/refined"
	loc logout = "G:/My Drive/weather_project/weather_data/nigeria/logs"

* open log	
	log using "`logout'/nga_ghsy1_weather", append


* **********************************************************************
* 1.A - run command for rainfall - north
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "GHSY1_rf*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder
		loc fileList : dir "`root'/`folder'" files "*daily.dta"
	
	* loop through each file in the above local
	foreach file in `fileList' {
		
		* import the daily data file
		use "`root'/`folder'/`file'", clear
		
		* define locals to govern file naming
			loc dat = substr("`file'", 1, 5)
			loc ext = substr("`file'", 7, 2)
			loc sat = substr("`file'", 10, 3)
		
		* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(5) fin_month(10) day_month(1) keep(hhid)
		
		* save file
		customsave , idvar(hhid) filename("`dat'_`ext'_`sat'_n.dta") ///
			path("`export'/`folder'") dofile(NGA_GHSY1_weather) user($user)
	}
}


* **********************************************************************
* 1.B - run command for rainfall - south
* **********************************************************************

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder
		loc fileList : dir "`root'/`folder'" files "*daily.dta"
	
	* loop through each file in the above local
	foreach file in `fileList' {
		
		* import the daily data file
		use "`root'/`folder'/`file'", clear
		
		* define locals to govern file naming
			loc dat = substr("`file'", 1, 5)
			loc ext = substr("`file'", 7, 2)
			loc sat = substr("`file'", 10, 3)
		
		* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(3) fin_month(9) day_month(1) keep(hhid)
		
		* save file
		customsave , idvar(hhid) filename("`dat'_`ext'_`sat'_s.dta") ///
			path("`export'/`folder'") dofile(NGA_GHSY1_weather) user($user)
	}
}


* **********************************************************************
* 2.A - run command for temperature - north
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "GHSY1_t*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder
	loc fileList : dir "`root'/`folder'" files "*daily.dta"
	
	* loop through each file in the above local
	foreach file in `fileList' {
		
		* import the daily data file
		use "`root'/`folder'/`file'", clear
		
		* define locals to govern file naming
			loc dat = substr("`file'", 1, 5)
			loc ext = substr("`file'", 7, 2)
			loc sat = substr("`file'", 10, 2)
		
		* run the user written weather command - this takes a while
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(5) fin_month(10) day_month(1) keep(hhid)
		
		* save file
		customsave , idvar(hhid) filename("`dat'_`ext'_`sat'_n.dta") ///
			path("`export'/`folder'") dofile(NGA_GHSY1_weather) user($user)
		}
}


* **********************************************************************
* 2.B - run command for temperature - south
* **********************************************************************

* loop through each of the sub-folders in the above local
foreach folder of local folderList {
	
	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"
	
	* define local with all files in each sub-folder
	loc fileList : dir "`root'/`folder'" files "*daily.dta"
	
	* loop through each file in the above local
	foreach file in `fileList' {
		
		* import the daily data file
		use "`root'/`folder'/`file'", clear
		
		* define locals to govern file naming
			loc dat = substr("`file'", 1, 5)
			loc ext = substr("`file'", 7, 2)
			loc sat = substr("`file'", 10, 2)
		
		* run the user written weather command - this takes a while
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(3) fin_month(9) day_month(1) keep(hhid) 
		
		* save file
		customsave , idvar(hhid) filename("`dat'_`ext'_`sat'_s.dta") ///
			path("`export'/`folder'") dofile(NGA_GHSY1_weather) user($user)
	}
}

* close the log
	log	close

/* END */
