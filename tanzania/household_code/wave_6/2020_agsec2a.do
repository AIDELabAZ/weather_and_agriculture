* Project: WB Weather
* Created on: Feb 2024
* Created by: reece
* Edited on: Feb 22 2024
* Edited by: reece
* Stata v.18

* does
	* cleans Tanzania household variables, wave 6 Ag sec2a
	* looks like a parcel roster, long rainy season
	* generates imputed plot sizes
	
* assumes
	* access to all raw data
	* distinct.ado
	* cleaned HH_SECA data

* TO DO:


	
************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_6/raw"
	global export 	"$data/household_data/tanzania/wave_6/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv6_AGSEC2A", append

	
*************************************************************************
**# 1 - prepare TZA 2020 (Wave 6) - Agriculture Section 2 
*************************************************************************

* load data
	use 		"$root/ag_sec_02", clear

* dropping duplicates
	duplicates 	drop
	*** 0 obs dropped

* must merge in regional identifiers from 2012_AG_SEC_3A to impute
	rename 		ag2a_05 prevplot_id
	
	merge		1:1 y5_hhid plot_id using "$root/ag_sec_3a"
	drop		_merge
	*** all merged
	
* renaming variables of interest
	rename 		ag2a_04 plotsize_self_ac
	rename 		ag2a_09 plotsize_gps_ac
	rename 		prevplot_id plotnum

* check for unique identifiers
	isid		y5_hhid plot_id
	lab var		plot_id "Plot identifier"
	
* convert from acres to hectares
	generate	plotsize_self = plotsize_self_ac * 0.404686
	label		var plotsize_self "Self-reported Area (Hectares)"
	generate	plotsize_gps = plotsize_gps_ac * 0.404686
	label		var plotsize_gps "GPS Measured Area (Hectares)"
	drop		plotsize_gps_ac plotsize_self_ac

	tab 		plotsize_gps
	*** several large outliers (1575.24 +) 
	
* ***********************************************************************
**#2 - merge in regional ID and cultivation status
* ***********************************************************************
	
* must merge in regional identifiers from 2020_HHSECA to impute
	merge		m:1 y5_hhid using "$export/HH_SECA"
	tab			_merge
	*** 1,780 not merged from using, out of 8,340, (dropped obs from line 45)
	
	drop		if _merge == 2
	drop		_merge
	
* unique district id
	sort		region district
	egen		uq_dist = group(region district)
	distinct 	uq_dist
	*** 172 distinct districts
	
* record if field was cultivated during long rainy
	gen 		status = ag3a_03==1 if ag3a_03!=.
	lab var		status "=1 if field cultivated during long rain"
	*** 1926 obs were cultivated (68%)
	*** 952 missing
	
* drop any obs that weren't cultivated
	drop if		status != 1
	*** dropped 1860 not cultivated during long rainy
	
	order plot_id plotsize_self plotsize_gps region district y5_rural clusterid strataid hhweight uq_dist, after(plotnum)
	
	drop 		ag3a_02_1- status
	

* ***********************************************************************
**#3 - clean and impute plot size
* ***********************************************************************
	
* interrogating plotsize variables
	count 		if plotsize_gps != . & plotsize_self != .
	*** 1556 missing out of 1926
	
	pwcorr 		plotsize_gps plotsize_self
	*** low correlation (0.0026)
	
	replace 	plotsize_gps = . if plotsize_gps > 55
	pwcorr		plotsize_gps plotsize_self
	*** correlation much higher after dropping two outliers (0.7335)
	*** 2 replaced as missing
	
