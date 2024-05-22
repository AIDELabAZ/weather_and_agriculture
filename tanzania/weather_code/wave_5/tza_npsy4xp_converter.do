* Project: WB Weather
* Created on: April 2020
* Created by: jdm
* edited on: 20 May 2024
* edited by: jdm
* Stata v.18

* does
	* reads in Tanzania, extended wave 4 .csv files
    * drops unnecessary daily observations
	* outputs .dta file ready for processing by the weather program
	* does the above for both rainfall and temperature data
	/* 	-To make our weather program work, we need to run the code on data that starts on Nov 1 and ends on May 1
		-Because of this, we will keep rainfall data for the months Nov through May and use the weather command to get rid of May
		-This means we only want to drop data from the months Jun - Oct */

* assumes
	* raw updated weather data

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc			root	=	"$data/weather_data/tanzania/wave_5/raw/npsy4xp_up"
	loc			export	=	"$data/weather_data/tanzania/wave_5/daily/npsy4xp_up"
	loc			logout	=	"$data/weather_data/tanzania/logs"

* open log
	cap log		close
	log			using	"`logout'/tza_npsy4xp_converter", append


* **********************************************************************
* 1 - converts rainfall data
* **********************************************************************

* loop through each file in the above local
	loc fileList : dir "`root'" files "*rf.csv"
	
* loop through each file in the above local
	foreach file in `fileList' {
		
		* import the .csv files - this takes time
		import delimited "`root'/`file'", varnames(1)   ///
			encoding(Big5) stringcols(1) clear

		* drop early and late observations (2015)
		keep 	y4_hhid rf_19831101-rf_20150531

		* drop unnecessary months, this will make renaming variables easier
		foreach var of varlist rf_* {
			if substr("`var'", 8, 2) == "06" drop `var'
			if substr("`var'", 8, 2) == "07" drop `var'
			if substr("`var'", 8, 2) == "08" drop `var'
			if substr("`var'", 8, 2) == "09" drop `var'
			if substr("`var'", 8, 2) == "10" drop `var'
	}
		* shift early month variables one year forward, year refers to start of season
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc cyear = `year'-1
			if `month' < 11 rename `var' rf_`cyear'`month'`day'
		}
		* rename the five early month variables			
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+2
			if `month' == 05 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+2
			if `month' == 04 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+2
			if `month' == 03 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+2
			if `month' == 02 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'+2
			if `month' == 01 rename `var' rf_`year'0`nmonth'`day'
		}
		* rename the two later month variables			
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'-10
			if `month' == 11 rename `var' rf_`year'0`nmonth'`day'
		}
		foreach var of varlist rf_* {
			loc year = substr("`var'", 4, 4)
			loc month = substr("`var'", 8, 2)
			loc day = substr("`var'", 10, 2)
			loc nmonth = `month'-10
			if `month' == 12 rename `var' rf_`year'0`nmonth'`day'
		}
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 

	* save file
		compress
		save			"`export'/`dat'_daily.dta", replace
}


* **********************************************************************
* 2 - converts temperature data
* **********************************************************************

* define local with all files in each sub-folder	
		loc fileList : dir "`root'" files "*tp.csv"
		
* loop through each file in the above local	
	foreach file in `fileList' {
		
		* import the .csv files - this takes time	
		import delimited "`root'/`file'", varnames(1)   ///
			encoding(Big5) stringcols(1) clear

		* drop early and late observations (2015)
		keep 	y4_hhid tmp_19831101-tmp_20150531

		* drop unnecessary months, this will make renaming variables easier (June-Oct)
		foreach var of varlist tmp_* {
			if substr("`var'", 9, 2) == "06" drop `var'
			if substr("`var'", 9, 2) == "07" drop `var'
			if substr("`var'", 9, 2) == "08" drop `var'
			if substr("`var'", 9, 2) == "09" drop `var'
			if substr("`var'", 9, 2) == "10" drop `var'
		}
		* shift early month variables one year forward
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc cyear = `year'-1
			if `month' < 11 rename `var' tmp_`cyear'`month'`day'
		}
		* rename the five early month variables			
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+2
			if `month' == 05 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+2
			if `month' == 04 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+2
			if `month' == 03 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+2
			if `month' == 02 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'+2
			if `month' == 01 rename `var' tmp_`year'0`nmonth'`day'
		}
		* rename the two later month variables			
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'-10
			if `month' == 11 rename `var' tmp_`year'0`nmonth'`day'
		}
		foreach var of varlist tmp_* {
			loc year = substr("`var'", 5, 4)
			loc month = substr("`var'", 9, 2)
			loc day = substr("`var'", 11, 2)
			loc nmonth = `month'-10
			if `month' == 12 rename `var' tmp_`year'0`nmonth'`day'
		}
		
	* define locals to govern file naming	
		loc dat = substr("`file'", 1, length("`file'") - 4) 

	* save file
		compress
		save			"`export'/`dat'_daily.dta", replace
}

* close the log
	log	close

/* END */
