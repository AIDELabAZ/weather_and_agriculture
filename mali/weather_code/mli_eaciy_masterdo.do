* Project: WB Weather
* Created on: Feb 2025
* Created by: jdm
* Edited on: 4 Feb 25
* Edited by: jdm
* Stata v.18

* does
	* Executes all wave specific Mali weather .do files
    * runs weather_command .ado file
	* outputs .dta rainfall data ready to merge with LSMS household data

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
	loc root = "$code/mali/weather_code"


* **********************************************************************
* 1 - run .do files
* **********************************************************************


* do each of the file converters
	do "`root'/wave_1/mli_eaciy1_converter.do"		//	convert wave 1 .csv to .dta
	do "`root'/wave_2/mli_eaciy2_converter.do"		//	convert wave 2 .csv to .dta


* do each of the weather commands
	do "`root'/wave_1/mli_eaciy1_weather.do"		//	generate wave 1 .weather variables
	do "`root'/wave_2/mli_eaciy2_weather.do"		//	generate wave 2 .weather variables

	
/* END */
