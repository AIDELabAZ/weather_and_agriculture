* Project: WB Weather
* Created on: March 2024
* Created by: alj
* Edited on: 11 March 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop price / sales information 
	* directly follow from ag_i code - by JB

* assumes
	* access to MWI W5 raw data
	
* TO DO:
	* done 

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_5/raw"	
	loc		export 	= 	"$data/household_data/malawi/wave_5/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"
	loc 	temp 	= 	"$data/household_data/malawi/wave_5/tmp"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_ag_mod_i", append


* **********************************************************************
* 1 - setup to clean plot  
* **********************************************************************

* **********************************************************************
* ? - end matter, clean up to save
* **********************************************************************

	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_i.dta", replace

* close the log
	log			close

/* END */