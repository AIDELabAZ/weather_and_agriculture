* Project: WB Weather
* Created on: June 2020
* Created by: alj
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Niger, WAVE 2 (2014), POST PLANTING (first passage), ECVMA2_AS2AP2
	* cleans labor post planting - planting labor 
	* cleans labor post harvest - harvesting labor 
	* outputs clean data file ready for combination with wave 2 plot data

* assumes
	* access to all raw data

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=		"$data/household_data/niger/wave_2/raw"
	loc		export	=		"$data/household_data/niger/wave_2/refined"
	loc		logout	= 		"$data/household_data/niger/logs"

* open log
	cap		log 	close
	log 	using	"`logout'/2014_as2ap2", append

	
* **********************************************************************
* 1 - set up and organization 
* **********************************************************************

* import the first relevant data file
	use				"`root'/ECVMA2_AS2AP2", clear

* need to rename for English
	rename 			PASSAGE visit
	label 			var visit "number of visit"
	rename			GRAPPE clusterid
	label 			var clusterid "cluster number"
	rename			MENAGE hh_num
	label 			var hh_num "household number - not unique id"
	rename 			EXTENSION extension 
	label 			var extension "extension of household"
	*** will need to do these in every file
	rename 			AS02AQ01 field 
	label 			var field "field number"
	rename 			AS02AQ03 parcel 
	label 			var parcel "parcel number"
	
* create new household id for merging with weather 
	tostring		clusterid, replace 
	gen str2 		hh_num1 = string(hh_num,"%02.0f")
	tostring		extension, replace
	egen			hhid_y2 = concat( clusterid hh_num1 extension  )
	destring		hhid_y2, replace
	order			hhid_y2 clusterid hh_num hh_num1 extension 
	
* create new household id for merging with year 1 
	egen			hid = concat( clusterid hh_num1  )
	destring		hid, replace
	order			hhid_y2 hid clusterid hh_num hh_num1 
	
* need to destring variables for later use in imputes 	
	destring 		clusterid, replace
	
	
* hhid_y2 field, and parcel to uniquely identify
	describe
	sort 			hhid_y2 field parcel
	*isid 			hhid_y2	field parcel  
	*** NOT UNIQUELY IDENTIFYING - will address at the end of the file 

* determine cultivated plot
	rename 			AS02AQ04 cultivated
	label 			var cultivated "plot cultivated"
* drop if not cultivated
	keep 			if cultivated == 1
	*** 305 observations dropped

	
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
* AS02AQ**A identified HH ID of laborer 
* AS02AQ**B identifies number of days that person worked 
	gen				hh_1 = AS02AQ28B
	replace			hh_1 = 0 if hh_1 == .
	
	gen				hh_2 = AS02AQ29B
	replace			hh_2 = 0 if hh_2 == .
	
	gen				hh_3 = AS02AQ30B
	replace			hh_3 = 0 if hh_3 == .
	
	gen				hh_4 = AS02AQ31B
	replace			hh_4 = 0 if hh_4 == .
	
	gen				hh_5 = AS02AQ32B
	replace			hh_5 = 0 if hh_5 == .
	
	gen				hh_6 = AS02AQ33B
	replace			hh_6 = 0 if hh_6 == .
	*** this calculation is for up to 6 members of the household that were laborers
	*** per the survey, these are laborers from the main rainy season
	*** includes labor for various planting activities - 182 day max 
	*** does not include harvest labor or prep labor 
	
* hired labor days   
* language is different than in P1, in this case refers to "other"
* i think that pooling all three together will be the most appropriate method 
* that is, including hired, mutual, and family labor 
	tab 			AS02AQ35A
	*** 1153 hired "other" labor, 3681  did not
	
	gen				hired_men = .
	replace			hired_men = AS02AQ35B if AS02AQ35A == 1
	replace			hired_men = 0 if AS02AQ35A == 2
	replace			hired_men = 0 if AS02AQ35A == 9 
	replace			hired_men = 0 if AS02AQ35B == 999
	replace 		hired_men = 0 if hired_men == .  

	gen				hired_women = .
	replace			hired_women = AS02AQ35C if AS02AQ35A == 1
	replace			hired_women = 0 if AS02AQ35A == 2
	replace			hired_women = 0 if AS02AQ35A == 9 
	replace			hired_women = 0 if AS02AQ35C == 999
	replace 		hired_women = 0 if hired_women == .  
	*** we do not include child labor days
	
