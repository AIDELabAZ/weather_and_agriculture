* Project: WB Weather
* Created on: Feb 2024
* Created by: alj
* Edited on: 22 Feb 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans ...
	* directly follow from ag_g code - by JB

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

* identify cases where units do not match
	bysort 			case_id gardenid plotid crop_code : egen min9 = min(ag_g13b)
	bysort 			case_id gardenid plotid crop_code : egen max9 = max(ag_g13b)	
	generate 		flag2 = ((min9!=max9)) 
	*** 0 observations 
	* list			case_id gardenid plotid crop_code if flag2==1, sepby(case_id)	
	
	generate 		hasall  = (!mi(ag_g13a) & !mi(ag_g13b) & !mi(ag_g13c))
	generate 		hassome = (!mi(ag_g13a) | !mi(ag_g13b) | !mi(ag_g13c))
	tabulate 		hasall hassome
	tabulate		hasall
	*** 32,688 total - 0 = 1800 (5.5%), 1 = 30877 (94.5%)
	tabulate 		hassome 
	*** 32677 total - 0 = 68 (0.21%), 1 = 32609 (99.8%) 
	drop 			hasall hassome
	
	
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