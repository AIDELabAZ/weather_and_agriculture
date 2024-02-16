* Project: WB Weather
* Created on: Feb 2024
* Created by: rg
* Edited on: 16 Feb 24
* Edited by: rg
* Stata v.18, mac

* does
	* household Location data (2015_GSEC1) for the 1st season

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* finish section 1 

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	 "$data/household_data/uganda/wave_5/raw"  
	global export 	 "$data/household_data/uganda/wave_5/refined"
	global logout 	 "$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2015_GSEC1", append

	
***********************************************************************
**# 1 - UNPS 2011 (Wave 5) - General(?) Section 1 
***********************************************************************

* import wave 5 season 1
	use				"$root/hh/gsec1", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid
	
	drop 			district
	rename 			district_name district
	rename 			subcounty_name subcounty
	rename 			parish_name parish
	rename 			hwgt_W5 wgt15

	tab 			region, missing

* drop if missing
	drop if			district == ""
	*** dropped 164 observations
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hhid region district county subcounty parish ///
						hh_status2011 wgt11

	compress
	describe
	summarize

* save file
		customsave , idvar(hhid) filename("2011_GSEC1.dta") ///
			path("`export'") dofile(2011_GSEC1) user($user)

* close the log
	log	close

/* END */	
