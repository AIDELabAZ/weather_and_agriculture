* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 1 (2010-2011) POST PLANTING, NIGERIA SECT 11C
	* creates binaries for pesticide and herbicide use
	* outputs clean data file ready for combination with wave 1 plot data

* assumes
	* access to all raw data
	* mdesc.ado
	
* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=	"$data/household_data/nigeria/wave_1/raw"
	loc		export	=	"$data/household_data/nigeria/wave_1/refined"
	loc		logout	=	"$data/household_data/nigeria/logs"
	
* close log (in case still open)
	*log close
	
* open log	
	cap log close
	log using "`logout'/pp_sect11c", append

	
* **********************************************************************
* 1 - determine pesticide and herbicide use 
* **********************************************************************
		
* import the first relevant data file
	use "`root'/sect11c_plantingw1", clear 	

	describe
	sort hhid plotid
	isid hhid plotid, missok


* binary for pesticide use
	rename			s11cq1 pest_any
	lab var			pest_any "=1 if any pesticide was used"

* binary for herbicide use
	rename			s11cq10 herb_any
	lab var			herb_any "=1 if any herbicide was used"

* check if any missing values
	mdesc			pest_any herb_any
	*** pest_any missing 6 and herb_any missing 26, change these to "no"
	
* convert missing values to "no"
	replace			pest_any = 2 if pest_any == .
	replace			herb_any = 2 if herb_any == .
	

* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					pest_any herb_any
	
* create unique household-plot identifier
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"

	
	compress
	describe
	summarize 

* save file
	save			"`export'/pp_sect11c.dta", replace
	
* close the log
	log	close

/* END */