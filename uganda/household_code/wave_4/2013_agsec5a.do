* Project: WB Weather
* Created on: Feb 2024
* Created by: rg
* Edited on: 17 April 24
* Edited by: rg
* Stata v.18, mac

* does
	* Crop output
	* reads Uganda wave 4 crop output (2013_AGSEC5A) for the 1st season
	* 3A - 5A are questionaires for the first planting season
	* 3B - 5B are questionaires for the second planting season

* assumes
	* mdesc.ado
	* access to raw data

* TO DO:
	* done

	
***********************************************************************
**# 0 - setup
***********************************************************************

* define paths	
	global 	root  		"$data/household_data/uganda/wave_4/raw"  
	global  export 		"$data/household_data/uganda/wave_4/refined"
	global 	logout 		"$data/household_data/uganda/logs"
	global 	conv 		"$data/household_data/uganda/conversion_files"  

* open log	
	cap log 			close
	log using 			"$logout/2013_AGSEC5A", append

	
***********************************************************************
**# 1 - import data and rename variables
***********************************************************************

* import wave 4 season 1
	use 			"$root/agric/AGSEC5A.dta", clear
		
	rename 			cropID cropid
	rename			plotID pltid
	rename			parcelID prcid
	rename 			a5aq6c unit
	rename			a5aq6b condition
	rename 			a5aq6e harvmonth
	*** during this wave condition = a5aq6b not c
	*** unit is c not b
	
* two observations are missing pltid
	*** the hhids are 163060401 and 172100401
	*** drop this observations
	
	drop			if pltid ==. & (HHID == 163060401| HHID == 172100401)
	*** two observations dropped

* unlike other waves, HHID is a numeric here
	format 			%18.0g HHID
	tostring		HHID, gen(hhid) format(%18.0g)

	
* drop observations from plots that did not harvest because crop was immature
	drop if 		a5aq5_2 == 1
	*** 2,002 observations deleted

* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 6 observations missing
	drop			if cropid ==.
	** 6 obs deleted
	
* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 880
	*** 25 observations deleted 
	
* replace harvests with 99999 with a 0, 99999 is code for missing
	replace 		a5aq6a = 0 if a5aq6a == 99999
	*** 0 changed to zero
	
* replace missing cropharvests with 0
	replace 		a5aq6a = 0 if a5aq6a == .
	*** 5 changed to zero

* missing prcid and pltid don't allow for unique id, drop missing
	drop			if prcid == .
	drop			if pltid == .
	duplicates 		drop
	*** zero dropped, still not unique ID
	
* some issues with cropid and matching
	replace		 	cropid = 810 if cropid == 811
	replace			cropid = 810 if cropid == 812

* unique identifier
	isid 			hhid prcid pltid Production_ID cropid
	sort 			hhid prcid pltid Production_ID cropid
	
***********************************************************************
**# 2 - merge kg conversion file and create harvested quantity
***********************************************************************
	
	merge m:1 	cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 272 from master 
	*** unmatched 613 from using
	
* drop from using
	drop 			if _merge == 2
	*** 613 dropped

* how many unmatched had a harvest of 0
	tab 			a5aq6a if _merge == 1
	*** only 2% have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** this isn't it either 
	
	tab 			cropid condition if condition != 99 & _merge == 1 & condition !=.
	
	tab 			unit if _merge == 1
	tab 			unit if _merge == 1, nolabel
	

* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if a5aq6a == 0 & _merge == 1
	*** 5 changes

