* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* edited on: 20 May 2024
* edited by: jdm
* Stata v.18

* does
	* reads in Uganda, wave 2 .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			http://www.fao.org/giews/countrybrief/country.jsp?code=UGA
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-Uganda has a bi-modal distribution so we generate variables for both north and south
		-we define the relevant months for the north as April 1 - September 30 
		-we define the relevant months for the south as February 1 - May 31 */

* assumes
	* daily data converted to .dta
	* weather_command.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc 		root 	= "$data/weather_data/uganda/wave_2/daily/unpsy2_up"
	loc 		export 	= "$data/weather_data/uganda/wave_2/refined/unpsy2_up"
	loc 		logout 	= "$data/weather_data/uganda/logs"

* open log	
	cap log		close
	log using 	"`logout'/uga_unpsy2_weather", replace


* **********************************************************************
* 1.A - run command for rainfall - north
* **********************************************************************

* define local with all files in each sub-folder
	loc fileList : dir "`root'" files "*rf_daily.dta"
		
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file
		use "`root'/`folder'/`file'", clear
		
	* drop weather variables beyond 2010
		keep hhid rf_19830101-rf_20101231
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 10) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(4) fin_month(10) day_month(1) keep(hhid)
		
	* save file
		compress
		save			"`export'/`dat'_n.dta", replace
}


* **********************************************************************
* 1.B - run command for rainfall - south
* **********************************************************************

* define local with all files in each sub-folder
	loc fileList : dir "`root'" files "*rf_daily.dta"
		
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file
		use "`root'/`folder'/`file'", clear
		
	* drop weather variables beyond 2010
		keep hhid rf_19830101-rf_20101231
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 10) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(2) fin_month(6) day_month(1) keep(hhid)
		
	* save file
		compress
		save			"`export'/`dat'_s.dta", replace
}


* **********************************************************************
* 2.A - run command for temperature - north
* **********************************************************************

* define local with all files in each sub-folder
	loc fileList : dir "`root'" files "*tp_daily.dta"
		
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file
		use "`root'/`folder'/`file'", clear
		
	* drop weather variables beyond 2010
		keep hhid tmp_19830101-tmp_20101231
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 10) 
		
	* run the user written weather command - this takes a while
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(4) fin_month(10) day_month(1) keep(hhid)
		
	* save file
		compress
		save			"`export'/`dat'_n.dta", replace
}


* **********************************************************************
* 2.B - run command for temperature - south
* **********************************************************************

* define local with all files in each sub-folder
	loc fileList : dir "`root'" files "*tp_daily.dta"
		
* loop through each file in the above local
	foreach file in `fileList' {
		
	* import the daily data file
		use "`root'/`folder'/`file'", clear
		
	* drop weather variables beyond 2010
		keep hhid tmp_19830101-tmp_20101231
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 10) 
		
	* run the user written weather command - this takes a while
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(2) fin_month(6) day_month(1) keep(hhid)
		
	* save file
		compress
		save			"`export'/`dat'_s.dta", replace
}

* close the log
	log	close

/* END */
