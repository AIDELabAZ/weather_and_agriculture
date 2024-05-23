* Project: WB Weather
* Created on: Aug 2020
* Created by: themacfreezie
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* household Location data (2011_GSEC1) for the 1st season

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* done

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 		 "$data/household_data/uganda/wave_3/raw"  
	global export 		 "$data/household_data/uganda/wave_3/refined"
	global logout 		 "$data/household_data/uganda/logs"
	
* open log	
	cap 				log close
	log using 			"$logout/2011_GSEC1", append

	
*+**********************************************************************
**# 1 - UNPS 2011 (Wave 3) - General(?) Section 1 
************************************************************************

* import wave 3 season 1
	use				"$root/GSEC1", clear

* rename variables
	isid 			HHID
	rename 			HHID hhid

	rename 			h1aq1 district
	rename 			h1aq2 county
	rename 			h1aq3 subcounty
	rename 			h1aq4 parish
	rename 			HHS_hh_shftd_dsntgrtd hh_status2011
	rename 			mult wgt11
	***	district variables not labeled in this wave, just coded

	tab 			region, missing

* drop if missing
	drop if			district == ""
	*** dropped 164 observations
	
	
************************************************************************
**# 2 - end matter, clean up to save
************************************************************************

	keep 			hhid region district county subcounty parish ///
						hh_status2011 wgt11

	compress
	describe
	summarize

* save file
	save 			"$export/2011_GSEC1.dta", replace

* close the log
	log	close

/* END */	