* manually replace conversion for the kilograms and sacks 
* if the condition is other condition and the observation is unmatched

	*kgs
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
		*** 8 changes
		
	*sack 120 kgs
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
		*** 0 changes
	
	*sack 100 kgs
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
		*** 3 changes
	
	* sack 80 kgs
		replace 		ucaconversion = 80 if unit == 11 & _merge == 1
		*** 1 change
	
	* sack 50 kgs
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
		*** 9 changes
		
	* jerrican 20 kgs
		replace 		ucaconversion = 20 if unit == 14 & _merge == 1
		*** 9 changes
		
	* jerrican 10 kgs
		replace 		ucaconversion = 10 if unit == 15 & _merge == 1
		*** 1 change
		
	* jerrican 5 kgs
		replace 		ucaconversion = 5 if unit == 16 & _merge == 1
		*** 0 changes
		
	* jerrican 3 kgs
		replace 		ucaconversion = 3 if unit == 17 & _merge == 1
		*** 1 change 
		
	* tin 20 kgs
		replace 		ucaconversion = 20 if unit == 20 & _merge == 1
		*** 4 changes
		
	* tin 5 kgs
		replace 		ucaconversion = 5 if unit == 21 & _merge == 1
		*** 4 chnages 

	* 15 kg tub
		replace 		ucaconversion = 15 if unit == 22 & _merge == 1	
		*** 3 changes
		
	* kimbo 2 kg 
		replace 		ucaconversion = 2 if unit == 29 & _merge == 1
		*** 4 changes
		
	* kimbo 1 kg
		replace 		ucaconversion = 1 if unit == 30 & _merge == 1
		*** 0 changes

	* kimbo 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 31 & _merge == 1	
		*** 0 changes 

	* cup 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 32 & _merge == 1		
		*** 1 change
		
	* basket 20 kg 
		replace 		ucaconversion = 20 if unit == 37 & _merge == 1
		*** 5 changes
		
	* basket 10 kg 
		replace 		ucaconversion = 10 if unit == 38 & _merge == 1
		*** 2 changes 

	* basket 5 kg 
		replace 		ucaconversion = 5 if unit == 39 & _merge == 1	
		*** 2 changes

	* basket 2 kg
		replace 		ucaconversion = 2 if unit == 40 & _merge == 1	
		*** 3 changes
		
	* nomi 1 kg
		replace 		ucaconversion = 1 if unit == 119 & _merge == 1	
		*** 13 changes

	* nomi 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 120 & _merge == 1
		*** 1 change 
		
* drop the unmatched remaining observations
	drop 			if _merge == 1 & ucaconversion == .
	*** 193 observatinos deleted

	replace 			ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	*** 821 changes made
	
		mdesc 			ucaconversion
		*** 0 missing
		
	drop 			_merge
	
	tab				cropid
	*** beans are the most numerous crop being 23.77% of crops planted
	***	maize is the second highest being 20.26%
	*** maize will be main crop following most other countries in the study
	
* convert harv quantity to kg
	*** harvest quantity is in a variety of measurements
	*** included in the file are the conversions from other measurements to kg
	
* replace missing harvest quantity to 0
	replace 		a5aq6a = 0 if a5aq6a == .
	*** no changes
	
* Convert harv quantity to kg
	gen 			harvqtykg = a5aq6a*ucaconversion
	label var		harvqtykg "quantity of crop harvested (kg)"
	mdesc 			harvqtykg
	*** all converted
	
* summarize harvest quantity
	sum				harvqtykg
	*** 1 crazy value, replace with missing
	
	replace			harvqtykg = . if harvqtykg > 100000
	*** replaced 1 observation
	
* summarize maize quantity harvest
	sum				harvqtykg if cropid == 130
	*** 296 mean, 25000 max
	
	
***********************************************************************
**# 3 - value of harvest
***********************************************************************

* value of crop sold in shillings
	rename			a5aq8 harvvlush
	label var 		harvvlush "Value of crop sold in ugandan shilling"
	
* summarize the value of sales in shillings
	sum 			harvvlush, detail
	*** mean 201,443.1 , min 6, max 1.03e+07

* NOTE: Anna will check the conversions 	
* generate crop is USD
	gen 			cropvl = harvvlush / 2860.0412
	lab var 		cropvl "total value of harvest in 2015 USD"
	*** value comes from World Bank. Used excel file "world_bank_exchange_rates.xlxs"
		
	sum 			cropvl, detail
	*** mean 70.4, min 0.002, max 3,593.48
	
	
***********************************************************************
**# 4 - generate sold harvested values
***********************************************************************

* drop converstion factor variables
	drop			crop_code unit_code condition_code ucaconversion ///
						medconversion medcount borrowed unit
					
* rename units and condition
	rename			a5aq7c unit
	
* replace unit with 1 if unit is missing
	replace			unit = 1 if unit == .
	
