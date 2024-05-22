* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in sdd panel key
	* generates new id
	* outputs new sdd panel key

* assumes
	* access to raw data

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		cnvrt	=	"$data/household_data/tanzania/wave_6/raw"
	global		import	=	"$data/household_data/tanzania"
	global		export	=	"$data/household_data/tanzania/wave_6/refined"
	global		logout 	= 	"$data/household_data/tanzania/logs"

* open log	
	cap log 	close 
	log 		using 		"$logout/tza_sdd_panel_key", append


* **********************************************************************
* 1 - process panel id key
* **********************************************************************

* read in data
	use			"$cnvrt/npssdd.panel.key.dta", clear
	
	compress
	recast 		int sdd_indid
	format 		%5.0g sdd_indid
	recast 		int indidy1
	format 		%5.0g indidy1
	recast 		int indidy2
	format 		%5.0g indidy2
	recast 		int indidy3
	format 		%5.0g indidy3
	lab drop 	indidy3
	recast 		int indidy4
	format 		%5.0g indidy4
	lab drop 	indidy4
	
	drop if y1_hhid == "" & y2_hhid == "" & y3_hhid == "" & y4_hhid == "" & sdd_hhid == ""
	** 0 dropped
	drop if y1_hhid != "" & y2_hhid == "" & y3_hhid == "" & y4_hhid == "" & sdd_hhid == ""
	** 894 dropped
	drop if y1_hhid == "" & y2_hhid != "" & y3_hhid == "" & y4_hhid == "" & sdd_hhid == ""
	** 541 dropped
	drop if y1_hhid == "" & y2_hhid == "" & y3_hhid != "" & y4_hhid == "" & sdd_hhid == ""
	** 5,472 dropped
	drop if y1_hhid == "" & y2_hhid == "" & y3_hhid == "" & y4_hhid != "" & sdd_hhid == ""
	** 293 dropped
	drop if y1_hhid == "" & y2_hhid == "" & y3_hhid == "" & y4_hhid == "" & sdd_hhid != ""
	** 1,741 dropped
	
* encode missing as 1 to help with duplicate drops
	replace		indidy1 = 1 if indidy1 == .
	replace		indidy2 = 1 if indidy2 == .
	replace		indidy3 = 1 if indidy3 == .
	replace		indidy4 = 1 if indidy4 == .
	replace		sdd_indid = 1 if sdd_indid == .
	
* drop additional individuals in households from sdd round
	keep if		sdd_indid == 1
	** dropped 2,845
	
* drop additional individuals in households from 4xp round
	replace		sdd_indid = . if sdd_hhid == ""
	keep if		indidy4 == 1 | (indidy4 != 1 & sdd_indid == 1)
	** dropped 485

* drop additional individuals in households from 3rd round
	replace		indidy4 = . if y4_hhid == ""
	keep if		indidy3 == 1 | (indidy3 != 1 & indidy4 == 1) | ///
					(indidy3 != 1 & sdd_indid == 1)
	** dropped 12,893

* drop additional individuals in households from 2rd round
	replace		indidy3 = . if y3_hhid == ""
	keep if		indidy2 == 1 | (indidy2 != 1 & indidy3 == 1) | ///
					(indidy2 != 1 & indidy4 == 1) | (indidy2 != 1 & sdd_indid == 1)
	** dropped 1,286

* drop additional individuals in households from 2rd round	
	replace		indidy2 = . if y2_hhid == ""
	keep if		indidy1 == 1 | (indidy1 != 1 & indidy2 == 1) | ///
					(indidy1 != 1 & indidy3 == 1) | (indidy1 != 1 & indidy4 == 1) | ///
					(indidy1 != 1 & sdd_indid == 1)
	** dropped 791
	
* drop individual ids and all duplicate household records
	drop		UPI indidy1 indidy2 indidy3 indidy4 sdd_indid
	duplicates 	drop
	*** this gets us 4,897 unique households

* **********************************************************************
* 2 - merge in household id data
* **********************************************************************
	
* merge in regional variables from wave 1
	rename		y1_hhid hhid
	merge		m:1 hhid using "$import\wave_1\refined\HH_SECA.dta"
	*** only 3,880 matched, 196 not matched in using
	*** there are 3,265 unique hh in wave 1, so we have 615 ``too many'' (movers)
	
	drop if		_merge == 2
	drop		_merge
	rename		hhid y1_hhid
	
* merge in regional variables from wave 2
	merge		m:1 y2_hhid using "$import\wave_2\refined\HH_SECA.dta"
	*** only 4,567 matched, 116 not matched in using
	*** there are 3,924 unique hh in wave 2, so we have 643 ``too many'' (movers)
	
	drop if		_merge == 2
	drop		_merge
	
* merge in regional variables from wave 3
	merge		m:1 y3_hhid using "$import\wave_3\refined\HH_SECA.dta"
	*** only 4,532 matched, 711 not matched in using
	*** there are 5,010 unique hh in wave 3, so we have 478 ``too many'' (movers)
	
	drop if		_merge == 2
	drop		_merge
	
* merge in regional variables from wave 4xp
	merge		m:1 y4_hhid using "$import\wave_5\refined\HH_SECA.dta"
	*** only 1,119 matched, 31 not matched in using
	*** there are 989 unique hh in wave 4xp, so we have 130 ``too many'' (movers)
	
	drop if		_merge == 2
	drop		_merge
	
* merge in regional variables from wave sdd
	merge		m:1 sdd_hhid using "$import\wave_6\refined\HH_SECA.dta"
	*** only 1,001 matched, 183 not matched in using
	*** there are 1,184 unique hh in wave 5-sdd, so we have 183 ``too few'' (non-panel)
	
	drop if		_merge == 2
	drop		_merge
	
* drop unnecessary variables
	keep		y1_hhid y2_hhid y3_hhid y4_hhid sdd_hhid
	
* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************

	
* saving production dataset
	compress
	save 		"$export/sdd_panel_key.dta", replace
	
* close the log
	log	close

/* END */