* mutual labor days from other households
	tab 			AS02AQ34A
	*** 372 received mutual labor,  4462  did not
	
	gen 			mutual_men = .
	replace			mutual_men = AS02AQ34B if AS02AQ34A == 1
	replace			mutual_men = 0 if AS02AQ34A == 2
	replace			mutual_men = 0 if AS02AQ34A == 9 
	replace			mutual_men = 0 if AS02AQ34B == 999
	replace 		mutual_men = 0 if mutual_men == . 

	gen 			mutual_women = .
	replace			mutual_women = AS02AQ34C if AS02AQ34A == 1
	replace			mutual_women = 0 if AS02AQ34A == 2
	replace			mutual_women = 0 if AS02AQ34A == 9 
	replace			mutual_women = 0 if AS02AQ34C == 999 
	replace			mutual_women = 0 if mutual_women == . 
	*** we do not include child labor days

	
* **********************************************************************
* 3 - impute planting labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				hh_1 hh_2 hh_3 hh_4 hh_5 hh_6 hired_men hired_women mutual_men mutual_women
	*** hired_men, hired_women, mutual_men are all greater than the minimum (182 days)
	
* generate local for variables that contain outliers
	loc				labor hh_1 hh_2 hh_3 hh_4 hh_5 hh_6 hired_men hired_women mutual_men mutual_women

* replace zero to missing, missing to zero, and outliers to missing
	foreach var of loc labor {
	    mvdecode 		`var', mv(0)
		mvencode		`var', mv(0)
	    replace			`var' = . if `var' > 90
	}
	*** 110 outliers changed to missing

* impute missing values (going to impute all variables - rather than subset)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local		
	foreach var of loc labor {
		mi register			imputed `var' // identify variable to be imputed
		sort				hhid_y2 field parcel, stable 
		// sort to ensure reproducability of results
		mi impute 			pmm `var' i.clusterid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap
	}						
	mi 				unset	
	
* summarize imputed variables
	sum				hh_1_1_ hh_2_2_ hh_3_3_ hh_4_4_ hh_5_5_ hh_6_6_ hired_men_4_ hired_women_4_ ///
					mutual_men_5_ mutual_women_6_ 
	*** all values seem fine

	replace			hh_1 = hh_1_1_
	replace			hh_2 = hh_2_2_	
	replace 		hh_3 = hh_3_3_
	replace			hh_4 = hh_4_4_
	replace			hh_5 = hh_5_5_
	replace 		hh_6 = hh_6_6_
	replace 		hired_men = hired_men_4_ 
	replace			hired_women = hired_women_4_ 
	replace			mutual_men = mutual_men_5_
	replace			mutual_women = mutual_women_6_ 

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
	*** with free labor: average = 46.9, max = 392
	*** without free labor: average = 47.4, max = 392
	
* drop intermediate variables
	drop 			hh_1- mutual_plant_labor
	
	
* **********************************************************************
* 4 - determine harvest labor allocation 
* **********************************************************************

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* will not disaggregate gender / age - pool together, as with other rounds 
* in line with others, will deal with each activity seperately

* create household member labor 
* AS02AQ**A identified HH ID of laborer 
* AS02AQ**B identifies number of days that person worked 

	gen				hh_1 = AS02AQ36B
	replace			hh_1 = 0 if hh_1 == .
	
	gen				hh_2 = AS02AQ37B
	replace			hh_2 = 0 if hh_2 == .
	
	gen				hh_3 = AS02AQ38B
	replace			hh_3 = 0 if hh_3 == .
	
	gen				hh_4 = AS02AQ39B
	replace			hh_4 = 0 if hh_4 == .
	
	gen				hh_5 = AS02AQ40B
	replace			hh_5 = 0 if hh_5 == .
	
	gen				hh_6 = AS02AQ41B
	replace			hh_6 = 0 if hh_6 == .
	
	*** this calculation is for up to 6 members of the household that were laborers
	*** per the survey, these are laborers from the main rainy season
	*** includes labor for various planting activities - 91 day max 
	*** does not include planting labor or prep labor 
	
