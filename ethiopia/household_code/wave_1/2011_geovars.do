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
	loc root 		= "$data/household_data/ethiopia/wave_1/raw"  
	loc export 		= "$data/household_data/ethiopia/wave_1/refined"
	loc logout 		= "$data/household_data/ethiopia/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/wave_1_geovars", append

	
* **********************************************************************
* 1 - ESS (Wave 1) - geovars
* **********************************************************************

* import wave 1 geovars
	use 			"`root'/Pub_ETH_HouseholdGeovariables_Y1.dta", clear

* rename variables
	isid 			household_id

	rename 			ssa_aez09 aez
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			household_id aez

	compress
	describe
	summarize

* save file
		customsave , idvar(household_id) filename("ess1_geovars.dta") ///
			path("`export'") dofile(wave_1_geovars) user($user)

* close the log
	log	close

/* END */	
