* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* Crop output
	* reads Uganda wave 1 crop output (2009_AGSEC5A) for the 1st season
	* 3A - 5A are questionaires for the first planting season
	* 3B - 5B are questionaires for the second planting season

* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* we are only considering sold value based on the observations that were succesfully merged (line 159- 190)
	* outcome of last imputation is changing everytime we run


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global root 		"$data/household_data/uganda/wave_1/raw"  
	global export 		"$data/household_data/uganda/wave_1/refined"
	global logout 		"$data/household_data/uganda/logs"
	global conv 		"$data/household_data/uganda/conversion_files"  

	
* open log	
	cap log 			close
	log using 			"$logout/2009_AGSEC5A", append

	
* **********************************************************************
* 1 - import data and rename variables
* **********************************************************************

* import wave 2 season 1
	use 			"$root/2009_AGSEC5A.dta", clear
	
	rename 			Hhid hhid
	rename 			A5aq5 cropid
	rename 			A5aq1 prcid
	rename			A5aq3 pltid
	rename			A5aq4 cropname
	rename 			A5aq6c unit_code
	rename			A5aq6b condition_code
	
	sort hhid prcid pltid
	*** cannot uniquely identify observations by hhid, prcid, or pltid 
	*** there multiple crops on the same plot
	
* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 1494 obs
	
	tab 			cropname if cropid == .
	drop 			if cropid == .
	*** dropped 1494 observations

* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 880
	*** 497 observations dropped
	
* replace harvests with 99999 with a 0, 99999 is code for missing
	replace 		A5aq6a = 0 if A5aq6a == 99999
	*** 1277 changed to zero
	
* replace missing cropharvests with 0
	replace 		A5aq6a = 0 if A5aq6a == .
	*** 234 changed to zero

* missing prcid and pltid don't allow for unique id, drop missing
	drop			if prcid == .
	drop			if pltid == .
	duplicates 		drop
	*** there is still not a unique identifier, will deal with later
	
	
* **********************************************************************
* 2 - merge kg conversion file and create harvested quantity
* **********************************************************************
	
* merge in conversation file
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 4195 from master, or 30% 
	
* drop from using
	drop 			if _merge == 2

* how many unmatched had a harvest of 0
	tab 			A5aq6a if _merge == 1
	*** 86%, 3217, have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	mdesc 			condition if _merge == 1
	*** all unmatched observations have missing condition_code
	
	tab 			unit if _merge == 1

* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if A5aq6a == 0
	*** 3221 changes

* some matched do not have ucaconversions, will use medconversion
	replace 		ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	mdesc 			ucaconversion
	*** 4% missing, 535 missing
	
* Drop the variables still missing ucaconversion
	drop 			if ucaconversion == .
	*** 535 dropped
	
	drop 			_merge
	
	tab				cropname
	*** beans are the most numerous crop being 18% of crops planted
	***	maize is the second highest being 17%
	*** maize will be main crop following most other countries in the study
	
* replace missing harvest quantity to 0
	replace 		A5aq6a = 0 if A5aq6a == .
	*** no changes
	
* Convert harv quantity to kg
	gen 			harvqtykg = A5aq6a*ucaconversion
	label var		harvqtykg "quantity of crop harvested (kg)"
	mdesc 			harvqtykg
	*** all converted

* summarize harvest quantity
	sum				harvqtykg
	*** three crazy values, replace with missing
	
	replace			harvqtykg = . if harvqtykg > 100000
	*** replaced 3 observations
	
* summarize maize quantity harvest
	sum				harvqtykg if cropid == 130
	*** 287 mean, 75600 max
	

* **********************************************************************
* 3 - value of harvest
* **********************************************************************

* value of crop sold in shillings
	rename			A5aq8 harvvlush
	label var 		harvvlush "Value of crop sold in ugandan shilling"
	
* in this season in this wave only, value is 100x too large
* per Talip Kilic, we should divide this variable by 100
	replace			harvvlush = harvvlush/100
	
* summarize the value of sales in shillings
	sum 			harvvlush, detail
	*** mean 146,570 min 0, max 1.30e+07
	*** much more inline with other years
		*** 2010: mean 126,886 min 0, max 1.01e+07
		*** 2011: mean 238,674 min 10, max 4.56e+07

* generate crop is USD
	gen 		cropvl = harvvlush / 2790.3360
	lab var 	cropvl "total value of harvest in 2015 USD"
	*** value comes from World Bank: world_bank_exchange_rates.xlxs
	
	sum 		cropvl, detail
	*** mean 79.87, min 0, max 7084
	*** much more inline with other years
		*** 2010: mean 62.54, min 0, max 4968
		*** 2011: mean 100.5, min 0, max 8304
	
	
* **********************************************************************
* 4 - generate sold harvested values
* **********************************************************************

* drop converstion factor variables
	drop			crop_code unit_code condition_code ucaconversion ///
						medconversion medcount borrowed unit
					
