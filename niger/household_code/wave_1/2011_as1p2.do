* Project: WB Weather
* Created on: June 2020
* Created by: ek
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Niger, WAVE 1 (2011), POST HARVEST (second passage), ecvmaas1_p2_en
	* cleans labor post planting - planting labor 
	* cleans labor post harvest - harvesting labor 
	* outputs clean data file ready for combination with wave 1 plot data

* assumes
	* access to all raw data

* To Do:
	* done
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=		"$data/household_data/niger/wave_1/raw"
	loc		export	=		"$data/household_data/niger/wave_1/refined"
	loc		logout	= 		"$data/household_data/niger/logs"

* open log
	cap 	log 	close
	log 	using	"`logout'/2011_as1p2", append

	
* **********************************************************************
* 1 - set up and organization 
* **********************************************************************

* import the first relevant data file
	use				"`root'/ecvmaas1_p2_en", clear

* need to rename for English
	rename 			passage visit
	label 			var visit "number of visit"
	rename			grappe clusterid
	label 			var clusterid "cluster number"
	rename			menage hh_num
	label 			var hh_num "household number - not unique id"
	*** will need to do these in every file
	rename 			as01qa ord 
	label 			var ord "number of order"
	rename 			as01q03 field 
	label 			var field "field number"
	rename 			as01q05 parcel 
	label 			var parcel "parcel number"


* drop households that did not use field during the rainy season
	drop 	if 	as02aq04 == 2
	*** 460 observations dropped
	*** This variable most closely resembles the variable that asks if fields were cultivated
	*** In wave 2 we dropped observations if fields were not cultivated

* drop the households missing field, parcel, ord to create the id variable
	mdesc clusterid hh_num ord field parcel
	drop	if field==.
	drop    if ord == .
	drop 	if parcel == .
	*** dropped 1630 observations
	
* need to include hid field parcel to uniquely identify
	sort 			hid field parcel
	isid 			hid field parcel


* **********************************************************************
* 2 - determine planting labor allocation 
* **********************************************************************

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* will not disaggregate gender / age - pool together, as with other rounds 
* in line with others, will deal with each activity seperately

* create household member labor 
* as02aq28**a identified HH ID of laborer 
* as02aq28**b identifies number of days that person worked 

	gen				hh_1 = as02aq28b
	replace			hh_1 = 0 if hh_1 == .
	
	gen				hh_2 = as02aq29b
	replace			hh_2 = 0 if hh_2 == .
	
	gen				hh_3 = as02aq30b
	replace			hh_3 = 0 if hh_3 == .
	
	gen				hh_4 = as02aq31b
	replace			hh_4 = 0 if hh_4 == .
	
	gen				hh_5 = as02aq32b
	replace			hh_5 = 0 if hh_5 == .
	
	gen				hh_6 = as02aq33b
	replace			hh_6 = 0 if hh_6 == .
	
	*** this calculation is for up to 6 members of the household that were laborers
	*** per the survey, these are laborers from the main rainy season
	*** includes labor for various planting activities - 182 day max 
	*** does not include harvest labor or prep labor 
	
* hired labor days   
	*** hired labor days is called is "non-family labor (other)" 

	tab 			as02aq35a
	*** 1237 hired "other" labor, 4965  did not
	
	gen				hired_men = .
	replace			hired_men = as02aq35b if as02aq35a == 1
	replace			hired_men = 0 if as02aq35a != 1
	replace			hired_men = 0 if as02aq35a == .
	replace 		hired_men = 0 if hired_men == .  

	gen				hired_women = .
	replace			hired_women = as02aq35c if as02aq35a == 1
	replace			hired_women = 0 if as02aq35a != 1
	replace			hired_women = 0 if as02aq35a == 2
	replace 		hired_women = 0 if as02aq35c == 999
	replace			hired_women = 0 if as02aq35a == .
	replace 		hired_women = 0 if hired_women == .  
	*** we do not include child labor days
	
