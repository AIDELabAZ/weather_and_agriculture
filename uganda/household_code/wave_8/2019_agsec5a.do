* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on: 19 Apr 24
* Edited by: KCD
* Stata v.18, Mac

* does
	* Crop output
	* reads Uganda wave 3 crop output (2019_agsec5a) for the 1st season
	* 3A - 5A are questionaires for the first planting season
	* 3B - 5B are questionaires for the second planting season

* assumes
	* access to raw data 
	* mdesc.ado

* TO DO:
	*done

	
* **********************************************************************
**#0 - setup
* **********************************************************************

* define paths	
	global root 		= "$data/household_data/uganda/wave_8/raw"  
	global export 		= "$data/household_data/uganda/wave_8/refined"
	global logout 		= "$data/household_data/uganda/logs"
	global conv 		= "$data/household_data/uganda/conversion_files"  
	
* open log	
	cap log 		close
	log using 		"$logout/2019_agsec5a", append
	
* **********************************************************************
**#1 - import data and rename variables
* **********************************************************************

* import wave 8 season A
	use 			"$root/agric/agsec5a.dta", clear
	
* rename variables
		
	rename 			cropID cropid
	rename			parcelID prcid
	rename 			s5aq06b_1 unit
	rename			s5aq06c_1 condition
	rename 			s5aq06e_1 harvmonth
		
* Generate hhidnew as string of hhid, change hhid to str as hhidnew, rename hhid to hhidoldold, and hhidnew to hhid  
	gen hhidnew = ustrtrim(hhid)
	recast str32 hhidnew
	rename hhid hhidoldold
	rename hhidnew hhid
	
* sort for ease of access
	sort 			hhid prcid pltid cropid unit condition harvmonth
	
* drop observations from plots that did not harvest because crop was immature
	drop if s5aq05_2 == 1
	*** 1034 observations deleted

* missing cropid's also lack crop names, drop those observations
	mdesc 			cropid
	*** 0 obs
	
* drop cropid is other, fallow, pasture, and trees
	drop 			if cropid > 880
	*** 24 observations dropped
	
* replace harvests with 99999 with a 0, 99999 is code for missing
	replace 		s5aq06a_1 = 0 if s5aq06a_1 == 99999
	*** 0 changed to zero
	
* replace missing cropharvests with 0
	replace 		s5aq06a_1 = 0 if s5aq06a_1 == .
	*** 408 changed to zero

* missing prcid and pltid don't allow for unique id, drop missing
	drop			if prcid == .
	drop			if pltid == .
	duplicates 		drop
	*** 0 dropped, still not unique ID
	
	
* **********************************************************************
**#2 - merge kg conversion file and create harvested quantity
* **********************************************************************

* coffee has 3 identifications in this file, but only one in conversion file 
	replace 		cropid = 810 if cropid == 811
	replace 		cropid = 810 if cropid == 812
	
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 1322 from master 
	*** unmatched 762 from using
	*** total unmatched, 2569 
	
* drop from using
	drop 			if _merge == 2
	*** 781 observations deleted 
	
* how many unmatched had a harvest of 0
	tab 			s5aq06a_1 if _merge == 1
	*** 23.27% have a harvest of 0
	
* how many unmatched because they used "other" to categorize the state of harvest?
	tab 			condition if _merge == 1
	*** No "other" category
	
	tab 			cropid condition if condition != 99 & _merge == 1 & condition !=.
	
	tab 			unit if _merge == 1
	tab				unit if _merge == 1, nolabel

* replace ucaconversion to 1 if the harvest is 0
	replace 		ucaconversion = 1 if s5aq06a_1 == 0 & _merge == 1
	*** 416 changes

