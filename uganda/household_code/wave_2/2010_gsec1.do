* Project: WB Weather
* Created on: Aug 2020
* Created by: themacfreezie
* Edited by: jdm
* Stata v.16

* does
	* household Location data (2010_GSEC1) for the 1st season

* assumes
	* customsave.ado
	* mdesc.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root 		= "$data/household_data/uganda/wave_2/raw"  
	loc export 		= "$data/household_data/uganda/wave_2/refined"
	loc logout 		= "$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/2010_GSEC1", append

	
* **********************************************************************
* 1 - UNPS 2009 (Wave 2) - General(?) Section 1 
* **********************************************************************

* import wave 2 season 1
	use 			"`root'/GSEC1", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			h1aq1 district
	rename 			h1aq2b county
	rename 			h1aq3b subcounty
	rename 			h1aq4b parish
	rename 			hh_status hh_status2010
	***	district variables not labeled in this wave, just coded

	tab 			region, missing

* drop if missing
	drop if			district == ""
	*** dropped 25 observations
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid region district county subcounty parish ///
						hh_status2010 spitoff09_10 spitoff10_11 wgt10

	compress
	describe
	summarize

* save file
		customsave , idvar(hhid) filename("2010_GSEC1.dta") ///
			path("`export'") dofile(2010_GSEC1) user($user)

* close the log
	log	close

/* END */	
