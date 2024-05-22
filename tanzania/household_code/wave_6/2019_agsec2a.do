* Project: WB Weather
* Created on: March 13, 2024
* Created by: reece
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 6 (NPSY5-SDD) Ag sec2a
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
	global root 	"$data/household_data/tanzania/wave_6/raw"
	global export 	"$data/household_data/tanzania/wave_6/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv6_AGSEC2A", append

	
*************************************************************************
**# 1 - prepare TZA 2019 (Wave 6) - Agriculture Section 2 
*************************************************************************

* load data
	use 		"$root/ag_sec_02", clear

* dropping duplicates
	duplicates 	drop
	*** 0 obs dropped

* renaming variables of interest
	rename 		ag2a_04 plotsize_self_ac
	rename 		ag2a_09 plotsize_gps_ac

* check for unique identifiers
	drop		if missing(plotnum)
	isid		sdd_hhid plotnum
	*** 0 obs dropped
	
* generating unique observation id for each ob
	tostring	plotnum, gen(plotnum_str)
	generate 	plot_id = sdd_hhid + " " + plotnum_str
	lab var		plot_id "Unique plot identifier"
	isid 		plot_id
	*** type mismatch- need to convert plotnum to string variable
	
* convert from acres to hectares
	generate	plotsize_self = plotsize_self_ac * 0.404686
	label		var plotsize_self "Self-reported Area (Hectares)"
	generate	plotsize_gps = plotsize_gps_ac * 0.404686
	label		var plotsize_gps "GPS Measured Area (Hectares)"
	drop		plotsize_gps_ac plotsize_self_ac

	
* ***********************************************************************
**#2 - merge in regional ID and cultivation status
* ***********************************************************************
	
* must merge in regional identifiers from 2008_HHSECA to impute
	merge		m:1 sdd_hhid using "$export/HH_SECA"
	tab			_merge
	*** 97 not merged from using
	
	drop		if _merge == 2
	drop		_merge
	
* unique district id
	sort		region district
	egen		uq_dist = group(region district)
	distinct 	uq_dist
	*** 127 distinct districts
	
* must merge in regional identifiers from 2012_AG_SEC_3A to impute
	merge			1:1 sdd_hhid plotnum using "$root/AG_SEC_3A"
	*** 0 not matched from using

	drop		if _merge == 2
	drop		_merge
	
* record if field was cultivated during long rainy
	gen 		status = ag3a_03==1 if ag3a_03!=.
	lab var		status "=1 if field cultivated during long rain"
	tab 		status
	*** 1031 obs were cultivated (51%)
	
* drop any obs that weren't cultivated
	drop if		status == 0
	*** dropped 999 obs not cultivated during long rainy
	
	drop 		ag3a_02_1- status
	

* ***********************************************************************
**#3 - clean and impute plot size
* ***********************************************************************
	
* interrogating plotsize variables
	count 		if plotsize_gps != . & plotsize_self != .
	*** 733 not missing, out of 1306
	
	pwcorr 		plotsize_gps plotsize_self
	*** medium strong corr (0.5666)
	
* inverstingating the high and low end of gps measurments
	* high end
		tab			plotsize_gps
		sum			plotsize_gps, detail
		*** mean = 1.20
		*** 90% of obs < 2.5
		
		sort		plotsize_gps
		sum 		plotsize_gps if plotsize_gps>2.5
		*** 72 obs > 2.5
		
		list		plotsize_gps plotsize_self if plotsize_gps>2.5 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>2.5 & ///
						!missing(plotsize_gps)
		*** corr = 0.6857
		
		sum 		plotsize_gps if plotsize_gps>4.43
		*** 146 obs > 4.43
		
		list		plotsize_gps plotsize_self if plotsize_gps>4.43 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>4.43 & ///
						!missing(plotsize_gps)
		*** corr = 0.5716
		
		count 		if plotsize_gps > 20 & plotsize_gps != .
		*** 4 obs >= 20
		
		list		plotsize_gps plotsize_self if plotsize_gps>20 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps>20 & ///
						!missing(plotsize_gps)
		*** corr at 0.9668 with plotsize_gps >20
		*** the high end seems okay, not dropping anything here yet

	* low end
		tab			plotsize_gps
		sum			plotsize_gps, detail
		*** mean = 1.20
		*** 10% of obs < 0.073
		
		sum 		plotsize_gps if plotsize_gps<0.073
		*** 75 obs < 0.073
		
		list		plotsize_gps plotsize_self if plotsize_gps<0.073 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.073 & ///
						!missing(plotsize_gps)
		*** corr = -0.1247 (pretty poor and negative)
		
		sum 		plotsize_gps if plotsize_gps<0.049
		*** 37 obs < 0.049
	
		list		plotsize_gps plotsize_self if plotsize_gps<0.049 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.049 & ///
						!missing(plotsize_gps)
		*** corr = -0.0610 (even more poor correlation and still negative)
	
	* dropping any '0' values, to be imputed later
		replace 	plotsize_gps = . if plotsize_gps == 0
		*** 0 changes made
		
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.049 & ///
						!missing(plotsize_gps)
		*** no obs changed, same correlation
		
		count		if plotsize_gps < 0.02 & plotsize_gps != .
		list		plotsize_gps plotsize_self if plotsize_gps<0.02 & ///
						!missing(plotsize_gps), sep(0)
		*** 5 obs < 0.01
		*** all values equal 0.0040469, 0.0121406, or 0.0161874
		*** meaning pre-conversion values of 0.01, 0.03, or 0.04
		*** I will not drop any low end values at this time

* impute missing + irregular plot sizes using predictive mean matching
* imputing 1,376 observations (out of 4,275) - 32.19% 
* including plotsize_self as control
	mi set 		wide 	// declare the data to be wide.
	mi xtset	, clear 	// clear any xtset in place previously
	mi register	imputed plotsize_gps // identify plotsize_GPS as the variable being imputed
	sort		sdd_hhid plotnum, stable // sort to ensure reproducability of results
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
	*** imputed 299 values out of 1306 total obs
	
	sum				plotsize_self plotsize_gps	plotsize
	*** self reported	:	mean 1.15 and s.d. 2.55
	*** gps				:	mean 1.20 and s.d. 2.89
	*** imputed			:	mean 1.23 and s.d. 2.69
	
	drop			if plotsize == . & plotsize_self ==.
	*** 274 observations dropped


* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************
	
* keep what we want, get rid of the rest
	keep		sdd_hhid plotnum plot_id plotsize clusterid strataid ///
					hhweight region district ward ea sdd_rural mover2019
	order		sdd_hhid plotnum plot_id clusterid strataid hhweight ///
					region district ward ea sdd_rural mover2019 plotsize
					
* renaming and relabelling variables
	lab var		sdd_hhid "Unique Household Identification NPS-SDD"
	lab var		sdd_rural "Cluster Type"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var		plotnum "Plot ID Within household"
	lab var		plot_id "Unquie Plot Identifier"
	lab var		plotsize "Plot size (ha), imputed"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		region "Region Code"
	lab var		district "District Code"
	lab var		ward "Ward Code"
	lab var		ea "Village / Enumeration Area Code"

* prepare for export
	isid			sdd_hhid plot_id
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/2019_AGSEC2A.dta", replace

* close the log
	log	close

/* END */
