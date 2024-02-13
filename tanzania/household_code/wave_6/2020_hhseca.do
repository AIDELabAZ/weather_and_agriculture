* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Stata v.16

* does
	* cleans Tanzania household variables, wave 4 hh secA
	* pulls regional identifiers

* assumes
	* customsave.ado

* TO DO:
	* completed

* NOTES: 
	* panel refresh in 2014, is a cross section not connected to waves 1-3

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc	root	=	"$data/household_data/tanzania/wave_4/raw"
	loc export	=	"$data/household_data/tanzania/wave_4/refined"
	loc logout	=	"$data/household_data/tanzania/logs"

* open log
	cap log close 
	log	using	"`logout'/wv4_HHSECA", append

* ***********************************************************************
* 1 - TZA 2014 (Wave 4) - Household Section A
* *********************1*************************************************

* load data
	use 		"`root'/hh_sec_a", clear
	
* dropping duplicates
	duplicates 	drop
	*** 0 obs dropped
	
	drop y4_rural 
	
* renaming some variables
	rename		hh_a01_1 region
	rename		hh_a02_1 district
	rename		hh_a03_1 ward
	rename		hh_a04_1 ea
	rename		y4_weights y4_weight
	rename		clustertype y4_rural

* keep variables of interest
	keep 		y4_hhid region district ward ea y4_rural ///
					clusterid strataid y4_weight 

	order		y4_hhid region district ward ea y4_rural ///
					clusterid strataid y4_weight 
	
	rename		y4_weight hhweight
	
* relabel variables
	lab var		y4_hhid "Unique Household Identification NPS Y4"
	lab var		region "Region Code"
	lab var		district "District Code"
	lab var		ward "Ward Code"
	lab var		ea "Village / Enumeration Area Code"
	lab var		y4_rural "Cluster Type"
	lab var		clusterid "Unique Cluster Identification"
	lab var		strataid "Design Strata"
	lab var		hhweight "Household Weights (Trimmed & Post-Stratified)"
					
* prepare for export
	compress
	describe
	summarize
	sort y4_hhid
	
	customsave , idvar(y4_hhid) filename(HH_SECA.dta) ///
		path("`export'") dofile(2014_HHSECA) user($user)

* close the log
	log	close

/* END */