* mutual labor days from other households
	tab 			as02aq34a, missing
	*** 521 received mutual labor,  5681  did not
	
	gen 			mutual_men = .
	replace			mutual_men = as02aq34b if as02aq34a == 1
	replace 		mutual_men = 0 if as02aq34a != 1
	replace			mutual_men = 0 if as02aq34a == 2
	replace			mutual_men = 0 if as02aq34a == . 
	replace 		mutual_men = 0 if mutual_men == . 

	gen 			mutual_women = .
	replace			mutual_women = as02aq34c if as02aq34a == 1
	replace 		mutual_women = 0 if as02aq34a != 1
	replace			mutual_women = 0 if as02aq34a == 2
	replace			mutual_women = 0 if as02aq34a == .
	replace			mutual_women = 0 if mutual_women == . 
	*** we do not include child labor days
	
	
* **********************************************************************
* 3 - impute planting labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				hh_1 hh_2 hh_3 hh_4 hh_5 hh_6 hired_men hired_women mutual_men mutual_women
	*** hired_men is greater than the maximum (182 days)
	*** max labor guidelines are per person and hired men and hired women is not disaggregated so those we leave the higher values
	
* generate local for variables that contain outliers
	loc				labor hired_men

* replace zero to missing, missing to zero, and outliers to missing
	foreach var of loc labor {
	mvdecode 		`var', mv(0)
	mvencode		`var', mv(0)
	replace			`var' = . if `var' > 90
}
	*** 23 outliers changed to missing

* impute missing values (going to impute all variables - rather than subset)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously


* impute each variable in local		
	foreach var of loc labor {
		mi register			imputed `var' // identify variable to be imputed
		sort				hid field parcel, stable 
		// sort to ensure reproducability of results
	mi impute 			pmm `var' i.clusterid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap
	}						
	mi 				unset	
	
* summarize imputed variables
	sum				hired_men_1_
	*** all values seem fine
	replace 		hired_men = hired_men_1_ 
	drop hired_men_1_

* total labor days for harvest
	egen			hh_plant_labor = rowtotal(hh_1 hh_2 hh_3 hh_4 hh_5 hh_6)
	egen			hired_plant_labor  = rowtotal(hired_men hired_women)
	egen			mutual_plant_labor = rowtotal(mutual_men mutual_women)
	egen			plant_labor = rowtotal(hh_plant_labor hired_plant_labor)
	lab var			plant_labor "total labor for planting (days) - no free labor"
	egen 			plant_labor_all = rowtotal(hh_plant_labor hired_plant_labor mutual_plant_labor)  
	lab var			plant_labor_all "total labor for planting (days) - with free labor"

* check for missing values
	mdesc			plant_labor plant_labor_all
	*** no missing values
	sum 			plant_labor plant_labor_all
	*** which is used will not make that much of a difference
	*** with free labor: average = 39.41, max = 554
	*** without free labor: average = 38.63, max = 554

* drop intermediate variables
	drop 			hh_1- mutual_plant_labor

	
* **********************************************************************
* 4 - determine harvest labor allocation 
* **********************************************************************

* create household member labor 
* as02aq36**a identified HH ID of laborer 
* as02aq36**b identifies number of days that person worked 
	gen				hh_1 = as02aq36b
	replace			hh_1 = 0 if hh_1 == .
	
	gen				hh_2 = as02aq37b
	replace			hh_2 = 0 if hh_2 == .
	
	gen				hh_3 = as02aq38b
	replace			hh_3 = 0 if hh_3 == .
	
	gen				hh_4 = as02aq39b
	replace			hh_4 = 0 if hh_4 == .
	
	gen				hh_5 = as02aq40b
	replace			hh_5 = 0 if hh_5 == .
	
	gen				hh_6 = as02aq41b
	replace			hh_6 = 0 if hh_6 == .
	*** this calculation is for up to 6 members of the household that were laborers
	*** per the survey, these are laborers from the main rainy season
	*** includes labor for various planting activities - 91 day max 
	*** does not include planting labor or prep labor 
	
