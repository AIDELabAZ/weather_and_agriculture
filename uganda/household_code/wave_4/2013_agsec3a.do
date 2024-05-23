* Project: WB Weather
* Created on: Feb 2024
* Created by: rg
* Edited on: 19 April 24
* Edited by: rg
* Stata v.18, mac

* does
	* fertilizer use
	* reads Uganda wave 4 fertilizer and pest info (2013_AGSEC3A) for the 1st season
	* 3A - 5A are questionaires for the first planting season
	* 3B - 5B are questionaires for the second planting season

* assumes
	* access to raw data
	* mdesc.ado

* TO DO:
	* done
	

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global root 	 	"$data/household_data/uganda/wave_4/raw"  
	global export		"$data/household_data/uganda/wave_4/refined"
	global logout 		"$data/household_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2013_agsec3a", append
	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 4 season A
	use 			"$root/agric/AGSEC3A.dta", clear
	
* rename variables 
	rename			HHID hhid
	rename			parcelID prcid
	rename			plotID pltid

	replace			prcid = 1 if prcid == .
	
	sort 			hhid prcid pltid
	isid 			hhid prcid pltid

	
***********************************************************************
**# 2 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2013_agsec1"
	*** 101 unmatched from using
	*** 7,550 matched
	
	drop if			_merge != 3
	

***********************************************************************
**# 3 - fertilizer, pesticide and herbicide
***********************************************************************

* fertilizer use
	rename 		a3aq13 fert_any
	rename 		a3aq15 kilo_fert

		
* replace the missing fert_any with 0
	tab 			kilo_fert if fert_any == .
	*** no observations
	
	replace			fert_any = 2 if fert_any == . 
	*** 7 changes
			
	sum 			kilo_fert if fert_any == 1, detail
	*** mean 28.53, min 0.2, max 1,000

* replace zero to missing, missing to zero, and outliers to missing
	replace			kilo_fert = . if kilo_fert > 264
	*** 2 outliers changed to missing

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
	sum 		kilo_fert_1_ if fert_any == 1, detail
	*** max 150, mean 20.71, min 0.2
	
	replace			kilo_fert = kilo_fert_1_ if fert_any == 1
	*** 2 changed
	
	drop 			kilo_fert_1_ mi_miss
	
* record fert_any
	replace			fert_any = 0 if fert_any == 2

	
***********************************************************************
**# 4 - pesticide & herbicide
***********************************************************************

* pesticide & herbicide
	tab 		a3aq22
	*** 4.83 percent of the sample used pesticide or herbicide
	tab 		a3aq23
	
	gen 		pest_any = 1 if a3aq23 != . & a3aq23 != 4 & a3aq23 != 96
	replace		pest_any = 0 if pest_any == .
	
	gen 		herb_any = 1 if a3aq23 == 4 | a3aq23 == 96
	replace		herb_any = 0 if herb_any == .

	
***********************************************************************
**# 5 - labor 
***********************************************************************
	* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
	* 7 days * 13 weeks = 91 days for land prep and planting
	* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
	* 7 days * 13 weeks = 91 days for harvesting
	* we will also exclude child labor_days
	* in this survey we can't tell gender or age of household members
	* since we can't match household members we deal with each activity seperately
	* includes all labor tasks performed on a plot during the first cropp season

* family labor	
* in this wave, it is asked about the specific household members who worked on the plot rather than the total number of members who did

* create a new variable counting how many household members worked on the plot
	egen 			household_count = rownonmiss(a3aq33a a3aq33b ///
					a3aq33c a3aq33d a3aq33e)
	
* make a binary if they had family work
	gen				fam = 1 if household_count > 0
	
* how many household members worked on this plot?
	tab 			household_count
	*** family labor is from 0 - 5 people
	
* hours worked on plot are recorded per household member not total
* create variable of total days worked on plot
	egen			days_worked = rowtotal (a3aq33a_1 a3aq33b_1 ///
					a3aq33c_1 a3aq33d_1 a3aq33e_1)
	
	sum 			days_worked, detail
	*** mean 42.01, min 0, max 450
	*** don't need to impute any values
	
* fam lab = number of family members who worked on the farm*days they worked	
	gen 			fam_lab = household_count*days_worked
	replace			fam_lab = 0 if fam_lab == .
	sum				fam_lab
	*** max 2250, mean 134.7, min 0
	
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
	*** mean 137.59, max 2,250, min 0	

	
***********************************************************************
**# 6 - end matter, clean up to save
***********************************************************************

	keep 			hhid hhid_pnl prcid region district subcounty ///
					parish wgt13 ea rotate pest_any herb_any labor_days ///
					fert_any kilo_fert pltid

	compress
	describe
	summarize

* save file
	save 			"$export/2013_agsec3a.dta", replace

* close the log
	log	close

/* END */	
