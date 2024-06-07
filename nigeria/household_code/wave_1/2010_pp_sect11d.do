* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 1 (2010-2011) POST PLANTING, NIGERIA SECT 11D AG - fertilizer
	* determines fertilizer use / measurement
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
	loc root = "$data/household_data/nigeria/wave_1/raw"
	loc export = "$data/household_data/nigeria/wave_1/refined"
	loc logout = "$data/household_data/nigeria/logs"

* close log (in case still open)
	*log close
	
* open log	
	cap log close
	log using "`logout'/pp_sect11d", append

	
* **********************************************************************
* 1 - determine fertilizer use 
* **********************************************************************
		
* import the first relevant data file
		use "`root'/sect11d_plantingw1", clear 

	describe
	sort hhid plotid
	isid hhid plotid

* binary for fert use
	rename s11dq1 fert_any 
	label variable fert_any "=1 if any fertilizer was used"

* removing observations that use manure
	drop if s11dq3==3 | s11dq3==4
	drop if s11dq7==3 | s11dq7==4
	drop if s11dq14==3
	drop if s11dq25==3
	***143 dropped

* quantity of fertilizer from different sources
	*** the quantity is giving in kgs so no conversion is needed
	
	* leftover fertilizer
	generate leftover_fert_kg = s11dq4
	sum leftover_fert_kg
	*** mean is 88 and max is 750, max and mean seem too high
	replace leftover_fert_kg = 0 if leftover_fert_kg ==.

	* free fertilizer
	gen free_fert_kg=s11dq8
	sum free_fert_kg
	*** mean is 80 and max is 800, again max and mean is too high
	replace free_fert_kg = 0 if free_fert_kg ==. 

	* purchased fert
	gen purchased_fert_kg1=s11dq15
	sum purchased_fert_kg1
	***mean is 110 and max is 999, both seem high but max seems especially high
	replace purchased_fert_kg1 = 0 if purchased_fert_kg1 ==. 

	gen purchased_fert_kg2=s11dq26
	sum purchased_fert_kg2
	*** mean is 45 and max is 99, looks good.
	replace purchased_fert_kg2 = 0 if purchased_fert_kg2 ==. 

	
* generate variable for total fertilizer use
	generate fert_used_kg = leftover_fert_kg + free_fert_kg + purchased_fert_kg1 + purchased_fert_kg2
	label variable fert_used_kg "fertilizer use (kg)"

* summarize fertilizer
	sum				fert_use, detail
	*** mean 41 and max is 999

* replace any +3 s.d. away from median as missing
	replace			fert_use = . if fert_use > `r(p50)'+(3*`r(sd)')
	*** replaced 182 values, max is now 265
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed fert_use // identify kilo_fert as the variable being imputed
	sort			hhid plotid, stable // sort to ensure reproducability of results
	mi impute 		pmm fert_use i.state, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset
	*** no values were imputed
	
* check for missing values
	mdesc			fert_any fert_used_kg	
	*** 18 fert_any missing no fert_use missing
	
* convert missing values to "no"
	replace			fert_any = 2 if fert_any == .

* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					fert_any fert_used_kg

* create unique household-plot identifier
	isid			hhid plotid
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"
	
	compress
	describe
	summarize 
	
* save file
	save 			"`export'/pp_sect11d.dta", replace

* close the log
	log	close

/* END */