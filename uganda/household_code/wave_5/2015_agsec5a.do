* Project: WB Weather
* Created on: Feb 2024
* Created by: rg
* Edited on: 22 May 24
* Edited by: rg
* Stata v.18, mac

* does
	* Crop output
	* reads Uganda wave 5 crop output (2015_AGSEC5B) for the 1st season
	* 3A - 5A are questionaires for the second planting season
	* 3B - 5B are questionaires for the first planting season

* assumes
	* mdesc.ado
	* access to raw data

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  			"$data/household_data/uganda/wave_5/raw"  
	global  export 			"$data/household_data/uganda/wave_5/refined"
	global 	logout 			"$data/household_data/uganda/logs"
	global 	conv 			"$data/household_data/uganda/conversion_files"  

* open log	
	cap log 				close
	log using 				"$logout/2015_AGSEC5A", append

	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 5 season 1
	
	use 			"$root/agric/AGSEC5B.dta", clear
		
	rename 			cropID cropid
	rename			plotID pltid
	rename			parcelID prcid
	rename 			a5bq6c unit
	rename			a5bq6b condition
	rename 			a5bq6e harvmonth
	rename			HHID hhid
	
	sort 			hhid prcid pltid cropid
	
* drop observations from plots that did not harvest because crop was immature
	drop 			if a5bq5_2 == 1
	*** 2 observations deleted

* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 8 observations missing
	drop			if cropid ==.
	*** 8 obs deleted
	
* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 880
	*** 18 observations dropped
	
	
* replace missing cropharvests with 0
	replace 		a5bq6a = 0 if a5bq6a == .
	*** 0 changed to zero

* missing prcid and pltid don't allow for unique id, drop missing
	drop			if prcid == .
	drop			if pltid == .
	duplicates 		drop
	*** zero dropped, still not unique ID
	
	
***********************************************************************
**# 2 - merge kg conversion file and create harvested quantity
***********************************************************************
	
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 198 from master 
	*** unmatched 717 from using
	*** total unmatched, 915
	
	
* drop from using
	drop 			if _merge == 2
	** 717 obs dropped

* how many unmatched had a harvest of 0
	tab 			a5bq6a if _merge == 1
	*** 0% have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** this isn't it either
	
	tab 			cropid condition if condition != 99 & _merge == 1 & condition !=.
	
	tab 			unit if _merge == 1
	tab				unit if _merge == 1, nolabel
	

* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if a5bq6a == 0 & _merge == 1
	*** 0 changes

* manually replace conversion for the kilograms and sacks 
* if the condition is other condition and the observation is unmatched

	*kgs
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
		*** 4 changes
		
	*sack 120 kgs
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
		*** 1 change
	
	*sack 100 kgs
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
		*** 1 change
		
	* sack 50 kgs
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
		*** 2 changes
		
	* jerrican 20 kgs
		replace 		ucaconversion = 20 if unit == 14 & _merge == 1
		*** 8 changes
		
	* jerrican 10 kgs
		replace 		ucaconversion = 10 if unit == 15 & _merge == 1
		*** 1 change
		
	* jerrican 5 kgs
		replace 		ucaconversion = 5 if unit == 16 & _merge == 1
		*** 1 change
		
	* jerrican 2 kgs
		replace 		ucaconversion = 2 if unit == 18 & _merge == 1
		*** 1 change 
		

	* tin 5 kgs
		replace 		ucaconversion = 5 if unit == 21 & _merge == 1
		*** 1 change 

	* 15 kg plastic Basin
		replace 		ucaconversion = 15 if unit == 22 & _merge == 1	
		*** 1 change
		
	* kimbo 2 kg 
		replace 		ucaconversion = 2 if unit == 29 & _merge == 1
		*** 3 changes
		
	* kimbo 1 kg
		replace 		ucaconversion = 0.5 if unit == 30 & _merge == 1	
		*** 1 change
		
	* kimbo 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 31 & _merge == 1	
		*** 2 changes 
		
	* basket 20 kg 
		replace 		ucaconversion = 20 if unit == 37 & _merge == 1
		*** 3 changes

	* basket 5 kg 
		replace 		ucaconversion = 5 if unit == 39 & _merge == 1	
		*** 1 change

		
