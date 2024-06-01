* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 1 (2010-2011), POST PLANTING
	* determines planting month and year
	* planting dates look ok, so we don't need anything from this file

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* complete 
	

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root = "$data/household_data/nigeria/wave_1/raw"
	loc export = "$data/household_data/nigeria/wave_1/refined"
	loc logout = "$data/household_data/nigeria/logs"

* close log (in case still open)
	*log close
	
* open log	
	cap log close
	log using "`logout'/pp_sect11f", append

	
* **********************************************************************
* 1 - general clean up, renaming, etc. 
* **********************************************************************
		
* import the first relevant data file
	use 	"`root'/sect11F_plantingw1", clear 	
	
	describe
	sort		hhid plotid cropid
	isid		hhid plotid cropid

* rename month and year
	rename 		s11fq3a month
	lab var		month "planting month"
	
	rename 		s11fq3b year
	lab var		year "planting year"
	
* check that month and year make sense
	tab			month
	*** vast majority are in March-July, consistent with FAO planting months

	tab			year
	***96% are the correct year and a small number have years that dont make sense.
	mdesc 		year
	***5% of observations are missing year
	
*dropping thpse years that dont make sense
	drop if year<2009
	*** 64 observations deleted
	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

* save file
	save 		"`export'/pp_sect11f.dta", replace

* close the log
	log	close

/* END */