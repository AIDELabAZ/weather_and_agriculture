* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Niger, WAVE 1 (2011), POST HARVEST, ecvmaas2e_p2_en
	* determines primary crops, cleans harvest (quantity in kg)
	* determines prices that are already in USD
	* determines harvest for all crops - to determine value 
	* outputs clean data file ready for combination with wave 1 plot data

* assumes
	* access to all raw data
	* cleaned 2011_ms00p1.dta
	
* To Do:
	* done


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=		"$data/household_data/niger/wave_1/raw"
	loc		export	=		"$data/household_data/niger/wave_1/refined"
	loc		logout	= 		"$data/household_data/niger/logs"

* open log
	cap 	log 	close
	log 	using	"`logout'/2011_as2ep2", append

	
* **********************************************************************
* 1 - describing plot size - self-reported and GPS
* **********************************************************************
	
* import the first relevant data file
	use				"`root'/ecvmaas2e_p2_en", clear
	
	duplicates 		drop
	
	rename 			passage visit
	label 			var visit "number of visit - wave number"
	rename			grappe clusterid
	label 			var clusterid "cluster number"
	rename			menage hh_num
	label 			var hh_num "household number - not unique id"
	rename 			as02eq0 ord 
	label 			var ord "number of order"
	*** note that ord is the id number
	
	rename 			as02eq01 field 
	label 			var field "field number"
	rename 			as02eq03 parcel 
	label 			var parcel "parcel number"
	rename			as02eq06 cropid
	*** can't find "extension" variable like they have in wave 2
	
	tab 			cropid
	*** main crop is "mil" = millet 
	*** cropcode for millet == 1
	*** second crop is cowpea, third is sorghum and then peanuts a distant fourth
	
* drop if parcel was not planted
	drop			if as02eq04 == 2
	*** 108 observations deleted
	
* drop if crop is "other"
	drop if cropid == 48
	*** 31 observations dropped
	
* rename variables associated with harvest
	rename 			as02eq07c harvkg 
	rename 			as02eq07a harv 

* make harvkg 0 if household said they harvested nothing
	replace			harvkg = 0 if harvkg == . & harv == 0 	
	*** 3140 changes
	
* make harvkg missing if household said they did not harvest
	replace 		harvkg = . if harvkg == 0 & harv != 0 
	*** 0 changes

* replace miscoded variables as missing 
	replace			harvkg = . if harvkg > 999997 
	replace 		harv = 0 if harvkg == . & harv == 999999
	replace 		harvkg = 0 if harv == 0
	*** 11 changes (obs = 999998 and 999999) - seems to be . in many cases for Niger
	replace 		harvkg = 0 if harv == .
	replace 		harv = 0 if harvkg == 0 & harv == .
	*** 5 changes made
	
* convert missing harvest data to zero if harvest was lost to event
	replace			harvkg = 0 if as02eq08 == 1 & as02eq09 == 100
	*** 23 changes made

* rename variables
	rename 			as02eq11 soldprodsold
	rename			as02eq13 earnwaf
	rename 			as02eq12c harvkgsold 
	
* collapse to get rid of multiple observations of same crop on same parcel
	collapse		(sum) harv harvkg soldprodsold harvkgsold earnwaf ///
						(max) as02eq08 as02eq09, ///
						by(hid visit clusterid hh_num field parcel cropid)
	
* need to include hid field parcel to uniquely identify
	sort 			hid field parcel cropid
	isid 			hid field parcel cropid
	
	
* **********************************************************************
* 2 - generate harvested quantities
* **********************************************************************

* examine quantity harvested variable
	lab	var			harvkg "quantity harvested, in kilograms"
	sum				harvkg, detail
	*** this is across all crops
	*** average  127.11, max 15000, min 0 

* replace any +3 s.d. away from median as missing
	replace			harvkg = . if harvkg > `r(p50)'+(3*`r(sd)')
	sum				harvkg, detail
	*** replaced 119 values, max is now 1392 
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed harvkg // identify harvkg as the variable being imputed
	sort			hid field parcel, stable // sort to ensure reproducability of results
	mi impute 		pmm harvkg i.clusterid i.cropid, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss
	tabstat			harvkg harvkg_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			harvkg = harvkg_1_
	lab var			harvkg "kg of harvest, imputed"
	drop			harvkg_1_
	sum 			harvkg
	*** imputed 119 observations
	*** mean from 127.11 to 97.67, max unchanged at 1392
	

* **********************************************************************
* 3 - generate sold harvested values
* **********************************************************************

* examine market participation 
	tab 			soldprod
	replace			soldprod = . if soldprod == 9 
	tab 			soldprod 
	*** 1300 (10.86 percent) sold crops 

* examine kg harvest value sold
	tab 			harvkgsold , missing
	lab	var			harvkgsold "quantity harvested and sold, in kilograms"
	*** 10795 missing
	
	replace			harvkgsold  = . if harvkgsold == 9999 
	*** 9 changed to missing (obs = 9999) - seems to be . in many cases for Niger
	
