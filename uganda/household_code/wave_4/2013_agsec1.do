* Project: WB Weather
* Created on: Feb 2024
* Created by: rg
* Edited on: 16 Feb 24
* Edited by: rg
* Stata v.18, mac

* does
	* household Location data (2013_AGSEC1) for the 1st season

* assumes
	* access to raw data
	
* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	"$data/household_data/uganda/wave_4/raw"  
	global export 	"$data/household_data/uganda/wave_4/refined"
	global logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2013_AGSEC1", append

	
***********************************************************************
**# 1 - UNPS 2013 (Wave 4) - Section 1 
***********************************************************************

* import wave 4 season 1
	use				"$root/agric/AGSEC1", clear

* rename variables
	isid 			HHID
	rename			HHID hhid

	rename 			district_name district
	rename 			subcounty_name subcounty
	rename 			parish_name parish
	rename 			wgt wgt13
	rename			HHID_old hhid_pnl

* drop if missing
	drop if			district == ""
	*** dropped 0 observations
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hh hhid region district subcounty parish ///
						 wgt13 hhid_pnl rotate ea 

	compress
	describe
	summarize

* save file
	save			"$export/2013_agsec1.dta", replace 

* close the log
	log	close

/* END */	
