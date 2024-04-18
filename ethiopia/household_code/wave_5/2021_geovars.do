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
	loc root 		= "$data/household_data/ethiopia/wave_3/raw"  
	loc export 		= "$data/household_data/ethiopia/wave_3/refined"
	loc logout 		= "$data/household_data/ethiopia/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/wave_3_geovars", append

	
* **********************************************************************
* 1 - ESS (Wave 3) - geovars
* **********************************************************************

* import wave 3 geovars
	use 			"`root'/ETH_HouseholdGeovars_y3.dta", clear

* rename variables
	isid 			household_id2

	rename 			ssa_aez09 aez
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			household_id2 aez

	compress
	describe
	summarize

* save file
		customsave , idvar(household_id2) filename("ess3_geovars.dta") ///
			path("`export'") dofile(wave_3_geovars) user($user)

* close the log
	log	close

/* END */	
