* Project: WB Weather
* Created on: Apr 2024
* Created by: rg
* Edited on: 26 Apr 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 1 owned plot info (2015_AGSEC2B) for the 1st season
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
	global 	root 		"$data/household_data/uganda/wave_1/raw"  
	global  export 		"$data/household_data/uganda/wave_1/refined"
	global 	logout 		"$data/household_data/uganda/logs"


* open log
	cap 				log close
	log using 			"$logout/2009_agsec2b", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 5 season A
	use 			"$root/2009_AGSEC2B.dta", clear
		
	rename			Hhid hhid
	rename			A2bq2 prcid
	rename 			A2bq4 plotsizeGPS
	rename 			A2bq5 plotsizeSR
	rename			A2bq7 tenure
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if A2bq19 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** there are 15 observations irrigated


***********************************************************************
**# 2 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2009_GSEC1"
	*** merged 1,513, 2,003 unmerged total, only 7 from master
	
	drop 		if _merge ! = 3
	drop		_merge
	
	
************************************************************************
**# 3 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** data label says first season is a2aq11b
	tab 		 	A2bq15a
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if A2bq15a == 1 | A2bq15a == 2
	*** 322 observations deleted	

	
***********************************************************************
**# 4 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean .72, max 80.9, min 0
	
	sum				plotsizeSR
	*** mean 1.02, max 25, min 0

* replace plot size = 0 with missing for imputation
	replace			plotsizeGPS = . if plotsizeGPS == 0
	replace			plotsizeSR = . if plotsizeSR == 0
	
* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 769 missing, 64.5% of observations

* convert acres to hectares
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* examine gps outlier values
	sum				plotsize, detail
	*** mean 0.43, min 0, max 32.7, std. dev. 1.63
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.41, min 0, max 10.11, std. dev. .539
	*** the self-reported 10 ha is large but not unreasonable	
	
* check correlation between the two
	corr 			plotsize selfreport
	*** 0.60 correlation, weak correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
* divide outlier by 10
	replace			plotsize = plotsize/10 if plotsize > 30

* replace outlier as missing values
	replace 		selfreport = . if selfreport > 9						
							
* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** correlation is negative, -0.16
	
* correlation for larger plots	
	corr			plotsize selfreport if plotsize > 1 & !missing(plotsize)
	*** this is pretty high, 0.40, so these look good

* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** this is terrible, correlation is -0.16

* correlation for extremely small plots	
	corr			plotsize selfreport if plotsize < .01 & !missing(plotsize)
	*** this is terrible, -0.38, correlation is basically zero

* summarize before imputation
	sum				plotsize
	*** mean 0.36, max 4.1, min 0.004
	
* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plotsize // identify plotsize_GPS as the variable being imputed
	sort			region district hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize selfreport i.district selfreport, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
		
* how did imputing go?
	sum 			plotsize_1_
	*** mean 0.39, max 4.11, min 0.004
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** so-so correlation, 0.56
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** two missing, both plotsize and selfreport values are missing
	
* drop observation
	drop			if plotsize ==.
	
* correlation plotsize vs selfreport
	corr 			plotsize selfreport
	*** correlation 0.58
	
***********************************************************************
**# 5 - appends sec2a
***********************************************************************
	
* keep only necessary variables
	keep 			hhid prcid region district county subcounty ///
					parish wgt09wosplits wgt09 hh_status2009 ///
					plotsize irr_any

* append owned plots
	append			using "$export/2009_AGSEC2A.dta"
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
	save 			"$export/2009_agsec2.dta", replace

* close the log
	log	close

/* END */
