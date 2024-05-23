* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* edited by: jdm
* edited on: 18 May 2024
* Stata v.18

* does
	* Executes all wave specific Malawi weather .do files
    * runs weather_command .ado file
	* outputs .dta rainfall data ready to merge with LSMS household data
	* take 210 minutes to convert and process weather data
	
* assumes
	* weather_command.ado
	* subsidiary, wave-specific .do files

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

clear

* set max vars
	set maxvar 120000, perm  // this amount is only allowed for MP editions 

* define paths
	loc root = "$code/malawi/weather_code"


* **********************************************************************
* 1 - run .do files
* **********************************************************************

* do each of the file converters
	do "`root'/wave_1/mwi_ihs3_converter.do"	//	convert wave 1 .csv to .dta
	do "`root'/wave_2/mwi_ihps_converter.do"	//	convert wave 2 .csv to .dta
	do "`root'/wave_3/mwi_ihs4_converter.do"	//	convert wave 3 .csv to .dta
	do "`root'/wave_4/mwi_ihs4p_converter.do"	//	convert wave 4 .csv to .dta
	do "`root'/wave_5/mwi_ihs5_converter.do"	//	convert wave 5 .csv to .dta
	do "`root'/wave_6/mwi_ihs5p_converter.do"	//	convert wave 6 .csv to .dta


* do each of the weather commands
	do "`root'/wave_1/mwi_ihs3_weather.do"		//	generate wave 1 weather variables
	do "`root'/wave_2/mwi_ihps_weather.do"		//	generate wave 2 weather variables
	do "`root'/wave_3/mwi_ihs4_weather.do"		//	generate wave 3 weather variables */
	do "`root'/wave_4/mwi_ihs4p_weather.do"		//	generate wave 4 weather variables
	do "`root'/wave_5/mwi_ihs5_weather.do"		//	generate wave 5 weather variables
	do "`root'/wave_6/mwi_ihs5p_weather.do"		//	generate wave 6 weather variables

	
/* END */
