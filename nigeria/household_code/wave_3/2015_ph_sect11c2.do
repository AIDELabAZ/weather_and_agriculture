* Project: WB Weather
* Created on: May 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 3 (2015-2016), POST HARVEST, AG SECT11C2
	* creates binaries for pesticide and herbicide use
	* outputs clean data file ready for combination with wave 2 plot data

* assumes
	* access to all raw data
	* mdesc.ado
	
* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************
	
* define paths	
	loc root = "$data/household_data/nigeria/wave_3/raw"
	loc export = "$data/household_data/nigeria/wave_3/refined"
	loc logout = "$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "`logout'/ph_sect11c2", append

	
* **********************************************************************
* 1 - determine pesticide, herbicide, etc.
* **********************************************************************
		
* import the first relevant data file
		use "`root'/secta11c2_harvestw3", clear 	

describe
sort hhid plotid 
isid hhid plotid

*binary for pesticide use since the new year
	rename s11c2q1 pest_any
	lab var			pest_any "=1 if any pesticide was used"

	*binary for herbicide use since the new year
	rename s11c2q10 herb_any
	lab var			herb_any "=1 if any herbicide was used"

* check if any missing values
	mdesc			pest_any herb_any
	*** 16 pest and 16 herb missing, change these to "no"
	
* convert missing values to "no"
	replace			pest_any = 2 if pest_any == .
	replace			herb_any = 2 if herb_any == .

* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					pest_any herb_any 
	
* create unique household-plot identifier
	isid			hhid plotid
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"

compress
describe
summarize 

* save file
	save 			"`export'/ph_sect11c2.dta", replace

* close the log
	log	close

/* END */