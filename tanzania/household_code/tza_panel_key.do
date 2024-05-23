* Project: WB Weather
* Created on: June 2020
* Created by: jdm
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* SUPERSCEDED BY tza_sdd_panel_key. DO NOT USE THIS FILE
	* reads in panel key
	* generates new id
	* outputs new panel key

* assumes
	* access to raw data

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		cnvrt	=	"$data/household_data/tanzania/wave_3/raw"
	global		import	=	"$data/household_data/tanzania"
	global		export	=	"$data/household_data/tanzania/wave_3/refined"
	global		logout 	= 	"$data/household_data/tanzania/logs"

* open log	
	cap log close 
	log 	using 		"$logout/tza_panel_key", append


* **********************************************************************
* 1 - process panel id key
* **********************************************************************

* read in data
	use			"$cnvrt/NPSY3.PANEL.KEY.dta", clear

* drop duplicate individuals in households
	keep if		indidy3 == 1
	
* drop individual ids and all duplicate household records
	drop		indidy1 indidy2 indidy3 UPI3
	duplicates 	drop
	*** this gets us 5,010 unique households

* merge in regional variables from wave 3
	merge		1:1 y3_hhid using "$import\wave_3\refined\HH_SECA.dta"
	*** all variables merge
	
	drop		_merge
	
* merge in regional variables from wave 1
	rename		y1_hhid hhid
	merge		m:1 hhid using "$import\wave_1\refined\HH_SECA.dta"
	*** only 284 not used
	
	drop if		_merge == 2
	drop		_merge

	rename		hhid y1_hhid
	
* merge in regional variables from wave 2
	merge		m:1 y2_hhid using "$import\wave_2\refined\HH_SECA.dta"
	*** only 231 not used
	
	drop if		_merge == 2
	drop		_merge
	
* drop unnecessary variables
	drop		y3_rural clusterid strataid hhweight mover_R1R2R3 ///
					location_R2_to_R3 y1_rural y2_rural mover_R1R2 ///
					location_R1_to_R2
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

* verify unique household id
	isid		y3_hhid

	compress
	describe
	summarize 
	*** missing 3 ward observations and 8 ea observations
	
* saving production dataset
	save 		"$export/panel_key.dta", replace
	
* close the log
	log	close

/* END */