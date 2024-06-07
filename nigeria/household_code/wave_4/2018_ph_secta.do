* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on: 29 May 2024
* Edited by: rjdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 4, (2018-2019) POST HARVEST, HOUSEHOLD
	* determines hhid and is household is new or old

* assumes
	* access to raw data
	
* TO DO:
	* complete

* **********************************************************************
**#0 - setup
* **********************************************************************

* define paths	
	global root			"$data/household_data/nigeria/wave_4/raw"
	global export		"$data/household_data/nigeria/wave_4/refined"
	global logout		"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "$logout/pp_secta", append


* **********************************************************************
**#1 - determine household id panel weights etc
* **********************************************************************

* import the first relevant data file
	use 					"$root/secta_plantingw4", clear

* rename variables
	isid 			hhid

	rename 			wt_wave4 wgt18
	rename 			wt_longpanel wgt_pnl
	rename 			tracked_obs track


	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	keep 			hhid zone state lga sector ea strata wgt18 ///
						wgt_pnl old_new track

	compress
	describe
	summarize

* save file
	save 			"$export/pp_secta.dta", replace

* close the log
	log	close

/* END */	
