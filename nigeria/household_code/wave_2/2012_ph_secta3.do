* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 29 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 2 (2012-2013), POST HARVEST, AG SECTA3
	* determines primary and secondary crops, cleans harvest (quantity and value)
	* converts to kilograms and constant 2015 USD
	* outputs clean data file ready for combination with wave 2 plot data

* assumes
	* access to all raw data
	* mdesc.ado
	* harvconv.dta conversion file

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc 	root	= 	"$data/household_data/nigeria/wave_2/raw"
	loc		cnvrt	=	"$data/household_data/nigeria/conversion_files"
	loc 	export	= 	"$data/household_data/nigeria/wave_2/refined"
	loc 	logout	= 	"$data/household_data/nigeria/logs"

* open log
	cap 	log 	close
	log 	using 	"`logout'/wave_2_ph_secta3", append

	
* **********************************************************************
* 1 - general clean up, renaming, etc.
* **********************************************************************

* import the first relevant data file
	use 			"`root'\secta3_harvestw2.dta" , clear

	tab 			cropcode
	*** main crop is "cassava old"
	*** not going to use cassava instead we use maize

* find out who is not harvesting and why
	tab				sa3q3
	tab				sa3q4
	tab				sa3q4b
	
* drop observations in which it was not harvest season
	drop if 		sa3q4 == 9 | sa3q4 == 10 | sa3q4 == 11
	*** drops 2517 observations

* convert missing harvest data to zero if harvest was lost to event
	replace			sa3q6a1 = 0 if sa3q6a1 == . & sa3q4 < 9
	replace			sa3q18  = 0 if sa3q18  == . & sa3q4 < 9
	*** 443 missing changed to 0

* drop if missing both quantity and values
	drop			if sa3q6a1 == . & sa3q18 == .
	*** dropped 49 observations

* replace missing quantity if value is not missing
	replace			sa3q6a1 = 0 if sa3q6a1 == . & sa3q18 != .
	*** 21 missing changed to zero
	
* replace missing value if quantity is not missing
	replace			sa3q18 = 0 if sa3q18 == . & sa3q6a1 != .
	*** 79 missing changed to zero
	
* check to see if there are missing observations for quantity and value
	mdesc 			sa3q6a1 sa3q18
	*** no missing values
	
	describe
	sort 			hhid plotid cropid
	isid 			hhid plotid cropid
	
* **********************************************************************
* 2 - generate harvested values
* **********************************************************************

* create quantity harvested variable
	gen 			harvestq = sa3q6a1
	lab	var			harvestq "quantity harvested, not in standardized unit"

* units of harvest
	rename 			sa3q6a2 harv_unit
	tab				harv_unit, nolabel
	rename 			sa3q3 cultivated

* create value variable
	gen 			crop_value = sa3q18
	rename 			crop_value vl_hrv

* convert 2013 Naria to constant 2015 USD
	replace			vl_hrv = vl_hrv/183.3461
	lab var			vl_hrv 	"total value of harvest in 2015 USD"
	*** value comes from World Bank: world_bank_exchange_rates.xlxs

* summarize value of harvest
	sum				vl_hrv, detail
	*** median 226, mean 105, max 13,654

* replace any +3 s.d. away from median as missing
	replace			vl_hrv = . if vl_hrv > `r(p50)'+(3*`r(sd)')
	*** replaced 111 values, max is now 1,054
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed vl_hrv // identify kilo_fert as the variable being imputed
	sort			hhid plotid cropid, stable // sort to ensure reproducability of results
	mi impute 		pmm vl_hrv i.state i.cropid, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss
	tabstat			vl_hrv vl_hrv_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			vl_hrv = vl_hrv_1_
	lab var			vl_hrv "Value of harvest (2015 USD), imputed"
	drop			vl_hrv_1_
	*** imputed 172 values out of 10,382 total observations
	
* **********************************************************************
* 3 - generate maize harvest quantities
* **********************************************************************