* manually replace conversion for the kilograms and sacks 
* if the condition is other condition and the observation is unmatched

	*kgs
		replace 		ucaconversion = 1 if unit == 1 & _merge == 1
		*** 348 changes made
		
	*sack 120 kgs
		replace 		ucaconversion = 120 if unit == 9 & _merge == 1
		*** 56 changes made
	*sack 100 kgs
		replace 		ucaconversion = 100 if unit == 10 & _merge == 1
		*** 328 changes made
	* sack 80 kgs
		replace 		ucaconversion = 80 if unit == 11 & _merge == 1
		*** 0 changes made
	* sack 50 kgs
		replace 		ucaconversion = 50 if unit == 12 & _merge == 1
		*** 38 changes made
	* jerrican 20 kgs
		replace 		ucaconversion = 20 if unit == 14 & _merge == 1
		*** 9 changes
		
	* jerrican 10 kgs
		replace 		ucaconversion = 10 if unit == 15 & _merge == 1
		*** 3 changes
		
	* jerrican 5 kgs
		replace 		ucaconversion = 5 if unit == 16 & _merge == 1
		*** 5 changes
		
	* jerrican 2 kgs
		replace 		ucaconversion = 2 if unit == 18 & _merge == 1
		*** 2 changes
		
	* tin 20 kgs
		replace 		ucaconversion = 20 if unit == 20 & _merge == 1
		*** 79 changes
		
	* tin 5 kgs
		replace 		ucaconversion = 5 if unit == 21 & _merge == 1
		*** 4 changes

	* 15 kg plastic Basin
		replace 		ucaconversion = 15 if unit == 22 & _merge == 1	
		*** 1 change
		
	* kimbo 2 kg 
		replace 		ucaconversion = 2 if unit == 29 & _merge == 1
		*** 3 changes
		
	* kimbo 1 kg
		replace 		ucaconversion = 1 if unit == 30 & _merge == 1
		*** 1 change

	* kimbo 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 31 & _merge == 1	
		*** 2 changes 

	* cup 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 32 & _merge == 1		
		*** 0 changes
		
	* basket 20 kg 
		replace 		ucaconversion = 20 if unit == 37 & _merge == 1
		*** 3 changes
		
	* basket 10 kg 
		replace 		ucaconversion = 10 if unit == 38 & _merge == 1
		*** 0 changes 

	* basket 5 kg 
		replace 		ucaconversion = 5 if unit == 39 & _merge == 1	
		*** 1 change

	* basket 2 kg
		replace 		ucaconversion = 2 if unit == 40 & _merge == 1	
		*** 0 changes
		
	* nomi 1 kg
		replace 		ucaconversion = 1 if unit == 119 & _merge == 1	
		*** 0 changes

	* nomi 0.5 kg
		replace 		ucaconversion = 0.5 if unit == 120 & _merge == 1
		*** 0 change 
			
* drop the unmatched remaining observations
	drop 			if _merge == 1 & ucaconversion == .
	*** 299 observatinos deleted

	replace 			ucaconversion = medconversion if _merge == 3 & ucaconversion == .
	*** 232 changes made
	
		mdesc 			ucaconversion
		*** 0 missing
		
	drop 			_merge
	
	tab				cropid
	
	*** beans are the most numerous crop being 17.90% of crops planted
	*** banana food is the second highest being 17.43
	***	maize is the third highest being 16.04%
	*** maize will be main crop following most other countries in the study
	
* Convert harv quantity to kg
	*** harvest quantity is in a variety of measurements
	*** included in the file are the conversions from other measurements to kg
	
* replace missing harvest quantity to 0
	replace 		s5aq06a_1 = 0 if s5aq06a_1 == .
	*** no changes
	
* Convert harv quantity to kg
	gen 			harvqtykg = s5aq06a_1*ucaconversion
	label var		harvqtykg "quantity of crop harvested (kg)"
	mdesc 			harvqtykg
	*** all converted
	
* summarize harvest quantity
	sum				harvqtykg
	*** three crazy values, replace with missing
	
	replace			harvqtykg = . if harvqtykg > 100000
	*** replaced 1 observations
	
* summarize maize quantity harvest
	sum				harvqtykg if cropid == 130
	*** 233.099 mean, 13750 max
	
	
* **********************************************************************
**#3 - value of harvest
* **********************************************************************

* value of crop sold in shillings
	rename			s5aq08_1 harvvlush
	label var 		harvvlush "Value of crop sold in ugandan shilling"
	
* summarize the value of sales in shillings
	sum 			harvvlush, detail
	*** mean 349634.8 min 50, max 1.50e+07 

* generate crop is USD
	gen 			cropvl = harvvlush / 3029.3832
	lab var 		cropvl "total value of harvest in 2015 USD"
	*** value comes from World Bank. Used excel file "world_bank_exchange_rates.xlxs"
	
	sum 			cropvl, detail
	*** mean 115.4145, min 0.016, max 4951.503  
	
	
* **********************************************************************
**#4 - generate sold harvested values
* **********************************************************************

* drop converstion factor variables
	drop			crop_code unit_code condition_code ucaconversion ///
						medconversion medcount borrowed unit
					
* rename units and condition
	rename			s5aq07c_1 unit
	
* replace unit with 1 if unit is missing
	replace			unit = 1 if unit == .
	
* merge conversion file in for sold
	merge m:1 		cropid unit condition using ///
						"$conv/ValidCropUnitConditionCombinations.dta" 
	*** unmatched 1022 from master
	
	drop			if _merge == 2
	*** 843 observations deleted
	
* most unmatched seem to be 0 production and unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						harvqtykg == 0
	*** replaces 416 
	
* replace missing ucaconversion with kg if unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						unit == 1
	*** replaces 777
	
