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
	global 	root 		"$data/household_data/uganda/wave_3/raw"  
	global  export 		"$data/household_data/uganda/wave_3/refined"
	global 	logout 		"$data/household_data/uganda/logs"


* open log	
	cap 				log close
	log using 			"$logout/2011_agsec2b", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 5 season A
	use 			"$root/2011_AGSEC2B.dta", clear

* unlike other waves, HHID is a numeric here
	format 			%18.0g HHID
	tostring		HHID, gen(hhid) format(%18.0g)
	
	rename			parcelID prcid
	rename 			a2bq4 plotsizeGPS
	rename 			a2bq5 plotsizeSR
	rename			a2bq7 tenure
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2bq16 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"


***********************************************************************
**# 2 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2011_GSEC1"
	*** merged 994, 2,049 unmerged total, only 83 from master
	*** 71 unmerged from master
	
	drop 		if _merge ! = 3
	drop		_merge
	
	
************************************************************************
**# 3 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** data label says first season is a2aq11b
	tab 		 	a2bq12a
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2bq12a == 1 | a2bq12a == 2
	*** 133 observations deleted	

	
***********************************************************************
**# 4 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean 1.23, max 12.2, min .07
	
	sum				plotsizeSR
	*** mean 1.1, max 12, min .01

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 732 missing, 85.02% of observations

* convert acres to hectares
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* examine gps outlier values
	sum				plotsize, detail
	*** mean 0.50, min 0.02, max 4.93, std. dev. .60
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.44, min 0.004, max4.85, std. dev. .45
	*** the self-reported 10 ha is large but not unreasonable	
	
* check correlation between the two
	corr 			plotsize selfreport
	*** 0.90 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** these all look good

* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** this is very low 0.03

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
	*** mean 0.56, max 4.9, min .02
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** so-so correlation, 0.55
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** none missing

***********************************************************************
**# 5 - appends sec2a
***********************************************************************
	
* keep only necessary variables
	keep 			hhid HHID prcid region district county subcounty ///
					parish hh_status2011 wgt11 ///
					plotsize irr_any

* append owned plots
	append			using "$export/2011_AGSEC2A.dta"
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
	save 			"$export/2011_agsec2.dta", replace

* close the log
	log	close

/* END */