* drop the unmatched remaining observations
	drop 			if _merge == 1 & ucaconversion == .
	*** 167 observatinos deleted

	replace 			ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	*** 579 changes made
	
		mdesc 			ucaconversion
		*** 0 missing
		
	drop 			_merge
	
	tab				cropid
	*** beans are the most numerous crop being 23.32% of crops planted
	***	maize is the second highest being 22.9%
	*** maize will be main crop following most other countries in the study
	
* Convert harv quantity to kg
	*** harvest quantity is in a variety of measurements
	*** included in the file are the conversions from other measurements to kg
	
* replace missing harvest quantity to 0
	replace 		a5bq6a = 0 if a5bq6a == .
	*** no changes
	
* Convert harv quantity to kg
	gen 			harvqtykg = a5bq6a*ucaconversion
	label var		harvqtykg "quantity of crop harvested (kg)"
	mdesc 			harvqtykg
	*** all converted
	
* summarize harvest quantity
	sum				harvqtykg
	*** no values > 100,000
	
	mdesc 			harvqtykg
	
* summarize maize quantity harvest
	sum				harvqtykg if cropid == 130
	*** 271.79 mean, 13,800 max
	
	
***********************************************************************
**# 3 - value of harvest
***********************************************************************

* value of crop sold in shillings
	rename			a5bq8 harvvlush
	label var 		harvvlush "Value of crop sold in ugandan shilling"
	
* summarize the value of sales in shillings
	sum 			harvvlush, detail
	*** mean 2,706,  min 0, max 520,000

* generate crop is USD
	gen 			cropvl = harvvlush / 3240.6454
	lab var 		cropvl "total value of harvest in 2015 USD"
	*** value comes from World Bank. Used excel file "world_bank_exchange_rates.xlxs"
		
	sum 			cropvl, detail
	*** mean 0.83, min 0, max 160.4
	*** compared to other waves, the mean is off by 100th
	*** multiply cropvl * 100
	
	replace			cropvl = cropvl * 100
	sum 			cropvl, detail
	*** mean 83.5, min 0, max 16,046.19
			
	
***********************************************************************
**# 4 - generate sold harvested values
***********************************************************************

* drop converstion factor variables
	drop			crop_code unit_code condition_code ucaconversion ///
						medconversion medcount borrowed unit
					
* rename units and condition
	rename			a5bq7c unit
	
* replace unit with 1 if unit is missing
	replace			unit = 1 if unit == .
	
* merge conversion file in for sold
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 22 from master
	*** unmatched 813 from using 
	** matched 8,754
	
	drop			if _merge !=3
	*** dropping unmatched observations
	
* replace missing ucaconversion with kg if unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						unit == 1
	*** replaces 386
	
* replace missing ucaconversion with median
	replace			ucaconversion = medconversion if ucaconversion == .
	*** 247 changes made
	
* replace zeros in sold data as missing
	replace			a5bq7a = . if a5bq7a == 0
	
* convert quantity sold into kg
	gen 			harvkgsold = a5bq7a*ucaconversion
	lab	var			harvkgsold "quantity sold, in kilograms"

	sum				harvkgsold, detail
	*** 1 min, mean 476.55, max 90,000

* replace missing values to 0
	replace 		cropvl = 0 if cropvl == .
	replace 		harvkgsold = 0 if harvkgsold == .
	
* before collapsing data, we have to fix harvmonth labels, 1-12 refers to the months in 2014 and 13-24 refers to the months in 2015

	tabulate 		harvmonth 
	tabulate 		a5bq6e_1
	tabulate 		harvmonth if a5bq6e_1 == 2015

	replace 		a5bq6e_1 = 2014 if harvmonth < 13
	replace 		a5bq6e_1 = 2015 if harvmonth > 12 & a5bq6e_1 == 2014
	
	drop if			harvmonth == 26 
	mdesc 			harvmonth 
	mdesc 			harvmonth if harvmonth ==. & a5bq6e_1 == 2015
	*** there are 115 missing values in 2015
	
	mdesc 			a5bq6e_1 
	*** one observation missing (a5bq6e_1 = year)
	
	drop if missing(a5bq6e_1) | missing(harvmont) | a5bq6e_1 != 2015
	*** 347 observations deleted
	*** keeping observations in 2015
	
	tabulate 		a5bq6e_1
	tabulate 		harvmonth 
	