* hired labor days   
	tab 			as02aq43a, missing
	*** 515 hired "other" labor, 5687  did not
	
	tab 			as02aq43a
	tab 			as02aq43b
	gen				hired_men = .
	replace			hired_men = as02aq43b if as02aq43a == 1 
	replace			hired_men = 0 if as02aq43a == 2
	replace			hired_men = 0 if as02aq43a != 1
	replace			hired_men = 0 if as02aq43a == .
	replace 		hired_men = 0 if hired_men == .  

	tab 			as02aq43c
	gen				hired_women = .
	replace			hired_women = as02aq43c if as02aq43a == 1
	replace			hired_women = 0 if as02aq43c == 2
	replace			hired_women = 0 if as02aq43c == .
	replace 		hired_women = 0 if as02aq43c == 999
	replace 		hired_women = 0 if hired_women == .  
	*** we do not include child labor days
	
* mutual labor days from other households
	tab 			as02aq42a
	*** 247 received mutual labor, 4587 did not
	
	gen 			mutual_men = .
	replace			mutual_men = as02aq42b if as02aq42a == 1
	replace 		mutual_men = 0 if as02aq42a != 1
	replace			mutual_men = 0 if as02aq42a == 2
	replace			mutual_men = 0 if as02aq42a == .
	replace 		mutual_men = 0 if mutual_men == . 

	gen 			mutual_women = .
	replace			mutual_women = as02aq42c if as02aq42a == 1
	replace			mutual_women = 0 if as02aq42a != 1
	replace			mutual_women = 0 if as02aq42a == 2
	replace			mutual_women = 0 if as02aq42a == . 
	replace			mutual_women = 0 if mutual_women == . 
	*** we do not include child labor days

	
* **********************************************************************
* 5 - impute labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				hh_1 hh_2 hh_3 hh_4 hh_5 hh_6 hired_men hired_women mutual_men mutual_women
	*** hh_1 is greater than the maximum (91 days)
	
* generate local for variables that contain outliers
	loc				labor hh_1

* replace zero to missing, missing to zero, and outliers to missing
	foreach var of loc labor {
	    mvdecode 		`var', mv(0)
		mvencode		`var', mv(0)
	    replace			`var' = . if `var' > 90
	}
	*** 6 outliers changed to missing

* impute missing values (only need to do 1 variable - set new local)
	loc				laborimp hh_1
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously


* impute each variable in local		
	foreach var of loc laborimp {
		mi register			imputed `var' // identify variable to be imputed
		sort				hid field parcel, stable // sort to ensure reproducability of results
		mi impute 			pmm `var' i.clusterid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap
	}						
	mi 				unset	
	
* summarize imputed variables
	sum				hh_1_1_
	* all values seem fine
	replace			hh_1 = hh_1_1_

* total labor days for harvest
	egen			hh_harvest_labor = rowtotal(hh_1 hh_2 hh_3 hh_4 hh_5 hh_6)
	egen			hired_harvest_labor  = rowtotal(hired_men hired_women)
	egen			mutual_harvest_labor = rowtotal(mutual_men mutual_women)
	egen			harvest_labor = rowtotal(hh_harvest_labor hired_harvest_labor)
	lab var			harvest_labor "total labor for planting (days) - no free labor"
	egen 			harvest_labor_all = rowtotal(hh_harvest_labor hired_harvest_labor mutual_harvest_labor)  
	lab var			harvest_labor_all "total labor for planting (days) - with free labor"

* check for missing values
	mdesc			harvest_labor harvest_labor_all
	*** no missing values
	sum 			harvest_labor harvest_labor_all
	*** which is used will not make that much of a difference (different max)
	*** with free labor: average = 8.5, max = 200
	*** without free labor: average = 8.79, max = 200
	*** seems a little low
	
	
* **********************************************************************
* 6 - end matter, clean up to save
* **********************************************************************

	keep 			hid clusterid hh_num field parcel plant_labor plant_labor_all ///
					harvest_labor harvest_labor_all

* create unique household-plot identifier
	isid				hid field parcel
	sort				hid field parcel
	egen				plot_id = group(hid field parcel)
	lab var				plot_id "unique field and parcel identifier"

	compress
	describe
	summarize

* save file
	save 			"`export'/2011_as1p2", replace

* close the log
	log	close

/* END */
