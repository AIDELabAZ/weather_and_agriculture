* Project: WB Weather
* Created on: Feb 2024
* Created by: alj
* Edited on: 17 June 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop plot size (gps and self-report)

* assumes
	* access to MWI 6 raw data - PANEL
	
* TO DO:
	* done

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_6/raw"	
	loc		export 	= 	"$data/household_data/malawi/wave_6/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_hh_mod_a19", append

* **********************************************************************
* 1 - clean plot area 
* **********************************************************************

* load data
	use 			"`root'/hh_mod_a_filt_19.dta", clear

	
* keep what we need
	keep			y4_hhid y3_hhid HHID case_id ea_id hh_wgt
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************
	
	compress
	describe
	summarize 
	
* save data
	save 			"`export'/hh_mod_a_filt_19.dta", replace

* close the log
	log			close


/* END */
