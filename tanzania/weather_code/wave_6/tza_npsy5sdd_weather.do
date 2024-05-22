* Project: WB Weather
* Created: May 2024
* Created: jdm
* edited on: 20 May 2024
* edited by: jdm
* Stata v.18

* does
	* reads in Tanzania, SSD which we call wave 6 .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			http://www.fao.org/giews/countrybrief/country.jsp?code=TZA
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-Tanzania has unimodal and bimodal regions. 70% of crop production occurs in regions that are unimodal, so we focus on those
		-We define the relevant months as Nov 1 - April 30
		-but in code below we keep the Jan 1 to Jul 1 since these are "rename" months */

* assumes
	* daily data converted to .dta
	* weather_command.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc 		root 	= 	"$data/weather_data/tanzania/wave_6/daily/npsy5sdd_up"
	loc 		export 	= 	"$data/weather_data/tanzania/wave_6/refined/npsy5sdd_up"
	loc 		logout 	= 	"$data/weather_data/tanzania/logs"

* open log	
	cap log		close
	log using 	"`logout'/tza_npsy5sdd_weather", append


* **********************************************************************
* 1 - run command for rainfall
* **********************************************************************

* define local with all files in each sub-folder
	loc fileList : dir "`root'" files "*rf_daily.dta"
	
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file
		use "`root'/`file'", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 10) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(1) fin_month(7) day_month(1) keep(sdd_hhid)
		
	* save file
		compress
		save			"`export'/`dat'.dta", replace
}


* **********************************************************************
* 2 - run command for temperature
* **********************************************************************

* define local with all files in each sub-folder	
	loc fileList : dir "`root'" files "*tp_daily.dta"
	
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file		
		use "`root'/`file'", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 10) 
		
	* run the user written weather command - this takes a while		
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(1) fin_month(7) day_month(1) keep(sdd_hhid)
		
	* save file
		compress
		save			"`export'/`dat'.dta", replace
}

* close the log
	log	close

/* END */
