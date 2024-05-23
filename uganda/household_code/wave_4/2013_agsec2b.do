* Project: WB Weather
* Created on: Apr 2024
* Created by: rg
* Edited on: 29 April 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 4 owned plot info (2013_AGSEC2B) for the 1st season
	* appends to owned plot info (2013_AGSEC2A)
	* outputs appended data to 2013_AGSEC2

* assumes
	* access to the raw data
	* mdesc.ado

* TO DO:
	* done

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root 		"$data/household_data/uganda/wave_4/raw"  
	global  export 		"$data/household_data/uganda/wave_4/refined"
	global 	logout 		"$data/household_data/uganda/logs"


* open log	
	cap 				log close
	log using 			"$logout/2013_agsec2b", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 5 season A
	use 			"$root/agric/AGSEC2B.dta", clear
		
	rename			HHID hhid
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
	merge m:1 hhid using "$export/2013_agsec1"
	*** merged 1,294, 0 unmatched from master
	
	drop 		if _merge ! = 3
	drop		_merge
	
	
************************************************************************
**# 3 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** data label says first season is a2aq11a
	tab 		 	a2bq12a
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2bq12a == 1 | a2bq12a == 2
	*** 231 observations deleted	

	
***********************************************************************
**# 4 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean 1.02, max 16.8, min .07
	
	sum				plotsizeSR
	*** mean .96, max 25, min .1

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 906 missing, 85% of observations

* convert acres to hectares
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* examine gps outlier values
	sum				plotsize, detail
	*** mean 0.41, min 0.02, max 6.79, std. dev. .66
	
* examine gps outlier values
	sum				selfreport, detail
	*** mean 0.39, min 0.04, max 10.11, std. dev. .53
	*** the self-reported 10 ha is large but not unreasonable	
	
* check correlation between the two
	corr 			plotsize selfreport
	*** 0.96 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** these all look good

* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** correlation is negative, 0.07
	
* correlation for larger plots	
	corr			plotsize selfreport if plotsize > 1 & !missing(plotsize)

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
	*** mean 0.41, max 6.7, min .02
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** high correlatio, 0.79
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** none missing

***********************************************************************
**# 5 - appends sec2a
***********************************************************************
	
* keep only necessary variables
	keep 			hhid hhid_pnl prcid region district subcounty ///
					parish wgt13 ///
					plotsize irr_any ea rotate

* append owned plots
	append			using "$export/2013_agsec2a.dta"
	
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
	save 			"$export/2013_agsec2.dta", replace

* close the log
	log	close

/* END */
