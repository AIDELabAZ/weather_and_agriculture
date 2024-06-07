* Project: WB Weather
* Created on: May 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 3, (2015-2016) POST HARVEST, NIGERIA SECTA3i
	* determines harvest information (area and quantity) 
	* maize is the second most widely cultivated crop
	* converts to kilograms and constant 2015 USD
	* outputs clean data file ready for combination with wave 3 hh data

* assumes
	* access to all raw data
	* land-conversion.dta conversion file
	
* TO DO:
	* complete

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc 	root		= 	"$data/household_data/nigeria/wave_3/raw"
	loc		cnvrt		=	"$data/household_data/nigeria/conversion_files"
	loc 	export 		= 	"$data/household_data/nigeria/wave_3/refined"
	loc 	logout 		= 	"$data/household_data/nigeria/logs"

* open log
	cap 	log 		close
	log 	using		"`logout'/ph_secta1", append

	
* **********************************************************************
* 1 - determine area harvested
* **********************************************************************

* import the first relevant data file
	use 					"`root'/secta3i_harvestw3", clear

	describe
	sort 				hhid plotid cropid
	isid 				hhid plotid cropid
		
	tab 			cropcode	
	*** cassava is most widely cropped 16.41% wont use cassava as main crop
	*** maize is second most widely cropped 14.38% we use maize as main crop
	
	tab sa3iq4
	
	* drop observations in which it was not harvest season
	drop if sa3iq4	==	9	|	sa3iq4	==	10	|	sa3iq4	==	11
	***1450 deleted
	
	replace sa3iq6i 	= 	0 	if 	sa3iq6i	==	. 	& 	sa3iq3	==	2
	***228 changes
	replace sa3iq6a 	= 	0 	if 	sa3iq6a	==	. 	& 	sa3iq3	==	2
	***228 changes
	
	* drop if missing both harvest quantities and harvest value
	drop if 	sa3iq6a	==	. 	& 	sa3iq6i	==	.
	***12 deleted
	
	* replace missing value if quantity is not missing
	replace			sa3iq6a = 0 if sa3iq6a == . & sa3iq6i != .
	***33 changes
	
* replace missing quantity if value is not missing
	replace			sa3iq6i = 0 if sa3iq6i == . & sa3iq6a != .
	***no changes
	
	* check to see if there are missing observations for quantity and value
	mdesc 			sa3iq6i sa3iq6a
	*** no missing values
	
	describe
	sort 			hhid plotid cropid
	isid 			hhid plotid cropid

	* **********************************************************************
* 2 - generate harvested values
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

* convert 2015 Naria to constant 2015 USD
	replace			vl_hrv = vl_hrv/192.4403
	lab var			vl_hrv 	"total value of harvest in 2015 USD"
	*** value comes from World Bank: world_bank_exchange_rates.xlxs

* summarize value of harvest
	sum				vl_hrv, detail
	*** median 97.56, mean 253.16, max 28292.72

* replace any +3 s.d. away from median as missing
	replace			vl_hrv = . if vl_hrv > `r(p50)'+(3*`r(sd)')
	*** replaced 149 values, max is now 1951.22
	
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
	***imputed 149 observations out of 10,494
	*** mean from 201 to 203, max = 1951
	
* **********************************************************************
* 3 - generate maize harvest quantities
* **********************************************************************

* merge harvest conversion file
	merge 			m:1 cropcode harv_unit using "`cnvrt'/harvconv_wave_3" 
	
	*** WILL NEED TO USE DIFFERENT FILE THAN PREVIOUS - alj will update file appropriately but file in folder named here should work 
	*** 9069 matched
	*** of those 1425 not matched, of those 92 are maize
	*** of those 92, 65 did not harvest and 7 who did harvest had a crop failure - so should set those equal to zero 
	*** okay with mismatch in using - not every crop and unit are used in the master 
	*** we are concerned about the maize values that had a harvest but did not convert we change their harvest amount to missing and impute them later
	
	*maize harvest amount if merge failed
	tab sa3iq3 if cropcode==1080 & _merge==1
	***12 maize did harvest and did not match and 44 did not harvest and did not match
	tab sa3iq6i if cropcode==1080 & _merge==1 & sa3iq3==2
	*** 44 did not harvest and they recorded 0 for quantity harvested
	
	* 1 observation claimed to harvest but recorded 0 for their harvest change their "did you harvest?" response to "no"
	replace sa3iq3=2 if cropcode==1080 & _merge==1 & sa3iq6i==0 & sa3iq3==1
	*** 1 change made
	
	* the remaining maize observations that did harvest but did not record the harv_unit and did not merge conversion will be changed to missing for imputing
	replace sa3iq6i=. if cropcode==1080 & _merge==1 & sa3iq3==1
	*** 11 changes made
	
* change those with a crop failure or no harvest to 0 quantity harvest and 0 harvest value
	count if sa3iq3==2 & _merge==1
	***228 failed to match and had no harvest, convert those to zero harvest amount and value
	
	replace vl_hrv=0 if sa3iq3==2 & _merge==1
	replace sa3iq6i=0 if sa3iq3==2 & _merge==1
	replace sa3iq6a=0 if sa3iq3==2 & _merge==1
	replace harv_unit=. if sa3iq3==2 & _merge==1
	*** values were already 0, no changes made.
	
		tab harvestq if vl_hrv==. & sa3iq6i==. & sa3iq6a==. 
		
	*ensure that harvest values and quantities are zero if you failed to harvest and harvest quantities and harvest values are missing
	replace vl_hrv=0 if vl_hrv==. & sa3iq6i==. & sa3iq6a==. & harvestq==.
	***368 real changes made


* drop unmerged using
	drop if			_merge == 2


	
* converting harvest quantities to kgs
	gen 			harv_kg = harvestq*conversion
	mdesc 			harv_kg if harv_unit==1080
	*** no missing maize

* replace other types of maize to all have the same crop code
	replace			cropcode = 1080 if cropcode > 1079 & cropcode < 1084
	*** 59 changes made
	
* check to see if outliers can be dealt with
	by harv_unit	, sort: sum harv_kg if 	cropcode == 1080
	*** kg is high the max is 20000
	*** small sack is too large max is 5456, the mean is possible 400
	***medium sack/bag is too large max is 31618 the mean is possible 800
	*** large sack/bag seems wrong max is 76320 the mean is a bit high 1600
	*** max heap is 2300 but heaps can be very large
	*** all others seem reasonable
	

* generate new variable that measures maize (1080) harvest
	gen 			mz_hrv = harv_kg 	if 	cropcode == 1080
	gen				mz_damaged = 1		if  cropcode == 1080 ///
						& mz_hrv == 0
						
* summarize value of harvest
	sum				mz_hrv, detail
	*** median 395, mean 948, max 70,000

* replace any +3 s.d. away from median as missing
	replace			mz_hrv = . if mz_hrv > `r(p50)' + (3*`r(sd)')
	sum				mz_hrv, detail
	*** replaced 10 values, max is now 8,545
	
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
	*** imputed 71 values out of 1,778 total observations
	mdesc 			mz_hrv if harv_unit==1080
		*** no missing maize observations

* rename cultivated variable
	rename 			sa3iq3 cultivated
		
* replace non-maize harvest values as missing
	replace			mz_hrv = . if mz_damaged == 0 & mz_hrv == 0

	
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
	save 			"`export'/ph_secta3i.dta", replace

* close the log
		log	close

/* END */
