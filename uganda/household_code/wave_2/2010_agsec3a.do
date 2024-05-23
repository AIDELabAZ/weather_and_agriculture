* Project: WB Weather
* Created on: Aug 2020
* Created by: themacfreezie
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* fertilizer use, pesticide, and labor
	* reads Uganda wave 2 labor, fertilizer and pest info (2010_AGSEC3A) for the 1st season
	* 3A - 5A are questionaires for the first planting season
	* 3B - 5B are questionaires for the second planting season

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* complete

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 		 "$data/household_data/uganda/wave_2/raw"  
	global export 		 "$data/household_data/uganda/wave_2/refined"
	global logout 		 "$data/household_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2010_agsec3a", append

	
************************************************************************
**# 1 - import data and rename variables
************************************************************************

* import wave 2 season A
	use 			"$root/2010_AGSEC3A.dta", clear
		
	rename 			HHID hhid
	
	sort 			hhid prcid pltid
	isid 			hhid prcid pltid


************************************************************************
**# 2 - merge location data
************************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2010_GSEC1"
	*** 639 unmatched from master
	
	drop if			_merge != 3
	

************************************************************************
**# 3 - fertilizer, pesticide and herbicide
************************************************************************

* fertilizer use
	rename 			a3aq14 fert_any
	rename 			a3aq16 kilo_fert
		
* replace the missing fert_any with 0
	tab 			kilo_fert if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 29 changes
	
	sum 			kilo_fert if fert_any == 1, detail
	*** 39.37, min 0.2, max 300

* replace zero to missing, missing to zero, and outliers to mizzing
	replace			kilo_fert = . if kilo_fert > 192
	*** 6 outliers changed to missing

* encode district to be used in imputation
	encode 			district, gen (districtdstrng) 	
	
* impute missing values (only need to do four variables)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local	
	*** the finer geographical variables will proxy for soil quality which is a determinant of fertilizer use
	mi register			imputed kilo_fert // identify variable to be imputed
	sort				hhid prcid pltid, stable // sort to ensure reproducability of results
	mi impute 			pmm kilo_fert i.districtdstrng fert_any, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset		
	
* how did impute go?	
	sum 			kilo_fert_1_ if fert_any == 1, detail
	*** max 150, mean 30.78, min 0.2
	
	replace			kilo_fert = kilo_fert_1_ if fert_any == 1
	*** 8 changed
	
	drop 			kilo_fert_1_ mi_miss
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	
	
************************************************************************
**# 4 - pesticide & herbicide
************************************************************************

* pesticide & herbicide
	tab 			a3aq26
	*** 4.18 percent of the sample used pesticide or herbicide
	
	gen 			pest_any = 1 if a3aq27 != . & a3aq27 != 4
	replace			pest_any = 0 if pest_any == .
	
	gen 			herb_any = 1 if a3aq27 == 4 | a3aq27 == 96
	replace			herb_any = 0 if herb_any == .
	
	
************************************************************************
**# 5 - labor 
************************************************************************
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
	gen				fam = 1 if a3aq38 > 0
	
* how many household members worked on this plot?
	tab 			a3aq38
	*** family labor is from 0 - 10 people
	
	replace			a3aq39 = . if a3aq39 > 365
	*** 2 changes made

* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local		
	mi register			imputed a3aq39 // identify variable to be imputed
	sort				hhid prcid pltid, stable // sort to ensure reproducability of results
	mi impute 			pmm a3aq39 i.districtdstrng i.fam, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap						
	mi 				unset
		
* how did impute go?
	sum 			a3aq39_1_
	*** mean 38.5, min 1, max 360
	
	replace			a3aq39 = a3aq39_1_ if fam == 1
	*** 161 changes made
	
* fam lab = number of family members who worked on the farm*days they worked
	gen 			fam_lab = a3aq38*a3aq39
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 2300, min 0, mean 114.8
	
* hired labor 
* hired men days
	rename	 		a3aq42a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			a3aq42b hired_women 
		
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
	*** no changes made
	
* generate labor days as the total amount of labor used on plot in person days
	gen				labor_days = fam_lab + hired_men + hired_women
	
	sum 			labor_days
	*** mean 119.28, max 2300, min 0
	
	
************************************************************************
**# 6 - end matter, clean up to save
************************************************************************

	keep hhid prcid pltid fert_any kilo_fert labor_days region ///
		district county subcounty parish pest_any herb_any

	compress
	describe
	summarize

* save file			
	save 			"$export/2010_AGSEC3A.dta", replace

* close the log
	log	close

/* END */
