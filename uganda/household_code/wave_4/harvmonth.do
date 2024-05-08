* Project: WB Weather
* Created on: May 2024
* Created by: rg
* Edited on: 8 May 24
* Edited by: rg
* Stata v.18, mac

* does
	* determines if regions are in "north" or "south"

* assumes
	* cleaned 2013_agsec5a.dta and 2013_agsec1

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
	
	use 			"$root/wave_4/refined/2013_agsec5a.dta", clear
		
	gen				year = 2013
		
	keep if 		cropid == 130
	
	*destring		hhid, replace 
	sum 			cropid
			
* merge the location identification
	merge m:1 		hhid using "$root/wave_4/refined/2013_agsec1"
	
	keep if 		_merge == 3
	drop			_merge hhid prcid pltid cropid harvqtykg ///
						hh ea hhid_pnl rotate ///
						cropvalue  wgt13
	
* generate average harvest month for district
	egen			harv = mean(harvmonth), by(district)
	
* round to nearest integer
	replace			harv = round(harv,1)
	lab var			harv "Start of harvest month"

* drop duplicates
	duplicates 		drop region district  harv, force
	
	keep			region district subcounty harv parish
	
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
	save 			"$root/wave_4/refined/harv_month.dta", replace

* close the log
	log	close

/* END */
