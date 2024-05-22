* Project: WB Weather
* Created on: Feb 2024
* Created by: reece
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 7 (NPSY5) Ag sec2a
	* looks like a parcel roster, long rainy season
	* generates imputed plot sizes
	
* assumes
	* access to all raw data
	* distinct.ado
	* cleaned hh_seca.dta
	* cleaned ag_sec_3a.dta

* TO DO:
	* completed

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_7/raw"
	global export 	"$data/household_data/tanzania/wave_7/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv7_AGSEC2A", append

	
*************************************************************************
**# 1 - prepare TZA 2020 (Wave 7) - Agriculture Section 2 
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
	*** 195 distinct districts
	
* record if field was cultivated during long rainy
	gen 		status = ag3a_03==1 if ag3a_03!=.
	lab var		status "=1 if field cultivated during long rain"
	*** 3838 obs were cultivated (68.5%)
	*** 957 missing
	
* drop any obs that weren't cultivated
	drop if		status != 1
	*** dropped 2722 not cultivated during long rainy
	
	order 		y4_hhid, after(y5_hhid)
	order 		plot_id plotsize_self plotsize_gps region district y5_rural ///
					clusterid strataid hhweight mover2020 uq_dist, after(plotnum)
	
	drop 		ag3a_02_1- status
	

* ***********************************************************************
**#3 - clean and impute plot size
* ***********************************************************************
	
* interrogating plotsize variables
	count 		if plotsize_gps != . & plotsize_self != .
	*** 2656 not missing out of 3838
	
	pwcorr 		plotsize_gps plotsize_self
	*** low correlation (0.0065)
	
	replace 	plotsize_gps = . if plotsize_gps > 160
	pwcorr		plotsize_gps plotsize_self
	*** correlation much higher after dropping five outliers (0.8884)
	*** 5 replaced as missing
	
* inverstingating the high and low end of gps measurments
	* high end
		tab			plotsize_gps
		sum			plotsize_gps, detail
		*** mean = 1.29
		*** 90% of obs < 2.59
		
		sort		plotsize_gps
		sum 		plotsize_gps if plotsize_gps>2.59
		*** 266 obs > 2.59
		
		list		plotsize_gps plotsize_self if plotsize_gps>2.59 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>2.59 & ///
						!missing(plotsize_gps)
		*** corr = 0.8953 (high correlation)
		
		sum 		plotsize_gps if plotsize_gps>4.25
		*** 95% of obs < 4.25, 135 obs > 4.25
		
		list		plotsize_gps plotsize_self if plotsize_gps>4.25 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>4.25 & ///
						!missing(plotsize_gps)
		*** corr = 0.8991 
		
		count 		if plotsize_gps > 20 & plotsize_gps != .
		*** 15 obs >= 20
		
		list		plotsize_gps plotsize_self if plotsize_gps>20 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>20 & ///
						!missing(plotsize_gps)
		*** corr at 0.9264

	* low end
		tab			plotsize_gps
		*hist		plotsize_gps if plotsize_gps < 0.5
		sum			plotsize_gps, detail
		*** mean = 1.29
		*** 10% of obs < 0.073
		
		sum 		plotsize_gps if plotsize_gps<0.073
		*** 267 obs < 0.073
		
		list		plotsize_gps plotsize_self if plotsize_gps<0.073 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.073 & ///
						!missing(plotsize_gps)
		*** corr = 0.1228 (correlation very low)
		
		sum 		plotsize_gps if plotsize_gps<0.040
		*** 129 obs < 0.040
	
		list		plotsize_gps plotsize_self if plotsize_gps<0.040 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.040 & ///
						!missing(plotsize_gps)
		*** corr = -0.0942
	
	* dropping any '0' values, to be imputed later
		replace 	plotsize_gps = . if plotsize_gps == 0
		*** 1 change made, to missing
		
		count		if plotsize_gps < 0.01 & plotsize_gps != .
		list		plotsize_gps plotsize_self if plotsize_gps<0.01 & ///
						!missing(plotsize_gps), sep(0)
		*** 27 obs < 0.01
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
	*** imputed 1188 values out of 3838 total obs
	
	sum				plotsize_self plotsize_gps	plotsize
	*** self reported	:	mean 1.16 and s.d. 3.96
	*** gps				:	mean 1.30 and s.d. 4.20
	*** imputed			:	mean 1.31 and s.d. 3.82
	
	drop			if plotsize == . & plotsize_self ==.
	*** no observations dropped


* **********************************************************************
**#4 - end matter, clean up to save
* **********************************************************************
	
* keep what we want, get rid of the rest
	keep		y5_hhid y4_hhid plot_id plotnum plotsize clusterid strataid ///
					hhweight region district y5_rural mover2020
	order		y5_hhid y4_hhid plot_id plotnum clusterid strataid hhweight ///
					region district y5_rural mover2020 plotsize
					
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