* rename units and condition
	rename			A5aq7c unit
	
* replace unit with 1 if unit is missing
	replace			unit = 1 if unit == .
	
* merge conversion file in for sold
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 3304 from master
	*** vast majority (97%) have harvqtykg == 0
	
	drop			if _merge == 2
	
* most unmatched seem to be 0 production and unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						harvqtykg == 0
	*** replaces 3218 of the 3304 unmatched obs
	
* replace missing ucaconversion with kg if unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						unit == 1
	*** replaces 570
	
* replace missing ucaconversion with median
	replace			ucaconversion = medconversion if ucaconversion == .
	*** 504 changes made, only 72 missing left
	
* set remaining missing equal to conversion factor in data
	replace			ucaconversion = A5aq7b if ucaconversion == .
	*** 72 changes made, now have conversion factor for all
	
* replace zeros in sold data as missing
	replace			A5aq7a = . if A5aq7a == 0
	
* convert quantity sold into kg
	gen 			harvkgsold = A5aq7a*ucaconversion
	lab	var			harvkgsold "quantity sold, in kilograms"

	sum				harvkgsold, detail
	*** 0.02 min, mean 593, max 120,000

* replace missing values to 0
	replace 		cropvl = 0 if cropvl == .
	replace 		harvkgsold = 0 if harvkgsold == .

* collapse the data to the crop level so that our imputations are reproducable and consistent
	collapse 		(sum) harvqtykg cropvl harvkgsold, ///
						by(hhid prcid pltid cropid)

	isid 			hhid prcid pltid cropid	

* revert 0 to missing values
	replace 		cropvl = . if cropvl == 0
	replace 		harvkgsold = . if harvkgsold == 0	
	
	
* ********************************************************************
* 5 - generate price data
* ********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2009_GSEC1"
	*** 21 unmatched from master
	
	drop 			if _merge == 2
	drop			_merge
	
* look at crop value in USD
	sum 			cropvl, detail
	*** max 7084, mean 82, min 0
	
* condensed crop codes
	inspect 		cropid
	*** generally things look all right - only 43 unique values 

* gen price per kg
	sort 			cropid
	by 				cropid: gen cropprice = cropvl / harvkgsold 
	sum 			cropprice, detail
	*** mean = 1.50, max = 653, min = 0
	*** there are some very large prices, replace with missing
	
	replace			cropprice = . if cropprice > 300
	replace			cropprice = . if cropprice > 5 & cropid == 741
	*** 6 replaced
	
* make datasets with crop price information
	preserve
	collapse 		(p50) p_parish=cropprice (count) n_parish=cropprice, by(cropid region district county subcounty parish)
	save 			"$export/2009_agsec5a_p1.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_subcounty=cropprice (count) n_subcounty=cropprice, by(cropid region district county subcounty)
	save 			"$export/2009_agsec5a_p2.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_county=cropprice (count) n_county=cropprice, by(cropid region district county)
	save 			"$export/2009_agsec5a_p3.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_dist=cropprice (count) n_district=cropprice, by(cropid region district)
	save 			"$export/2009_agsec5a_p4.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_reg=cropprice (count) n_reg=cropprice, by(cropid region)
	save 			"$export/2009_agsec5a_p5.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
	save 			"$export/2009_agsec5a_p6.dta", replace 	
	restore
	
* merge the price datasets back in
	merge m:1 cropid region district county subcounty parish		using "$export/2009_agsec5a_p1.dta", gen(p1)
	*** all observations matched
	
	merge m:1 cropid region district county subcounty		using "$export/2009_agsec5a_p2.dta", gen(p2)
	*** all observations matched

	merge m:1 cropid region district county				using "$export/2009_agsec5a_p3.dta", gen(p3)
	*** all observations matched
	
	merge m:1 cropid region district				using "$export/2009_agsec5a_p4.dta", gen(p4)
	*** all observations matched
	
	merge m:1 cropid region						using "$export/2009_agsec5a_p5.dta", gen(p5)
	*** all observations matched
	
	merge m:1 cropid						using "$export/2009_agsec5a_p6.dta", gen(p6)
	*** all observatinos matched

* erase price files
	erase			"$export/2009_agsec5a_p1.dta"
	erase			"$export/2009_agsec5a_p2.dta"
	erase			"$export/2009_agsec5a_p3.dta"
	erase			"$export/2009_agsec5a_p4.dta"
	erase			"$export/2009_agsec5a_p5.dta"
	erase			"$export/2009_agsec5a_p6.dta"

	drop p1 p2 p3 p4 p5 p6

* check to see if we have prices for all crops
	tabstat 		p_parish n_parish p_subcounty n_subcounty p_county n_county p_dist n_district p_reg n_reg p_crop n_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	*** no prices for crop code 650
	
* drop if we are missing prices
	drop			if p_crop == .
	*** dropped 1 observation
	
