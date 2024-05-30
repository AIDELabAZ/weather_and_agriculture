* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 29 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 1 (2010-2011), POST HARVEST, NGA SECTA3 AG 
	* determines primary and secondary crops, cleans harvest (quantity and value)
	* converts to kilograms and constant 2015 USD
	* outputs clean data file ready for combination with wave 1 plot data

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
	loc 	root 		= 		"$data/household_data/nigeria/wave_1/raw"
	loc 	cnvrt 		=		"$data/household_data/nigeria/conversion_files"
	loc 	export 		= 		"$data/household_data/nigeria/wave_1/refined"
	loc 	logout 		= 		"$data/household_data/nigeria/logs"

* close log 
	*log close
	
* open log	
	cap log close
	log using "`logout'/wave_1_ph_secta3", append
		

* **********************************************************************
* 1 - harvest information
* **********************************************************************

* import the first relevant data file
	use 		"`root'/secta3_harvestw1", clear 	

	rename 		sa3q2 cropcode
	tab 		cropcode
	*** main crop is "cassava old" 
	*** cassava is continuous cropping, so not using that as a main crop
	*** going to use maize, which is second most cultivated crop
	
	drop		if cropcode == . 
	***33 observations deleted
	rename 		sa3q1 cropname
	
*find out who is not harvesting
	tab 	sa3q3
	
* drop observations in which it was not harvest season or nothing was planted that season
	tab		sa3q4
	drop if sa3q4==9
	***2,115 observations deleted
	
	drop if sa3q4b== "DID NOT PLANT IT" | sa3q4b=="FALLOW"  |   sa3q4b=="DRY SEASON PLANTING" 
	***2 observations deleted
	
* convert missing harvest data to zero if harvest was lost to event
	replace			sa3q6a = 0 if sa3q6a == . & sa3q4b!= "DID NOT PLANT IT" 
	***795 real changes made
	replace			sa3q6a = 0 if sa3q6a == . & sa3q4b!="FALLOW"  
	replace			sa3q6a = 0 if sa3q6a == . & sa3q4b!="DRY SEASON PLANTING"
	***0 changes made
	
	***value of harvest was not recorded in this wave.

* missing values for quantity of harvest
	mdesc sa3q6a
	*** no missing values

	describe
	sort 			hhid plotid cropid cropcode
	isid 			hhid plotid cropid cropcode, missok

	gen 			crop_area = sa3q5a
	label 			variable crop_area "what was the land area of crop harvested since the last interview? not using standardized unit"
	rename 			sa3q5b area_unit

* **********************************************************************
* 2 - conversion to kilograms
* **********************************************************************

* create quantity harvested variable
	gen 			harvestq = sa3q6a
	lab	var			harvestq "quantity harvested, not in standardized unit"

* units of harvest
	rename 			sa3q6b harv_unit
	tab				harv_unit, nolabel
	rename 			sa3q3 cultivated

	* create value variable
	gen 			crop_value = sa3q18
	rename 			crop_value vl_hrv

* convert 2013 Naria to constant 2015 USD
	replace			vl_hrv = vl_hrv/192.0423
	lab var			vl_hrv 	"total value of harvest in 2015 USD"
	*** value comes from World Bank: world_bank_exchange_rates.xlxs

	* summarize value of harvest
	sum				vl_hrv, detail
	*** median 103, mean 240, max 30570

* replace any +3 s.d. away from median as missing
	replace			vl_hrv = . if vl_hrv > `r(p50)'+(3*`r(sd)')
	*** replaced 135 values, max is now 1,900
	
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
	*** imputed 1214 values out of 10,868 total observations
	
* **********************************************************************
* 3 - generate maize harvest quantities
* **********************************************************************
	
	merge m:1 cropcode harv_unit using "`cnvrt'/harvconv_wave_1" 
	*** 1000 did not match from master
	
* drop unmerged using
	drop if			_merge == 2
	*** dropped 2105

* check into unmatched from master	
	tab 	harv_unit if _merge == 1
	drop 	if harv_unit==5
	***11 observations deleted
	***observations that did not match and were not missing the harv_unit were already in standard units.
	
*dropping observations with missing harv_unit
	mdesc	harv_unit if _merge == 1
	drop 	if harv_unit==.
	***1007 deleted
	
	drop _merge

* make sure no missing values in conversion
	mdesc			conversion
	tab 			harv_unit if conversion == .
	*** missing observations were missing because their units because their units were already standard
	
* replace missing conversion factors with 1 (for kg)
	replace			conversion = 1 if harv_unit == 1 & conversion==.
	***the above is the conversion for kgs
	replace 		conversion = 1 if harv_unit == 3 & conversion==.
	*** the above is the conversion for litres
	replace 		conversion = 1000 if harv_unit == 2 & conversion==.
	*** the above is the conversion for grams
	mdesc			conversion
	*** no more missing
	
*converting harvest quantities to kgs
	gen harv_kg = harvestq*conversion
	mdesc 			harv_kg
	*** no missing
	
* replace other types of maize to all have the same crop code
	replace			cropcode = 1080 if cropcode > 1079 & cropcode < 1084
	
* check to see if outliers can be dealt with
	by harv_unit	, sort: sum harv_kg if 	cropcode == 1080
	*** grams seem to be wrong (mean of 52,600)
	*** max for small, medium and large sack is high too (10,800; 7,500; 45,000)

* deal with grams 
	sort 			cropcode harv_unit
	replace			harv_kg = harv_kg/1000 if harv_unit == 2 & ///
						sa3q6a > 500 & cropcode == 1080
	*** 1 value changed
	
* generate new variable that measures maize (1080) harvest
	gen 			mz_hrv = harv_kg 	if 	cropcode == 1080
	gen				mz_damaged = 1		if  cropcode == 1080 ///
						& mz_hrv == 0
						
* summarize value of harvest
	sum 			mz_hrv, detail
* replace any +3 s.d. away from median as missing
	replace			mz_hrv = . if mz_hrv > `r(p50)' + (3*`r(sd)')
	*** replaced 20 values
	sum				mz_hrv
	*** mean 749, max 6000
	
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
	*** imputed 20 values out of 1,338 total observations									
	
* replace non-maize harvest values as missing
	replace			mz_hrv = . if mz_damaged == 0 & mz_hrv == 0

* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************

* keep what we want, get rid of what we don't
	keep 				zone state lga sector ea hhid plotid cropid harv_kg ///
					cropname cropcode cultivated mz_hrv vl_hrv mz_damaged
			
* check for duplicates
	duplicates		report hhid plotid cropid
	*** there are 3 duplicates
	sort			hhid plotid cropid
	quietly by hhid plotid cropid:  gen dup = cond(_N==1,0,_n)
	drop if dup>1
	*** 2 observations deleted

* create unique household-plot-crop identifier
	count if cropid==.
	***2 missing
	count if hhid==130019
	***1 observation meaning there is only one plot with one crop belonging to this hh
	count if hhid==280064
	***1 observation meaning there is only one plot with one crop belonging to this hh
	***we will replace the missing cropid's with 1
	
	replace cropid=1 if cropid==.
	*** 2 changes made
	
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
	save 			"`export'/ph_secta3.dta", replace
	
* close the log
	log	close

/* END */