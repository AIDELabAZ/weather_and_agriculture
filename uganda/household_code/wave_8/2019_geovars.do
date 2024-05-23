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
	loc root 		= "$data/household_data/uganda/wave_3/raw"  
	loc export 		= "$data/household_data/uganda/wave_3/refined"
	loc logout 		= "$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/2011_geovars", append

	
* **********************************************************************
* 1 - UNPS 2011 (wave 1) - geovars 
* **********************************************************************

* import wave 1 geovars
	use 			"`root'/UNPS_Geovars_1112.dta", clear

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
		customsave , idvar(hhid) filename("2011_geovars.dta") ///
			path("`export'") dofile(2011_geovars) user($user)

* close the log
	log	close

/* END */	
