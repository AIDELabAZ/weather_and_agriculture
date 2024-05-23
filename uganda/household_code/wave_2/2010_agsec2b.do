* Project: WB Weather
* Created on: Apr 2024
* Created by: jdm
* Edited on: 19 Apr 24
* Edited by: jdm
* Stata v.18

* does
	* reads Uganda wave 5 owned plot info (2015_AGSEC2B) for the 1st season
	* appends to owned plot info (2015_AGSEC2A)
	* outputs appended data to 2015_AGSEC2

* assumes
	* access to the raw data
	* mdesc.ado

* TO DO:
	* done

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root 		"$data/household_data/uganda/wave_2/raw"  
	global  export 		"$data/household_data/uganda/wave_2/refined"
	global 	logout 		"$data/household_data/uganda/logs"


* open log	
	cap 				log close
	log using 			"$logout/2010_agsec2b", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 5 season A
	use 			"$root/2010_AGSEC2B.dta", clear
		
	rename			HHID hhid
	rename 			a2bq4 plotsizeGPS
	rename 			a2bq5 plotsizeSR
	rename			a2bq7 tenure
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2bq19 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"


***********************************************************************
**# 2 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2010_GSEC1"
	*** merged 1,052 1,921 unmerged total, only 11 from master
	*** 71 unmerged from master
	
	drop 		if _merge ! = 3
	drop		_merge
	
	
************************************************************************
**# 3 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** data label says first season is a2aq11b
	tab 		 	a2bq15a
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2bq15a == 1 | a2bq15a == 2
	*** 146 observations deleted	

	
***********************************************************************
**# 4 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean 1.27, max 29, min .08
	
	sum				plotsizeSR
	*** mean 1.14, max 50, min .1

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 648 missing, 71.5% of observations

* convert acres to hectares
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* examine gps outlier values
	sum				plotsize, detail
	*** mean 0.51, min 0.03 max 11.7, std. dev. .94
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.46, min 0.04, max 20.23, std. dev. 0.85
	*** the self-reported 10 ha is large but not unreasonable	
	
* examine outliers
	list 			plotsize selfreport if plotsize > 10 & !missing(plotsize)

* recode outlier
	replace 		selfreport = selfreport*100 if plotsize > 10 & !missing(plotsize)
	*** plotsize looks to be 100 times larger than self reported
* check correlation between the two
	corr 			plotsize selfreport
	*** 0.84 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** these all look good

* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** correlation is negative, -0.15

* encode district to be used in imputation
	encode district, gen (districtdstrng) 	

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plotsize // identify plotsize_GPS as the variable being imputed
	sort			region district hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize i.districtdstrng selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			plotsize_1_
	*** mean 0.45, max 11.7, min .003
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** so-so correlation, 0.67
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** 8 missing
	** 8 observations are missing self report and plotsizeGPS
	
* drop observations
	drop 			if plotsize == .

***********************************************************************
**# 5 - appends sec2a
***********************************************************************
	
* keep only necessary variables
	keep 			hhid prcid region district county subcounty ///
					parish hh_status2010 spitoff09_10 spitoff10_11 wgt10 ///
					plotsize irr_any

* append owned plots
	append			using "$export/2010_AGSEC2A.dta"
	*** creates 1 duplicate observation
	
* drop duplicate
	duplicates 		drop hhid prcid, force
					
***********************************************************************
**# 6 - end matter, clean up to save
***********************************************************************				
					
	isid			hhid prcid
	compress
	describe
	summarize

* save file
	save 			"$export/2010_agsec2.dta", replace

* close the log
	log	close

/* END */
