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
	loc root 		= "$data/household_data/tanzania/wave_2/raw"  
	loc export 		= "$data/household_data/tanzania/wave_2/refined"
	loc logout 		= "$data/household_data/tanzania/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/2010_geovars", append

	
* **********************************************************************
* 1 - NPSY2 (Wave 2) - geovars
* **********************************************************************

* import wave 2 geovars
	use 			"`root'/HH.Geovariables_Y2.dta", clear

* rename variables
	isid 			y2_hhid

	rename 			land03 aez
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			y2_hhid aez

	compress
	describe
	summarize

* save file
		customsave , idvar(y2_hhid) filename("2010_geovars.dta") ///
			path("`export'") dofile(2010_geovars) user($user)

* close the log
	log	close

/* END */	
