* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* Crop output
	* reads Uganda wave 2 crop output (2010_AGSEC5A) for the 1st season
	* 3A - 5A are questionaires for the first planting season
	* 3B - 5B are questionaires for the second planting season

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* done

************************************************************************
**# 0 - setup
************************************************************************

* define paths	
	global root 		 "$data/household_data/uganda/wave_2/raw"  
	global export 		 "$data/household_data/uganda/wave_2/refined"
	global logout 		 "$data/household_data/uganda/logs"
	global conv 		 "$data/household_data/uganda/conversion_files"  

* open log	
	cap log 		close
	log using 		"$logout/2010_AGSEC5A", append

	
************************************************************************
**# 1 - import data and rename variables
************************************************************************

* import wave 2 season 1
	use 			"$root/2010_AGSEC5A.dta", clear
	
	rename 			HHID hhid
	rename 			cropID cropid
	rename 			a5aq6c unit
	rename			a5aq6b condition
	rename 			a5aq6e harvmonth	
	
	sort 			hhid prcid pltid cropid
	*** cannot uniquely identify observations by hhid, prcid, or pltid 
	*** there multiple crops on the same plot
	
* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 0 obs
	
* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 880
	*** 728 observations dropped
	
* replace harvests with 99999 with a 0, 99999 is code for missing
	replace 		a5aq6a = 0 if a5aq6a == 99999
	*** 0 changed to zero
	
* replace missing cropharvests with 0
	replace 		a5aq6a = 0 if a5aq6a == .
	*** 1651 changed to zero

* missing prcid and pltid don't allow for unique id, drop missing
	drop			if prcid == .
	drop			if pltid == .
	duplicates 		drop
	*** zero dropped, still not unique ID
	

************************************************************************
**# 2 - merge kg conversion file and create harvested quantity
************************************************************************
	
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 2946 from master 
	
* drop from using
	drop 			if _merge == 2

* how many unmatched had a harvest of 0
	tab 			a5aq6a if _merge == 1
	*** 78% have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** any condition is mostly missing from unmerged observations
		
	tab 			unit if _merge == 1
	
* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if a5aq6a == 0 & _merge == 1
	*** 2317 changes
	
* manually replace conversion for the kilograms and sacks
* if the condition is other condition and the observation is unmatched

	*kgs, 49 changes
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
	
	*sack 120 kgs, 12 changes
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
	
	*sack 100 kgs, 164 changes
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
	
	* sack 80 kgs, 6 changes
		replace 		ucaconversion = 80 if unit == 11 & _merge == 1
	
	* sack 50 kgs, 17 changes
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
	
		tab 			ucaconversion if _merge == 3 & ucaconversion != a5aq6d 
		*** 7745 different
	
		tab 			medconversion if _merge == 3 & medconversion != a5aq6d 
		*** 5321 different
	
		replace 		ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	
		mdesc 			ucaconversion
		*** 2.9% missing
	
* replace conversion to 1 (kg) if harvest is 0
	replace ucaconversion = 1 if a5aq6a == 0
	*** 7 changes
	
* some missing harvests still have a value for amount sold. Will replace amount sold with 0 if harv qty is missing

	tab a5aq8 if a5aq6a == .
	*** 0 observations
	
	replace a5aq8 = . if a5aq6a == 0 & a5aq7a > 0
	*** 6 observations
	
* drop any observations that remain and still dont have a conversion factor
	drop if ucaconversion == .
	*** 381 observations dropped
	
	drop _merge
	
	tab			cropid
	*** beans are the most numerous crop being 16.69% of crops planted
	***	maize is the second highest being 15.72%
	*** maize will be main crop following most other countries in the study
	
* Convert harv quantity to kg
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
	
* summarize maize quantity harvest
	sum				harvqtykg if cropid == 130
	*** 275 mean, 62500 max
	

************************************************************************
**# 3 - value of harvest
************************************************************************

* value of crop sold in shillings
	rename			a5aq8 harvvlush
	label var 		harvvlush "Value of crop sold in ugandan shilling"
	
* summarize the value of sales in shillings
	sum 			harvvlush, detail
	*** mean 126886 min 0, max 1.01e+07

* generate crop is USD
	gen 		cropvl = harvvlush / 2832.7427
	lab var 	cropvl "total value of harvest in 2015 USD"
	*** value comes from World Bank: world_bank_exchange_rates.xlxs
	
	sum 		cropvl, detail
	*** mean 62.54, min 0, max 4968
	
	
