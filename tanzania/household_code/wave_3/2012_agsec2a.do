* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 3 Ag sec2a
	* looks like a parcel roster, long rainy season
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
	global root 	"$data/household_data/tanzania/wave_3/raw"
	global export 	"$data/household_data/tanzania/wave_3/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv3_AGSEC2A", append

	
* ***********************************************************************
* 1 - prepare TZA 2012 (Wave 3) - Agriculture Section 2A 
* ***********************************************************************

* load data
	use				"$root/AG_SEC_2A", clear
	
* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped

* renaming variables of interest
	rename			ag2a_04 plotsize_self_ac
	rename			ag2a_09 plotsize_gps_ac
	
* check for uniquie identifiers
	drop			if plotnum == ""
	isid			y3_hhid plotnum
	*** 1,710 obs dropped that lacked plot ids

* generating unique ob id
	gen				plot_id = y3_hhid + " " + plotnum
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
	merge			m:1 y3_hhid using "$export/HH_SECA"
	tab				_merge
	*** 1,710 not matched, these are the ones we dropped that lacked plotnum
	
	drop if			_merge == 2
	drop			_merge
	
* unique district id
	sort			region district
	egen			uq_dist = group(region district)
	distinct		uq_dist
	*** 132 once again, good deal
	
* must merge in regional identifiers from 2012_AG_SEC_3A to impute
	merge			1:1 y3_hhid plotnum using "$root/AG_SEC_3A"
	*** 1,710 not matched
	
	drop if			_merge == 2
	drop			_merge
	
* record if field was cultivated during long rains
	gen 			status = ag3a_03==1 if ag3a_03!=.
	lab var			status "=1 if field cultivated during long rains"
	*** 6,183 observations were cultivated (83%)
	
* drop observations that were not cultivated
	drop if			status == 0
	*** dropped 1,264 observations that were not cultivated in long rains
	
	drop			ag3a_02_1- status


* ***********************************************************************
* 3 - clean and impute plot size
* ***********************************************************************	

* interrogating plotsize variables
	count if		plotsize_gps != . & plotsize_self != .
	*** 4,618 not mising, out of 6,183
	
	pwcorr			plotsize_gps plotsize_self
	*** high correlation (0.85)

* inverstingating the high and low end of gps measurments
	* high end
		*hist			plotsize_gps if plotsize_gps > 2
		sum				plotsize_gps, detail
		*** mean = 1.2
		*** 90% of obs < 2.6
		
		sort			plotsize_gps
		sum				plotsize_gps if plotsize_gps > 2.6
		*** 467 obs > 2.6
		
		list			plotsize_gps plotsize_self if plotsize_gps > 2.6 & ///
							!missing(plotsize_gps), sep(0)
		pwcorr			plotsize_gps plotsize_self if plotsize_gps > 2.6 & ///
							!missing(plotsize_gps)
		*** corr = 0.80 (very good)
		
		sum				plotsize_gps if plotsize_gps > 4.3
		*** 226 obs > 4.3
		
		list			plotsize_gps plotsize_self if plotsize_gps > 4.3 & ///
							!missing(plotsize_gps), sep(0)
		pwcorr			plotsize_gps plotsize_self if plotsize_gps > 4.3 & ///
							!missing(plotsize_gps)
		*** corr = 0.77 (still real high)
		
		count if		plotsize_gps > 20 & plotsize_gps != .
		*** 22 obs > 20
		
		list			plotsize_gps plotsize_self if plotsize_gps > 20 & ///
							!missing(plotsize_gps), sep(0)
		sum				plotsize_gps plotsize_self if plotsize_gps > 20 & ///
							plotsize_gps != .
		*** 22 observations
		
		pwcorr			plotsize_gps plotsize_self if plotsize_gps > 20 & ///
							!missing(plotsize_gps)
		*** corr still at 0.57 even w/ plotsize_gps > 20
		*** the high end seems very high, but the correlation still seems pretty good
		*** not dropping anything here
	
	* low end
		tab				plotsize_gps
		*hist			plotsize_gps if plotsize_gps < 0.5
		sum				plotsize_gps, detail
		*** mean = 1.2
		*** 10% of obs < 0.08
		
		sum				plotsize_gps if plotsize_gps < 0.08
		*** 373 obs < 0.08
		
		list			plotsize_gps plotsize_self if plotsize_gps < 0.08 & ///
							!missing(plotsize_gps), sep(0)
		pwcorr			plotsize_gps plotsize_self if plotsize_gps < 0.08 & ///
							!missing(plotsize_gps)
		*** corr = 0.07 (pretty poor)
		
		sum				plotsize_gps if plotsize_gps<0.05
		*** 243 obs < 0.05
		
		list			plotsize_gps plotsize_self if plotsize_gps < 0.05 & ///
							!missing(plotsize_gps), sep(0)
		pwcorr			plotsize_gps plotsize_self if plotsize_gps < 0.05 & ///
							!missing(plotsize_gps)
		*** corr = 0.05 (even more poor correlation)
		
	* dropping any '0' values, to be imputed later
		replace			plotsize_gps = . if plotsize_gps == 0
		*** 12 changes made
		
		pwcorr			plotsize_gps plotsize_self if plotsize_gps < 0.05 & ///
							!missing(plotsize_gps)
		*** this correlation improves to 0.11 once zeros are dropped
		
		count			if plotsize_gps < 0.01 & plotsize_gps != .
		*** 33 obs < 0.01
		*** again I see values of 0, 0.0040469, or 0.0080937 many times 
		*** meaning pre-conversion values of 0, 0.01, or 0.02
		*** I will not drop any low end values at this time

* impute missing + irregular plot sizes using predictive mean matching
* imputing 2,065 observations (out of 7,447) - 27.73% 
* including plotsize_self as control
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed plotsize_gps // identify plotsize_GPS as the variable being imputed
	sort			y3_hhid plotnum, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize_gps plotsize_self i.uq_dist, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset
	
* how did the imputation go?
	tab				mi_miss
	pwcorr			plotsize_gps plotsize_gps_1_ if plotsize_gps != .
	tabstat			plotsize_gps plotsize_self plotsize_gps_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	rename			plotsize_gps_1_ plotsize
	lab var			plotsize "Plot size (ha), imputed"
	*** imputed 1,577 values out of 6,183 total observations
	
	sum				plotsize_self plotsize_gps	plotsize
	*** self reported	:	mean 1.07 and s.d. 2.4
	*** gps				:	mean 1.24 and s.d. 3.2
	*** imputed			:	mean 1.19 and s.d. 3.0
	
	drop			if plotsize == . & plotsize_self ==.
	*** no observations dropped


* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************

* keep what we want, get rid of the rest
	keep		y3_hhid region district ward ea y3_rural ///
					clusterid strataid hhweight mover_R1R2R3 ///
					location_R2_to_R3 plotnum plot_id plotsize

	order		y3_hhid plotnum plot_id clusterid strataid hhweight ///
					region district ward ea y3_rural mover_R1R2R3 ///
					location_R2_to_R3 plotsize
					
* renaming and relabelling variables
	lab var		y3_hhid "Unique Household Identification NPS Y3"
	lab var		y3_rural "Cluster Type"
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
	isid			y3_hhid plotnum
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/AG_SEC2A.dta", replace


* close the log
	log	close

/* END */
