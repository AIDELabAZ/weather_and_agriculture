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
	loc root 		= "$data/household_data/uganda/wave_2/raw"  
	loc export 		= "$data/household_data/uganda/wave_2/refined"
	loc logout 		= "$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/2010_geovars", append

	
* **********************************************************************
* 1 - UNPS 2010 (wave 1) - geovars 
* **********************************************************************

* import wave 1 geovars
	use 			"`root'/UNPS_Geovars_1011.dta", clear

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
		customsave , idvar(hhid) filename("2010_geovars.dta") ///
			path("`export'") dofile(2010_geovars) user($user)

* close the log
	log	close

/* END */	
