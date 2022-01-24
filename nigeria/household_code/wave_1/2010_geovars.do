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
	loc root 		= "$data/household_data/nigeria/wave_1/raw"  
	loc export 		= "$data/household_data/nigeria/wave_1/refined"
	loc logout 		= "$data/household_data/nigeria/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/wave_1_geovars", append

	
* **********************************************************************
* 1 - GHSY1 (Wave 1) - geovars
* **********************************************************************

* import wave 1 geovars
	use 			"`root'/NGA_HouseholdGeovariables_Y1.dta", clear

* rename variables
	isid 			hhid

	rename 			ssa_aez09 aez
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid aez

	compress
	describe
	summarize

* save file
		customsave , idvar(hhid) filename("NGA_geovars.dta") ///
			path("`export'") dofile(NGA_geovars) user($user)

* close the log
	log	close

/* END */	