* subtract 12 to harvmonth 
	replace 		harvmonth = harvmonth - 12
	tabulate 		harvmonth	
	*** harvest months range from 1 to 12

* collapse the data to the crop level so that our imputations are reproducable and consistent
	collapse 		(sum) harvqtykg cropvl harvkgsold (mean) harvmonth, ///
						by(hhid prcid pltid cropid)

	isid 			hhid prcid pltid cropid	

* revert 0 to missing values
	replace 		cropvl = . if cropvl == 0
	replace 		harvkgsold = . if harvkgsold == 0	
	
	
*********************************************************************
**# 5 - generate price data
*********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2015_gsec1"
	*** 41 unmatched from master
	
	drop 			if _merge == 2
	drop			_merge
	
* encode district for the imputation
	encode 			district, gen (districtdstrng)
	encode			subcounty, gen (subcountydstrng)
	encode			parish, gen (parishdstrng)

* look at crop value in USD
	sum 			cropvl, detail
	*** max 2,582, mean 85, min 0.00016
	
* condensed crop codes
	inspect 		cropid
	*** generally things look all right - only 37 unique values 

* gen price per kg
	sort 			cropid
	by 				cropid: gen cropprice = cropvl / harvkgsold 
	sum 			cropprice, detail
	*** mean = 0.377, max = 57.95, min = 1.34e-06
	*** will do some imputations later
	
* make datasets with crop price information
	preserve
	collapse 		(p50) p_parish=cropprice (count) n_parish=cropprice, by(cropid region districtdstrng subcountydstrng parishdstrng)
	save 			"$export/2015_agsec5a_p1.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_subcounty=cropprice (count) n_subcounty=cropprice, by(cropid region districtdstrng subcountydstrng)
	save 			"$export/2015_agsec5a_p2.dta", replace 	
	restore
		
	preserve
	collapse 		(p50) p_dist=cropprice (count) n_district=cropprice, by(cropid region districtdstrng)
	save 			"$export/2015_agsec5a_p3.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_reg=cropprice (count) n_reg=cropprice, by(cropid region)
	save 			"$export/2015_agsec5a_p4.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
	save 			"$export/2015_agsec5a_p5.dta", replace 	
	restore
	
* merge the price datasets back in
	merge m:1 cropid region districtdstrng subcountydstrng parishdstrng	        using "$export/2015_agsec5a_p1.dta", gen(p1)
	*** all observations matched
	
	merge m:1 cropid region districtdstrng subcountydstrng 	        using "$export/2015_agsec5a_p2.dta", gen(p2)
	*** all observations matched
	
	merge m:1 cropid region districtdstrng 						using "$export/2015_agsec5a_p3.dta", gen(p3)
	*** all observations matched
	
	merge m:1 cropid region						        using "$export/2015_agsec5a_p4.dta", gen(p4)
	*** all observations matched
	
	merge m:1 cropid 						        using "$export/2015_agsec5a_p5.dta", gen(p5)
	*** all observatinos matched

* erase price files
	erase			"$export/2015_agsec5a_p1.dta"
	erase			"$export/2015_agsec5a_p2.dta"
	erase			"$export/2015_agsec5a_p3.dta"
	erase			"$export/2015_agsec5a_p4.dta"
	erase			"$export/2015_agsec5a_p5.dta"
	
	drop p1 p2 p3 p4 p5 

* check to see if we have prices for all crops
	tabstat 		p_parish n_parish p_subcounty n_subcounty p_dist n_district p_reg n_reg p_crop n_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	*** no prices for jackfruit
	
* drop if we are missing prices
	drop			if p_crop == .
	*** dropped 12 observations
	
* make imputed price, using median price where we have at least 10 observations
* this code generlaly files parts of malawi ag_i
* but this differs from Malawi - seems like their code ignores prices 
	gene	 		croppricei = .
	*** 6,974 missing values generated
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_parish if n_parish>=10 & missing(croppricei)
	*** 190 replaced
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_subcounty if p_subcounty>=10 & missing(croppricei)
	*** 2 replaced
		
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_dist if n_district>=10 & missing(croppricei)
	*** 2,388 replaced
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_reg if n_reg>=10 & missing(croppricei)
	*** 3,936 replaced 
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_crop if missing(croppricei)
	*** 458 changes
	
	lab	var			croppricei	"implied unit value of crop"

