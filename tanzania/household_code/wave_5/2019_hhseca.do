* Project: WB Weather
* Created on: March 2024
* Created by: reece
* Edited on: March 19, 2024
* Edited by: reece
* Stata v.18

* does
	* cleans Tanzania household variables, wave 5 hh secA
	* pulls regional identifiers

* assumes
	* customsave.ado

* TO DO:
	*

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root		"$data/household_data/tanzania/wave_5/raw"
	global export		"$data/household_data/tanzania/wave_5/refined"
	global logout		"$data/household_data/tanzania/logs"

* open log
	cap log close 
	log	using	"$logout/wv5_HHSECA", append

*************************************************************************
**#1 - TZA 2014 (Wave 4) - Household Section A
***********************1*************************************************

* load data
	use 		"$root/hh_sec_a", clear
	
* dropping duplicates
	duplicates 	drop
	*** 0 obs dropped
	
* renaming some variables
	rename		t0_region region
	rename		t0_district district
	rename		t0_ward_code ward
	rename		t0_ea_codee ea
	rename		sdd_weights sdd_weight
	
* fill in region, district, ward, ea for split households
	replace		region = hh_a01_1 if hh_a10 == 2
	replace		district = hh_a02_1 if hh_a10 == 2
	replace		ward = hh_a03_1 if hh_a10 == 2
	replace		ea = hh_a04_1 if hh_a10 == 2
	
* keep variables of interest
	keep 		sdd_hhid region district ward ea sdd_rural ///
					clusterid strataid sdd_weight 

	order		sdd_hhid region district ward ea sdd_rural ///
					clusterid strataid sdd_weight 
	
	rename		sdd_weight hhweight
	
* relabel variables
	lab var		sdd_hhid "Unique Household Identification NPS Y4"
	lab var		region "Region Code"
	lab var		district "District Code"
	lab var		ward "Ward Code"
	lab var		ea "Village / Enumeration Area Code"
	lab var		sdd_rural "Cluster Type"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
					
* prepare for export
	compress
	describe
	summarize
	sort sdd_hhid
	
	save 			"$export/HH_SECA.dta", replace

* close the log
	log	close

/* END */