* merge conversion file in for sold
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 161 from master
	*** dropping unmatched obs 
	
	drop			if _merge !=3
	*** 932 observations deleted, 771 are from using file
	
	
* replace missing ucaconversion with kg if unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						unit == 1
	*** replaces 481
	
* replace missing ucaconversion with median
	replace			ucaconversion = medconversion if ucaconversion == .
	*** 326 changes made
		
* replace zeros in sold data as missing
	replace			a5aq7a = . if a5aq7a == 0
	*** 5,316 changes made
	
* convert quantity sold into kg
	gen 			harvkgsold = a5aq7a*ucaconversion
	lab	var			harvkgsold "quantity sold, in kilograms"

	sum				harvkgsold, detail
	*** 0.25 min, mean 606.61, max 425,000
	*** only 1 observation =425000
	
	drop 			if harvkgsold == 425000

* replace missing values to 0
	replace 		cropvl = 0 if cropvl == .
	replace 		harvkgsold = 0 if harvkgsold == .

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

* hhid is a long variable in the using file 
	destring		hhid, replace
	format 			hhid %16.0g
	
* merge the location identification
	merge m:1 		hhid using "$export/2013_agsec1"
	*** 0 unmatched from master
	
	drop 			if _merge == 2
	drop			_merge
	
* encode district for the imputation
	encode 			district, gen (districtdstrng)
	encode			subcounty, gen (subcountydstrng)
	encode			parish, gen (parishdstrng)

* look at crop value in USD
	sum 			cropvl, detail
	*** max 3,593.48, mean 73.2, min 0.002
	
* condensed crop codes
	inspect 		cropid
	*** generally things look all right - only 38 unique values 

* gen price per kg
	sort 			cropid
	by 				cropid: gen cropprice = cropvl / harvkgsold 
	sum 			cropprice, detail
	*** mean = 0.79, max = 87.41, min = 0.0001
	*** will do some imputations later
	
* make datasets with crop price information
	preserve
	collapse 		(p50) p_parish=cropprice (count) n_parish=cropprice, by(cropid region districtdstrng subcountydstrng parishdstrng)
	save 			"$export/2013_agsec5a_p1.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_subcounty=cropprice (count) n_subcounty=cropprice, by(cropid region districtdstrng subcountydstrng)
	save 			"$export/2013_agsec5a_p2.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_dist=cropprice (count) n_district=cropprice, by(cropid region districtdstrng)
	save 			"$export/2013_agsec5a_p3.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_reg=cropprice (count) n_reg=cropprice, by(cropid region)
	save 			"$export/2013_agsec5a_p4.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
	save 			"$export/2013_agsec5a_p5.dta", replace 	
	restore
	
* merge the price datasets back in
	merge m:1 cropid region districtdstrng  subcountydstrng parishdstrng	        using "$export/2013_agsec5a_p1.dta", gen(p1)
	*** all observations matched
	
	merge m:1 cropid region districtdstrng  subcountydstrng 	        using "$export/2013_agsec5a_p2.dta", gen(p2)
	*** all observations matched

	merge m:1 cropid region districtdstrng  			        using "$export/2013_agsec5a_p3.dta", gen(p3)
	*** all observations matched
	
	merge m:1 cropid region  						using "$export/2013_agsec5a_p4.dta", gen(p4)
	*** all observations matched
	
	merge m:1 cropid 						        using "$export/2013_agsec5a_p5.dta", gen(p5)
	*** all observations matched
	

* erase price files
	erase			"$export/2013_agsec5a_p1.dta"
	erase			"$export/2013_agsec5a_p2.dta"
	erase			"$export/2013_agsec5a_p3.dta"
	erase			"$export/2013_agsec5a_p4.dta"
	erase			"$export/2013_agsec5a_p5.dta"

	drop p1 p2 p3 p4 p5 

* check to see if we have prices for all crops
	tabstat 		p_parish n_parish p_subcounty n_subcounty p_dist n_district p_reg n_reg p_crop n_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	*** no prices for pumpkins, pinapples, and jackfruits
	
* drop if we are missing prices
	drop			if p_crop == .
	*** dropped 6 observations
	
