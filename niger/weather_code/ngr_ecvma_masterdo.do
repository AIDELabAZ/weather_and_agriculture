* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* Executes all wave specific Niger weather .do files
    * runs weather_command .ado file
	* outputs .dta rainfall data ready to merge with LSMS household data

* assumes
	* weather_command.ado
	* subsidiary, wave-specific .do files
	* customsave.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

clear

* set max vars
	set maxvar 120000, perm  // this amount is only allowed for MP editions 
	
* set global user
	global user "jdmichler"

* define paths
	loc root = "C:/Users/$user/git/weather_project/niger/weather_code"


* **********************************************************************
* 1 - run .do files
* **********************************************************************


* do each of the file converters
	do "`root'/wave_1/NGR_ECVMAY1_converter.do"		//	convert wave 1 .csv to .dta
	do "`root'/wave_2/NGR_ECVMAY2_converter.do"		//	convert wave 2 .csv to .dta


* do each of the weather commands
	do "`root'/wave_1/NGR_ECVMAY1_weather.do"		//	generate wave 1 .weather variables
	do "`root'/wave_2/NGR_ECVMAY2_weather.do"		//	generate wave 2 .weather variables

	
/* END */