* replace missing ucaconversion with median
	replace			ucaconversion = medconversion if ucaconversion == .
	*** 301 changes made, 226 missing left
	
* set remaining missing equal to conversion factor in data
	replace			ucaconversion = unit if ucaconversion == .
	*** 225 changes made, now have conversion factor for all
	
	**** STOP HERE
	
* replace zeros in sold data as missing
	replace			a5aq7a = . if a5aq7a == 0
	
* convert quantity sold into kg
	gen 			harvkgsold = a5aq7a*ucaconversion
	lab	var			harvkgsold "quantity sold, in kilograms"

	sum				harvkgsold, detail
	*** 0.04 min, mean 550, max 80000

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
		
	
	
	
	
	
	
	
	
* replace missing ucaconversion with kg if unit = kg
	replace			ucaconversion = 1 if ucaconversion == . & ///
						unit == 1
	*** replaces 186
	
* replace missing ucaconversion with median
	replace			ucaconversion = medconversion if ucaconversion == .
	*** 44 changes made
	
* replace zeros in sold data as missing
	replace			s5aq07a_1 = . if s5aq07a_1 == 0
	*** 3633 real changes made (converted to missing?)
	
* convert quantity sold into kg
	gen 			harvkgsold = s5aq07a_1*ucaconversion
	lab	var			harvkgsold "quantity sold, in kilograms"

	sum				harvkgsold, detail
	*** 0.5 min, mean 970.06, max 75000

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
	
	
* ********************************************************************
**#5 - generate price data
* ********************************************************************	
	
* merge the location identification
	merge m:1 		hhid using "$export/2019_gsec1"
	*** 3 unmatched from master, 1113 from using
	
	drop 			if _merge == 2
	drop			_merge
	
* encode district for the imputation
	encode 			district, gen (districtdstrng)
	encode			county, gen (countydstrng)
	encode			subcounty, gen (subcountydstrng)
	encode			parish, gen (parishdstrng)

* look at crop value in USD
	sum 			cropvl, detail
	*** max 8304, mean 103, min 0.004
	
* condensed crop codes
	inspect 		cropid
	*** generally things look all right - only 42 unique values 

* gen price per kg
	sort 			cropid
	by 				cropid: gen cropprice = cropvl / harvkgsold 
	sum 			cropprice, detail
	*** mean = 0.457, max = 61.24, min = 0
	*** will do some imputations later
	
* make datasets with crop price information
	preserve
	collapse 		(p50) p_parish=cropprice (count) n_parish=cropprice, by(cropid region districtdstrng countydstrng subcountydstrng parishdstrng)
	save 			"`export'/2011_agsec5a_p1.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_subcounty=cropprice (count) n_subcounty=cropprice, by(cropid region districtdstrng countydstrng subcountydstrng)
	save 			"`export'/2011_agsec5a_p2.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_county=cropprice (count) n_county=cropprice, by(cropid region districtdstrng countydstrng)
	save 			"`export'/2011_agsec5a_p3.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_dist=cropprice (count) n_district=cropprice, by(cropid region districtdstrng)
	save 			"`export'/2011_agsec5a_p4.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_reg=cropprice (count) n_reg=cropprice, by(cropid region)
	save 			"`export'/2011_agsec5a_p5.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
	save 			"`export'/2011_agsec5a_p6.dta", replace 	
	restore
	
* merge the price datasets back in
	merge m:1 cropid region districtdstrng countydstrng subcountydstrng parishdstrng	        using "`export'/2011_agsec5a_p1.dta", gen(p1)
	*** all observations matched
	
	merge m:1 cropid region districtdstrng countydstrng subcountydstrng 	        using "`export'/2011_agsec5a_p2.dta", gen(p2)
	*** all observations matched

	merge m:1 cropid region districtdstrng countydstrng 			        using "`export'/2011_agsec5a_p3.dta", gen(p3)
	*** all observations matched
	
	merge m:1 cropid region districtdstrng 						using "`export'/2011_agsec5a_p4.dta", gen(p4)
	*** all observations matched
	
	merge m:1 cropid region						        using "`export'/2011_agsec5a_p5.dta", gen(p5)
	*** all observations matched
	
	merge m:1 cropid 						        using "`export'/2011_agsec5a_p6.dta", gen(p6)
	*** all observatinos matched

* erase price files
	erase			"`export'/2011_agsec5a_p1.dta"
	erase			"`export'/2011_agsec5a_p2.dta"
	erase			"`export'/2011_agsec5a_p3.dta"
	erase			"`export'/2011_agsec5a_p4.dta"
	erase			"`export'/2011_agsec5a_p5.dta"
	erase			"`export'/2011_agsec5a_p6.dta"

	drop p1 p2 p3 p4 p5 p6

