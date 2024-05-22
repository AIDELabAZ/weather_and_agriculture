* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on: 22 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans geovars

* assumes
	* access to all raw data

* TO DO:
	* GEOVARS DOES NOT EXIST FOR THIS WAVE
/*
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root 		= "$data/household_data/tanzania/wave_4/raw"  
	loc export 		= "$data/household_data/tanzania/wave_4/refined"
	loc logout 		= "$data/household_data/tanzania/logs"
	
* open log	
	cap log 		close
	log using 		"`logout'/2014_geovars", append

	
* **********************************************************************
* 1 - NPSY3 (Wave 3) - geovars
* **********************************************************************

* import wave 3 geovars
	use 			"`root'/HouseholdGeovars_Y3.dta", clear

* rename variables
	isid 			y3_hhid

	rename 			land03 aez
	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			y3_hhid aez

	compress
	describe
	summarize

* save file
	save 			"`export'/2012_geovars.dta", replace

* close the log
	log	close

/* END */	
