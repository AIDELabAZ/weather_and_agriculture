* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on: 24 May 24
* Edited by: jdm
* Stata v.18

* does
	* Crop output
	* reads Uganda wave 8 crop output (2019_agsec5b) for the 1st season
	* 3B - 5B are questionaires for the first planting season of 2019 (main)
	* 3A - 5A are questionaires for the second planting season of 2018 (secondary)

* assumes
	* access to raw data 
	* mdesc.ado

* TO DO:
	* done

	
* **********************************************************************
**#0 - setup
* **********************************************************************

* define paths	
	global 	root  		"$data/household_data/uganda/wave_8/raw"  
	global  export 		"$data/household_data/uganda/wave_8/refined"
	global 	logout 		"$data/household_data/uganda/logs"
	
* open log	
	cap log 			close
	log using 			"$logout/2019_agsec5b", append
	
	
* **********************************************************************
**#1 - import data and rename variables
* **********************************************************************

* import wave 8 season B
	use 			"$root/agric/agsec5b.dta", clear
	
* rename variables	
	rename 			cropID cropid
	rename			parcelID prcid
	rename 			s5bq06b_1 unit1
	rename 			s5bq06b_2 unit2
	rename			s5bq06c_1 condition1
	rename			s5bq06c_2 condition2
	rename 			s5bq06e_1 harvmonth1  
	rename 			s5bq06e_2 harvmonth2 
	rename			s5bq06d_1 conversion1
	rename			s5bq06d_2 conversion2
	recast 			str32 hhid
		
* sort for ease of access
	describe
	sort 			hhid prcid pltid cropid
	isid 			hhid prcid pltid cropid
	
* drop observations from plots that did not harvest because crop was immature
	drop if s5bq05_2 == 1
	*** 1304 observations deleted

* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 0 obs
	
* drop cropid is other
	drop 			if cropid > 880
	*** 41 observations dropped
	
* replace missing cropharvests with 0
	replace 		s5bq06a_1 = 0 if s5bq06a_1 == .
	*** 680 changed to zero
	replace 		s5bq06a_2 = 0 if s5bq06a_2 == .
	*** 6,705 changed to zero

	
* **********************************************************************
**#2 - merge kg conversion file and create harvested quantity
* **********************************************************************

* coffee has 3 identifications in this file, but only one in conversion file 
	replace 		cropid = 810 if cropid == 811
	replace 		cropid = 810 if cropid == 812
	replace			conversion1 = 0 if conversion1 == .
	replace			conversion2 = 0 if conversion2 == .
	
	tab cropid
	***	maize is the most numerous crop being 20%
	*** beans are the second highest being 17% of crops planted
	*** banana food is the third highest being 15% of crops planted
	*** maize will be main crop following most other countries in the study
	
* Convert harv quantity to kg
	*** harvest quantity is in a variety of measurements and in two conditions
	*** convert quantity to kg for both conditions and add
	gen 			harvqtykg = s5bq06a_1*conversion1 + s5bq06a_2*conversion2
	label var		harvqtykg "quantity of crop harvested (kg)"
	mdesc 			harvqtykg
	*** all converted
	
* summarize harvest quantity
	sum				harvqtykg, detail
	*** two crazy values, replace with missing
	
	replace			harvqtykg = . if harvqtykg > 100000
	*** 2 real change made
	
* summarize maize quantity harvest
	sum				harvqtykg if cropid == 130
	*** 269 mean, 24,000 max
	
	
* **********************************************************************
**#3 - value of harvest
* **********************************************************************

* value of crop sold in shillings
	rename			s5bq08_1 harvvlush1
	label var 		harvvlush1 "Value of crop sold in ugandan shilling"
	rename			s5bq08_2 harvvlush2
	label var 		harvvlush2 "Value of crop sold in ugandan shilling"
	
* summarize the value of sales in shillings
	sum 			harvvlush1, detail
	*** mean 385,665 min 13, max 1.80e+07 
	sum 			harvvlush2, detail
	*** mean 179,257 min 4000, max 1,920,000 

* generate crop is USD
	*** value comes from World Bank. Used excel file "world_bank_exchange_rates.xlxs"
	gen 			cropvl1 = harvvlush1 / 3029.3832
	lab var 		cropvl1 "total value of harvest in 2015 USD"
	*** 5,338 missing values generated
	gen 			cropvl2 = harvvlush2 / 3029.3832
	lab var 		cropvl2 "total value of harvest in 2015 USD"
	*** 7,501 missing values generated
	
	
* **********************************************************************
**#4 - generate sold harvested values
* **********************************************************************