* check to see if we have prices for all crops
	tabstat 		p_parish n_parish p_subcounty n_subcounty p_county n_county p_dist n_district p_reg n_reg p_crop n_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	*** no prices for wheat, chickpeas, and coco yams
	
* drop if we are missing prices
	drop			if p_crop == .
	*** dropped 3 observations
	
* make imputed price, using median price where we have at least 10 observations
* this code generlaly files parts of malawi ag_i
* but this differs from Malawi - seems like their code ignores prices 
	gene	 		croppricei = .
	*** 9291 missing values generated
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_parish if n_parish>=10 & missing(croppricei)
	*** 647 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_subcounty if p_subcounty>=10 & missing(croppricei)
	*** 10 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_county if n_county>=10 & missing(croppricei)
	*** 1282 replaced 
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_dist if n_district>=10 & missing(croppricei)
	*** 748 replaced
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_reg if n_reg>=10 & missing(croppricei)
	*** 5701 replaced 
	
	bys 			cropid (region districtdstrng countydstrng subcountydstrng parishdstrng hhid prcid pltid): ///
						replace croppricei = p_crop if missing(croppricei)
	*** 903 changes
	
	lab	var			croppricei	"implied unit value of crop"

* verify that prices exist for all crops
	mdesc 			croppricei
	*** no missing
	
	sum 			cropprice croppricei
	*** mean = 0.316, max = 32.97

	
* **********************************************************************
* 6 - impute harvqtykg
* **********************************************************************

* summarize harvest quantity prior to imputations
	sum				harvqtykg
	*** mean 542, max 80,000

* replace observations 3 std deviation from the mean and impute missing
	*** 3 std dev from mean is 
	sum 			harvqtykg, detail
	replace			harvqtykg = . if harvqtykg > `r(p50)'+ (3*`r(sd)')
	*** 111 changed to missing

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
	*** mean 412, min 0, max 5600

* replace the imputated variable
	replace 			harvqtykg = harvqtykg_1_ 
	*** 104 changes
	
	drop 				harvqtykg_1_ mi_miss
	
	
* ***********************************************************************
* 7 - impute cropvl
* ***********************************************************************	

* summarize value of sales prior to imputations
	sum				cropvl
	*** mean 103, max 8304
	
* replace cropvl with missing if over 3 std dev from the mean
	sum 			cropvl, detail
	replace			cropvl = . if cropvl > `r(p50)'+ (3*`r(sd)')
	*** 40 changes
	
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
	*** mean 58.86, max 989

	replace 		cropvl = cropvl_1_
	*** 5539 changes
	
	drop 			cropvl_1_ mi_miss
	
* do harvest value and harvest quantity contradict?
	replace 		cropvl = 0 if harvqty == 0
	*** 397 changes made
	
		
* ********************************************************************
* 8 - impute cropvalue from sales
* ********************************************************************	
	
* generate value of harvest 
	gen				cropvalue = harvqtykg * croppricei
	label 			variable cropvalue	"implied value of crops" 
	
* replace cropvalue with cropvl if cropvl is not missing and crop value is missing
	replace 		cropvalue = cropvl if cropvalue == . & cropvl != .
	*** 4 change
	
* verify that we have crop value for all observations
	mdesc 			cropvalue
	*** 3 missing

* summarize value of harvest prior to imputations	
	sum 			cropvalue
	*** mean 71.5, max 12,365

* replace any +3 s.d. away from median as missing, by crop	
	sum				cropvalue, detail
	replace			cropvalue = . if cropvalue > `r(p50)'+ (3*`r(sd)')
	*** replaced 74 values
	
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
	*** mean 63.38, max 573
	
	replace			cropvalue = cropvalue_1_
	lab var			cropvalue "value of harvest, imputed"
	*** 71 changes
	
	drop 			cropvalue_1_ mi_miss

	
* **********************************************************************
* 9 - end matter, clean up to save
* **********************************************************************

* summarize crop value, imputed crop value, and maize harvest
	sum				cropvl
	*** mean 56.21 max 989
	sum				cropvalue
	*** mean 63.38 max 573
	sum				harvqtykg if cropid == 130
	*** mean 271.27 max 5533
	
* despite all the work to get prices and impute values
* this process does not seem to work as well in Uganda as in other countries
* so we will got with crop value based on the imputation in sec 7
	replace			cropvalue = cropvl
	replace			cropvalue = 0 if cropvalue == .
	
	keep 			hhid prcid pltid cropvalue harvqtykg region district ///
						county subcounty parish cropid hh_status2011 ///
						wgt11 harvmonth

	compress
	describe
	summarize

* save file
		customsave , idvar(hhid) filename("2011_AGSEC5A.dta") ///
			path("`export'") dofile(2011_AGSEC5A) user($user)

* close the log
	log	close

/* END */