************************************************************************
**# 4 - generate sold harvested values
************************************************************************

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
	*** unmatched 2632 from master
	
	drop			if _merge == 2
	
* most unmatched seem to be 0 production and unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						harvqtykg == 0
	*** replaces 2320 of the 2632unmatched obs
	
* replace missing ucaconversion with kg if unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						unit == 1
	*** replaces 903
	
* replace missing ucaconversion with median
	replace			ucaconversion = medconversion if ucaconversion == .
	*** 274 changes made, only 5 missing left
	
* set remaining missing equal to conversion factor in data
	replace			ucaconversion = a5aq7b if ucaconversion == .
	*** 105 changes made, now have conversion factor for all
	
* replace zeros in sold data as missing
	replace			a5aq7a = . if a5aq7a == 0
	
* convert quantity sold into kg
	gen 			harvkgsold = a5aq7a*ucaconversion
	lab	var			harvkgsold "quantity sold, in kilograms"
	
	replace			harvkgsold = . if harvkgsold == 0

	sum				harvkgsold, detail
	*** 0.1 min, mean 223, max 60000

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
	
	
**********************************************************************
**# 5 - generate price data
**********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2010_GSEC1"
	*** 533 unmatched from master
	
	drop 			if _merge == 2
	drop			_merge
	
* encode district for the imputation
	encode 			district, gen (districtdstrng)
	encode			county, gen (countydstrng)
	encode			subcounty, gen (subcountydstrng)
	encode			parish, gen (parishdstrng)

* look at crop value in USD
	sum 			cropvl, detail
	*** max 4968, mean 65.99, min 0.004
	
* condensed crop codes
	inspect 		cropid
	*** generally things look all right - only 41 unique values 

* gen price per kg
	sort 			cropid
	by 				cropid: gen cropprice = cropvl / harvkgsold 
	sum 			cropprice, detail
	*** mean = 1.95, max = 184, min = 0
	*** there are some very large prices all across the board
	
* for whatever reason all prices are much higher in 2010 compared to 09 or 11
* this is despite 2010 having the lowest crop value sold
* these seem to be resulting in very high crop values in section 8
	replace			cropprice = . if cropprice > 1.3
	*** 659 replaced

		
* make datasets with crop price information
	preserve
	collapse 		(p50) p_parish=cropprice (count) n_parish=cropprice, by(cropid region districtdstrng countydstrng subcountydstrng parishdstrng)
	save 			"$export/2010_agsec5a_p1.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_subcounty=cropprice (count) n_subcounty=cropprice, by(cropid region districtdstrng countydstrng subcountydstrng)
	save 			"$export/2010_agsec5a_p2.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_county=cropprice (count) n_county=cropprice, by(cropid region districtdstrng countydstrng)
	save 			"$export/2010_agsec5a_p3.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_dist=cropprice (count) n_district=cropprice, by(cropid region districtdstrng)
	save 			"$export/2010_agsec5a_p4.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_reg=cropprice (count) n_reg=cropprice, by(cropid region)
	save 			"$export/2010_agsec5a_p5.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
	save 			"$export/2010_agsec5a_p6.dta", replace 	
	restore
	
* merge the price datasets back in
	merge m:1 cropid region districtdstrng countydstrng subcountydstrng parishdstrng	        using "$export/2010_agsec5a_p1.dta", gen(p1)
	*** all observations matched
	
	merge m:1 cropid region districtdstrng countydstrng subcountydstrng 	        using "$export/2010_agsec5a_p2.dta", gen(p2)
	*** all observations matched

	merge m:1 cropid region districtdstrng countydstrng 			        using "$export/2010_agsec5a_p3.dta", gen(p3)
	*** all observations matched
	
	merge m:1 cropid region districtdstrng 						using "$export/2010_agsec5a_p4.dta", gen(p4)
	*** all observations matched
	
	merge m:1 cropid region						        using "$export/2010_agsec5a_p5.dta", gen(p5)
	*** all observations matched
	
	merge m:1 cropid 						        using "$export/2010_agsec5a_p6.dta", gen(p6)
	*** all observatinos matched

