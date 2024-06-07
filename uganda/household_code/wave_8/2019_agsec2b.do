* Project: WB Weather
* Created on: Apr 2024
* Created by: jdm
* Edited on: 24 May 24
* Edited by: jdm
* Stata v.18

* does
	* reads Uganda wave 8 rented plot info (2019_AGSEC2B)
	* appends to owned plot info (2019_AGSEC2A)
	* outputs appended data to 2019_AGSEC2

* assumes
	* access to the raw data
	* mdesc.ado

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/household_data/uganda/wave_8/raw"  
	global  export 		"$data/household_data/uganda/wave_8/refined"
	global 	logout 		"$data/household_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2019_agsec2b", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 8 season B
	use 			"$root/agric/agsec2b.dta", clear

* Rename ID variables
	rename			parcelID prcid
	rename 			s2aq04 plotsizeGPS
	rename 			s2aq05 plotsizeSR
	rename			s2aq07 tenure
	recast 			str32 hhid
	
	describe
	sort 			hhid prcid
	isid 			hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2aq18 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** irrigation is q18 not q20 like in other rounds


***********************************************************************
**# 2 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2019_gsec1"	
	*** 1,276 matched only 2 not merged from master
	*** 2,187 unmatched from using
	*** that means 2,187 households did not rent plots
	
	drop 		if _merge != 3	
	*** 2,189 observations deleted
	
	
************************************************************************
**# 3 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	tab 		 	a2bq12a 
	tab				a2bq12b
	*** activities includepasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2bq12a == 1 | a2bq12b == 1
	*** 218 observations deleted	

	
***********************************************************************
**# 4 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean .90, max 4.17, min .06
	
	sum				plotsizeSR
	*** mean .96, max 10, min .01

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 980 missing, 93% of observations

* convert acres to hectares
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* check correlation between the two
	corr 			plotsize selfreport
* twoway (scatter plotsize selfreport)
	*** 0.972correlation, high correlation between GPS and self reported
	
* Look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** these all look good, largest size is 1.68 ha
	
* summarize before imputation
	sum				plotsize
	*** mean 0.367, max 1.68, min 0.024
	
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
	*** mean 0.36, max 1.68, min 0.024
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** strong correlation 0.83
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** 5 missing, 0.47%

	drop if			plotsize == .
	
* **********************************************************************
**#4 - end matter, clean up to save
* **********************************************************************
	
	keep 			hhid hh prcid region district county subcounty ///
					parish wgt19 plotsize irr_any

	compress
	describe
	summarize

* save file
	save 			"$export/2019_agsec2b.dta", replace

* append 2a to build complete plot data setup
	append			using "$export/2019_agsec2a.dta", force

	compress
	describe
	summarize

* save file
	save 			"$export/2019_agsec2.dta", replace
	
* close the log
	log	close

/* END */
