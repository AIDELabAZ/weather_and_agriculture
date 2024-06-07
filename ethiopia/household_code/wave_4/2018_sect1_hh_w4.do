* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 4 HH sec1
	* gives location identifiers for participants
	* hierarchy: holder > parcel > field > crop - not a concern in this dofile
	* seems to very roughly correspond to Malawi ag-modI and ag-modO
	
* assumes
	* access to raw data
	* distinct.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global		root 		 	"$data/household_data/ethiopia/wave_4/raw"  
	global		export 		 	"$data/household_data/ethiopia/wave_4/refined"
	global		logout 		 	"$data/household_data/ethiopia/logs"
	
* open log	
	cap log 	close
	log 		using			"$logout/wv4_HHSEC1", append

	
* **********************************************************************
* 1 - preparing ESS 2018/19 (Wave 4) - Household Section 1 
* **********************************************************************

* load data
	use 		"$root/sect1_hh_w4.dta", clear

* dropping duplicates
	duplicates 	drop

* individual_id2 is unique identifier 
	describe
	sort 		household_id individual_id
	isid 		household_id individual_id

* create district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 105 distinct districts


* ***********************************************************************
* 2 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid
	rename 		saq01 region
	rename 		saq02 zone
	rename 		saq03 woreda
	rename		saq07 ea
	rename		saq14 sector

* destring zone and woreda
	destring	zone, replace
	destring	woreda, replace
	destring	ea, replace
	
* restrict to variables of interest
	keep  		hhid- woreda ea
	
* prepare for export
	isid		hhid individual_id
	compress
	describe
	summarize 
	sort hhid ea_id
	
	save 		"$export/HH_SEC1.dta", replace

* close the log
	log	close

/* END */