* merge harvest conversion file
	merge 			m:1 cropcode harv_unit using "`cnvrt'/harvconv_wave_2.dta"
	*** matched 9633 but didn't match 2799 (from master 749 and using 2050)
	*** okay with mismatch in using - not every crop and unit are used in the master 
		
* drop unmerged using
	drop if			_merge == 2
	* dropped 2050

* check into 306 unmatched from master
	mdesc			harv_unit if _merge == 1
	tab 			harv_unit if _merge == 1
	*** 465 unmatched missing harv_unit, all but one are zeros (assume other is kg)
	*** 211 unmatched are already in kgs, so these are okay
	*** 73 unmatched have strange units

* dropped unmatched with missing or strange units
	drop if			_merge == 1 & harv_unit != 1
	*** dropped 95 observations (73 + 22)

	drop 			_merge

* make sure no missing values in conversion
	mdesc			conversion
	tab 			harv_unit if conversion == .
	*** there are 211 missing conversion factors
	*** all of these are kg

* replace missing conversion factors with 1 (for kg)
	replace			conversion = 1 if conversion == .
	mdesc			conversion
	*** no more missing
	
* converting harvest quantities to kgs
	gen 			harv_kg = harvestq*conversion
	mdesc 			harv_kg
	*** no missing

* replace other types of maize to all have the same crop code
	replace			cropcode = 1080 if cropcode > 1079 & cropcode < 1084
	
* check to see if outliers can be dealt with
	by harv_unit	, sort: sum harv_kg if 	cropcode == 1080
	*** grams seem to be wrong (mean of 61066)
	*** max for large sack is high too (13,000)
	*** as are wheelbarrow and pick up (4,400; 6,000; 26,000; 15,000)
	*** all others seem reasonable
	
* deal with grams 
	sort 			cropcode harv_unit
	replace			harv_kg = harv_kg/1000 if harv_unit == 2 & ///
						sa3q6a1 > 500 & cropcode == 1080
	*** 4 values changed
	
* deal with sack and barrow etc 
	sort 			cropcode harv_unit harv_kg
	replace			harv_kg = 3000 if sa3q6a1 == 130 & cropcode == 1080
	*** 1 value changed, the other high values may be plausible

* generate new variable that measures maize (1080) harvest
	gen 			mz_hrv = harv_kg 	if 	cropcode == 1080
	gen				mz_damaged = 1		if  cropcode == 1080 ///
						& mz_hrv == 0
						
* summarize value of harvest
	sum				mz_hrv, detail
	*** median 400, mean 886, max 40,000

* replace any +3 s.d. away from median as missing
	replace			mz_hrv = . if mz_hrv > `r(p50)' + (3*`r(sd)')
	*** replaced 17 values, max is now 6,600
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed mz_hrv // identify kilo_fert as the variable being imputed
	sort			hhid plotid cropid, stable // sort to ensure reproducability of results
	mi impute 		pmm mz_hrv i.state if cropcode == 1080, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss1 if cropcode == 1080
	tabstat			mz_hrv mz_hrv_1_ if cropcode == 1080, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			mz_hrv = mz_hrv_1_  if cropcode == 1080
	lab var			mz_hrv "Quantity of maize harvested (kg)"
	drop			mz_hrv_1_
	*** imputed 17 values out of 1,422 total observations									

	
* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************

* keep what we want, get rid of what we don't
	keep 				zone state lga sector ea hhid plotid cropid ///
							cropname cropcode cultivated ///
							mz_hrv vl_hrv mz_damaged
							
* check for duplicates
	duplicates		report hhid plotid cropid
	*** there are 0 duplicates
	*** would drop if some existed

* create unique household-plot-crop identifier
	isid			hhid plotid cropid
	sort			hhid plotid cropid
	egen			cropplot_id = group(hhid plotid cropid)
	lab var			cropplot_id "unique crop-plot identifier"
	
* create unique household-plot identifier
	sort			hhid plotid 
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"
	
	compress
	describe
	summarize

* save file
	save			"`export'/ph_secta3.dta", replace

* close the log
	log		close

/* END */
