* Project: WB Weather
* Created on: Feb 2024
* Created by: jet
* Edited on: May 17, 2024
* Edited by: reece
* Stata v.18

* does
	* reads in Nigeria, WAVE 4 (2018-2019), POST HARVEST, AG SECT11C2
	* creates binaries for pesticide and herbicide use, fertilizer variables
	* outputs clean data file ready for combination with wave 4 plot data

* assumes
	* customsave.ado
	* mdesc.ado
	
* TO DO:
	* fertilizer variables
	
* **********************************************************************
* 0 - setup
* **********************************************************************
	
* define paths	
	global root			"$data/household_data/nigeria/wave_4/raw"
	global export		"$data/household_data/nigeria/wave_4/refined"
	global logout		"$data/household_data/nigeria/logs"

* close log (in case still open)
	*log close
	
* open log	
	cap log close
	log using "$logout/ph_sect11c2", append

* **********************************************************************
* 1 - determine pesticide, herbicide, etc.
* **********************************************************************
		
* import the first relevant data file
		use "$root/secta11c2_harvestw4", clear 	

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
	*** 1 pest and 1 herb missing, change these to "no"
	
* convert missing values to "no"
	replace			pest_any = 2 if pest_any == .
	replace			herb_any = 2 if herb_any == .

* **********************************************************************
* 2 - generate fertilizer variables
* **********************************************************************

*binary for fert use
	gen fert_any = 1 if s11dq1a == 1
	lab var			fert_any "=1 if any fertilizer was used"

*drop manure/compost observations
	drop if s11c2q36_os=="COMPOST"
	***0 observations deleted
	
* quantity of fertilizer 
	*NPK use
	gen 			npk_kg = s11c2q37a
	replace			npk_kg = npk_kg*s11c2q37a_conv
	
	*UREA use
	gen 			urea_kg = s11c2q38a
	replace			urea_kg = urea_kg*s11c2q38a_conv
	
	*other fert use
	gen				other_fert_kg = s11c2q39a
	replace			other_fert_kg = other_fert_kg*s11c2q39a_conv
	*converted fertilizer use to kgs
	
	*total fertilizer use
	egen			fert_use = rsum (npk_kg urea_kg other_fert_kg)
	lab var			fert_use "fertilizer use (kg)"		
	
	tab 			fert_use
	***4 huge outliers
	***outliers from urea, values are very large before conversion

	replace  		fert_use = . if fert_use > 5000
	
* summarize fertilizer
	sum				fert_use, detail
	***median 0, mean 44.50, max 3500
	***8293 observations 

* replace any +3 s.d. away from median as missing
	replace			fert_use = . if fert_use > `r(p50)'+(3*`r(sd)')
	***125 changes made
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed fert_use // identify kilo_fert as the variable being imputed
	sort			hhid plotid, stable // sort to ensure reproducability of results
	mi impute 		pmm fert_use i.state, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset
	
* how did the imputation go?
	tab				mi_miss
	tabstat			fert_use fert_use_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			fert_use = fert_use_1_
	lab var			fert_use "fertilizer use (kg), imputed"
	drop			fert_use_1_
	*** imputed 129 values out of 8293 total observations
	*** mean 33.90, maximum 400 (min still = 0)
	
* check for missing values
	mdesc			fert_any fert_use	
	*** 5505 fert_any missing, 0 fert_use missing
	
* convert missing values to "no"
	replace			fert_any	=	2	if	fert_any	==	.
	*** 5505 changes made
	replace 		fert_use	=	2	if 	fert_use	==	.
	*** 0 changes made 

* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					pest_any herb_any fert_any fert_use
	
* create unique household-plot identifier
	isid			hhid plotid
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"

compress
describe
summarize 

* save file
	save			"$export/ph_sect11c2.dta", replace

* close the log
	log	close

/* END */