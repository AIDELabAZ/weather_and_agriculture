* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* edited on: 20 May 2024
* edited by: jdm
* Stata v.18

* does
	* Executes all wave specific Uganda weather .do files
    * runs weather_command .ado file
	* outputs .dta rainfall data ready to merge with LSMS household data
	* takes (15:25-) XXX minutes to convert and process weather data

* assumes
	* weather_command.ado
	* customsave.ado 
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
	loc root = "$code/uganda/weather_code"


* **********************************************************************
* 1 - run .do files
* **********************************************************************

* do each of the file converters
	do "`root'/wave_1/UGA_UNPSY1_converter.do"	//	convert wave 1 .csv to .dta
	do "`root'/wave_2/UGA_UNPSY2_converter.do"	//	convert wave 2 .csv to .dta
	do "`root'/wave_3/UGA_UNPSY3_converter.do"	//	convert wave 3 .csv to .dta
	do "`root'/wave_4/UGA_UNPSY4_converter.do"	//	convert wave 4 .csv to .dta
	do "`root'/wave_5/UGA_UNPSY5_converter.do"	//	convert wave 5 .csv to .dta
	do "`root'/wave_7/UGA_UNPSY7_converter.do"	//	convert wave 7 .csv to .dta
	do "`root'/wave_8/UGA_UNPSY8_converter.do"	//	convert wave 8 .csv to .dta
	
* do each of the weather commands
	do "`root'/wave_1/UGA_UNPSY1_weather.do"	//	generate wave 1 weather variables
	do "`root'/wave_2/UGA_UNPSY2_weather.do"	//	generate wave 2 weather variables
	do "`root'/wave_3/UGA_UNPSY3_weather.do"	//	generate wave 3 weather variables
	do "`root'/wave_4/UGA_UNPSY4_weather.do"	//	generate wave 4 weather variables
	do "`root'/wave_5/UGA_UNPSY5_weather.do"	//	generate wave 5 weather variables
	do "`root'/wave_7/UGA_UNPSY7_weather.do"	//	generate wave 7 weather variables
	do "`root'/wave_8/UGA_UNPSY8_weather.do"	//	generate wave 8 weather variables

/* END */
