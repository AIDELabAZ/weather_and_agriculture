* Project: WB Weather
* Created on: Oct 2020
* Created by: jdm
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans geovars

* assumes
	* access to all raw data

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root 		= "$data/household_data/tanzania/wave_1/raw"  
	loc export 		= "$data/household_data/tanzania/wave_1/refined"
	loc logout 		= "$data/household_data/tanzania/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/npsy1_geovars", append

	
* **********************************************************************
* 1 - NPSY1 (Wave 1) - geovars
* **********************************************************************

* import wave 1 geovars
	use 			"`root'/HH.Geovariables_Y1.dta", clear

* rename variables
	isid 			hhid

	rename 			land03 aez
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid aez

	compress
	describe
	summarize

* save file
		save 		"`export'/2008_geovars.dta", replace

* close the log
	log	close

/* END */	