* inverstingating the high and low end of gps measurments
	* high end
		tab			plotsize_gps
		sum			plotsize_gps, detail
		*** mean = 1.33
		*** 90% of obs < 2.9
		
		sort		plotsize_gps
		sum 		plotsize_gps if plotsize_gps>2.9
		*** 159 obs > 2.9
		
		list		plotsize_gps plotsize_self if plotsize_gps>2.9 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>2.9 & ///
						!missing(plotsize_gps)
		*** corr = 0.6439 (pretty high correlation)
		
		sum 		plotsize_gps if plotsize_gps>4.60
		*** 95% of obs < 4.60, 77 obs > 4.22
		
		list		plotsize_gps plotsize_self if plotsize_gps>4.22 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>4.22 & ///
						!missing(plotsize_gps)
		*** corr = 0.5944 
		
		count 		if plotsize_gps > 20 & plotsize_gps != .
		*** 5 obs >= 20
		
		list		plotsize_gps plotsize_self if plotsize_gps>20 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>20 & ///
						!missing(plotsize_gps)
		*** corr at 0.2894

	* low end
		tab			plotsize_gps
		*hist		plotsize_gps if plotsize_gps < 0.5
		sum			plotsize_gps, detail
		*** mean = 1.189
		*** 10% of obs < 0.085
		
		sum 		plotsize_gps if plotsize_gps<0.085
		*** 161 obs < 0.085
		
		list		plotsize_gps plotsize_self if plotsize_gps<0.085 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.085 & ///
						!missing(plotsize_gps)
		*** corr = 0.0791 (correlation very low)
		
		sum 		plotsize_gps if plotsize_gps<0.049
		*** 88 obs < 0.049
	
		list		plotsize_gps plotsize_self if plotsize_gps<0.049 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.049 & ///
						!missing(plotsize_gps)
		*** corr = 0.0346
	
	* dropping any '0' values, to be imputed later
		replace 	plotsize_gps = . if plotsize_gps == 0
		*** 0 changes made
		
		count		if plotsize_gps < 0.01 & plotsize_gps != .
		list		plotsize_gps plotsize_self if plotsize_gps<0.01 & ///
						!missing(plotsize_gps), sep(0)
		*** 16 obs < 0.01
		*** all values equal 0.0040469 or 0.0080937 
		*** meaning pre-conversion values of 0.01, or 0.02
		*** I will not drop any low end values at this time

* impute missing + irregular plot sizes using predictive mean matching
* including plotsize_self as control
	mi set 		wide 	// declare the data to be wide.
	mi xtset	, clear 	// clear any xtset in place previously
	mi register	imputed plotsize_gps // identify plotsize_GPS as the variable being imputed
	sort		y5_hhid plot_id, stable // sort to ensure reproducability of results
	mi impute 	pmm plotsize_gps plotsize_self i.uq_dist, add(1) rseed(245780) ///
					noisily dots force knn(5) bootstrap
	mi 			unset
	
* how did the imputation go?
	tab			mi_miss
	pwcorr 		plotsize_gps plotsize_gps_1_ if plotsize_gps != .
	tabstat 	plotsize_gps plotsize_self plotsize_gps_1_, by(mi_miss) ///
					statistics(n mean min max) columns(statistics) longstub ///
					format(%9.3g) 
	rename		plotsize_gps_1_ plotsize
	lab var		plotsize "Plot size (ha), imputed"
	*** imputed 1554 values out of 1926 total obs
	
	sum				plotsize_self plotsize_gps	plotsize
	*** self reported	:	mean 1.19 and s.d. 2.21
	*** gps				:	mean 1.33 and s.d. 2.93
	*** imputed			:	mean 1.35 and s.d. 2.84
	
	drop			if plotsize == . & plotsize_self ==.
	*** no observations dropped


* **********************************************************************
**#4 - end matter, clean up to save
* **********************************************************************
	
* keep what we want, get rid of the rest
	keep		y5_hhid plot_id plotnum plotsize clusterid strataid ///
					hhweight region district y5_rural
	order		y5_hhid plot_id plotnum clusterid strataid hhweight ///
					region district plotsize
					
* renaming and relabeling variables
	lab var		y5_hhid "Unique Household Identification NPS Y4"
	lab var		y5_rural "Cluster Type"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var		plotnum "Plot ID Within household"
	lab var		plot_id "Plot Identifier"
	lab var		plotsize "Plot size (ha), imputed"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		region "Region Code"
	lab var		district "District Code"

* prepare for export
	isid			y5_hhid plot_id
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/2020_AGSEC2A.dta", replace

* close the log
	log	close

/* END */