* make imputed price, using median price where we have at least 10 observations
* this code generlaly files parts of malawi ag_i
* but this differs from Malawi - seems like their code ignores prices 
	gene	 		croppricei = .
	*** 11504 missing values generated
	
	bys 			cropid (region district county subcounty parish hhid prcid pltid): ///
						replace croppricei = p_parish if n_parish>=10 & missing(croppricei)
	*** 335 replaced
	
	bys 			cropid (region district county subcounty parish hhid prcid pltid): ///
						replace croppricei = p_subcounty if p_subcounty>=10 & missing(croppricei)
	*** 55 replaced
	
	bys 			cropid (region district county subcounty parish hhid prcid pltid): ///
						replace croppricei = p_county if n_county>=10 & missing(croppricei)
	*** 1363 replaced 
	
	bys 			cropid (region district county subcounty parish hhid prcid pltid): ///
						replace croppricei = p_dist if n_district>=10 & missing(croppricei)
	*** 1990 replaced
	
	bys 			cropid (region district county subcounty parish hhid prcid pltid): ///
						replace croppricei = p_reg if n_reg>=10 & missing(croppricei)
	*** 7032 replaced 
	
	bys 			cropid (region district county subcounty parish hhid prcid pltid): ///
						replace croppricei = p_crop if missing(croppricei)
	*** 729 changes
	
	lab	var			croppricei	"implied unit value of crop"

* verify that prices exist for all crops
	mdesc 			croppricei
	*** no missing
	
	sum 			cropprice croppricei
	*** mean = 0.370, max = 54.80

	
* **********************************************************************
* 6 - impute harvqtykg
* **********************************************************************

* summarize harvest quantity prior to imputations
	sum				harvqtykg
	*** mean 382, max 80,200

* replace observations 3 std deviation from the mean and impute missing
	*** 3 std dev from mean is 
	sum 			harvqtykg, detail
	replace			harvqtykg = . if harvqtykg > `r(p50)'+ (3*`r(sd)')
	*** 92 changed to missing

* impute missing harvqtykg
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously

* impute harvqtykg	
	mi register			imputed harvqtykg // identify harvqty variable to be imputed
	sort				hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 			pmm harvqtykg i.district i.cropid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* inspect imputation 
	sum 				harvqtykg_1_, detail
	*** mean 283, min 0, max 5250

* replace the imputated variable
	replace 			harvqtykg = harvqtykg_1_ 
	*** 92 changes
	
	drop 				harvqtykg_1_ mi_miss
	
	
* ***********************************************************************
* 7 - impute cropvl
* ***********************************************************************	

* summarize value of sales prior to imputations
	sum				cropvl
	*** mean 82 max 7084
	
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
	mi impute 			pmm cropvl i.district i.cropid harvqtykg, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap					
	mi 				unset	
	
* how did impute go?
	sum 			cropvl_1_, detail
	*** mean 44.56, max 743

	replace 		cropvl = cropvl_1_
	*** 8302 changes
	
	drop 			cropvl_1_ mi_miss
	
* do harvest value and harvest quantity contradict?
	replace 		cropvl = 0 if harvqty == 0
	*** 3104 changes made
	
		
* ********************************************************************
* 8 - impute cropvalue from sales
* ********************************************************************	
	
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
	*** mean 65.5, max 81,744

* replace any +3 s.d. away from median as missing, by crop	
	sum				cropvalue, detail
	replace			cropvalue = . if cropvalue > `r(p50)'+ (3*`r(sd)')
	*** replaced 17 values
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed cropvalue // identify cropvalue as the variable being imputed
	sort			hhid prcid pltid cropid, stable // sort to ensure reproducability of results
	mi impute 		pmm cropvalue i.district i.cropid, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did impute go?
	sum 			cropvalue_1_, detail
	*** mean 46.36, max 2676
	
	replace			cropvalue = cropvalue_1_
	lab var			cropvalue "value of harvest, imputed"
	*** 17 changes
	
	drop 			cropvalue_1_ mi_miss

	
* **********************************************************************
* 9 - end matter, clean up to save
* **********************************************************************

* summarize crop value, imputed crop value, and maize harvest
	sum				cropvl
	*** mean 35.31 max 743
	sum				cropvalue
	*** mean 46.56, max 2676
	sum				harvqtykg if cropid == 130
	*** mean 236.57 max 5180

* despite all the work to get prices and impute values
* this process does not seem to work as well in Uganda as in other countries
* so we will got with crop value based on the imputation in sec 7
	replace			cropvalue = cropvl
	replace			cropvalue = 0 if cropvalue == .
	
	keep 			hhid prcid pltid cropvalue harvqtykg region district ///
						county subcounty parish cropid wgt09wosplits ///
						wgt09 hh_status2009

	compress
	describe
	summarize

* save file
	save 			"$export/2009_AGSEC5A.dta", replace


* close the log
	log	close

/* END */
