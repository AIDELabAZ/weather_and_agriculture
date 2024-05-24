* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on: 24 May 24
* Edited by: jdm
* Stata v.18

* does
	* fertilizer use and labor
	* reads Uganda wave 8 inputs and labor (2019_agsec5b) for the 1st season
	* 3B - 5B are questionaires for the first planting season of 2019 (main)
	* 3A - 5A are questionaires for the second planting season of 2018 (secondary)

* assumes
	* access to raw data 
	* mdesc.ado

* TO DO:
	* complete
	

* **********************************************************************
**#0 - setup
* **********************************************************************

* define paths	
	global root 		= "$data/household_data/uganda/wave_8/raw"  
	global export 		= "$data/household_data/uganda/wave_8/refined"
	global logout 		= "$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2019_agsec3b", append
	
* **********************************************************************
**#1 - import data and rename variables, manipulate hh labor 
* **********************************************************************

* import 3b_1 data for household labor - to be integrated later 

* import wave 8 season B1
	use 			"$root/agric/agsec3b_1.dta", clear
		
* collapse household labor
	collapse	 	(sum) s3bq33_1, by (parcelID pltid hhid)
	rename 			parcelID prcid
	rename 			s3bq33_1 fam_lab 
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
*	*** max 360, mean 35, min 0

	save 			"$export/agsec3b_1hh.dta", replace 	
		
* **********************************************************************
**#2 - import data and rename variables
* **********************************************************************

* import wave 8 season B
	use 			"$root/agric/agsec3b.dta", clear		
	
* Rename ID variables
	rename			parcelID prcid
	recast 			str32 hhid
	
	describe
	sort 			hhid prcid pltid
	isid 			hhid prcid pltid

	
* **********************************************************************
**#3 - merge location data
* **********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2019_gsec1"
	*** 706 unmatched (0 from master)
	
	drop if			_merge != 3
	*** 706 observations deleted
	drop 			_merge 

* **********************************************************************
**#4 - fertilizer, pesticide and herbicide
* **********************************************************************

* fertilizer use
	rename 		s3bq13 fert_any
	rename 		s3bq15 kilo_fert
		
* replace the missing fert_any with 0
	tab 			kilo_fert if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 1 real changes
			
	summarize 			kilo_fert if fert_any == 1
	*** mean 42, min 1, max 900

* replace zero to missing, missing to zero, and outliers to mizzing
	replace			kilo_fert = . if kilo_fert > 187
	*** 7 outliers changed to missing

* encode district to be used in imputation
	encode 			district, gen (districtdstrng) 	
	
* impute missing values (only need to do four variables)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local	
	*** the finer geographical variables will proxy for soil quality which is a determinant of fertilizer use
	mi register			imputed kilo_fert // identify variable to be imputed
	sort				hhid prcid pltid, stable // sort to ensure reproducability of results
	mi impute 			pmm kilo_fert  i.districtdstrng fert_any, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset		
	
* how did impute go?	
	sum 		kilo_fert_1_ if fert_any == 1
	*** max 187, mean 28, min 1
	
	replace			kilo_fert = kilo_fert_1_ if fert_any == 1
	*** 8 changed
	
	drop 			kilo_fert_1_ mi_miss
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	*** 6,226 real changes made
	
* **********************************************************************
**#5 - pesticide & herbicide
* **********************************************************************

* pesticide & herbicide
	tab 		s3bq22
	*** 6 percent of the sample used pesticide or herbicide
	tab 		s3bq23
	
	gen 		pest_any = 1 if s3bq23 != . & s3bq23 != 4 & s3bq23 != 96
	replace		pest_any = 0 if pest_any == .
	
	gen 		herb_any = 1 if s3bq23 == 4 | s3bq23 == 96
	replace		herb_any = 0 if herb_any == .
	*** 6,245 real changes made
	
* **********************************************************************
**# 6 - labor 
* **********************************************************************

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* includes all labor tasks performed on a plot during the first crop season
	

* **********************************************************************
**## 6.a - hired labor 
* **********************************************************************

* hired labor days
	egen	 		hired_labor = rsum(s3bq35a s3bq35b)
		
* check values of hired labor
	sum				hired_labor, detail
	
* replace values greater than 365 and turn missing to zeros
	replace			hired_labor = 0 if hired_labor == .
	*** no changes made
	replace			hired_labor = 365 if hired_labor > 365
	*** no changes made


* **********************************************************************
**## 6.b - family labor 
* **********************************************************************

* This wave asked about specific household members who worked on the plot rather than the total number of members 

* merge in family labor 
	merge 1:1 		hhid prcid pltid using "$export/agsec3b_1hh"
	*** matched 6,378, not matched 67 from using, none from master
	*** this means that 67 plots only used hired labor, seems fine

* check values of family labor
	sum				fam_lab, detail
*	*** max 360, mean 28, min 0
	
* generate labor days as the total amount of labor used on plot in person days
	egen			labor_days = rsum(fam_lab hired_labor)
	
	sum 			labor_days
	*** mean 37, max 360, min 0	
	
	
* **********************************************************************
**#7 - end matter, clean up to save
* **********************************************************************
	
	keep 			hhid prcid pltid region district subcounty ///
					parish fert_any kilo_fert labor_days ///
					pest_any herb_any

	isid			hhid prcid pltid
					
	compress
	describe
	summarize

**# save file
	save 			"$export/2019_agsec3b.dta", replace

* close the log
	log	close

/* END */	