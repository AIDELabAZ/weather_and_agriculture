* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 3 HH sec1
	* gives location identifiers for participants
	* hierarchy: holder > parcel > field > crop - not a concern in this dofile
	* seems to very roughly correspond to Malawi ag-modI and ag-modO
	
* assumes
	* raw lsms-isa data
	* distinct.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc root = "$data/household_data/ethiopia/wave_3/raw"
	loc export = "$data/household_data/ethiopia/wave_3/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv3_HHSEC1", append

	
* **********************************************************************
* 1 - preparing ESS 2015/16 (Wave 3) - Household Section 1 
* **********************************************************************

* load data
	use 		"`root'/sect1_hh_w3.dta", clear

* dropping duplicates
	duplicates 	drop

* individual_id2 is unique identifier 
	describe
	sort 		household_id2 individual_id2
	isid 		individual_id2, missok

* creating district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 84 distinct districts


* ***********************************************************************
* 2 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid
	rename 		household_id2 hhid2
	rename 		saq01 region
	rename 		saq02 district
	label var 	district "District Code"
	rename 		saq03 woreda
	rename		saq07 ea

* restrict to variables of interest
	keep  		hhid- hh_s1q00 district_id
	order 		hhid- saq08
	
* prepare for export
	isid		individual_id2
	compress
	describe
	summarize 
	sort hhid ea_id
	save 		"`export'/HH_SEC1.dta", replace
* close the log
	log	close

/* END */
