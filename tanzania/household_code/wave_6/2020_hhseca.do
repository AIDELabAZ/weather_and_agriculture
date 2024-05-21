* Project: WB Weather
* Created on: Feb 2024
* Created by: reece
* Edited on: Feb 16 2024
* Edited by: reece
* Stata v.18

* does
	* cleans Tanzania household variables, wave 6 hh secA
	* pulls regional identifiers

* assumes
	* customsave.ado

* TO DO:
	* complete

************************************************************************
**#0 - setup
************************************************************************

* define paths
	global	root		"$data/household_data/tanzania/wave_6/raw"
	global export		"$data/household_data/tanzania/wave_6/refined"
	global logout		"$data/household_data/tanzania/logs"

* open log
	cap log close 
	log	using	"$logout/wv6_HHSECA", append

*************************************************************************
**#1 - TZA 2020 (Wave 6) - Household Section A
***********************1*************************************************

* load data
	use 		"$root/hh_sec_a", clear
	
* dropping duplicates
	duplicates 	drop
	*** 0 obs dropped

* renaming some variables
	rename		hh_a01_1 region
	rename		hh_a02_1 district
	rename		y5_panelweight hhweight

* keep variables of interest
	keep 		y5_hhid region district y5_rural ///
					clusterid strataid hhweight 

	order		y5_hhid region district y5_rural ///
					clusterid strataid hhweight
	
* relabel variables
	lab var		y5_hhid "Unique Household Identification NPS Y5"
	lab var		region "Region Code"
	lab var		district "District Code"
	lab var		y5_rural "Cluster Type"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
					
* prepare for export
	compress
	describe
	summarize
	sort y5_hhid
	
	save 			"$export/HH_SECA.dta", replace

* close the log
	log	close

/* END */
