* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 1 Ag sec2a
	* looks like a parcel roster, 2008 long rainy season
	* generates imputed plot sizes

* assumes
	* access to all raw data
	* distinct.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_1/raw"
	global export 	"$data/household_data/tanzania/wave_1/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv1_AGSEC2A", append


	
* ***********************************************************************
* 1 - prepare TZA 2008 (Wave 1) - Agriculture Section 2A 
* ***********************************************************************

* load data
	use				"$root/SEC_2A", clear
	
* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped

* renaming variables of interest
	rename 		s2aq4 plotsize_self_ac
	rename 		area plotsize_gps_ac
	
* check for uniquie identifiers
	drop			if plotnum == ""
	isid			hhid plotnum
	*** 0 obs dropped - none lack plot ids

* generating unique ob id
	gen				plot_id = hhid + " " + plotnum
	lab var			plot_id "Unique plot identifier"
	isid			plot_id
	
* convert from acres to hectares
	gen				plotsize_self = plotsize_self_ac * 0.404686
	lab var			plotsize_self "Self-reported Area (Hectares)"
	gen				plotsize_gps = plotsize_gps_ac * 0.404686
	lab var			plotsize_gps "GPS Measured Area (Hectares)"
	drop			plotsize_gps_ac plotsize_self_ac

	
* ***********************************************************************
* 2 - merge in regional ID and cultivation status
* ***********************************************************************	

* must merge in regional identifiers from 2012_HHSECA to impute
	merge			m:1 hhid using "$export/HH_SECA"
	tab				_merge
	*** 981 not matched, using only
	
	drop if			_merge == 2
	drop			_merge
	
* unique district id
	sort			region district
	egen			uq_dist = group(region district)
	distinct		uq_dist
	*** 125 distinct ditricts
	
* must merge in regional identifiers from 2012_AG_SEC_3A to impute
	merge			1:1 hhid plotnum using "$root/SEC_3A"
	*** 2 not matched from master, 0 not matched from using
	*** this doesn't come up in any other waves - issue?
	
	drop if			_merge == 2
	drop			_merge
	
* record if field was cultivated during long rains
	gen 			status = s3aq3==1 if s3aq3!=.
	lab var			status "=1 if field cultivated during long rains"
	*** 4,408 observations were cultivated (86%)
	
* drop observations that were not cultivated
	drop if			status == 0
	*** dropped 718 observations that were not cultivated in long rains
	*** this code does not drop the 2 obs w/ missing sec 3 info
	*** their valus will be imputed, but w/ no input info the obs are likely useless
	
	drop			s3aq2_1- status


* ***********************************************************************
* 3 - clean and impute plot size
* ***********************************************************************
	
* interrogating plotsize variables
	count 		if plotsize_gps != . & plotsize_self != .
	*** only 856 not mising, out of 5,128

	pwcorr 		plotsize_gps plotsize_self
	*** high correlation (0.8027)

* investigating the high and low end of gps measurments
	* high end
		tab			plotsize_gps
		*hist		plotsize_gps if plotsize_gps > 2
		sum			plotsize_gps, detail
		*** mean = 0.935
		*** 90% of obs < 2.18

		sort		plotsize_gps
		sum 		plotsize_gps if plotsize_gps > 2
		*** 101 obs > 2

		list		plotsize_gps plotsize_self if plotsize_gps > 2 ///
						& !missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps > 2 ///
						& !missing(plotsize_gps)
		*** corr = 0.6891 (not terrible)

		sum 		plotsize_gps if plotsize_gps>3
		*** 54 obs > 2

		list		plotsize_gps plotsize_self if plotsize_gps > 3 ///
						& !missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps > 3 ///
						& !missing(plotsize_gps)
		*** corr = 0.6461 (still not terrible)
		*** the high end seems okay, maybe not dropping anything here...

	* low end
		tab			plotsize_gps
		*hist		plotsize_gps if plotsize_gps < 0.5
		sum			plotsize_gps, detail
		*** mean = 0.935
		*** 10% of obs < 0.084

		sum 		plotsize_gps if plotsize_gps < 0.085
		*** 88 obs < 0.085

		list		plotsize_gps plotsize_self if plotsize_gps < 0.085 ///
						& !missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps < 0.085 ///
						& !missing(plotsize_gps)
		*** corr = -0.3194 (inverse correlation! interesting! but not completely useless)

		sum 		plotsize_gps if plotsize_gps<0.05
		*** 43 obs < 0.05

		list		plotsize_gps plotsize_self if plotsize_gps < 0.05 ///
						& !missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps < 0.05 ///
						& !missing(plotsize_gps)
		*** corr = -0.5301 (even higher inverse correlation)
		*** inverse correlation seems like it could be useful in imputing values

	* will drop the lone '0' value, to be imputed later
		replace 	plotsize_gps = . if plotsize_gps == 0
		
		count			if plotsize_gps < 0.05 & plotsize_gps != .
		*** 39 obs < 0.05
		*** I will not drop any low end values at this time

* impute missing + irregular plot sizes using predictive mean matching
* imputing 3,650 observations (out of 4,410) - 82.77% 
* including plotsize_self as control
	mi set 		wide 	// declare the data to be wide.
	mi xtset	, clear 	// this is a precautinary step to clear any existing xtset
	mi register	imputed plotsize_gps // identify plotsize_GPS as the variable being imputed
	sort		hhid plotnum, stable // sort to ensure reproducability of results
	mi impute 	pmm plotsize_gps plotsize_self i.uq_dist, add(1) rseed(245780) ///
					noisily dots force knn(5) bootstrap
	mi 			unset

* how did the imputation go?
	tab			mi_miss
	pwcorr 		plotsize_gps plotsize_gps_1_ if plotsize_gps != .
	tabstat 	plotsize_gps plotsize_self plotsize_gps_1_, ///
					by(mi_miss) statistics(n mean min max) columns(statistics) ///
					longstub format(%9.3g)
	rename		plotsize_gps_1_ plotsize
	*** imputed 3,650 values out of 4,410 total observations
	
	sum				plotsize_self plotsize_gps	plotsize
	*** self reported	:	mean 0.95 and s.d. 4.1
	*** gps				:	mean 0.92 and s.d. 1.4
	*** imputed			:	mean 0.91 and s.d. 1.4
	
	drop			if plotsize == . & plotsize_self ==.
	*** no observations dropped
	

* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************	

* keep what we want, get rid of the rest
	keep		hhid plotnum plot_id plotsize clusterid strataid ///
					hhweight region district ward ea y1_rural
	order		hhid plotnum plot_id clusterid strataid hhweight ///
					region district ward ea y1_rural plotsize
	
* renaming and relabelling variables
	lab var		hhid "Unique Household Identification NPS Y1"
	lab var		y1_rural "Cluster Type"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var		plotnum "Plot ID Within household"
	lab var		plot_id "Unique Plot Identifier"
	lab var		plotsize "Plot size (ha), imputed"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		region "Region Code"
	lab var		district "District Code"
	lab var		ward "Ward Code"
	lab var		ea "Village / Enumeration Area Code"

* prepare for export
	isid			hhid plotnum
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/AG_SEC2A.dta", replace
	
* close the log
	log	close

/* END */
