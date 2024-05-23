* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 2 hh secA
	* pulls regional identifiers

* assumes
	* access to all raw data

* TO DO:
	* completed


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root		"$data/household_data/tanzania/wave_2/raw"
	global export		"$data/household_data/tanzania/wave_2/refined"
	global logout		"$data/household_data/tanzania/logs"

* open log
	cap log 			close 
	log					using	"$logout/wv2_HHSECA", append
	

* ***********************************************************************
* 1 - TZA 2010 (Wave 2) - Household Section A
* *********************1*************************************************

* load data
	use 		"$root/HH_SEC_A", clear
	
* dropping duplicates
	duplicates 	drop
	*** 0 obs dropped

* keep variables of interest
	keep 		y2_hhid y2_weight clusterid strataid ///
					region district ward ea ///
					y2_rural hh_a11

* generate mover/stayer
	gen			mover_R1R2 = 1 if hh_a11 == 3
	replace		mover_R1R2 = 0 if mover_R1R2 == .
	lab var	 	mover_R1R2 "Household moved from its original 2008 sample"
	lab def		yesno 0 "No" 1 "Yes"
	lab val		mover_R1R2 yesno
	
* generate location variable
	rename		hh_a11 location_R1_to_R2
	lab var		location_R1_to_R2 "Household location category"
	lab def		location 1 "Original household in same location" ///
					2 "Original household in new location" ///
					3 "Split-off household"
	lab val		location_R1_to_R2 location

* replace two miscoded observations 
	replace 	location_R1_to_R2 = 1 if location_R1_to_R2 == . 
	replace		location_R1_to_R2 = 1 if location_R1_to_R2 == 6 
	
	order		y2_hhid region district ward ea y2_rural ///
					clusterid strataid y2_weight mover_R1R2 location_R1_to_R2
					
	rename		y2_weight hhweight
	
* relabel variables
	lab var		y2_hhid "Unique Household Identification NPS Y2"
	lab var		region "Region Code"
	lab var		district "District Code"
	lab var		ward "Ward Code"
	lab var		ea "Village / Enumeration Area Code"
	lab var		y2_rural "Cluster Type"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
	
* prepare for export
	compress
	describe
	summarize
	sort y2_hhid
	
	save 			"$export/HH_SECA.dta", replace

* close the log
	log	close

/* END */