* convert quantity sold into kg
	gen 			harvkgsold1 = s5bq07a_1*conversion1
	replace			harvkgsold1 = 0 if harvkgsold1 == .
	gen 			harvkgsold2 = s5bq07a_2*conversion2
	replace			harvkgsold2 = 0 if harvkgsold2 == .
	gen				harvkgsold = harvkgsold1 + harvkgsold2
	replace			harvkgsold = . if harvkgsold == 0
	*** 4348 missing values generated
	lab	var			harvkgsold "quantity sold, in kilograms"

* deal with the 8 values where sales exceed harvest
	gen 			diff = harvqtykg- harvkgsold
	replace			harvkgsold = harvqtykg if diff < 0
	replace			harvkgsold = . if harvqtyk == .
	*** 8 values replaced
	
	drop			diff
	
	sum				harvkgsold, detail
	*** .5 min, mean 622, max 80,760

* replace missing values to 0
	replace			cropvl1 = 0 if cropvl1 == .
	replace			cropvl2 = 0 if cropvl2 == .
	gen				cropvl = cropvl1 + cropvl2
	replace 		cropvl = 0 if cropvl == .
	replace 		harvkgsold = 0 if harvkgsold == .
	
* collapse the data to the crop level so that our imputations are reproducable and consistent
	collapse 		(sum) harvqtykg cropvl harvkgsold (mean) harvmonth1  harvmonth2, ///
						by(hhid prcid pltid cropid)
	*** got rid of 2 double counts
	
	isid 			hhid prcid pltid cropid	


* revert 0 to missing values
	replace 		cropvl = . if cropvl == 0
	replace 		harvkgsold = . if harvkgsold == 0	
	gen				harvmonth = harvmonth1 if harvmonth1 != .
	replace			harvmonth = (harvmonth + harvmonth2)/2 if ///
					harvmonth1 != . & harvmonth2 != . & harvmonth != .
	drop			harvmonth1 harvmonth2
	lab var 		harvkgsold "Quantity of crop sold in kg"
	lab var 		cropvl "Total value of hcrop sold in 2015 USD"
	
	
* ********************************************************************
**#5 - generate price data
* ********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2019_gsec1"
	*** 0 unmatched from master
	
	drop 			if _merge == 2
	drop			_merge
	
* encode district for the imputation
	encode 			district, gen (districtdstrng)
	encode			county, gen (countydstrng)
	encode			subcounty, gen (subcountydstrng)
	encode			parish, gen (parishdstrng)

* condensed crop codes
	inspect 		cropid
	*** generally things look all right - only 42 unique values 

* gen price per kg
	sort 			cropid
	by 				cropid: gen cropprice = cropvl / harvkgsold 
	sum 			cropprice, detail
	*** mean = 0.49, max = 66, min = 0
	*** will do some imputations later
	
* make datasets with crop price information
	preserve
	collapse 		(p50) p_parish=cropprice (count) n_parish=cropprice, by(cropid region districtdstrng countydstrng subcountydstrng parishdstrng)
	save 			"$export/2019_agsec5a_p1.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_subcounty=cropprice (count) n_subcounty=cropprice, by(cropid region districtdstrng countydstrng subcountydstrng)
	save 			"$export/2019_agsec5a_p2.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_county=cropprice (count) n_county=cropprice, by(cropid region districtdstrng countydstrng)
	save 			"$export/2019_agsec5a_p3.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_dist=cropprice (count) n_district=cropprice, by(cropid region districtdstrng)
	save 			"$export/2019_agsec5a_p4.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_reg=cropprice (count) n_reg=cropprice, by(cropid region)
	save 			"$export/2019_agsec5a_p5.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
	save 			"$export/2019_agsec5a_p6.dta", replace 	
	restore
	
* merge the price datasets back in
	merge m:1 		cropid region districtdstrng countydstrng subcountydstrng parishdstrng	///
						using "$export/2019_agsec5a_p1.dta", gen(p1)
	*** all observations matched
	
	merge m:1 		cropid region districtdstrng countydstrng subcountydstrng ///
						using "$export/2019_agsec5a_p2.dta", gen(p2)
	*** all observations matched

	merge m:1 		cropid region districtdstrng countydstrng ///
						using "$export/2019_agsec5a_p3.dta", gen(p3)
	*** all observations matched
	
	merge m:1 		cropid region districtdstrng ///
						using "$export/2019_agsec5a_p4.dta", gen(p4)
	*** all observations matched
	
	merge m:1 		cropid region ///
						using "$export/2019_agsec5a_p5.dta", gen(p5)
	*** all observations matched
	
	merge m:1 		cropid ///
						using "$export/2019_agsec5a_p6.dta", gen(p6)
	*** all observatinos matched

