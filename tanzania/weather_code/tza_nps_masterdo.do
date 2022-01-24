* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* Executes all wave specific Tanzania weather .do files
    * runs weather_command .ado file
	* outputs .dta rainfall data ready to merge with LSMS household data

* assumes
	* weather_command.ado
	* customsave.ado 
	* subsidiary, wave-specific .do files

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

	clear mata

*set max vars
	set maxvar 120000, perm  // this amount is only allowed for MP editions 

* define paths
	loc root = "$code/tanzania/weather_code"


* **********************************************************************
* 1 - run .do files
* **********************************************************************

* do each of the file converters
	do "`root'/wave_1/TZA_NPSY1_converter.do"	//	convert wave 1 .csv to .dta
	do "`root'/wave_2/TZA_NPSY2_converter.do"	//	convert wave 2 .csv to .dta
	do "`root'/wave_3/TZA_NPSY3_converter.do"	//	convert wave 3 .csv to .dta
	do "`root'/wave_4/TZA_NPSY4_converter.do"	//	convert wave 4 .csv to .dta
	
* do each of the weather commands
	do "`root'/wave_1/TZA_NPSY1_weather.do"		//	generate wave 1 .weather variables
	do "`root'/wave_2/TZA_NPSY2_weather.do"		//	generate wave 2 .weather variables
	do "`root'/wave_3/TZA_NPSY3_weather.do"		//	generate wave 3 .weather variables
	do "`root'/wave_4/TZA_NPSY4_weather.do"		//	generate wave 4 .weather variables

/* END */
