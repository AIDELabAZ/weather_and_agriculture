* Project: WB Weather
* Created on: Oct 2020
* Created by: jdm
* Edited by: jdm
* Stata v.16

* does
	* cleans geovars

* assumes
	* customsave.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root 		= "$data/household_data/uganda/wave_1/raw"  
	loc export 		= "$data/household_data/uganda/wave_1/refined"
	loc logout 		= "$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/2009_geovars", append

	
* **********************************************************************
* 1 - UNPS 2009 (Wave 1) - geovars
* **********************************************************************

* import wave 1 geovars
	use 			"`root'/2009_UNPS_Geovars_0910.dta", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			ssa_aez09 aez
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid aez

	compress
	describe
	summarize

* save file
		customsave , idvar(hhid) filename("2009_geovars.dta") ///
			path("`export'") dofile(2009_geovars) user($user)

* close the log
	log	close

/* END */	
