* Project: WB Weather
* Created by: jdm
* Created on: April 2020
* edited by: jdm
* edited on: 16 May 2024
* Stata v.18

* does
	* reads in Ethiopia, wave 2 .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			http://www.fao.org/giews/countrybrief/country.jsp?code=ETH
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-we define the relevant months as May 1 - September 30 */
	* start run at 11:50
		
* assumes
	* daily data converted to .dta
	* weather_command.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root = "$data/weather_data/ethiopia/wave_2/daily/essy2_up"
	loc export = "$data/weather_data/ethiopia/wave_2/refined/essy2_up"
	loc logout = "$data/weather_data/ethiopia/logs"

* open log	
	cap log		close
	log using "`logout'/eth_essy2_weather", replace


* **********************************************************************
* 1 - run command for rainfall
* **********************************************************************

* import the daily ARC2 data file
		use "`root'/essy2_arc2_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_arc2.dta", replace

* import the daily CHIRPS data file
		use "`root'/essy2_chirps_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_chirps.dta", replace

* import the daily CPC RF data file
		use "`root'/essy2_cpcrf_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_cpcrf.dta", replace

* import the daily ERA5 RF data file
		use "`root'/essy2_erarf_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_erarf.dta", replace

* import the daily TAMSAT data file
		use "`root'/essy2_tamsat_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_tamsat.dta", replace

* import the daily MERRA-2 RF data file
		use "`root'/essy2_merrarf_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_merrarf.dta", replace

		
* **********************************************************************
* 2 - run command for temperature
* **********************************************************************

* import the daily CPC TP data file
		use "`root'/essy2_cpct_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_cpct.dta", replace

* import the daily ERA5 TP data file
		use "`root'/essy2_erat_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_erat.dta", replace

* import the daily MERRA-2 TP data file
		use "`root'/essy2_merrat_daily.dta", clear
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 
		
	* run the user written weather command - this takes a while
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(5) fin_month(10) day_month(1) keep(household_id)
		
	* save file
		save			"`export'/essy2_merrat.dta", replace


* close the log
	log	close

/* END */
