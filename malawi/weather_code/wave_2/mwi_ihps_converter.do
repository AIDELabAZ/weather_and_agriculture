* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* Stata v.16

* does
	* reads in Malawi IHPS, which we term wave 2, .csv files
    * drops unnecessary daily observations
	* outputs .dta file ready for processing by the weather program
	* does the above for both rainfall and temperature data
	/* 	-To make our weather program work, we need to run the code on data that starts on Oct 1 and ends on May 1
		-Because of this, we will keep rainfall data for the months Oct through May and use the weather command to get rid of May
		-This means we only want to drop data from the months Jun, Jul, Aug, Sep */

* assumes
	* customsave.ado

* TO DO:
	* completed


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc 	root 	= 	"$data/weather_data/malawi/wave_2/raw"
	loc 	export 	= 	"$data/weather_data/malawi/wave_2/daily"
	loc 	logout 	= 	"$data/weather_data/malawi/logs"

* open log
	log 	using 		"`logout'/mwi_ihps_converter", replace


* **********************************************************************
* 1 - converts rainfall data
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "IHPS_rf*"

* define local with all files in each sub-folder
foreach folder of local folderList {

	* create directories to write output to
	qui: capture mkdir "`export'/`folder'/"

	* loop through each file in the above local
		loc fileList : dir "`root'/`folder'" files "*.csv"

	* loop through each file in the above local
	foreach file in `fileList' {

		* import the .csv files - this takes time
		import delimited "`root'/`folder'/`file'", varnames (1) clear

		* drop early and late observations
		drop 	rf_19830101-rf_19830930 ///
				rf_20170601-rf_20171231

		* drop unnecessary months, this will make renaming variables easier (June-Aug)
		foreach var of varlist rf_* {
			if substr("`var'", 8, 2) == "06" drop `var'
			if substr("`var'", 8, 2) == "07" drop `var'
			if substr("`var'", 8, 2) == "08" drop `var'
			if substr("`var'", 8, 2) == "09" drop `var'
		}
		* shift early month variables one year forward, year refers to start of season
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc cyear = `year'-1
			if `month' < 10 rename `var' rf_`cyear'`month'`day'
		}
		* rename the five early month variables
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+3
			if `month' == 05 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+3
			if `month' == 04 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+3
			if `month' == 03 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+3
			if `month' == 02 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+3
			if `month' == 01 rename `var' rf_`year'0`nmonth'`day'
		}
		* rename the three later month variables
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'-9
			if `month' == 10 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'-9
			if `month' == 11 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'-9
			if `month' == 12 rename `var' rf_`year'0`nmonth'`day'
		}
		* define locals to govern file naming
			loc dat = substr("`file'", 1, 4)
			loc ext = substr("`file'", 6, 2)
			loc sat = substr("`file'", 9, 3)

	* save file
	customsave , idvar(y2_hhid) filename("`dat'_`ext'_`sat'_daily.dta") ///
		path("`export'/`folder'") dofile(MWI_IHPS_converter) user($user)
	}
}


* **********************************************************************
* 2 - converts temperature data
* **********************************************************************

* define local with all sub-folders in it
	loc folderList : dir "`root'" dirs "IHPS_t*"

* loop through each of the sub-folders in the above local
foreach folder of local folderList {

	*create directories to write output to
	qui: capture mkdir "`export'/`folder'/"

	* define local with all files in each sub-folder
		loc fileList : dir "`root'/`folder'" files "*.csv"

	* loop through each file in the above local
	foreach file in `fileList' {

		* import the .csv files - this takes time
		import delimited "`root'/`folder'/`file'", varnames (1) clear

		* drop early and late observations
		drop 	tmp_19830101-tmp_19830930 ///
				tmp_20170601-tmp_20171231

		* drop unnecessary months, this will make renaming variables easier (June-Aug)
		foreach var of varlist tmp_* {
			if substr("`var'", 9, 2) == "06" drop `var'
			if substr("`var'", 9, 2) == "07" drop `var'
			if substr("`var'", 9, 2) == "08" drop `var'
			if substr("`var'", 9, 2) == "09" drop `var'
		}
		* shift early month variables one year forward
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc cyear = `year'-1
			if `month' < 10 rename `var' tmp_`cyear'`month'`day'
		}
		* rename the five early month variables
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+3
			if `month' == 05 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+3
			if `month' == 04 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+3
			if `month' == 03 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+3
			if `month' == 02 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+3
			if `month' == 01 rename `var' tmp_`year'0`nmonth'`day'
		}
		* rename the three later month variables
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'-9
			if `month' == 10 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'-9
			if `month' == 11 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'-9
			if `month' == 12 rename `var' tmp_`year'0`nmonth'`day'
		}
		* define locals to govern file naming
			loc dat = substr("`file'", 1, 4)
			loc ext = substr("`file'", 6, 2)
			loc sat = substr("`file'", 9, 2)


	* save file
	customsave , idvar(y2_hhid) filename("`dat'_`ext'_`sat'_daily.dta") ///
		path("`export'/`folder'") dofile(MWI_IHPS_converter) user($user)
	}
}

* close the log
	log	close

/* END */
