* Project: WB Weather
* Created on: Feb 2024
* Created by: jet
* Edited on: 27 May 2024
* Edited by: reece
* Stata v.18

* does
	* reads in Nigeria, WAVE 4 (2018-2019) POST PLANTING, NIGERIA AG SECT11F
	* determines planting month and year

* assumes
	* customsave.ado
	
* TO DO:
	* everything
	
* **********************************************************************
* 0 - setup
* **********************************************************************
* define paths	
	global root		"$data/household_data/nigeria/wave_4/raw"
	global export	"$data/household_data/nigeria/wave_4/refined"
	global logout	"$data/household_data/nigeria/logs"

* close log (in case still open)
	*log close
	
* open log	
	cap log close
	log using "$logout/2018_pp_sect11f", append

* **********************************************************************
* 1 - determine plot size
* **********************************************************************
		
* import the first relevant data file
		use "$root/sect11f_plantingw4", clear 

describe
sort hhid plotid cropcode
isid hhid plotid cropcode, missok


* **********************************************************************
* 2 - determine planting year and months 
* **********************************************************************

*rename month and year
rename 			s11fq3_1 month 
lab var			month "planting month"

rename 			s11fq3_2 year
lab var			year "planting year"


* check that month and year make sense
	tab				month
	*** vast majority are in March-June
	*** this aligns with FAO planting season
	tab year
	*** 95.52% are in 2018, we will drop those from years before 2017
	drop if year<=2016
* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************


compress
describe
summarize 

* save file
	save 			"$export/pp_sect11f.dta", replace

* close the log
	log	close

/* END */
