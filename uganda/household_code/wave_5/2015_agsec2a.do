* Project: WB Weather
* Created on: Feb 2024
* Created by: rg
* Edited on: 20 Feb 24
* Edited by: rg
* Stata v.18, mac

* does
	* reads Uganda wave 5 owned plot info (2015_AGSEC2A) for the 1st season
	* ready to append to rented plot info (2015_AGSEC2B)
	* owned plots are in A and rented plots are in B
	* ready to be appended to 2015_AGSEC2B to make 2015_AGSEC2

* assumes
	* access to the raw data
	* mdesc.ado

* TO DO:
	* clean up to save section

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root 		"$data/household_data/uganda/wave_5/raw"  
	global  export 		"$data/household_data/uganda/wave_5/refined"
	global 	logout 		"$data/household_data/uganda/logs"


* open log	
	cap log close
	log using "$logout/2015_agsec2a", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 5 season A
	use "$root/agric/AGSEC2A.dta", clear
		
	rename			HHID hhid
	rename			parcelID prcid
	rename 			a2aq4 plotsizeGPS
	rename 			a2aq5 plotsizeSR
	rename			a2aq7 tenure
	
	describe
	sort hhid prcid
	isid hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2aq18 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** there are 39 observations irrigated


***********************************************************************
**# 2 - merge location data
***********************************************************************	
	
* merge the location identification
	merge m:1 hhid using "$export/2015_gsec1"
	*** merged 4,129, 1,128 unmerged total, 1,057 from using data
	*** 71 unmerged from master
	
	drop 		if _merge ! = 3
	drop		_merge
	
	
************************************************************************
**# 3 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	*** for some reason, the first cropping season is a2aq11b, not a2aq11a
	tab 		 	a2aq11b
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if a2aq11b == 1 | a2aq11b == 2
	*** 1,170 observations deleted	

	
***********************************************************************
**# 4 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean 1.59, max 158, min 0
	*** only 1 plotsize = 0
	
	sum				plotsizeSR
	*** mean 1.38, max 50, min .01

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 1,840 missing, 62% of observations

* convert acres to hectares
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* examine gps outlier values
	sum				plotsize, detail
	*** mean 0.64, min 0, max 63.94, std. dev. 2.03
	
	sum				plotsize if plotsize < 60, detail
	*** mean 0.59, max 9.3, min 0, std. dev 0.75
	
	list			plotsize selfreport if plotsize > 60 & !missing(plotsize)
	*** gps plotsize is a hundred times larger self reported, which means a decimal point misplacement.
	
* recode outlier to be 1/100
	replace			plotsize = plotsize/100 if plotsize > 60
	
* check correlation between the two
	corr 			plotsize selfreport
	*** 0.88 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** these all look good, largest size is 9 ha
	
* gps on the larger side vs self-report
	tab				plotsize if plotsize > 3, plot
	*** distribution looks reasonable

* correlation for larger plots	
	corr			plotsize selfreport if plotsize > 3 & !missing(plotsize)
	*** this is very high, 0.86, so these look good

* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** correlation is negative, -0.12
		
* correlation for extremely small plots	
	corr			plotsize selfreport if plotsize < .01 & !missing(plotsize)
	*** correlation is negative, -0.79
	
* summarize before imputation
	sum				plotsize
	*** mean 0.589, max 9.3, min 0
	
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
	*** mean 0.569, max 9.3, min 0
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** strong correlation 0.816
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** none missing

	
***********************************************************************
**# 4 - end matter, clean up to save
***********************************************************************
	
	keep 			hhid HHID prcid region district county subcounty ///
					parish hh_status2011 wgt11 ///
					plotsize irr_any

	compress
	describe
	summarize

* save file
		customsave , idvar(hhid) filename("2011_AGSEC2A.dta") ///
			path("`export'") dofile(2011_AGSEC2A) user($user)

* close the log
	log	close

/* END */
