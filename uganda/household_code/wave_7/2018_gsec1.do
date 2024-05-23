* Project: WB Weather
* Created on: Aug 2020
* Created by: themacfreezie
* Edited by: jdm
* Stata v.16

* does
	* household Location data (2011_GSEC1) for the 1st season

* assumes
	* customsave.ado
	* mdesc.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root 		= "$data/household_data/uganda/wave_3/raw"  
	loc export 		= "$data/household_data/uganda/wave_3/refined"
	loc logout 		= "$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/2011_GSEC1", append

	
* **********************************************************************
* 1 - UNPS 2011 (Wave 3) - General(?) Section 1 
* **********************************************************************

* import wave 3 season 1
	use				"`root'/GSEC1", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			h1aq1 district
	rename 			h1aq2 county
	rename 			h1aq3 subcounty
	rename 			h1aq4 parish
	rename 			HHS_hh_shftd_dsntgrtd hh_status2011
	rename 			mult wgt11
	***	district variables not labeled in this wave, just coded

	tab 			region, missing

* drop if missing
	drop if			district == ""
	*** dropped 164 observations
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

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
