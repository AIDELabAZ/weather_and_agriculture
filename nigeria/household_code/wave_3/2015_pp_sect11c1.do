* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 3 (2015-2016) POST PLANTING, NIGERIA AG SECT11C1
	* determines planting (not harvest) labor for rainy season
	* outputs clean data file ready for combination with wave 3 plot data

* assumes
	* access to all raw data
	* mdesc.ado
	
* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root 	= "$data/household_data/nigeria/wave_3/raw"
	loc export 	= "$data/household_data/nigeria/wave_3/refined"
	loc logout 	= "$data/household_data/nigeria/logs"
	
* open log	
	cap log 	close
	log 		using "`logout'/pp_sect11c1", append

	
* **********************************************************************
* 1 - determine labor
* **********************************************************************
		
* import the first relevant data file
	use "`root'/sect11c1_plantingw3", clear 

	describe
	sort hhid plotid
	isid hhid plotid, missok

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* in this survey we can't tell gender or age of household members
* the survey also does not distinguish between planting and other non-harvest activities
*household labor (# of weeks * # of days/wk = days of labor) for up to 4 members of hh

* create household member labor (weeks x days per week)
	gen hh_1 = (s11c1q1a2 * s11c1q1a3)
	replace hh_1 = 0 if hh_1 == .

	gen hh_2 = (s11c1q1b2 * s11c1q1b3)
	replace hh_2 = 0 if hh_2 == .

	gen hh_3 = (s11c1q1c2 * s11c1q1c3)
	replace hh_3 = 0 if hh_3 == .

	gen hh_4 = (s11c1q1d2 * s11c1q1d3)
	replace hh_4 = 0 if hh_4 == .
	*** this calculation is for up to 4 members of the household that were laborers
	*** per the survey, these are laborers for planting
	*** does not include harvest labor (see NGA_ph_secta2)

*hired labor (# of people days hired for planting)
	gen men_days =  s11c1q3
	replace men_days = 0 if men_days == .

	gen women_days =  s11c1q6
	replace women_days = 0 if women_days == .
	*** we do not include child labor days
	
* **********************************************************************
* 2 - impute labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				hh_1 hh_2 hh_3 hh_4 men_days women_days
	***none of the variables exceed the number of days possible

	
* generate local for variables that contain outliers
	loc				labor hh_1 hh_2 hh_3 hh_4 men_days women_days

* replace zero to missing, missing to zero, and outliers to missing
	foreach var of loc labor {
	    mvdecode 		`var', mv(0)
		mvencode		`var', mv(0)
	    replace			`var' = . if `var' > 142
	}
	*** 212 changes missing

* impute missing values 
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
	
* summarize imputed variables
	sum				hh_1_1_  hh_2_2_ hh_3_3_ hh_4_4_ men_days_5_ 
	
* total labor days for harvest
	egen			pp_labor = rowtotal(hh_1_1_  hh_2_2_ hh_3_3_ hh_4_4_ men_days_5_ women_days)
	lab var			pp_labor "total labor for planting (days)"
	*** unlike harvest labor, this did not ask for unpaid/exchange labor

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
	save 			"`export'/pp_sect11c1.dta", replace

* close the log
	log	close

/* END */