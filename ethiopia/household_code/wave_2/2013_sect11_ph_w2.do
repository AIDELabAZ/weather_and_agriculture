* Project: WB Weather
* Created on: July 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 3 PH sec11
	* seems to roughly correspong to Malawi ag-modI and ag-modO
	* contains crop sales data
	* hierarchy: holder > parcel > field > crop

* assumes
	* raw lsms-isa data
	
* TO DO:
	* done
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc root = "$data/household_data/ethiopia/wave_2/raw"
	loc export = "$data/household_data/ethiopia/wave_2/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv2_PHSEC11", append


* **********************************************************************
* 1 - preparing ESS 2013/14 (Wave 2) - Post Harvest Section 11
* **********************************************************************

* load data
	use 		"`root'/sect11_ph_w2.dta", clear
	
* dropping duplicates
	duplicates drop
	
* creating district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 73 distinct districts
	
* drop if obs haven't sold any crop
	tab			ph_s11q01, missing
	*** 6,978 answered no (!), 12 answered missing
	
	tab			ph_s11q04 ph_s11q01, missing
	*** sales data not present for al 6,978 obs that answered no and 12 that are missing
	
	drop 		if ph_s11q01 != 1
	
* checking unique identifier
	describe
	sort 		holder_id crop_code
*	isid 		holder_id crop_code
	*** non uniquely identifying
	
* checking on crop_code
	sort 		crop_code
	*** one ob missing crop code, can't use it

	drop		if crop_code == .
	
	duplicates 	list holder_id crop_code
	*** one duplicate, will collapse
	
	collapse	(sum) ph_s11q03_a ph_s11q03_b ph_s11q04, by(holder_id crop_code ///
					household_id household_id2 saq01 saq02 saq03 saq05)
	*** # of obs dropped by one, success!
	
* checking unique id again
	sort 		holder_id crop_code
	isid 		holder_id crop_code
	*** perf
	
* creating unique crop identifier
	tostring	crop_code, generate(crop_codeS)
	generate 	crop_id = holder_id + " " + crop_codeS
	isid		crop_id
	drop		crop_codeS	

	
* ***********************************************************************
* 2 - sales weights and prices
* ***********************************************************************	
	
* renaming key variables	
	rename		ph_s11q03_a sales_qty_kg
	rename		ph_s11q03_b sales_qty_g
	gen			sales_qty = sales_qty_kg + (sales_qty_g/1000)
	tab			sales_qty, missing
	*** not missing any values
	
	rename		ph_s11q04 sales_val
	tab			sales_val, missing
	
* generate a price per kilogram
	gen 		price = sales_val/sales_qty
	*** this can be applied to harvested crops which weren't sold
	
	tab			price, missing
	*** missing one ob, because divisor was zero (qty)
	*** will drop
	
	drop		if price == .
	
* hard coding weird outlier potato price (1000), replacing with 10
	replace 	price = 10 if crop_code == 60 & price > 500
	
	lab var		price "Sales Price (BIRR/kg)"
	

* ***********************************************************************
* 3 - generating price dataset
* ***********************************************************************
	
* renaming regional variables
	rename 		saq01 region
	rename 		saq02 zone
	rename 		saq03 woreda
	rename 		saq05 ea	
	
* distinct geographical areas by crop
	distinct 	crop_code, joint
	*** 49 distinct crops
	
	distinct 	crop_code region, joint
	*** 131 distinct regions by crop

	distinct 	crop_code region zone, joint
	*** 494 distinct zones by crop
	
	distinct 	crop_code region zone woreda, joint
	*** 832 distinct woreda by crop
	
	distinct 	crop_code region zone woreda ea, joint
	*** 871 distinct eas by crop

	distinct 	crop_code region zone woreda ea holder_id, joint
	*** 2,481 distinct holders by crop (this is the dataset)
	
* summarize prices	
	sum 			price, detail
	*** mean = 22.25, max = 20,800, min = 0 (??)
	*** will do some imputations later
	
* make datasets with crop price information	

	preserve
	collapse 		(p50) p_holder=price (count) n_holder=price, by(crop_code holder_id ea woreda zone region)
	save 			"`export'/w2_sect11_pholder.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_ea=price (count) n_ea=price, by(crop_code ea woreda zone region)
	save 			"`export'/w2_sect11_pea.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_woreda=price (count) n_woreda=price, by(crop_code woreda zone region)
	save 			"`export'/w2_sect11_pworeda.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_zone=price (count) n_zone=price, by(crop_code zone region)
	save 			"`export'/w2_sect11_pzone.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_region=price (count) n_region=price, by(crop_code region)
	save 			"`export'/w2_sect11_pregion.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=price (count) n_crop=price, by(crop_code)
	save 			"`export'/w2_sect11_pcrop.dta", replace 
	restore	

* close the log
	log	close
	
/* END */