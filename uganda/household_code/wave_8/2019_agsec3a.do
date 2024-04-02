* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on 02 Apr 24
* Edited by kd
* Stata v.18, mac

* does
	* fertilizer use
	* reads Uganda wave 3 fertilizer and pest info (2019_AGSEC3A) for the 1st season
	* 3A - 5A are questionaires for the first planting season
	* 3B - 5B are questionaires for the second planting season

* assumes
	* access to raw data 
	* mdesc.ado

* TO DO:
	* everything
	

* **********************************************************************
**#0 - setup
* **********************************************************************

* define paths	
	loc root 		= "$data/household_data/uganda/wave_8/raw"  
	loc export 		= "$data/household_data/uganda/wave_8/refined"
	loc logout 		= "$data/household_data/uganda/logs"
	
* open log	
	cap log 		close
	log using 		"$logout/2019_agsec3a", append
	
* **********************************************************************
**#1 - import data and rename variables
* **********************************************************************

* import wave 8 season A
	use 			"$root/agric/agsec3a.dta", clear
	compress
		
	
* Change hhid to str as hhidnew, rename hhid to hhidoldold, and hhidnew to hhid 
	
	gen hhidnew = ustrtrim(hhid)
	recast str32 hhidnew
	rename hhid hhidoldold
	rename hhidnew hhid
	
	
*	rename			parcelID prcid
	rename			parcelID prcid

	replace			prcid = 1 if prcid == .
	
	sort 			hhid prcid pltid
	isid 			hhid prcid pltid

	
* **********************************************************************
**#2 - merge location data
* **********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2019_gsec1"
	*** 846 unmatched (3 from master)
	
	drop if			_merge != 3
	*** 846 observations deleted

* **********************************************************************
**#3 - fertilizer, pesticide and herbicide
* **********************************************************************

* fertilizer use
	rename 		s3aq13 fert_any
	rename 		s3aq15 kilo_fert

		
* replace the missing fert_any with 0
	tab 			kilo_fert if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 80 real changes
			
	summarize 			kilo_fert if fert_any == 1
	*** mean 37.25, min 0, max 1100

* replace zero to missing, missing to zero, and outliers to mizzing
	replace			kilo_fert = . if kilo_fert > 264
	*** 3 outliers changed to missing

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
	*** max 250, mean 26.43, min 0
	
	replace			kilo_fert = kilo_fert_1_ if fert_any == 1
	*** 3 changed
	
	drop 			kilo_fert_1_ mi_miss
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2
	*** 5710 real changes made
	
* **********************************************************************
**#4 - pesticide & herbicide
* **********************************************************************

* pesticide & herbicide
	tab 		s3aq22
	*** 7.62 percent of the sample used pesticide or herbicide
	tab 		s3aq23
	
	gen 		pest_any = 1 if s3aq23 != . & s3aq23 != 4 & s3aq23 != 96
	replace		pest_any = 0 if pest_any == .
	
	gen 		herb_any = 1 if s3aq23 == 4 | s3aq23 == 96
	replace		herb_any = 0 if herb_any == .
	*** 5,720 real changes made
	
* **********************************************************************
**#5 - labor 
* **********************************************************************
	* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
	* 7 days * 13 weeks = 91 days for land prep and planting
	* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
	* 7 days * 13 weeks = 91 days for harvesting
	* we will also exclude child labor_days
	* includes all labor tasks performed on a plot during the first cropp season

* family labor	
* iThis wave asked about specific household members who worked on the plot rather than the total number of members 

* create a new variable counting how many household members worked on the plot 
**#	egen 			household_count = rownonmiss(s3aq35a s3aq35b)
					
* make a binary if they had family work
	gen				fam = 1 if household_count > 0	
	*** 4334 missing values generated?? 
* how many household members worked on this plot?
	tab 			a3aq31
	replace			a3aq31 = 12 if a3aq31 == 25000
	*** family labor is from 0 - 12 people
	
	sum 			a3aq32, detail
	*** mean 32.8, min 1, max 300
	*** don't need to impute any values
	
* fam lab = number of family members who worked on the farm*days they worked	
	gen 			fam_lab = a3aq31*a3aq32
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 3000, mean 9780, min 0
	
* hired labor 
* hired men days
	rename	 		a3aq35a hired_men
		
* make a binary if they had hired_men
	gen 			men = 1 if hired_men != . & hired_men != 0
	
* hired women days
	rename			a3aq35b hired_women 
		
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
	*** mean 101.45, max 3080, min 0	

	
* **********************************************************************
* 6 - end matter, clean up to save
* **********************************************************************

	keep hhid prcid pltid fert_any kilo_fert labor_days region ///
		district county subcounty parish pest_any herb_any

	compress
	describe
	summarize

* save file
		customsave , idvar(hhid) filename("2011_AGSEC3A.dta") ///
			path("`export'") dofile(2011_AGSEC3A) user($user)

* close the log
	log	close

/* END */	
