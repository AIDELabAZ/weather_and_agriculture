* Project: WB Weather
* Created on: Feb 24
* Created by: jet
* Edited by: jet
* Stata v.18

* does
	* cleans geovars

* assumes
	* customsave.ado

* TO DO:
	* customsave, log

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global root 		= "$data/household_data/nigeria/wave_4/raw"  
	global export 		= "$data/household_data/nigeria/wave_4/refined"
	global logout 		= "$data/household_data/nigeria/logs"
	
* open log	
	*cap log 		close
	*log using 		"$logout/wave_4_geovars", append

	
* **********************************************************************
* 1 - GHSY3 (Wave 4) - geovars
* **********************************************************************

* import wave 4 geovars
	use 			"$root/NGA_HouseholdGeovars_Y4.dta", clear

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
