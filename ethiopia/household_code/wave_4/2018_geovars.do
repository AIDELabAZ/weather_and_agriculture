* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on 24 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans geovars

* assumes
	* access to raw data

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global		root 		 	"$data/household_data/ethiopia/wave_4/raw"  
	global		export 		 	"$data/household_data/ethiopia/wave_4/refined"
	global		logout 		 	"$data/household_data/ethiopia/logs"
	
* open log	
	cap log 	close
	log 		using			"$logout/wave_4_geovars", append

	
* **********************************************************************
* 1 - ESS (Wave 3) - geovars
* **********************************************************************

* import wave 3 geovars
	use 			"$root/ETH_HouseholdGeovariables_Y4.dta", clear

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
	save			"$export/ess3_geovars.dta", replace

* close the log
	log	close

/* END */	
