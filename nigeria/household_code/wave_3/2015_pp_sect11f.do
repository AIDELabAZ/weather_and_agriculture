* Project: WB Weather
* Created on: May 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 3 (2015-2016) POST PLANTING, NIGERIA AG SECT11F
	* determines planting month and year

* assumes
	* access to all raw data
	
* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************
* define paths	
	loc root = "$data/household_data/nigeria/wave_3/raw"
	loc export = "$data/household_data/nigeria/wave_3/refined"
	loc logout = "$data/household_data/nigeria/logs"

* close log (in case still open)
	*log close
	
* open log	
	cap log close
	log using "`logout'/pp_sect11f", append

	
* **********************************************************************
* 1 - determine plot size
* **********************************************************************
		
* import the first relevant data file
		use "`root'/sect11f_plantingw3", clear 

describe
sort hhid plotid cropid
isid hhid plotid cropid, missok


* **********************************************************************
* 2 - determine planting year and months 
* **********************************************************************

*rename month and year
rename 			s11fq3a month 
lab var			month "planting month"

rename 			s11fq3b year
lab var			year "planting year"


* check that month and year make sense
	tab				month
	*** vast majority are in March-June
	*** this aligns with FAO planting season
	*** roughly 7% are not in the FAO planting season
	tab year
	*** 97% are in 2015, we will drop those from years before 2014
	drop if year<=2013
* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************


compress
describe
summarize 

* save file
	save 			"`export'/pp_sect11f.dta", replace

* close the log
	log	close

/* END */
