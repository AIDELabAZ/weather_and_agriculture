* Project: WB Weather
* Created on: Feb 2025
* Created by: jdm
* Edited on: 4 Feb 25
* Edited by: jdm
* Stata v.18

* does
	* reads in Mali, wave 2 .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			https://www.fao.org/giews/countrybrief/country.jsp?lang=en&code=MLI
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-we define the relevant months as 1 May - 31 December */

* assumes
	* MLI_EACIY1_converter.do
	* weather_command.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root = "$data/weather_data/mali/wave_2/daily/eaciy2_up"
	loc export = "$data/weather_data/mali/wave_2/refined/eaciy2_up"
	loc logout = "$data/weather_data/mali/logs"

* open log	
	cap log		close
	log using "`logout'/mli_eaciy2_weather", replace


* **********************************************************************
* 1 - run command for rainfall
* **********************************************************************
	
* define local with all files in each sub-folder
	loc fileList : dir "`root'" files "*rf_daily.dta"
	
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file
		use "`root'/`file'", clear
		
	* drop weather variables beyond 2017
		keep uid rf_19830101-rf_20180101
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 10) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(5) fin_month(11) day_month(1) keep(uid)
		
	* save file
		compress
		save			"`export'/`dat'.dta", replace
}


* **********************************************************************
* 2 - run command for temperature
* **********************************************************************

* define local with all files in each sub-folder	
	loc fileList : dir "`root'/`folder'" files "*tp_daily.dta"
	
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file		
		use "`root'/`file'", clear
		
	* drop weather variables beyond 2017
		keep uid tmp_19830101-tmp_20180101
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 10) 
		
		* run the user written weather command - this takes a while		
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(5) fin_month(1) day_month(1) keep(uid)
		
	* save file
		compress
		save			"`export'/`dat'.dta", replace
}

* close the log
	log	close

/* END */
