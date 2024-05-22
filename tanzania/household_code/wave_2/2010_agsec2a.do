* Project: WB Weather
* Created on: April 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 2 Ag sec2a
    * looks like a parcel roster, 2010 long rainy season
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
	global root 	"$data/household_data/tanzania/wave_2/raw"
	global export 	"$data/household_data/tanzania/wave_2/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv2_AGSEC2A", append



* ***********************************************************************
* 1 - prepare TZA 2010 (Wave 2) - Agriculture Section 2A 
* ***********************************************************************

* load data
	use				"$root/AG_SEC2A", clear
	
* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped

* renaming variables of interest
	rename			ag2a_04 plotsize_self_ac
	rename			ag2a_09 plotsize_gps_ac
	
* check for uniquie identifiers
	drop			if plotnum == ""
	isid			y2_hhid plotnum
	*** 0 obs dropped that lacked plot ids

* generating unique ob id
	gen				plot_id = y2_hhid + " " + plotnum
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
	merge			m:1 y2_hhid using "$export/HH_SECA"
	tab				_merge
	*** 1,294 not matched
	
	drop if			_merge == 2
	drop			_merge
	
* unique district id
	sort			region district
	egen			uq_dist = group(region district)
	distinct		uq_dist
	*** 129 distinct ditricts
	
* must merge in regional identifiers from 2012_AG_SEC_3A to impute
	merge			1:1 y2_hhid plotnum using "$root/AG_SEC3A"
	*** everything matches - no drops from using
	
	drop if			_merge == 2
	drop			_merge
	
* record if field was cultivated during long rains
	gen 			status = ag3a_03==1 if ag3a_03!=.
	lab var			status "=1 if field cultivated during long rains"
	*** 4,902 observations were cultivated (68%)
	
* drop observations that were not cultivated
	drop if			status == 0
	*** dropped 1,136 observations that were not cultivated in long rains
	
	drop			ag3a_02_1- status
	
	
* ***********************************************************************
* 3 - clean and impute plot size
* ***********************************************************************
	
* interrogating plotsize variables
	count 		if plotsize_gps != . & plotsize_self != .
	*** 3,941 not mising, out of 6,038
	
	pwcorr 		plotsize_gps plotsize_self
	*** high correlation (0.7562)

* inverstingating the high and low end of gps measurments
	* high end
		tab			plotsize_gps
		*hist		plotsize_gps if plotsize_gps > 2
		sum			plotsize_gps, detail
		*** mean = 1.061
		*** 90% of obs < 2.34
		
		sort		plotsize_gps
		sum 		plotsize_gps if plotsize_gps > 2.3
		*** 403 obs > 2.3
		
		list		plotsize_gps plotsize_self if plotsize_gps > 2.3 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps > 2.3 & ///
						!missing(plotsize_gps)
		*** corr = 0.6652 (not terrible)
		
		sum 		plotsize_gps if plotsize_gps>3.95
		*** 184 obs > 3.95
		
		list		plotsize_gps plotsize_self if plotsize_gps > 3.95 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps > 3.95 & ///
						!missing(plotsize_gps)
		*** corr = 0.6375 (still not terrible)
	 	
		sum 		plotsize_gps if plotsize_gps > 20
		*** 11 obs > 20
		
		list		plotsize_gps plotsize_self if plotsize_gps > 20 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps > 20 & ///
						!missing(plotsize_gps)
		*** corr = 0.6777 (still not terrible)
	
	* low end
		tab			plotsize_gps
		*hist		plotsize_gps if plotsize_gps < 0.5
		sum			plotsize_gps, detail
		*** mean = 1.061
		*** 10% of obs < 0.085
		
		sum 		plotsize_gps if plotsize_gps<0.085
		*** 409 obs < 0.085
		
		list		plotsize_gps plotsize_self if plotsize_gps<0.09 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.09 & ///
						!missing(plotsize_gps)
		*** corr = 0.0498 (very very low correlation)
		
		sum 		plotsize_gps if plotsize_gps<0.05
		*** 201 obs < 0.05
		
		list		plotsize_gps plotsize_self if plotsize_gps<0.05 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.05 & ///
						!missing(plotsize_gps)
		*** corr = -0.0716 (negative and still very very low)
		
		tab			plotsize_gps if plotsize_gps<0.01
		*** 25 obs w/ plotsize_gps < 0.01 (including four zero values)
		
		list		plotsize_gps plotsize_self if plotsize_gps<0.01 & ///
						!missing(plotsize_gps), sep(0)
		pwcorr		plotsize_gps plotsize_self if plotsize_gps<0.01 & ///
						!missing(plotsize_gps)
		*** these all take values of 0, 0.0040469, or 0.0080937 
		*** (meaning pre-conversion values of 0, 0.01, or 0.02)
	
	* will drop the '0' values, to be imputed later
		replace 	plotsize_gps = . if plotsize_gps == 0
		*** 2 changes made
		
		pwcorr		plotsize_gps plotsize_self if plotsize_gps < 0.01 & ///
							!missing(plotsize_gps)
		*** this correlation is the same as before zeros were dropped
		
		count		if plotsize_gps < 0.01 & plotsize_gps != .
		*** 23 obs < 0.01
		*** again I see values of 0, 0.0040469, or 0.0080937 many times 
		*** meaning pre-conversion values of 0, 0.01, or 0.02
		*** I will not drop any low end values at this time
		
		
* impute missing + irregular plot sizes using predictive mean matching
* imputing 1,319 observations (out of 6,038) - 21.85% 
* including plotsize_self as control
	mi set 		wide 	// declare the data to be wide.
	mi xtset	, clear 	// this is a precautinary step to clear any xtset that the analyst may have had in place previously
	mi register	imputed plotsize_gps // identify plotsize_GPS as the variable being imputed
	sort		y2_hhid plotnum, stable // sort to ensure reproducability of results
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
	*** imputed 963 values out of 4,902 total observations
	
	sum				plotsize_self plotsize_gps	plotsize
	*** self reported	:	mean 0.95 and s.d. 1.97
	*** gps				:	mean 1.06 and s.d. 2.19
	*** imputed			:	mean 1.05 and s.d. 2.14
	
	drop			if plotsize == . & plotsize_self ==.
	*** no observations dropped


* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************
	
* keep what we want, get rid of the rest
	keep			y2_hhid plotnum plot_id region district ward ///
						ea y2_rural clusterid strataid hhweight ///
						mover_R1R2 location_R1_to_R2 plotnum plot_id plotsize
						
	order			y2_hhid plotnum plot_id clusterid strataid hhweight ///
						region district ward ea y2_rural mover_R1R2 ///
						location_R1_to_R2 plotsize
						
* renaming and relabelling variables
	lab var		y2_hhid "Unique Household Identification NPS Y2"
	lab var		y2_rural "Cluster Type"
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
	isid			y2_hhid plotnum
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/AG_SEC2A.dta", replace
	
* close the log
	log	close

/* END */
