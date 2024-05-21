* Project: WB Weather
* Created on: July 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 1 PH sec11
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
	loc root = "$data/household_data/ethiopia/wave_1/raw"
	loc export = "$data/household_data/ethiopia/wave_1/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv1_PHSEC11", append


* **********************************************************************
* 1 - preparing ESS (Wave 1) - Post Harvest Section 11
* **********************************************************************

* load data
	use 		"`root'/sect11_ph_w1.dta", clear
	
* dropping duplicates
	duplicates drop
	
* creating district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 69 distinct districts
	
* drop if obs haven't sold any crop
	tab			ph_s11q01
	
	tab			ph_s11q04_a ph_s11q01, missing
	*** sales data not present for al 6,710 obs that answered no
	
	drop 		if ph_s11q01 == 2
	*** 6,710 obs dropped
	
* generate unique identifier
	describe
	sort 		holder_id crop_code
	drop		if crop_code == .
	*** 413 obs dropped, none containing sales data
	
	isid 		holder_id crop_code	
	
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
	replace		sales_qty_kg = 0 if sales_qty_kg == . & sales_qty_g != .
	replace		sales_qty_g = 0 if sales_qty_g == . & sales_qty_kg != .
	gen			sales_qty = sales_qty_kg + (sales_qty_g/1000)
	tab			sales_qty, missing
	*** missing 352 values
	
	rename		ph_s11q04_a sales_val_whole
	rename		ph_s11q04_b sales_val_dec
	replace		sales_val_whole = 0 if sales_val_whole == . & sales_val_dec != .
	replace		sales_val_dec = 0 if sales_val_dec == . & sales_val_whole != .
	gen			sales_val = sales_val_whole + (sales_val_dec/100)
	tab			sales_val, missing
	*** missing 351 values
	
* generate a price per kilogram
	gen 		price = sales_val/sales_qty
	*** this can be applied to harvested crops which weren't sold
	
	tab			price, missing
	*** missing 356 values
	*** will drop, no price data makes the ob useless
	
	drop		if price == .
	
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
	*** 28 distinct crops
	
	distinct 	crop_code region, joint
	*** 90 distinct regions by crop

	distinct 	crop_code region zone, joint
	*** 389 distinct zones by crop
	
	distinct 	crop_code region zone woreda, joint
	*** 604 distinct woreda by crop
	
	distinct 	crop_code region zone woreda ea, joint
	*** 624 distinct eas by crop

	distinct 	crop_code region zone woreda ea holder_id, joint
	*** 1,747 distinct holders by crop (this is the dataset)
	
* summarize prices	
	sum 			price, detail
	*** mean = 8.477, max = 111.7647, min = 0.0000596
	*** will do some imputations later
	
* make datasets with crop price information	

	preserve
	collapse 		(p50) p_holder=price (count) n_holder=price, by(crop_code holder_id ea woreda zone region)
	save 			"`export'/w1_sect11_pholder.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_ea=price (count) n_ea=price, by(crop_code ea woreda zone region)
	save 			"`export'/w1_sect11_pea.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_woreda=price (count) n_woreda=price, by(crop_code woreda zone region)
	save 			"`export'/w1_sect11_pworeda.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_zone=price (count) n_zone=price, by(crop_code zone region)
	save 			"`export'/w1_sect11_pzone.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_region=price (count) n_region=price, by(crop_code region)
	save 			"`export'/w1_sect11_pregion.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=price (count) n_crop=price, by(crop_code)
	save 			"`export'/w1_sect11_pcrop.dta", replace 
	restore	

* close the log
	log	close
	
/* END */