* hired labor days   
* language is different than in P1, in this case refers to "other"
* i think that pooling all three together will be the most appropriate method 
* that is, including hired, mutual, and family labor 

	tab 			AS02AQ43A
	*** 671 hired "other" labor, 4164  did not
	
	gen				hired_men = .
	replace			hired_men = AS02AQ43B if AS02AQ43A == 1
	replace			hired_men = 0 if AS02AQ43A == 2
	replace			hired_men = 0 if AS02AQ43A == 9 
	replace			hired_men = 0 if AS02AQ43B == 999
	replace 		hired_men = 0 if hired_men == .  

	gen				hired_women = .
	replace			hired_women = AS02AQ43C if AS02AQ43A == 1
	replace			hired_women = 0 if AS02AQ43A == 2
	replace			hired_women = 0 if AS02AQ43A == 9 
	replace			hired_women = 0 if AS02AQ43C == 999
	replace 		hired_women = 0 if hired_women == .  
	
	*** we do not include child labor days
	
* mutual labor days from other households

	tab 			AS02AQ42A
	*** 247 received mutual labor, 4587 did not
	
	gen 			mutual_men = .
	replace			mutual_men = AS02AQ42B if AS02AQ42A == 1
	replace			mutual_men = 0 if AS02AQ42A == 2
	replace			mutual_men = 0 if AS02AQ42A == 9 
	replace			mutual_men = 0 if AS02AQ42B == 999
	replace 		mutual_men = 0 if mutual_men == . 

	gen 			mutual_women = .
	replace			mutual_women = AS02AQ42C if AS02AQ42A == 1
	replace			mutual_women = 0 if AS02AQ42A == 2
	replace			mutual_women = 0 if AS02AQ42A == 9 
	replace			mutual_women = 0 if AS02AQ42C == 999 
	replace			mutual_women = 0 if mutual_women == . 

	*** we do not include child labor days
	
* **********************************************************************
* 5 - impute harvest labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				hh_1 hh_2 hh_3 hh_4 hh_5 hh_6 hired_men hired_women mutual_men mutual_women
	*** hh_1, hired_men, mutual_men, mutual_women are all greater than the minimum (91 days)
	
* generate local for variables that contain outliers
	loc				labor hh_1 hh_2 hh_3 hh_4 hh_5 hh_6 hired_men hired_women mutual_men mutual_women

* replace zero to missing, missing to zero, and outliers to missing
	foreach var of loc labor {
	    mvdecode 		`var', mv(0)
		mvencode		`var', mv(0)
	    replace			`var' = . if `var' > 90
	}
	*** 6 outliers changed to missing

* impute missing values (only need to do four variables - set new locals)
	loc				laborimp hh_1 hired_men mutual_men mutual_women
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously


* impute each variable in local		
	foreach var of loc laborimp {
		mi register			imputed `var' // identify variable to be imputed
		sort				hhid_y2 field parcel, stable 
		// sort to ensure reproducability of results
		mi impute 			pmm `var' i.clusterid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap
	}						
	mi 				unset	
	
* summarize imputed variables
	sum				hh_1_1_ hired_men_2_ mutual_men_3_ mutual_women_4_ 
	* all values seem fine
	replace			hh_1 = hh_1_1_
	replace 		hired_men = hired_men_2_ 
	replace			mutual_men = mutual_men_3_
	replace			mutual_women = mutual_women_4_ 

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
	*** with free labor: average = 23.7, max = 300
	*** without free labor: average = 24.1, max = 335
	
	
* **********************************************************************
* 6 - end matter, clean up to save
* **********************************************************************
		
* collapse to get rid of multiple observations of same crop on same parcel
	collapse		(sum) plant_labor plant_labor_all harvest_labor harvest_labor_all, ///
						by(hhid_y2 hid clusterid hh_num hh_num1 extension field parcel)
	
* need to include hid field parcel to uniquely identify
	sort 			hhid_y2 field parcel
	isid 			hhid_y2 field parcel

* create unique household-plot identifier
	isid				hhid_y2 field parcel 
	sort				hhid_y2 field parcel, stable 
	egen				plot_id = group(hhid_y2 field parcel)
	lab var				plot_id "unique field and parcel identifier (hhid_y2 field parcel)"
	
	label var 		hhid_y2 "unique id - match w2 with weather"
	label var		hid "unique id - match w2 with w1 (no extension)"
	label var 		hh_num1 "household id - string changed, not unique"

	compress
	describe
	summarize

* save file
		save 			"`export'/2014_as2ap2", replace

* close the log
	log	close

/* END */
