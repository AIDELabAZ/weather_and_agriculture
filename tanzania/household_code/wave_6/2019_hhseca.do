* Project: WB Weather
* Created on: March 2024
* Created by: reece
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 6 (NPSY5-SDD) hh secA
	* pulls regional identifiers

* assumes
	* access to all raw data

* TO DO:
	* done

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root		"$data/household_data/tanzania/wave_6/raw"
	global export		"$data/household_data/tanzania/wave_6/refined"
	global logout		"$data/household_data/tanzania/logs"

* open log
	cap log close 
	log	using	"$logout/wv6_HHSECA", append

*************************************************************************
**#1 - TZA 2019 (Wave 6) - Household Section A
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
	rename		hh_a10 mover2019
	
* fill in region, district, ward, ea for split households
	replace		region = hh_a01_1 if mover2019 == 2
	replace		district = hh_a02_1 if mover2019 == 2
	replace		ward = hh_a03_1 if mover2019 == 2
	replace		ea = hh_a04_1 if mover2019 == 2
	
* keep variables of interest
	keep 		sdd_hhid region district ward ea sdd_rural ///
					clusterid strataid sdd_weight y4_hhid mover2019

	order		y4_hhid sdd_hhid region district ward ea sdd_rural ///
					clusterid strataid sdd_weight mover2019
	
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
	lab var		mover2019 "Original or split household"
					
* prepare for export
	compress
	describe
	summarize
	sort sdd_hhid
	
	save 			"$export/HH_SECA.dta", replace

* close the log
	log	close

/* END */