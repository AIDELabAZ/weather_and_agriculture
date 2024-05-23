* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* fertilizer use
	* reads Uganda wave 1 labor, fertilizer and pest info (2009_AGSEC3A) for the 1st season
	* 3A - 5A are questionaires for the first planting season
	* 3B - 5B are questionaires for the second planting season

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global root 		"$data/household_data/uganda/wave_1/raw"  
	global export 		"$data/household_data/uganda/wave_1/refined"
	global logout 		"$data/household_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2009_agsec3a", append

	
* **********************************************************************
* 1 - import data and rename variables
* **********************************************************************

* import wave 2 season A
	use 			"$root/2009_AGSEC3A.dta", clear
		
	rename 			Hhid hhid
	rename			A3aq1 prcid 
	rename 			A3aq3 pltid
	
* drop observations missing prcid or pltid 
	*** observations missing prcid or pltid are missing in all other variables too
	drop 			if prcid == . | pltid == .
	*** 1098 observations deleted

	sort 			hhid prcid pltid
	isid 			hhid prcid pltid


* **********************************************************************
* 2 - merge location data
* **********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2009_GSEC1"
	*** 689 unmatched from master
	
	drop if			_merge != 3
	
	
* **********************************************************************
* 3 - fertilizer, pesticide and herbicide
* **********************************************************************

* fertilizer use
	rename 			A3aq14 fert_any
	rename 			A3aq16 kilo_fert
		
* replace the missing fert_any with 0
	tab 			kilo_fert if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 268 changes
	
	sum 			kilo_fert if fert_any == 1, detail
	*** 90 mean, min 0.25, max 7000
	
	replace			kilo_fert = . if kilo_fert >= 7000
	*** 1 change
	
* impute missing values (only need to do four variables)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local	
	*** the finer geographical variables will proxy for soil quality which is a determinant of fertilizer use
	mi register			imputed kilo_fert // identify variable to be imputed
	sort				hhid prcid pltid, stable // sort to ensure reproducability of results
	mi impute 			pmm kilo_fert i.district fert_any, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset		
	
* how did impute go?	
	sum 			kilo_fert_1_ if fert_any == 1, detail
	*** max 200, mean 32.8, min 0.25
	
	replace			kilo_fert = kilo_fert_1_ if fert_any == 1
	*** 1 changed
	
	drop 			kilo_fert_1_ mi_miss
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	
	
* **********************************************************************
* 4 - pesticide & herbicide
* **********************************************************************

* pesticide & herbicide
	tab 			A3aq26
	replace  		A3aq26 = 2 if A3aq26 == 5
	*** 4.61 percent of the sample used pesticide or herbicide
	
	tab 			A3aq27
	
	gen 			pest_any = 1 if A3aq27 != . & A3aq27 != 4
	replace			pest_any = 0 if pest_any == .
	
	gen 			herb_any = 1 if A3aq27 == 4 | A3aq27 == 96
	replace			herb_any = 0 if herb_any == .	
	
	
* **********************************************************************
* 5 - labor 
* **********************************************************************
	* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
	* 7 days * 13 weeks = 91 days for land prep and planting
	* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
	* 7 days * 13 weeks = 91 days for harvesting
	* we will also exclude child labor_days
	* in this survey we can't tell gender or age of household members
	* since we can't match household members we deal with each activity seperately
	* includes all labor tasks performed on a plot during the first cropp season

* family labor
* make a binary if they had family work
	gen				fam = 1 if A3aq38 > 0
	replace			fam = 0 if fam == .
	
* how many household members worked on this plot?
	tab 			A3aq38
	*** family labor is from 0 - 94 people
	
* limit family size to 15 people and replace missing with zero
	replace			A3aq38 = 0 if A3aq38 == .
	replace			A3aq38 = 15 if A3aq38 > 15
	*** 278 missing to zero, 10 large families downsized
	
	sum 			A3aq39
	*** mean 36.6, min 0, max 999
	*** cannot have max above 365, will replace to missing
	
	replace			A3aq39 = . if A3aq39 > 365
	*** 34 missing values generated
	
* impute missing values	
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local		
	mi register			imputed A3aq39 // identify variable to be imputed
	sort				hhid prcid pltid, stable // sort to ensure reproducability of results
	mi impute 			pmm A3aq39 i.district i.fam, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap						
	mi 				unset
		
* how did impute go?
	sum 			A3aq39_1_
	*** mean 34.1, min 0, max 360
	
	replace			A3aq39 = A3aq39_1_ if fam == 1
	*** 336 changes made
	
* fam lab = number of family members who worked on the farm*days they worked	
	gen 			fam_lab = A3aq38*A3aq39
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 3000, min 0, mean 104.8
	
* hired labor 
* hired men days
	rename	 		A3aq42a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			A3aq42b hired_women 
		
* make a binary if they had hired_men
	gen 			women = 1 if hired_women != . & hired_women != 0
	
* impute hired labor all at once
	sum				hired_men, detail
	sum 			hired_women, detail
	
* replace values greater than 365 and turn missing to zeros
	replace			hired_men = 0 if hired_men == .
	replace			hired_women = 0 if hired_women == .
	
	replace			hired_men = 365 if hired_men > 365
	replace			hired_women = 365 if hired_women > 365
	*** only two high values replaced
	
* generate labor days as the total amount of labor used on plot in person days
	gen				labor_days = fam_lab + hired_men + hired_women
	
	sum 			labor_days
	*** mean 109.89, max 3000, min 0
	
	
* **********************************************************************
* 6 - end matter, clean up to save
* **********************************************************************

	keep hhid prcid pltid fert_any kilo_fert labor_days region ///
		district county subcounty parish pest_any herb_any

	compress
	describe
	summarize

* save file			
	save 			"$export/2009_AGSEC3A.dta", replace

* close the log
	log	close

/* END */
