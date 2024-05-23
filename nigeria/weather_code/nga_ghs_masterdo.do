* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* edited on: 20 May 2024
* edited by: jdm
* Stata v.18

* does
	* Executes all wave specific Nigeria weather .do files
    * runs weather_command .ado file
	* outputs .dta rainfall data ready to merge with LSMS household data
	* take 100 minutes to convert and process weather data
	
* assumes
	* weather_command.ado
	* subsidiary, wave-specific .do files

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

clear

*set max vars
	set maxvar 120000, perm  // this amount is only allowed for MP editions 

* define paths
	loc root = "$code/nigeria/weather_code"


* **********************************************************************
* 1 - run .do files
* **********************************************************************

* do each of the file converters
	do "`root'/wave_1/NGA_GHSY1_converter.do"	//	convert wave 1 .csv to .dta
	do "`root'/wave_2/NGA_GHSY2_converter.do"	//	convert wave 2 .csv to .dta
	do "`root'/wave_3/NGA_GHSY3_converter.do"	//	convert wave 3 .csv to .dta
	do "`root'/wave_4/NGA_GHSY4_converter.do"	//	convert wave 4 .csv to .dta

* do each of the weather commands
	do "`root'/wave_1/NGA_GHSY1_weather.do"		//	generate wave 1 weather variables
	do "`root'/wave_2/NGA_GHSY2_weather.do"		//	generate wave 2 weather variables
	do "`root'/wave_3/NGA_GHSY3_weather.do"		//	generate wave 3 weather variables
	do "`root'/wave_4/NGA_GHSY4_weather.do"		//	generate wave 4 weather variables

/* END */