* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited by: reece
* Edited on: May 22 2024
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

* create household member labor 

	
	*** this calculation is for up to 4 members of the household that were laborers although this wave has 8 household members we only use the first 4
	*** per the survey, these are laborers from the last rainy/harvest season
	*** NOT the dry season harvest
	*** does not include planting or cultivation labor (see NGA_pp_sect11c1)
		

	**********************************************************************
* 2 - impute labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				hh_1 hh_2 hh_3 hh_4 men_days women_days free_days
	*** all but one (men_days) has more harvest days than possible
	
* generate local for variables that contain outliers
	loc				labor hh_1 hh_2 hh_3 hh_4 men_days women_days free_days

* replace zero to missing, missing to zero, and outliers to mizzing
	foreach var of loc labor {
	    mvdecode 		`var', mv(0)
		mvencode		`var', mv(0)
	    replace			`var' = . if `var' > 90
	}
	*** 270 outliers changed to missing

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
	sum hh_1_1_  hh_1_2_ hh_1_3_ hh_1_4_ 
	sum hh_2_2_ hh_2_1_ hh_2_3_ hh_2_4_ 
	sum hh_3_1_ hh_3_2_  hh_3_3_ hh_3_4_ 
	sum hh_4_1_ hh_4_2_ hh_4_3_  hh_4_4_ 
	sum men_days_1_ men_days_2_ men_days_3_ men_days_4_ 
	sum women_days_1_ women_days_2_ women_days_3_ women_days_4_ 
	sum free_days_1_ free_days_2_ free_days_3_ free_days_4_	
	
* replace the imputated variables
	replace hh_1 = hh_1_1_
	replace hh_2 = hh_2_2_
	replace hh_3 = hh_3_3_
	replace hh_4 = hh_4_4_
	
* total labor days for harvest
	egen			hrv_labor = rowtotal(hh_1 hh_2 hh_3 hh_4 ///
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
		customsave , idvar(hhid) filename("ph_secta2.dta") ///
			path("`export'/`folder'") dofile(ph_secta2) user($user)

* close the log
	log	close

/* END */