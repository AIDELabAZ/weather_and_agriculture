* Project: WB Weather
* Created on: June 2024
* Created by: jdm
* Edited on: 6 June 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans geovars

* assumes
	* raw lsms-isa data

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global	root 		= 	"$data/household_data/ethiopia/wave_5/raw"  
	global	export 		= 	"$data/household_data/ethiopia/wave_5/refined"
	global	logout 		= 	"$data/household_data/ethiopia/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/wave_5_geovars", append

	
* **********************************************************************
* 1 - ESS (Wave 4) - geovars
* **********************************************************************

* import wave 4 geovars
	use 			"$root/ETH_HouseholdGeovariables_Y5.dta", clear

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
	save			"$export/ess5_geovars.dta", replace

* close the log
	log	close

/* END */	
