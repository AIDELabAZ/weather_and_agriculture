* Project: WB Weather
* Created on: Aug 2020
* Created by: alj
* Edited by: jdm
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* household Location data (2009_GSEC1) for the 1st season

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global root 		"$data/household_data/uganda/wave_1/raw"  
	global export 		"$data/household_data/uganda/wave_1/refined"
	global logout 		"$data/household_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2009_GSEC1", append

	
* **********************************************************************
* 1 - UNPS 2009 (Wave 1) - General(?) Section 1 
* **********************************************************************

* import wave 1 season 1
	use 			"$root/2009_GSEC1.dta", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			h1aq1 district
	rename 			h1aq2b county
	rename 			h1aq3b subcounty
	rename 			h1aq4b parish
	rename 			hh_status hh_status2009
	***	district variables not labeled in this wave, just coded

	tab 			region, missing

* drop if missing
	drop if			district == .
	*** dropped 6 observations
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid region district county subcounty parish ///
						hh_status2009 wgt09wosplits wgt09

	compress
	describe
	summarize

* save file
	save 			"$export/2009_GSEC1.dta", replace


* close the log
	log	close

/* END */	