* examine quantity harvested variable 
	sum				harvkgsold, detail
	*** this is across all crops
	*** average 245.95, max 11000, min 2 
	*** how could you sell zero - replace to missing

* replace any +3 s.d. away from median as missing, by cropid
	sort 			cropid
	sum				harvkgsold, detail 
	by 				cropid: replace	harvkgsold = . if harvkgsold > `r(p50)'+ (3*`r(sd)')
	sum				harvkgsold, detail
	*** replaced 32 values, max is now 2595, mean 122.9  
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed harvkgsold // identify harvkgsold as the variable being imputed
	sort			hid field parcel, stable // sort to ensure reproducability of results
	mi impute 		pmm harvkgsold i.clusterid i.cropid, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss
	tabstat			harvkgsold harvkgsold_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			harvkgsold = harvkgsold_1_ if soldprod == 1
	lab var			harvkgsold "kg of harvest sold, imputed (only if produce was sold)"
	drop			harvkgsold_1_
	*** imputed observations changed 45 observations for people who sold 
	*** mean 122.9 to 148.83, max stays at 2595 
	
* check out amount sold
* currently reported in West African CFA franc
	tab 			earnwaf
	replace 		earnwaf = . if earnwaf == 9999999 
	*** 2 changed to missing

* convert to usd
	gen 			earn = earnwaf/517.0391802
	lab var			earn 	"total earnings from sales in 2010 USD"
	tab 			earn, missing
	*** 10787 missing
	sum				earn, detail
	*** mean 60.9, max 4255, min 0.3868
	*** total of 1273 observations 
	
	
* **********************************************************************
* 4 - price information - following ag_i in Malawi 
* **********************************************************************

* merge in regional information 
	merge m:1		hid using "`export'/2011_ms00p1"
	*** 12058 matched, 2 from master not matched, 1720 from using (which is fine)
	keep if _merge == 3
	drop _merge

* condensed crop codes
	inspect 		cropid
	*** generally things look all right - only 30 unique values 

* gen price per kg
	sort 			cropid
	by 				cropid: gen cropprice = earn / harvkgsold 
	*** 10785 missing values, but 10,661 did not sell
	sum 			cropprice, detail
	*** mean = 0.427, max = 10.82, min = 0.0193
	*** will do some imputations later

* rename enumeration zd
	rename 			enumeration zd
	lab var 		zd "enumeration zone"
	
* make datasets with crop price information
	preserve
	collapse 		(p50) p_zd=cropprice (count) n_zd=cropprice, by(cropid region dept canton zd)
	save 			"`export'/2011_as2ep2_p1.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_can=cropprice (count) n_can=cropprice, by(cropid region dept canton)
	save 			"`export'/2011_as2ep2_p2.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_dept=cropprice (count) n_dept=cropprice, by(cropid region dept)
	save 			"`export'/2011_as2ep2_p3.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_reg=cropprice (count) n_reg=cropprice, by(cropid region)
	save 			"`export'/2011_as2ep2_p4.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
	save 			"`export'/2011_as2ep2_p5.dta", replace 
	restore
			
* **********************************************************************
* 5 - merge back in prices 
* **********************************************************************
	
* merge price data back into dataset
	
	merge m:1 cropid region dept canton zd	        using "`export'/2011_as2ep2_p1.dta", gen(p1)
	drop			if p1 == 2
	*** 1 observation deleted
	
	merge m:1 cropid region dept canton 	        using "`export'/2011_as2ep2_p2.dta", gen(p2)
	drop			if p2 == 2
	*** 1 observation deleted

	merge m:1 cropid region dept 			        using "`export'/2011_as2ep2_p3.dta", gen(p3)
	drop			if p3 == 2
	*** 1 observation deleted

	merge m:1 cropid region 						using "`export'/2011_as2ep2_p4.dta", gen(p4)
	drop			if p4 == 2
	*** 1 observation deleted
	
	merge m:1 cropid 						        using "`export'/2011_as2ep2_p5.dta", gen(p5)
	keep			if p5 == 3
	*** 1 observation deleted
	
* erase price files
	erase			"`export'/2011_as2ep2_p1.dta"
	erase			"`export'/2011_as2ep2_p2.dta"
	erase			"`export'/2011_as2ep2_p3.dta"
	erase			"`export'/2011_as2ep2_p4.dta"
	erase			"`export'/2011_as2ep2_p5.dta"
	
	drop p1 p2 p3 p4 p5

* check to see if we have prices for all crops
	tabstat 		p_can n_can p_dept n_dept p_reg n_reg p_crop n_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	*** no prices for cucumbeer, gourd, cotton, fonio, wheat, gourd, souchet
	*** few observations in those crops
	
* drop if we are missing prices
	drop			if p_crop == .
	*** dropped 34 observations
	
