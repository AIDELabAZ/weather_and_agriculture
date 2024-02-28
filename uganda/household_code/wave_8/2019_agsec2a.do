* Project: WB Weather
* Created on: Feb 2024
* Created by: rg
* Edited on: 27 Feb 24
* Edited by: KCD
* Stata v.18, mac

* does
	* reads Uganda wave 4 owned plot info (2019_AGSEC2A) for the 1st season
	* ready to append to rented plot info (2019_AGSEC2B)
	* owned plots are in A and rented plots are in B
	* ready to be appended to 2019_AGSEC2B to make 2019_AGSEC2

* assumes
	* access to the raw data
	* mdesc.ado

* TO DO:
	* everything

***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/household_data/uganda/wave_8/raw"  
	global  export 		"$data/household_data/uganda/wave_8/refined"
	global 	logout 		"$data/household_data/uganda/logs"
	
* open log	
	cap log close
	log using "$logout/2019_agsec2a", append

	
***********************************************************************
**# 1 - clean up the key variables
***********************************************************************

* import wave 4 season A
	use "$root/agric/agsec2a.dta", clear
	
	compress
		
* Rename ID variables
	rename			parcelID prcid
	rename 			s2aq4 plotsizeGPS
	rename 			s2aq5 plotsizeSR
	rename			s2aq7 tenure
	
	describe
	sort hhid prcid
	isid hhid prcid

* make a variable that shows the irrigation
	gen				irr_any = 1 if a2aq18 == 1
	replace			irr_any = 0 if irr_any == .
	lab var			irr_any "Irrigation (=1)"
	*** irrigation is q18 not q20 like in other rounds
	*** there is an error that labels the question with soil type


***********************************************************************
**#2 - merge location data
 **********************************************************************	
* merge the location identification
	merge m:1 hhid using "$export/2019_gsec1"
	
	*** 995 unmatched from master
	*** that means 995 observations did not have location data
	*** no option at this stage except to drop all unmatched
	
	drop 		if _merge != 3	

	
************************************************************************
**# 3 - keeping cultivated land
************************************************************************

* what was the primary use of the parcel
	*** activity in the first season is recorded seperately from activity in the second season
	tab 		 	s2aq11a 
	*** activities include renting out, pasture, forest. cultivation, and other
	*** we will only include plots used for annual or perennial crops
	
	keep			if s2aq11a == 1 | s2aq11a == 2
	*** 955 observations deleted

	
***********************************************************************
**#4 - clean plotsize
***********************************************************************

* summarize plot size
	sum 			plotsizeGPS
	***	mean 1.38, max 19.86, min .01
	*** no plotsizes that are zero
	
	sum				plotsizeSR
	*** mean 1.48, max 50, min .01

* how many missing values are there?
	mdesc 			plotsizeGPS
	*** 1,773 missing, 56.61% of observations

**# convert acres to square meters
	gen				plotsize = plotsizeGPS*0.404686
	label var       plotsize "Plot size (ha)"
	
	gen				selfreport = plotsizeSR*0.404686
	label var       selfreport "Plot size (ha)"

* check correlation between the two
	corr 			plotsize selfreport
	*** 0.79 correlation, high correlation between GPS and self reported
	
* compare GPS and self-report, and look for outliers in GPS 
	sum				plotsize, detail
	*** save command as above to easily access r-class stored results 

* look at GPS and self-reported observations that are > ±3 Std. Dev's from the median 
	list			plotsize selfreport if !inrange(plotsize,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) ///
						& !missing(plotsize)
	*** these all look good, largest size is 30 ha
	
* gps on the larger side vs self-report
	tab				plotsize if plotsize > 3, plot
	*** distribution has a few high values, but mostly looks reasonable

* correlation for larger plots	
	corr			plotsize selfreport if plotsize > 3 & !missing(plotsize)
	*** this is very high, 0.842, so these look good

* correlation for smaller plots	
	corr			plotsize selfreport if plotsize < .1 & !missing(plotsize)
	*** this is very low 0.127
		
* correlation for extremely small plots	
	corr			plotsize selfreport if plotsize < .01 & !missing(plotsize)
	*** this is terrible, 0.036, basically no relation, not unexpected
	
* summarize before imputation
	sum				plotsize
	*** mean 0.883, max 30.35, min 0.004
	
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
	*** mean 0.884, max 30.35, min 0.004
	
	corr 			plotsize_1_ selfreport if plotsize == .
	*** strong correlation 0.824
	
	replace 		plotsize = plotsize_1_ if plotsize == .
	
	drop			mi_miss plotsize_1_
	
	mdesc 			plotsize
	*** none missing

	
* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************
	
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