* erase price files
	erase			"$export/2019_agsec5a_p1.dta"
	erase			"$export/2019_agsec5a_p2.dta"
	erase			"$export/2019_agsec5a_p3.dta"
	erase			"$export/2019_agsec5a_p4.dta"
	erase			"$export/2019_agsec5a_p5.dta"
	erase			"$export/2019_agsec5a_p6.dta"

	drop p1 p2 p3 p4 p5 p6

* check to see if we have prices for all crops
	tabstat 		p_parish n_parish p_subcounty n_subcounty p_county n_county p_dist n_district p_reg n_reg p_crop n_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	*** prices for everything except coco yams
	
* drop if we are missing prices
	drop			if p_crop == .
	*** dropped 1 observations
	
* make imputed price, using median price where we have at least 10 observations
* this code generlaly follows parts of malawi ag_i
* but this differs from Malawi - seems like their code ignores prices 
	gene	 		croppricei = .
	*** 8,007 missing values generated
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_parish if n_parish>=10 & missing(croppricei)
	*** 412 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_subcounty if p_subcounty>=10 & missing(croppricei)
	*** 11 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_county if n_county>=10 & missing(croppricei)
	*** 1272 replaced 
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_dist if n_district>=10 & missing(croppricei)
	*** 659 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_reg if n_reg>=10 & missing(croppricei)
	*** 5,107 replaced 
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_crop if missing(croppricei)
	*** 546 changes
	
	lab	var			croppricei	"implied unit value of crop"

* verify that prices exist for all crops
	mdesc 			croppricei
	*** no missing
	
	sum 			cropprice croppricei
	*** mean = 0.497 v. .394, max = 66 for both

	
* **********************************************************************
* 6 - impute harvqtykg
* **********************************************************************

* summarize harvest quantity prior to imputations
	sum				harvqtykg
	*** mean 436, max 80,760
	
* replace three observations clearly erroneous
	*twoway 		(scatter cropvl harvkgsold)
	replace			harvqtykg = . if harvqtykg == 80760
	replace			harvqtykg = . if harvqtykg == 62500
	replace			harvqtykg = . if harvqtykg == 44000
	replace			harvkgsold = . if harvkgsold == 80760
	replace			harvkgsold = . if harvkgsold == 62500
	replace			harvkgsold = . if harvkgsold == 44000

* replace observations 3 std deviation from the mean and impute missing
	*** 3 std dev from mean is 
	sum 			harvqtykg, detail
	replace			harvqtykg = . if harvqtykg > `r(p50)'+ (3*`r(sd)')
	*** 69 changed to missing

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
	*** mean 311, min 0, max 5184

* replace the imputated variable
	replace 			harvqtykg = harvqtykg_1_ 
	*** 72 changes
	
	drop 				harvqtykg_1_ mi_miss
	
	
* ***********************************************************************
* 7 - impute cropvl
* ***********************************************************************	

* summarize value of sales prior to imputations
	sum				cropvl
	*** mean 117, max 5,941
	
* replace cropvl with missing if over 3 std dev from the mean
	sum 			cropvl, detail
	replace			cropvl = . if cropvl > `r(p50)'+ (3*`r(sd)')
	*** 46 changes
	
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
	*** mean 63, max 871

	replace 		cropvl = cropvl_1_
	*** 4,904 changes
	
	drop 			cropvl_1_ mi_miss
	
* do harvest value and harvest quantity contradict?
	replace 		cropvl = 0 if harvqty == 0
	*** 702 changes made
	
		
* ********************************************************************
* 8 - impute cropvalue from sales
* ********************************************************************	
	
* impute crop value different way using implied prices

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
	*** mean 80, max 15,211

* replace any +3 s.d. away from median as missing, by crop	
	sum				cropvalue, detail
	replace			cropvalue = . if cropvalue > `r(p50)'+ (3*`r(sd)')
	*** replaced 48 values
	
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
	*** mean 70, max 794
	
	replace			cropvalue = cropvalue_1_
	lab var			cropvalue "value of harvest, imputed"
	*** 48 changes
	
	drop 			cropvalue_1_ mi_miss

	
* **********************************************************************
* 9 - end matter, clean up to save
* **********************************************************************

* summarize crop value, imputed crop value, and maize harvest
	sum				cropvl
	*** mean 60 max 871
	sum				cropvalue
	*** mean 70 max 794
	sum				harvqtykg if cropid == 130
	*** mean 214 max 4,770
	
* unlike in previous waves from uganda getting prices and impute values
* seems to work better than in other waves
* so we will go with crop value based on the imputation in sec 8
		
	keep 			hhid prcid pltid cropvalue harvqtykg region district ///
						county subcounty parish cropid harvmonth

	compress
	describe
	summarize

* save file
	save 			"$export/2019_agsec5b.dta", replace

* close the log
	log	close

/* END */
