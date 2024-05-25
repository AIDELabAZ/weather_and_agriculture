* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited by: reece
* Edited on: May 23 2024
* Stata v.18

* does
	* reads in Nigeria, WAVE 4 (2018-2019) POST HARVEST, NIGERIA AG SECTA2
	* determines harvest labor (only) for preceeding rainy season
	* outputs clean data file ready for combination with wave 1 plot data

* assumes
	* customsave.ado
	* mdesc.ado
	
* TO DO:
	* complete
	
* **********************************************************************
* 0 - setup
* **********************************************************************
	
* define paths	
	global root			"$data/household_data/nigeria/wave_4/raw"
	global export		"$data/household_data/nigeria/wave_4/refined"
	global logout		"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "$logout/ph_secta2", append

* **********************************************************************
* 1 - determine labor use
* **********************************************************************
		
* import the first relevant data file
	use "$root/secta2a_harvestw4", clear 	

	describe
	sort hhid plotid indiv
	isid hhid plotid indiv
	collapse (sum) sa2aq1b, by(zone state lga sector ea hhid plotid)

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* in this survey we can't tell gender or age of household members
* since we can't match household members we deal with each activity seperately
	*cannot follow, not given day for each activity
	

* merge in post harvest hired labor
	merge 1:1 hhid plotid using "$root/secta2b_harvestw4"
	

* create household member labor 
	gen 		ph_hh_labor = sa2aq1b
	replace 	ph_hh_labor = 0 if sa2aq1b == .
	
* hired labor days, (# of people days hired to work)
	gen			men_days = sa2bq3
	replace 	men_days = 0 if sa2bq3 == .
	
	gen 		women_days = sa2bq6
	replace		women_days = 0 if sa2bq6 == .
	*** we do not include child labor days

* free labor days, from other households
	replace 	sa2bq15a = 0 if sa2bq15a == .
	replace 	sa2bq15b = 0 if sa2bq15b == .
	
	gen 		free_days = (sa2bq15a + sa2bq15b)
	replace		free_days = 0 if free_days == .
	
	
	*** this calculation is for up to 4 members of the household that were laborers although this wave has 8 household members we only use the first 4
	*** per the survey, these are laborers from the last rainy/harvest season
	*** NOT the dry season harvest
	*** does not include planting or cultivation labor (see NGA_pp_sect11c1)
		*** did not follow exactly, not able to identify hh members
		

	**********************************************************************
* 2 - impute labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				ph_hh_labor men_days women_days free_days
	
* generate local for variables that contain outliers
	loc				labor ph_hh_labor men_days women_days free_days

* replace zero to missing, missing to zero, and outliers to mizzing
	foreach var of loc labor {
	    mvdecode 		`var', mv(0)
		mvencode		`var', mv(0)
	    replace			`var' = . if `var' > 90
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
	sum ph_hh_labor_1 ph_hh_labor_2
	sum men_days_1_ men_days_2_
	sum women_days_1_ women_days_2_
	sum free_days_1_ free_days_2_
	
* replace the imputated variables
	replace ph_hh_labor = ph_hh_labor_1_ 
	* 235 changes made
	replace men_days = men_days_1_
	* 0 changes
	replace women_days = women_days_1_
	* 0 changes
	replace free_days = free_days_1_
	* 0 changes
	
* total labor days for harvest
	egen			hrv_labor = rowtotal(ph_hh_labor ///
							 women_days men_days free_days)
	lab var			hrv_labor "total labor at harvest (days)"

* check for missing values
	mdesc			hrv_labor
	*** no missing values

* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					hrv_labor

* create unique household-plot identifier
	isid			hhid plotid
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"
	
	compress
	describe
	summarize 
	
	sum hrv_labor, detail
	* harvest labor looks reasonable more than 90% of observations are less than 91 days within the cap by Palacios-Lopez et al. (2017) in Food Policy for harvest labor.

* save file
	save 			"$export/ph_secta2.dta", replace

* close the log
	log	close

/* END */