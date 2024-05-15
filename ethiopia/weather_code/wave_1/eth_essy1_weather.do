* Project: WB Weather
* Created by: jdm
* Created on: April 2020
* edited by: jdm
* edited on: 15 May 2024
* Stata v.18

* does
	* reads in Ethiopia, wave 1 .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			http://www.fao.org/giews/countrybrief/country.jsp?code=ETH
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-we define the relevant months as March 1 - November 30 */

* assumes
	* daily data converted to .dta
	* weather_command.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root = "$data/weather_data/ethiopia/wave_1/daily/erssy1_up"
	loc export = "$data/weather_data/ethiopia/wave_1/refined/erssy1_up"
	loc logout = "$data/weather_data/ethiopia/logs"

* open log	
	cap log		close
	log using "`logout'/eth_essy1_weather", replace


* **********************************************************************
* 1 - run command for rainfall
* **********************************************************************


* define local with all files in each sub-folder
	loc fileList : dir "`root'/`folder'" files "*.dta"
	
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file
		use "`root'/`file'", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(3) fin_month(12) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/`dat'.dta", replace
}

* close the log
	log	close

/* END */
