* Project: WB Weather
* Created on: May 2024
* Created by: reece
* Edited on: 24 May 2024
* Edited by: reece
* Stata v.18

* does
	* reads in Nigeria, WAVE 4 (2018-2019) POST PLANTING, NIGERIA AG SECT11C1
	* determines planting (not harvest) labor for rainy season
	* outputs clean data file ready for combination with wave 3 plot data

* assumes
	* customsave.ado
	* mdesc.ado
	
* TO DO:
	* 
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global	root			"$data/household_data/nigeria/wave_4/raw"
	global 	export  		"$data/household_data/nigeria/wave_4/refined"
	global 	logout  		"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "$logout/2018_ph_sect11c1", append


* **********************************************************************
* 1 - determine labor
* **********************************************************************
		
* import the first relevant data file
	use "$root/sect11c1a_plantingw4", clear 
	
	describe
	sort hhid plotid indiv
	isid hhid plotid indiv
	collapse (sum) s11c1q1b, by(zone state lga sector ea hhid plotid)

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* in this survey we can't tell gender or age of household members
* the survey also does not distinguish between planting and other non-harvest activities
*household labor (# of weeks * # of days/wk = days of labor) for up to 4 members of hh
	* cannot follow, not given days for each activity
	
	

* merge in post planting hired labor
	merge 1:1 hhid plotid using "$root/sect11c1b_plantingw4"

** create household member labor 
	gen 		pp_hh_labor = s11c1q1b
	replace 	pp_hh_labor = 0 if s11c1q1b == .
	
* hired labor days, (# of people days hired to work)
	gen			men_days = s11c1q3
	replace 	men_days = 0 if s11c1q3 == .
	
	gen 		women_days = s11c1q5
	replace		women_days = 0 if s11c1q5 == .
	*** we do not include child labor days

* free labor days, from other households
	replace 	s11c1q15a = 0 if s11c1q15a == .
	replace 	s11c1q15b = 0 if s11c1q15b == .
	
	gen 		free_days = (s11c1q15a + s11c1q15b)
	replace		free_days = 0 if free_days == .

	*** this calculation is for up to 4 members of the household that were laborers
	*** per the survey, these are laborers for planting
	*** does not include harvest labor (see NGA_ph_secta2)
		*** did not follow exactly, not able to identify hh members
	
* **********************************************************************
* 2 - impute labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				pp_hh_labor men_days women_days free_days
	
* generate local for variables that contain outliers
	loc				labor pp_hh_labor men_days women_days free_days

* replace zero to missing, missing to zero, and outliers to mizzing
	foreach var of loc labor {
	    mvdecode 		`var', mv(0)
		mvencode		`var', mv(0)
	    replace			`var' = . if `var' > 142
	}
	*** 

* impute missing values (only need to do four variables)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously


* impute each variable in local		
	foreach var of loc labor {
		mi register			imputed `var' // identify variable to be imputed
		sort				hhid plotid, stable // sort to ensure reproducability of results
		mi impute 			pmm `var' i.state, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap
	}						
	mi 				unset	
	

* sum the imputation
	sum pp_hh_labor_1_ pp_hh_labor_2_
	sum men_days_1_ men_days_2_
	sum women_days_1_ women_days_2_
	sum free_days_1_ free_days_2_
	
* replace the imputated variables
	replace pp_hh_labor = pp_hh_labor_1_ 
	* 413 changes made
	replace men_days = men_days_1_
	* 0 changes
	replace women_days = women_days_1_
	* 0 changes
	replace free_days = free_days_1_
	* 0 changes
	
* total labor days for harvest
	egen			pp_labor = rowtotal(pp_hh_labor ///
							 women_days men_days free_days)
	lab var			pp_labor "total labor for planting (days)"

* check for missing values
	mdesc			pp_labor
	*** no missing values


* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					pp_labor

* create unique household-plot identifier
	isid			hhid plotid
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"
	
	compress
	describe
	summarize 

* save file
	save 			"$export/pp_sect11c1.dta", replace

* close the log
	log	close

/* END */