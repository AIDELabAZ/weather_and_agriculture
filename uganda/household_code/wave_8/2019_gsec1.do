* Project: WB Weather
* Created on: Aug 2020
* Created by: themacfreezie
* Edited on: 24 May 24
* Edited by: jdm
* Stata v.18

* does
	* household Location data (2019_GSEC1) for the 1st season

* assumes
	* access to raw data 
	* mdesc.ado

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 			root 	"$data/household_data/uganda/wave_8/raw"  
	global 			export 	"$data/household_data/uganda/wave_8/refined"
	global 			logout 	"$data/household_data/uganda/logs"
	
* open log	
	cap 			log 	close
	log 			using 	"$logout/2019_GSEC1", append

	
***********************************************************************
**# 1 - UNPS 2019 (Wave 8) - General(?) Section 1 
***********************************************************************

* import wave 8 season 1
	use				"$root/hh/GSEC1", clear

	isid 			hhid
	
* rename variables
	rename			hhidold hh
	rename 			s1aq02a county
	rename 			s1aq03a subcounty
	rename 			s1aq04a parish
	rename 			wgt wgt19

	tab 			region, missing
	*** 3 households with missing regions, two of which we can replace
	
	replace 		region = 3 if region == . & district == "NEBBI"
	replace 		region = 1 if region == . & district == "KAMPALA"
	
	replace 		subreg = 11 if subreg == . & district == "NEBBI"
	replace 		subreg = 1 if subreg == . & district == "KAMPALA"

	
	drop if 		region == .	
	*** 1 observation deleted
	
* drop if missing
	drop if			district == ""
	*** dropped 0 observations
	
	
***********************************************************************
**# 2 - end matter, clean up to save
***********************************************************************

	keep 			hhid hh region district county subcounty parish ///
						wgt19 subreg
	compress
	describe

* save file
		save		"$export/2019_gsec1.dta", replace 

* close the log
	log	close

/* END */	
