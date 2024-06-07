* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: May 23 2024
* Edited by: reece
* Stata v.18

* does
	* reads in Nigeria, WAVE 4, (2018-2019) POST HARVEST, NIGERIA SECTA3i
	* determines harvest information (area and quantity) 
	* maize is the second most widely cultivated crop
	* converts to kilograms and constant 2015 USD
	* outputs clean data file ready for combination with wave 3 hh data

* assumes
	* land-conversion.dta conversion file
	
* TO DO:
	* complete

* **********************************************************************
**#0 - setup
* **********************************************************************

* define paths	
	global root			"$data/household_data/nigeria/wave_4/raw"
	*global cnvrt		"$data/household_data/nigeria/conversion_files"
	global export		"$data/household_data/nigeria/wave_4/refined"
	global logout		"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "$logout/ph_secta3i", append


* **********************************************************************
**#1 - determine area harvested
* **********************************************************************

* import the first relevant data file
	use 					"$root/secta3i_harvestw4", clear

	describe
	sort 				hhid plotid cropcode
	isid 				hhid plotid cropcode
		
	tab 			cropcode	
	*** cassava is most widely cropped 20.94% wont use cassava as main crop
	*** maize is second most widely cropped 18.98% we use maize as main crop
	
	tab sa3iq4
	
	* drop observations in which it was not harvest season
	drop if sa3iq4	==	9	|	sa3iq4	==	10	|	sa3iq4	==	11
	***2630 deleted
	
	replace sa3iq6i 	= 	0 	if 	sa3iq6i	==	. 	& 	sa3iq3	> 0
	***601 changes
	replace sa3iq6a 	= 	0 	if 	sa3iq6a	==	. 	& 	sa3iq3	> 0
	***601 changes
	
	* drop if missing both harvest quantities and harvest value
	drop if 	sa3iq6a	==	. 	& 	sa3iq6i	==	.
	***0 deleted
	
	* replace missing value if quantity is not missing
	replace			sa3iq6a = 0 if sa3iq6a == . & sa3iq6i != .
	***0 changes
	
* replace missing quantity if value is not missing
	replace			sa3iq6i = 0 if sa3iq6i == . & sa3iq6a != .
	***0 changes
	
	* check to see if there are missing observations for quantity and value
	mdesc 			sa3iq6i sa3iq6a
	*** no missing values
	
	describe
	sort 			hhid plotid cropcode
	isid 			hhid plotid cropcode

	* **********************************************************************
**#2 - generate harvested values
* **********************************************************************

* create quantity harvested variable
	gen 			harvestq = sa3iq6i
	lab	var			harvestq "quantity harvested, not in standardized unit"
	
* units of harvest
	rename 			sa3iq6ii harv_unit
	tab				harv_unit, nolabel

* create value variable
	gen 			crop_value = sa3iq6a
	rename 			crop_value vl_hrv

* convert 2018 Naria to constant 2015 USD
	replace			vl_hrv = vl_hrv/302.8046 
	lab var			vl_hrv 	"total value of harvest in 2015 USD"
	*** value comes from World Bank: world_bank_exchange_rates.xlxs

* summarize value of harvest
	sum				vl_hrv, detail
	*** median 66, mean 170, max 23,117

* replace any +3 s.d. away from median as missing
	replace			vl_hrv = . if vl_hrv > `r(p50)'+(3*`r(sd)')
	*** replaced 122 values, max is now 1585
	
	* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed vl_hrv // identify kilo_fert as the variable being imputed
	sort			hhid plotid cropcode, stable // sort to ensure reproducability of results
	mi impute 		pmm vl_hrv i.state i.cropcode, add(1) rseed(245780) ///
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
	***imputed 122 observations out of 11566
	*** mean from 137 to 139, max = 1585
	
* **********************************************************************
**#3 - generate maize harvest quantities
* **********************************************************************
	
* converting harvest quantities to kgs
	gen 			harv_kg = harvestq*sa3iq6_conv
	mdesc 			harv_kg if cropcode == 1080
	*** 123 missing maize
	
* replace harv_kg as zero if there was no harvest
	replace			harv_kg = 0 if sa3iq3 == 2
	
* three missing conversion factors
	replace			harv_kg = harvestq*2.7072 if harv_kg == . ///
						& cropcode == 1080 & sa3iq6_4 == 1
	replace			harv_kg = harvestq*1.3482 if harv_kg == . ///
						& cropcode == 1080 & sa3iq6_4 == 0
	*** 3 changes made	
	
* check to see if outliers can be dealt with
	by harv_unit	, sort: sum harv_kg if 	cropcode == 1080
	*** kg is high the max is 3000
	*** sac is high max is 20000
	*** max heap is 1710
	*** all others seem reasonable
	
* generate new variable that measures maize (1080) harvest
	gen 			mz_hrv = harv_kg 	if 	cropcode == 1080
	gen				mz_damaged = 1		if  cropcode == 1080 ///
						& mz_hrv == 0
						
* summarize value of harvest
	sum				mz_hrv, detail
	*** median 200, mean 584, max 20,000

* replace any +3 s.d. away from median as missing
	replace			mz_hrv = . if mz_hrv > `r(p50)' + (3*`r(sd)')
	sum				mz_hrv, detail
	*** replaced 61 values, max is now 3600
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed mz_hrv // identify kilo_fert as the variable being imputed
	sort			hhid plotid cropcode, stable // sort to ensure reproducability of results
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
	*** imputed 61 values out of 2665 total observations
	mdesc 			mz_hrv if harv_unit==1080
		*** no missing maize observations

* rename cultivated variable
	rename 			sa3iq3 cultivated
		
* replace non-maize harvest values as missing
	replace			mz_hrv = . if mz_damaged == 0 & mz_hrv == 0

	
* **********************************************************************
**#4 - end matter, clean up to save
* **********************************************************************

* keep what we want, get rid of what we don't
	keep 				zone state lga sector ea hhid plotid ///
							 cropcode cultivated ///
							mz_hrv vl_hrv mz_damaged
							
* check for duplicates
	duplicates		report hhid plotid cropcode
	*** there are 0 duplicates
	*** would drop if some existed

* create unique household-plot-crop identifier
	isid			hhid plotid cropcode
	sort			hhid plotid cropcode
	egen			cropplot_id = group(hhid plotid cropcode)
	lab var			cropplot_id "unique crop-plot identifier"
	
* create unique household-plot identifier
	sort			hhid plotid 
	egen			plot_id = group(hhid plotid)
	lab var			plot_id "unique plot identifier"
	
	compress
	describe
	summarize

* save file
	save 			"$export/ph_secta3i.dta", replace

* close the log
		log	close

/* END */
