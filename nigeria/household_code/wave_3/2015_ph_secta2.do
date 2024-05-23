* Project: WB Weather
* Created on: May 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 3 (2015-2016) POST HARVEST, NIGERIA AG SECTA2
	* determines harvest labor (only) for preceeding rainy season
	* outputs clean data file ready for combination with wave 1 plot data

* assumes
	* access to all raw data
	* mdesc.ado
	
* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************
	
* define paths	
	loc root = "$data/household_data/nigeria/wave_3/raw"
	loc export = "$data/household_data/nigeria/wave_3/refined"
	loc logout = "$data/household_data/nigeria/logs"
	
* open log	
	cap log close
	log using "`logout'/ph_secta2", append

	
* **********************************************************************
* 1 - determine labor use
* **********************************************************************
		
* import the first relevant data file
		use "`root'/secta2_harvestw3", clear 	

describe
sort hhid plotid
isid hhid plotid

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* in this survey we can't tell gender or age of household members
* since we can't match household members we deal with each activity seperately

* create household member labor (weeks x days per week)
		gen	hh_1	=	(sa2q1a2 * sa2q1a3)
		replace	hh_1	=	0	if	hh_1	==	.

		gen	hh_2	=	(sa2q1b2 * sa2q1b3)
		replace	hh_2	=	0	if	hh_2	==	. 

		gen	hh_3 	= 	(sa2q1c2 * sa2q1c3)
		replace	hh_3	=	0	if	hh_3 	== 	.

		gen	hh_4 	= 	(sa2q1d2 * sa2q1d3)
		replace	hh_4 	= 	0 	if 	hh_4 	== 	. 
	
	*** this calculation is for up to 4 members of the household that were laborers although this wave has 8 household members we only use the first 4
	*** per the survey, these are laborers from the last rainy/harvest season
	*** NOT the dry season harvest
	*** does not include planting or cultivation labor (see NGA_pp_sect11c1)


* hired labor days, (# of people days hired to work) HARVEST & THRESH
		gen men_days = (sa2q3)
		replace men_day = 0 if men_days == . 

		gen women_days = (sa2q6)
		replace women_days = 0 if women_days == .
		*** we do not include child labor days

* free labor days, from other households, HARVEST & THRESH
		replace sa2q12a = 0 if sa2q12a == .
		replace sa2q12b = 0 if sa2q12b == .

		gen free_days = (sa2q12a + sa2q12b)
		replace free_days = 0 if free_days == . 

* **********************************************************************
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
	save 			"`export'/ph_secta2.dta", replace

* close the log
	log	close

/* END */