* Project: WB Weather
* Created on: Feb 2024
* Created by: alj
* Edited on: 5 March 2024
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
	
* generate variables for merge with conversion factor database
	generate 		unit_name = ag_g13b
* about 600 observations with _oth - many with kgs but "odd sizes" 
	generate		unit_other_conversion = . 
	replace			unit 
	generate 		condition = ag_g13c
	replace  		condition = ag_g09c if missing(ag_g13c)
	*drop 			if missing(crop_code,unit,condition)		
	recode 			condition (1 2 = 3) if inlist(crop_code,5,28,31,32,33,37,42)
	
* prepare for converstion 
* need district variables 
	merge m:1 case_id using "`root'/hh_mod_a_filt.dta", keepusing(region) assert (2 3) keep (3) nogenerate
	
* bring in conversion file 
	merge m:1 crop_code region unit_name condition conversion using "$root/ihs_seasonalcropconversion_factor_2020.dta", keep(1 3) generate(_conversion)
	tabulate crop_code unit_name if _conversion==1
	keep if _conversion==3
	drop _conversion	
	
	
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