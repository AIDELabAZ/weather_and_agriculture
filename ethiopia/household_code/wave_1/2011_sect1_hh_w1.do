* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Stata v.16

* does
	* cleans Ethiopia household variables, wave 1 HH sec1
	* gives location identifiers for participants
	* hierarchy: holder > parcel > field > crop - not a concern in this dofile
	* seems to very roughly correspond to Malawi ag-modI and ag-modO
	
* assumes
	* customsave.ado
	* distinct.ado

* TO DO:
	* 


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc root = "$data/household_data/ethiopia/wave_1/raw"
	loc export = "$data/household_data/ethiopia/wave_1/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	log using "`logout'/wv1_HHSEC1", append
	
	
**********************************************************************************
**	1 - preparing ESS 20??/?? (Wave 1) - Household Section 1
**********************************************************************************

* load data
	use 		"`root'/sect1_hh_w1.dta", clear

* dropping duplicates
	duplicates	drop
	
* individual_id is unique identifier	
	describe
	sort 		household_id individual_id
	isid 		individual_id


/* drop observations with a missing field_id
	summarize 	if missing()
	drop 		if missing()
	isid 		household_id individual_id */

* creating unique district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 69 distincct districts
	
	
* ***********************************************************************
* 2 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid
	rename 		saq01 region
	rename 		saq02 zone
	rename 		saq03 woreda
	rename 		saq07 ea
	
* restrict to variables of interest
	keep  		hhid- hh_s1q00 district_id
	order 		hhid- saq08
	
* prepare for export
	isid		individual_id
	compress
	describe
	summarize 
	sort hhid ea_id
	customsave , idvar(individual_id) filename(HH_SEC1.dta) path("`export'") ///
		dofile(HH_SEC1) user($user)

* close the log
	log	close

/* END */