* make imputed price, using median price where we have at least 10 observations
* this code generlaly files parts of malawi ag_i
* but this differs from Malawi - seems like their code ignores prices 
	gene	 		croppricei = .
	*** 11916 missing values generated
	
	bys cropid (hid field parcel): replace croppricei = p_zd if n_zd>=10 & missing(croppricei)
	*** 11746 replaced
	bys cropid (hid field parcel): replace croppricei = p_can if n_can>=10 & missing(croppricei)
	*** 0 replaced
	bys cropid (hid field parcel): replace croppricei = p_dept if n_dept>=10 & missing(croppricei)
	*** 0 replaced 
	bys cropid (hid field parcel): replace croppricei = p_reg if n_reg>=10 & missing(croppricei)
	*** 0 replaced
	bys cropid (hid field parcel): replace croppricei = p_crop if missing(croppricei)
	*** 170 replaced 
	lab	var			croppricei	"implied unit value of crop"

* verify that prices exist for all crops
	mdesc 			croppricei
	*** 0 missing
	
	sum 			cropprice croppricei
	*** mean = 0.316, max = 3.245
	
* generate value of harvest 
	gen				cropvalue = harvkg * croppricei
	label 			variable cropvalue	"implied value of crops" 
	
* verify that we have crop value for all observations
	mdesc 			cropvalue
	*** 0 missing

* replace any +3 s.d. away from median as missing, by cropid
	sum 			cropvalue, detail
	*** mean 29.0, max 1135.6
	replace			cropvalue = . if cropvalue > `r(p50)'+ (3*`r(sd)')
	sum				cropvalue, detail
	*** replaced 352 values
	*** reduces mean to 21.92, max to 170.66 
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed cropvalue // identify cropvalue as the variable being imputed
	sort			hid field parcel, stable // sort to ensure reproducability of results
	mi impute 		pmm cropvalue i.clusterid i.cropid, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss
	tabstat			cropvalue cropvalue_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			cropvalue = cropvalue_1_
	lab var			cropvalue "value of harvest, imputed"
	drop			cropvalue_1_
	sum 			cropvalue
	*** imputed 352 out of 11916 total observations
	*** mean from 21.9 to 22.6, max at 170.66 no change in max

	
* **********************************************************************
* 6 - examine millet harvest quantities
* **********************************************************************

* check to see if outliers can be dealt with
	sum 			harvkg if cropid == 1
	*** mean = 166.68, max = 1357, min = 0 
	
* generate new variable that measures millet (1) harvest
	gen 			mz_hrv = harvkg 	if 	cropid == 1
	*** for consistency going to keep the mz abbreviation though crop is millet
	
* create variable = 1 if millet was damaged	
	replace 		as02eq09 = . if as02eq09 == 999
	gen				mz_damaged = 1		if  cropid == 1 ///
						&  as02eq08 == 1 & as02eq09 == 100
	lab var			mz_damaged "=1 if millet crop was lost"
	sort			mz_damaged
	tab 			mz_damaged, missing
	replace			mz_damaged = 0 if mz_damaged == . & cropid == 1
	replace			mz_hrv = 0 if mz_damaged == 1
	*** all damaged millet have harvkg = zero
						
* replace any +3 s.d. away from median as missing
	sum				mz_hrv, detail
	replace			mz_hrv = . if mz_hrv > `r(p50)' + (3*`r(sd)')
	sum				mz_hrv
	*** replaced 142 values, max is now 710 instead of 1357
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed mz_hrv // identify mz_hrv as the variable being imputed
	sort			hid field parcel, stable // sort to ensure reproducability of results
	mi impute 		pmm mz_hrv i.clusterid if cropid == 1, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss1 if cropid == 1
	tabstat			mz_hrv mz_hrv_1_ if cropid == 1, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			mz_hrv = mz_hrv_1_  if cropid == 1
	lab var			mz_hrv "Quantity of millet harvested (kg)"
	drop			mz_hrv_1_
	sum				mz_hrv
	*** imputed 142 values out of 4451 total values
	*** mean from 141.7 to 143.9, max 710 (no change), min 0 (no change)

* replace non-maize harvest values as missing
	replace			mz_hrv = . if mz_damaged == 0 & mz_hrv == 0
	*** 32 changes made 

	
* **********************************************************************
* 7 - end matter, clean up to save
* **********************************************************************

* create unique household-plot identifier
	sort			hid field parcel cropid
	isid			hid field parcel cropid
	egen			crop_id = group(hid field parcel cropid)
	lab var			crop_id "unique crop, field, and parcel identifier"

	keep 			crop_id hid clusterid hh_num field parcel cropid ///
						mz_hrv mz_damaged cropvalue harvkg
					
	rename 			cropvalue vl_hrv 
	lab	var			vl_hrv "value of harvest, in 2010 USD"

	compress
	describe
	summarize

* save file
	save 			"`export'/2011_as2ep2.dta", replace

* close the log
	log		close

/* END */
