* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 2 (2012-2013), POST PLANTING, AG SECT11C2
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
	loc		root	=	"$data/household_data/nigeria/wave_2/raw"
	loc		export	=	"$data/household_data/nigeria/wave_2/refined"
	loc		logout	=	"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log 	using 	"`logout'/wave_2_pp_sect11c2", append
	

* **********************************************************************
* 1 - determine pesticide and herbicide use 
* **********************************************************************
		
* import the first relevant data file
	use				"`root'/sect11c2_plantingw2", clear 	

	describe
	sort			hhid plotid
	isid			hhid plotid

* binary for pesticide use
	rename			s11c2q1 pest_any
	lab var			pest_any "=1 if any pesticide was used"

* binary for herbicide use
	rename			s11c2q10 herb_any
	lab var			herb_any "=1 if any herbicide was used"

* check if any missing values
	mdesc			pest_any herb_any
	*** 13 pest and 11 herb missing, change these to "no"
	
* convert missing values to "no"
	replace			pest_any = 2 if pest_any == .
	replace			herb_any = 2 if herb_any == .

	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					pest_any herb_any tracked_obs
	
* create unique household-plot identifier
	isid			hhid plotid
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"
	
	compress
	describe
	summarize 

* save file
	save 			"`export'/pp_sect11c2.dta", replace

* close the log
	log	close

/* END */