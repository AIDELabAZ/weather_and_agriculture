* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 1 hh secA
	* pulls regional identifiers
	
* assumes
	* access to all raw data

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global 			root 	"$data/household_data/tanzania/wave_1/raw"
	global 			export 	"$data/household_data/tanzania/wave_1/refined"
	global 			logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log 		close 
	log 			using 	"$logout/wv1_HHSECA", append

* ***********************************************************************
* 1 - TZA 2008 (Wave 1) - Household Section A
* *********************1*************************************************

* load data
	use 		"$root/SEC_A_T", clear
	
* dropping duplicates
	duplicates 	drop
	*** 0 obs dropped

* keep variables of interest
	keep		hhid hh_weight clusterid strataid ///
					region district ward ea ///
					locality
					
* rename variables
	rename		hh_weight hhweight
	rename		locality y1_rural
	
	order		hhid region district ward ea y1_rural ///
					clusterid strataid hhweight
	
* relabel variables
	lab var		hhid "Unique Household Identification NPS Y1"
	lab var		region "Region Code"
	lab var		district "District Code"
	lab var		ward "Ward Code"
	lab var		ea "Village / Enumeration Area Code"
	lab var		y1_rural "Cluster Type"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
	
* prepare for export
	compress
	describe
	summarize 
	sort hhid
	
	save 			"$export/HH_SECA.dta", replace
	

* close the log
	log	close

/* END */