* make imputed price, using median price where we have at least 10 observations
* this code generlaly files parts of malawi ag_i
* but this differs from Malawi - seems like their code ignores prices 
	gene	 		croppricei = .
	*** 7,337 missing values generated
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_parish if n_parish>=10 & missing(croppricei)
	*** 409 replaced
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_subcounty if p_subcounty>=10 & missing(croppricei)
	*** 55 replaced
	
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_dist if n_district>=10 & missing(croppricei)
	*** 2,341 replaced
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_reg if n_reg>=10 & missing(croppricei)
	*** 4,169 replaced 
	
	bys 			cropid (region districtdstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_crop if missing(croppricei)
	*** 363 changes
	
	lab	var			croppricei	"implied unit value of crop"

* verify that prices exist for all crops
	mdesc 			croppricei
	*** no missing
	
	sum 			cropprice croppricei
	*** mean = 0.436, max = 64.1

	
***********************************************************************
**# 6 - impute harvqtykg
***********************************************************************

* summarize harvest quantity prior to imputations
	sum				harvqtykg
	*** mean 482.22, max 56,400

* replace observations 3 std deviation from the mean and impute missing
	*** 3 std dev from mean is 
	sum 			harvqtykg, detail
	replace			harvqtykg = . if harvqtykg > `r(p50)'+ (3*`r(sd)')
	*** 88 changed to missing

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
	*** mean 376, min 0, max 4625

* replace the imputated variable
	replace 			harvqtykg = harvqtykg_1_ 
	*** 88 changes
	
	drop 				harvqtykg_1_ mi_miss
	
	
************************************************************************
**# 7 - impute cropvl
************************************************************************	

* summarize value of sales prior to imputations
	sum				cropvl
	*** mean 73.2, max 3,593.48
	
* replace cropvl with missing if over 3 std dev from the mean
	sum 			cropvl, detail
	replace			cropvl = . if cropvl > `r(p50)'+ (3*`r(sd)')
	*** 47 changes
	
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
	*** mean 41.9, max 524.46

	replace 		cropvl = cropvl_1_
	*** 4,390 changes
	
	drop 			cropvl_1_ mi_miss
	
* do harvest value and harvest quantity contradict?
	replace 		cropvl = 0 if harvqty == 0
	*** 1 changes made
	
		
*********************************************************************
**# 8 - impute cropvalue from sales
*********************************************************************	
	
* generate value of harvest 
	gen				cropvalue = harvqtykg * croppricei
	label 			variable cropvalue	"implied value of crops" 
	
* replace cropvalue with cropvl if cropvl is not missing and crop value is missing
	replace 		cropvalue = cropvl if cropvalue == . & cropvl != .
	*** 0 change
	
* verify that we have crop value for all observations
	mdesc 			cropvalue
	*** 0 missing

* summarize value of harvest prior to imputations	
	sum 			cropvalue
	*** mean 99.3, max 34,964

* replace any +3 s.d. away from median as missing, by crop	
	sum				cropvalue, detail
	replace			cropvalue = . if cropvalue > `r(p50)'+ (3*`r(sd)')
	*** replaced 31 values
	
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
	*** mean 64.05, max 2,185.2
	
	replace			cropvalue = cropvalue_1_
	lab var			cropvalue "value of harvest, imputed"
	*** 31 changes
	
	drop 			cropvalue_1_ mi_miss

	
***********************************************************************
**# 9 - end matter, clean up to save
***********************************************************************

* summarize crop value, imputed crop value, and maize harvest
	sum				cropvl
	*** mean 41.9 max 524.4
	sum				cropvalue
	*** mean 64.05 max 2,185
	sum				harvqtykg if cropid == 130
	*** mean 288.5 max 4,625
	
* following method used in other waves which differs from other countries
* we will use implied crop value as opposed to crop value based on prices
* so we will got with crop value based on the imputation in sec 7
	replace			cropvalue = cropvl
	replace			cropvalue = 0 if cropvalue == .
	
	keep 			hhid hh hhid_pnl prcid pltid cropvalue harvqtykg region district ///
						subcounty parish cropid  ///
						wgt13 harvmonth 

	compress
	describe
	summarize

* save file
	save			"$export/2013_agsec5a.dta", replace
	

* close the log
	log	close

/* END */