* verify that prices exist for all crops
	mdesc 			croppricei
	*** no missing
	
	sum 			cropprice croppricei
	*** mean = 0.248, max = 57.95

	
***********************************************************************
**# 6 - impute harvqtykg
***********************************************************************

* summarize harvest quantity prior to imputations
	sum				harvqtykg
	*** mean 431.9, max 90,000

* replace observations 3 std deviation from the mean and impute missing
	*** 3 std dev from mean is 
	sum 			harvqtykg, detail
	replace			harvqtykg = . if harvqtykg > `r(p50)'+ (3*`r(sd)')
	*** 62 changed to missing

* impute missing harvqtykg
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute harvqtykg	
	mi register			imputed harvqtykg // identify harvqty variable to be imputed
	sort				hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 			pmm harvqtykg i.districtdstrng i.cropid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* inspect imputation 
	sum 				harvqtykg_1_, detail
	*** mean 364.9, min 1, max 4,250

* replace the imputated variable
	replace 			harvqtykg = harvqtykg_1_ 
	*** 61 changes
	
	drop 				harvqtykg_1_ mi_miss
	
	
************************************************************************
**# 7 - impute cropvl
************************************************************************	

* summarize value of sales prior to imputations
	sum				cropvl
	*** mean 85, max 16,046
	
* replace cropvl with missing if over 3 std dev from the mean
	sum 			cropvl, detail
	replace			cropvl = . if cropvl > `r(p50)'+ (3*`r(sd)')
	*** 14 changes
	
* impute cropvl if missing and harvest was sold
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute each variable in local	
	mi register			imputed cropvl // identify harvqty variable to be imputed
	sort				hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 			pmm cropvl i.districtdstrng i.cropid harvqtykg, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* how did impute go?
	sum 			cropvl_1_, detail
	*** mean 49.94, max 1,049

	replace 		cropvl = cropvl_1_
	*** 4,212 changes
	
	drop 			cropvl_1_ mi_miss
	
* do harvest value and harvest quantity contradict?
	replace 		cropvl = 0 if harvqty == 0
	*** 0 changes made
	
		
*********************************************************************
**# 8 - impute cropvalue from sales
*********************************************************************	
	
* generate value of harvest 
	gen				cropvalue = harvqtykg * croppricei
	label 			variable cropvalue	"implied value of crops" 
	
* replace cropvalue with cropvl if cropvl is not missing and crop value is missing
	replace 		cropvalue = cropvl if cropvalue == . & cropvl != .
	*** 1 change
	
* verify that we have crop value for all observations
	mdesc 			cropvalue
	*** 0 missing

* summarize value of harvest prior to imputations	
	sum 			cropvalue
	*** mean 64.8, max 41,730

* replace any +3 s.d. away from median as missing, by crop	
	sum				cropvalue, detail
	replace			cropvalue = . if cropvalue > `r(p50)'+ (3*`r(sd)')
	*** replaced 3 values
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed cropvalue // identify cropvalue as the variable being imputed
	sort			hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 		pmm cropvalue i.districtdstrng i.cropid, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did impute go?
	sum 			cropvalue_1_, detail
	*** mean 57.69, max 1,388
	
	replace			cropvalue = cropvalue_1_
	lab var			cropvalue "value of harvest, imputed"
	*** 3 changes
	
	drop 			cropvalue_1_ mi_miss

	
***********************************************************************
**# 9 - end matter, clean up to save
***********************************************************************

* summarize crop value, imputed crop value, and maize harvest
	sum				cropvl
	*** mean 49.9 max 1,049
	sum				cropvalue
	*** mean 57.69  max 1,388
	sum				harvqtykg if cropid == 130
	*** mean 326.47, max 3,936
	
* following method used in other waves which differs from other countries
* we will use implied crop value as opposed to crop value based on prices
* so we will got with crop value based on the imputation in sec 7
	replace			cropvalue = cropvl
	replace			cropvalue = 0 if cropvalue == .
	
	keep 			hhid hh prcid pltid cropvalue harvqtykg region district ///
						subcounty parish cropid  ///
						wgt15 harvmonth

	compress
	describe
	summarize

* save file
	save			"$export/2015_agsec5a.dta", replace	

* close the log
	log	close

/* END */
