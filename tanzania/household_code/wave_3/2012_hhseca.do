* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 3 hh secA
	* pulls regional identifiers

* assumes
	* access to all raw data

* TO DO:
	* completed


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root		"$data/household_data/tanzania/wave_3/raw"
	global export		"$data/household_data/tanzania/wave_3/refined"
	global logout		"$data/household_data/tanzania/logs"

* open log
	cap log 			close 
	log					using	"$logout/wv3_HHSECA", append

* ***********************************************************************
* 1 - TZA 2012 (Wave 3) - Household Section A
* ***********************************************************************

* load data
	use 		"$root/HH_SEC_A", clear
	
* dropping duplicates
	duplicates 	drop
	*** 0 obs dropped

* renaming some variables
	rename		hh_a01_1 region
	rename		hh_a02_1 district
	rename		hh_a03_1 ward
	rename		hh_a04_1 ea
	
* keep variables of interest
	keep 		y3_hhid y3_weight clusterid strataid ///
					region district ward ea ///
					y3_rural hh_a10 hh_a11

* generate mover/stayer
	gen			mover_R1R2R3 = 0 if hh_a10 == 1
	replace		mover_R1R2R3 = 1 if hh_a10 == 2
	lab var		mover_R1R2R3 "Household moved from its original 2008 sample"
	lab def		yesno 0 "No" 1 "Yes"
	lab val		mover_R1R2R3 yesno

* generate location variable
	rename		hh_a11 location_R2_to_R3	
	lab var		location_R2_to_R3 "Household location category"
	
	drop		hh_a10

	order		y3_hhid region district ward ea y3_rural ///
					clusterid strataid y3_weight mover_R1R2R3 location_R2_to_R3	

	rename		y3_weight hhweight
	
* relabel variables
	lab var		y3_hhid "Unique Household Identification NPS Y3"
	lab var		region "Region Code"
	lab var		district "District Code"
	lab var		ward "Ward Code"
	lab var		ea "Village / Enumeration Area Code"
	lab var		y3_rural "Cluster Type"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
					
* prepare for export
	compress
	describe
	summarize
	sort y3_hhid
	*** missing 3 ward values, 8 ea values 
	
	save 			"$export/HH_SECA.dta", replace

* close the log
	log	close

/* END */
