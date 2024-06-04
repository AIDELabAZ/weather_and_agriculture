* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 1 (2010-2011) POST PLANTING, NIGERIA SECT 11B AG
	* determines irrigation 
	* outputs clean data file ready for combination with wave 1 plot data

* assumes
	* access to all raw data
	* mdsec.ado
	
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
	log using "`logout'/pp_sect11b", append

	
* **********************************************************************
* 1 - determine cultivated plot + irrigation 
* **********************************************************************
		
* import the first relevant data file
		use "`root'/sect11b_plantingw1", clear 	

	describe
	sort hhid plotid
	isid hhid plotid

* is this plot irrigated?
	rename			s11bq24 irr_any
	lab var			irr_any "=1 if any irrigation was used"
	
* check to see if values are missing
	mdesc			irr_any
	*** 431 missing observations, change these to "no"
	
* convert missing values to "no"
	replace			irr_any = 2 if irr_any == .

* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					irr_any

* create unique household-plot identifier
	isid			hhid plotid
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"
	
	compress
	describe
	summarize 


* save file
	save 			"`export'/pp_sect11b.dta", replace
* close the log
	log	close

/* END */