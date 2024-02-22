* Project: WB Weather
* Created on: Feb 2024
* Created by: alj
* Edited on: 22 Feb 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans plot size 

* assumes
	* 
* TO DO:
	* complete

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_5/raw"	
	loc		export 	= 	"$data/household_data/malawi/wave_5/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_ag_mod_g", append


* **********************************************************************
* 1 - clean details about crops 
* **********************************************************************

* load data
	use 			"`root'/ag_mod_g.dta", clear
	
	capture 		: noisily : isid case_id gardenid plotid crop_code, missok	
	*** not yet identified at household x plot level, but with missing plot id
	duplicates 		report case_id gardenid plotid crop_code
	* none 

	
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************
	
	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_g.dta", replace

* close the log
	log			close


/* END */