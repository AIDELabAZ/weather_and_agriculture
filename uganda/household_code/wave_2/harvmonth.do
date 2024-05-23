* Project: WB Weather
* Created on: Oct 2020
* Created by: jdm
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* determines if regions are in "north" or "south"

* assumes
	* access to all raw data
	* cleaned 2010_AGSEC5A.dta, 2011_AGSEC5A.dta, and 2010_GSEC1

* TO DO:
	* done


************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global root 		 "$data/household_data/uganda"
	global logout 		 "$data/household_data/uganda/logs"
	
	cap log 			close
	log using 			"$logout/harvmonth", append
	
	
************************************************************************
**# 1 - import data and rename variables
************************************************************************
	
	use 			"$root/wave_2/refined/2010_AGSEC5A.dta", clear
		
	gen				year = 2010

	append			using "$root/wave_3/refined/2011_AGSEC5A.dta"
	
	replace			year = 2011 if year == .
		
	keep if 		cropid == 130

	sum 			cropid
			
* merge the location identification
	merge m:1 		hhid using "$root/wave_2/refined/2010_GSEC1"
	
	keep if 		_merge == 3
	drop			_merge hhid prcid pltid cropid harvqtykg ///
						hh_status2010 spitoff09_10 spitoff10_11 wgt10 ///
						cropvalue hh_status2011 wgt11
	
* encode district for the imputation
	encode 			district, gen (districtdstrng)
	encode			county, gen (countydstrng)
	encode			subcounty, gen (subcountydstrng)
	encode			parish, gen (parishdstrng)
	
* generate average harvest month for district
	egen			harv = mean(harvmonth), by(districtdstrng)
	
* round to nearest integer
	replace			harv = round(harv,1)
	lab var			harv "Start of harvest month"

* drop duplicates
	duplicates 		drop region district harv, force
	
	drop if			districtdstrng == .
	keep			region district county harv
	
* create "north"/"south" dummy
	gen				season = 0 if harv < 8
	replace			season = 1 if harv > 7
	lab def			season 0 "South" 1 "North"
	lab val			season season
	lab var			season "South/North season"
	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	compress
	describe
	summarize

* save file			
	save 			"$root/wave_1/refined/harv_month.dta", replace
	save 			"$root/wave_2/refined/harv_month.dta", replace
	save 			"$root/wave_3/refined/harv_month.dta", replace

* close the log
	log	close

/* END */
