* Project: WB Weather
* Created on: May 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 3 (2015-2016), POST HARVEST, NIGERIA AG SECT11D - Fertilizer
	* determines fertilizer use / measurement
	* outputs clean data file ready for combination with wave 2 plot data

* assumes
	* access to all raw data
	* mdesc.ado
	
* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc root = "$data/household_data/nigeria/wave_3/raw"
	loc export = "$data/household_data/nigeria/wave_3/refined"
	loc logout = "$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "`logout'/ph_sect11d", append

	
* **********************************************************************
* 1 - determine fertilizer and conversion to kgs
* **********************************************************************
		
* import the first relevant data file
		use "`root'/secta11d_harvestw3", clear 

describe
sort hhid plotid 
isid hhid plotid

*binary for fert use
rename s11dq1 fert_any
	lab var			fert_any "=1 if any fertilizer was used"

*drop manure/compost observations
	tab sect11dq7
	tab s11dq15 
	tab s11dq27
	tab s11dq3
	drop if s11dq15==3
	***1 observation deleted
	drop if s11dq15_os=="COMPOST"
	***1 observation deleted
	
* quantity of fertilizer from different sources

* leftover fertilizer
	gen				leftover_fert_kg = s11dq4a
	replace 		leftover_fert_kg = leftover_fert_kg/1000 if s11dq4b==2
	*** convert grams to kgs - 5 obs (divide to get kgs)
	sum 			leftover_fert_kg
	***maximum observation is 300, average 55.45 kg 
	replace			leftover_fert_kg = 0 if leftover_fert_kg ==.

* free fertilizer
	gen				free_fert_kg = sect11dq8a
	replace 		free_fert_kg=free_fert_kg/1000 if sect11dq8b==2
	sum				free_fert_kg
	***maximum observation is 200, average is 49.21 kg 
	*** OMITTED IN ROUND 2 - CAN ALSO PLAN TO OMIT HERE FOR CONSISTENCY 
	replace			free_fert_kg = 0 if free_fert_kg ==. 

*purchased fertilizer
	gen				purchased_fert_kg1 = s11dq16a
	replace purchased_fert_kg1 = purchased_fert_kg1/1000 if s11dq16b==2
	sum				purchased_fert_kg1
	*** observations are too high - max = 2000 kg, mean is 90.96 kgs
	*** mean is okay, but max is a bit high 
	***  max value is too high but will keep it and deal with by winsorizing

	gen				purchased_fert_kg2 = s11dq28a
	replace purchased_fert_kg2 = purchased_fert_kg2/1000 if s11dq28b==2
	sum				purchased_fert_kg2
	*** max observation is 250, mean is 55.37 

	replace			purchased_fert_kg1 = 0 if purchased_fert_kg1 ==. 
	replace			purchased_fert_kg2 = 0 if purchased_fert_kg2 ==. 

* the survey divides the fertilizer into left over, received for free, and purchased so here I combine them
* generate variable for total fertilizer use
	egen			fert_use	= rsum (leftover_fert_kg purchased_fert_kg1 purchased_fert_kg2) 
	lab var			fert_use "fertilizer use (kg)"
	*** omit free fertilizer 

* summarize fertilizer
	sum				fert_use, detail
	*** median 0, mean 32.584, max 2000
	*** only 5914 observations 

* replace any +3 s.d. away from median as missing
	replace			fert_use = . if fert_use > `r(p50)'+(3*`r(sd)')
	*** 5 changes made
	
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
	*** imputed 114 values out of 5,914 total observations
	*** impute went fine - mean - 24.3 and maximum 250 (min still = 0)
	
* check for missing values
	mdesc			fert_any fert_use	
	*** 9 fert_any missing 0 fert_use missing
	
* convert missing values to "no"
	replace			fert_any	=	2	if	fert_any	==	.
	*** 9 changes made
	replace 		fert_use	=	2	if 	fert_use	==	.
	*** 0 changes made 

* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************

	keep 			hhid zone state lga sector hhid ea plotid ///
					fert_any fert_use

* create unique household-plot identifier
	isid			hhid plotid
	sort			hhid plotid
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"
	
	compress
	describe
	summarize 
	
* save file
	save 			"`export'/ph_sect11d.dta", replace

* close the log
	log	close

/* END */