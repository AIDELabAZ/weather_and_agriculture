* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Niger, WAVE 2 (2014), POST HARVEST, ECVMA2 AS2E1P2
	* file will broadly follow ag_i from Malawi "kitchen sink"
	* cleans harvest sold (quantity in kg)
	* determines prices for merge (five files) into 2014_ase1p2

* assumes
	* access to all raw data
	* cleaned version of 2014_ms00p1

* TO DO:
	* done 
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc 	root	= 	"$data/household_data/niger/wave_2/raw"
	loc 	export	= 	"$data/household_data/niger/wave_2/refined"
	loc 	cnvrt	= 	"$data/household_data/niger/wave_2/raw"
	loc 	logout	= 	"$data/household_data/niger/logs"

* open log
	cap log close 
	log 	using 	"`logout'/2014_as2e2p2", append

	
* **********************************************************************
* 1 - harvest information
* **********************************************************************

* import the first relevant data file
	use				"`root'/ECVMA2_AS2E2P2", clear
		
* need to rename for English
	rename 			PASSAGE visit
	label 			var visit "number of visit"
	rename			GRAPPE clusterid
	label 			var clusterid "cluster number"
	rename			MENAGE hh_num
	label 			var hh_num "household number - not unique id"
	rename 			EXTENSION extension 
	label 			var extension "extension of household"
	*** will need to do these in every file

* create new household id for merging with weather 
	tostring		clusterid, replace 
	gen str2 		hh_num1 = string(hh_num,"%02.0f")
	tostring		extension, replace
	egen			hhid_y2 = concat( clusterid hh_num1 extension  )
	destring		hhid_y2, replace
	order			hhid_y2 clusterid hh_num hh_num1 extension 
	
* create new household id for merging with year 1 
	egen			hid = concat( clusterid hh_num1  )
	destring		hid, replace
	order			hhid_y2 hid clusterid hh_num hh_num1 
	
	label var 		hhid_y2 "unique id - match w2 with weather"
	label var		hid "unique id - match w2 with w1 (no extension)"
	label var 		hh_num1 "household id - string changed, not unique"
	
* need to destring variables for later use in imputes 	
	destring 		clusterid, replace
		
	rename 			AS02EQ110B cropid
	tab 			cropid
	*** 19 are "autre" 
	*** include zucchini, morgina, cane sugar, spice, malohiya, etc. 
	*** only 19 out of 5225 - drop them
	drop			if cropid == 48
	
* examine market participation 
	tab 			AS02EQ11
	rename 			AS02EQ11 soldprod
	replace			soldprod = . if soldprod == 9 
	tab 			soldprod 
	*** 1067 (22 percent) sold crops 

* examine kg harvest value sold
	tab 			AS02EQ12C, missing
	*** 4134 missing
	
	replace			AS02EQ12C = . if AS02EQ12C > 8999 
	*** 12 changed to missing (obs = 9999) - seems to be . in many cases for Niger
	
	rename 			AS02EQ12C harvkgsold 

	describe
	sort 			hhid_y2 cropid 
	isid 			hhid_y2 cropid 

	
* **********************************************************************
* 2 - generate sold harvested values
* **********************************************************************

* examine quantity harvested variable sold
	lab	var			harvkgsold "quantity harvested and sold, in kilograms"
	sum				harvkgsold, detail
	*** this is across all crops
	*** average 426, max 8960, min 0 
	*** how could you sell zero - replace to missing
	
	replace 		harvkgsold = . if harvkgsold == 0 
	*** 24 changed to missing 

* replace any +3 s.d. away from median as missing, by cropid
	sort 			cropid
	sum				harvkgsold, detail 
	by 				cropid: replace	harvkgsold = . if harvkgsold > `r(p50)'+ (3*`r(sd)')
	sum				harvkgsold, detail
	*** replaced 38 values, max is now 1446, mean 191  
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed harvkgsold // identify kilo_fert as the variable being imputed
	sort			hhid_y2 cropid, stable // sort to ensure reproducability of results
	mi impute 		pmm harvkg i.clusterid i.cropid, add(1) rseed(245780) ///
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
	*** imputed observations changed 100 observations for people who sold 
	*** mean 191 to 156, max stays at 1446 
	
* check out amount sold
* currently reported in West African CFA franc
	tab 			AS02EQ13 
	rename			AS02EQ13 earnwaf
	replace 		earnwaf = . if earnwaf == 9999999 
	*** 6 changed to missing
	
	replace 		earnwaf = . if earnwaf == 0 
	*** 6 changed to missing
	
* convert to usd
	gen 			earn = earnwaf/549.4396989
	lab var			earn 	"total earnings from sales in 2010 USD"
	tab 			earn, missing
	*** 4146 missing
	sum				earn, detail
	*** mean 190, max 5496, min 0.018 
	*** total of 1061 observations 
	
	
* **********************************************************************
* 3 - price information - following ag_i in Malawi 
* **********************************************************************

* merge in regional information 
	merge m:1		hhid_y2 using "`export'/2014_ms00p1"
	*** 5207 matched, 0 from master not matched, 1817 from using (which is fine)
	keep if _merge == 3
	drop _merge

* condensed crop codes
	inspect 		cropid
	*** generally things look all right - only 30 unique values 

* gen price per kg
	sort 			cropid
	by 				cropid: gen cropprice = earn / harvkgsold 
	*** 4146 missing values
	sum 			cropprice, detail
	*** mean = 0.75, max = 92, min = 0.0003 
	*** will do some imputations later
	
	label var 		cropprice "crop price"
	
* make datasets with crop price information
	preserve
	collapse 		(p50) p_zd=cropprice (count) n_zd=cropprice, by(cropid region dept canton zd)
	save 			"`export'/2014_as2e2p2_p1.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_can=cropprice (count) n_can=cropprice, by(cropid region dept canton)
	save 			"`export'/2014_as2e2p2_p2.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_dept=cropprice (count) n_dept=cropprice, by(cropid region dept)
	save 			"`export'/2014_as2e2p2_p3.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_reg=cropprice (count) n_reg=cropprice, by(cropid region)
	save 			"`export'/2014_as2e2p2_p4.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
	save 			"`export'/2014_as2e2p2_p5.dta", replace 
	
* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************

* if directly following malawi, would be able to proceed with different process
* however, did not work in niger
* mismatched when attemping to match it into harvest file 
* look at malawi code for reference, as needed 
* but see 2014_ase1p2 for next steps

	clear 

* close the log
	log		close

/* END */