* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* reads in Malawi IHS3, which we term wave 1, .dta files with daily values
    * runs weather_command .ado file
	* outputs .dta file of the relevant weather variables
	* does the above for both rainfall and temperature data
	/* 	-the growing season that we care about is defined on the FAO website:
			http://www.fao.org/giews/countrybrief/country.jsp?code=MWI
		-we measure rainfall during the months that the FAO defines as sowing and growing
		-we define the relevant months as October 1 - April 30 */

* assumes
	* MWI_IHS3_converter.do
	* weather_command.ado
	* customsave.ado

* TO DO:
	* completed


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc 	root 	= 	"$data/weather_data/malawi/wave_1/daily"
	loc 	export 	= 	"$data/weather_data/malawi/wave_1/refined"
	loc 	logout 	= 	"$data/weather_data/malawi/logs"

* open log
	log 	using 		"`logout'/mwi_ihs3_weather"


* **********************************************************************
* 1 - run command for rainfall
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "IHS3_rf*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {

	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"

	* define local with all files in each sub-folder
		loc fileList : dir "`root'/`folder'" files "*.dta"

	* loop through each file in the above local
	foreach file in `fileList' {

		* import the daily data file
		use "`root'/`folder'/`file'", clear

		* define locals to govern file naming
			loc dat = substr("`file'", 1, 4)
			loc ext = substr("`file'", 6, 2)
			loc sat = substr("`file'", 9, 3)

		* run the user written weather command - this takes a while
		weather rf_ , rain_data ini_month(1) fin_month(8) day_month(1) keep(case_id)

		* save file
		customsave , idvar(case_id) filename("`dat'_`ext'_`sat'.dta") ///
			path("`export'/`folder'") dofile(MWI_IHS3_weather) user($user)
	}
}


* **********************************************************************
* 2 - run command for temperature
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "IHS3_t*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {

	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"

	* define local with all files in each sub-folder
	loc fileList : dir "`root'/`folder'" files "*.dta"

	* loop through each file in the above local
	foreach file in `fileList' {

		* import the daily data file
		use "`root'/`folder'/`file'", clear

		* define locals to govern file naming
		loc dat = substr("`file'", 1, 4)
		loc ext = substr("`file'", 6, 2)
		loc sat = substr("`file'", 9, 2)

		* run the user written weather command - this takes a while
		weather tmp_ , temperature_data growbase_low(10) growbase_high(30) ini_month(1) fin_month(8) day_month(1) keep(case_id)

		* save file
		customsave , idvar(case_id) filename("`dat'_`ext'_`sat'.dta") ///
			path("`export'/`folder'") dofile(MWI_IHS3_weather) user($user)
		}
}

* close the log
	log	close

/* END */