* erase price files
	erase			"$export/2010_agsec5a_p1.dta"
	erase			"$export/2010_agsec5a_p2.dta"
	erase			"$export/2010_agsec5a_p3.dta"
	erase			"$export/2010_agsec5a_p4.dta"
	erase			"$export/2010_agsec5a_p5.dta"
	erase			"$export/2010_agsec5a_p6.dta"

	drop p1 p2 p3 p4 p5 p6

* check to see if we have prices for all crops
	tabstat 		p_parish n_parish p_subcounty n_subcounty p_county n_county p_dist n_district p_reg n_reg p_crop n_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	*** no prices for wheat
	
* drop if we are missing prices
	drop			if p_crop == .
	*** dropped 1 observation
	
* make imputed price, using median price where we have at least 10 observations
* this code generlaly files parts of malawi ag_i
* but this differs from Malawi - seems like their code ignores prices 
	gene	 		croppricei = .
	*** 11259 missing values generated
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_parish if n_parish>=10 & missing(croppricei)
	*** 297 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_subcounty if p_subcounty>=10 & missing(croppricei)
	*** 160 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_county if n_county>=10 & missing(croppricei)
	*** 1371 replaced 
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_dist if n_district>=10 & missing(croppricei)
	*** 677 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_reg if n_reg>=10 & missing(croppricei)
	*** 7907 replaced 
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_crop if missing(croppricei)
	*** 847 changes
	
	lab	var			croppricei	"implied unit value of crop"

* verify that prices exist for all crops
	mdesc 			croppricei
	*** no missing
	
	sum 			cropprice croppricei
	*** mean = 0.887, max = 44

	
************************************************************************
**# 6 - impute harvqtykg
************************************************************************

* summarize harvest quantity prior to imputations
	sum				harvqtykg
	*** mean 414, max 70,215

* replace observations 3 std deviation from the mean and impute missing
	*** 3 std dev from mean is 
	sum 			harvqtykg, detail
	replace			harvqtykg = . if harvqtykg > `r(p50)'+ (3*`r(sd)')
	*** 139 changed to missing

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
	*** mean 309, min 0, max 4700

* replace the imputated variable
	replace 			harvqtykg = harvqtykg_1_ 
	*** 138 changes
	
	drop 				harvqtykg_1_ mi_miss
	
	
*************************************************************************
**# 7 - impute cropvl
**************************************************************************	

* summarize value of sales prior to imputations
	sum				cropvl
	*** mean 65.99, max 4968
	
* replace cropvl with missing if over 3 std dev from the mean
	sum 			cropvl, detail
	replace			cropvl = . if cropvl > `r(p50)'+ (3*`r(sd)')
	*** 35 changes
	
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
	*** mean 36.26, max 642

	replace 		cropvl = cropvl_1_
	*** 7896 changes
	
	drop 			cropvl_1_ mi_miss
	
* do harvest value and harvest quantity contradict?
	replace 		cropvl = 0 if harvqty == 0
	*** 2335 changes made
	
		
**********************************************************************
**# 8 - impute cropvalue from sales
**********************************************************************	
	
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
	*** mean 142, max 4396

* replace any +3 s.d. away from median as missing, by crop	
	sum				cropvalue, detail
	replace			cropvalue = . if cropvalue > `r(p50)'+ (3*`r(sd)')
	*** replaced 326 values
	
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
	*** mean 94.65, max 1265
	
	replace			cropvalue = cropvalue_1_
	lab var			cropvalue "value of harvest, imputed"
	*** 71 changes
	
	drop 			cropvalue_1_ mi_miss

	
************************************************************************
**# 9 - end matter, clean up to save
************************************************************************

* summarize crop value, imputed crop value, and maize harvest
	sum				cropvl
	*** mean 31.19 max 642
	sum				cropvalue
	*** mean 94.65, max 1265
	sum				harvqtykg if cropid == 130
	*** mean 252.95 max 4700
	
* despite all the work to get prices and impute values
* this process does not seem to work as well in Uganda as in other countries
* so we will got with crop value based on the imputation in sec 7
	replace			cropvalue = cropvl
	replace			cropvalue = 0 if cropvalue == .
	
	keep 			hhid prcid pltid cropvalue harvqtykg region district ///
						county subcounty parish cropid hh_status2010 ///
						spitoff09_10 spitoff10_11 wgt10 harvmonth

	compress
	describe
	summarize

* save file
	save 			"$export/2010_AGSEC5A.dta", replace

* close the log
	log	close

/* END */
