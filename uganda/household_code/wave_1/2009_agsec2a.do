* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads Uganda wave 1 owned plot info (2009_AGSEC2A) for the 1st season
	* ready to append to rented plot info (2010_AGSEC2B)
	* owned plots are in A and rented plots are in B
	* ready to be appended to 2010_AGSEC2B

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	*	done
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global 	root 		 	"$data/household_data/uganda/wave_1/raw"  
	global  export 		 	"$data/household_data/uganda/wave_1/refined"
	global 	logout 			"$data/household_data/uganda/logs"

	
* open log	
	cap 					log close
	log using 				"$logout/2009_agsec2a", append

	
**********************************************************************************
* 1	- clean up the key variables
**********************************************************************************

	use 			"$root/2009_AGSEC2A", clear

	rename 			Hhid hhid
	rename 			A2aq2 prcid
	rename 			A2aq4 plotsizeGPS
	rename 			A2aq5 plotsizeSR
	rename			A2aq7 tenure
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid
	
* make a variable that shows the irrigation
	gen				irr_any = 1 if A2aq20 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	
	
* **********************************************************************
* 2 - merge location data
* **********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2009_GSEC1"
	*** 3 unmatched from master
	*** that means 3 observations did not have location data
	*** no option at this stage except to drop all unmatched
	
	drop 		if _merge != 3

	
**********************************************************************
* 3 - keeping cultivated land
************************************************************************	

* what was the primary use of the parcel
	tab 		 	A2aq13a 
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if A2aq13a == 1 | A2aq13a == 2
	*** 850 observations deleted
	
	
* **********************************************************************
* 4 - clean plotsize
* **********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean 2.45, max 810, min 0
	*** plot size of zero looks to be a mistake
	
	sum				plotsizeSR
	*** mean 2.27, max 250, min 0
	
* replace plot size = 0 with missing for imputation
	replace			plotsizeGPS = . if plotsizeGPS == 0
	replace			plotsizeSR = . if plotsizeSR == 0
	*** 52 changes made in plotsizeGPS, 5 plotsizeSR

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 998 missing, 29% of observations
	
* convert acres to square meters
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* check correlation between the two
	corr 			plotsize selfreport
	*** 0.186 correlation, low correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** obs. 860 appear to be incorrect GPS value, as the self-report is nowhere close
	*** obs. 2031 appears to be correct GPS value, as self-reported is close
	
	replace			plotsize = . if plotsize > 300
	*** 1 change made

* gps on the larger side vs self-report
	tab				plotsize if plotsize > 3, plot
	*** distribution has a few high values, but mostly looks reasonable

* correlation for larger plots	
	corr			plotsize selfreport if plotsize > 3 & !missing(plotsize)
	*** this is pretty high, 0.616, so these look good

* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** this is terrible, correlation is -0.042, bassically zero relatinship
		
* correlation for extremely small plots	
	corr			plotsize selfreport if plotsize < .01 & !missing(plotsize)
	*** this is actually pretty good, 0.212, which is strange in itself
	
* summarize before imputation
	sum				plotsize
	*** mean 0.880, max 25.80, min 0.004
	
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
	*** mean 0.933, max 25.80, min 0.004
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** 0.558 better correlation
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
* impute one final observation that does not have self reported
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plotsize // identify plotsize_GPS as the variable being imputed
	sort			region district hhid prcid, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize i.district, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	

	mdesc 			plotsize
	*** none missing
	
	
* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************

	keep 			hhid prcid region district county subcounty ///
					parish wgt09wosplits wgt09 hh_status2009 ///
					plotsize irr_any

	compress
	describe
	summarize

* save file		
	save 			"$export/2009_AGSEC2A.dta", replace


* close the log
	log	close

/* END */	
