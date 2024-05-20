* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 3 PH sec12
	* seems to roughly correspong to Malawi ag-modD and ag-modK
	* contains harvest and sales info on fruit/nuts/root crops
	* hierarchy: holder > parcel > field > crop
	* generates price data

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
	log using "`logout'/wv2_PHSEC12", append


* **********************************************************************
* 1 - preparing ESS 2013/14 (Wave 2) - Post Harvest Section 12
* **********************************************************************

* load data
	use 		"`root'/sect12_ph_w2.dta", clear

* dropping duplicates
	duplicates drop
	
* drop any obs w/out sales data
	drop		if ph_s12q06 == 2 & ph_s12q07 == .
	*** 4,671 obs dropped
	
* drop trees and other perennial crops
	drop if crop_code == 41 	// apples
	drop if crop_code == 42 	// bananas
	drop if crop_code == 44 	// lemons
	drop if crop_code == 45 	// mandarins
	drop if crop_code == 46 	// mangos
	drop if crop_code == 47 	// oranges
	drop if crop_code == 48 	// papaya
	drop if crop_code == 49 	// pineapples
	drop if crop_code == 50 	// citron
	drop if crop_code == 65 	// guava
	drop if crop_code == 66 	// peach
	drop if crop_code == 71 	// chat
	drop if crop_code == 72 	// coffee 
	drop if crop_code == 73 	// cotton
	drop if crop_code == 76 	// sugar cane
	drop if crop_code == 78 	// tobacco
	drop if crop_code == 84 	// avocados
	drop if crop_code == 85		// grazing land
	drop if crop_code == 64 	// godere
	drop if crop_code == 74 	// enset
	drop if crop_code == 75 	// gesho
	drop if crop_code == 81 	// rue
	drop if crop_code == 82 	// gishita
	drop if crop_code == 112 	// kazmir
	drop if crop_code == 98 	// other, root
	drop if crop_code == 115	// other, fruits
	drop if crop_code == 117	// other, spices
	drop if crop_code == 118	// other, pulses (?)
	drop if crop_code == 119	// other, oil seed
	drop if crop_code == 120	// other, cereal
	drop if crop_code == 121	// other, case crops
	drop if crop_code == 123	// other, vegetable
	*** 2,206 obs dropped
	
* checking unique identifier
	describe
	sort 		holder_id crop_code
*	isid 		holder_id crop_code
	*** non uniquely identifying

* checking on crop_code
	sort 		holder_id crop_code
	drop		if crop_code == .
	*** no obs dropped
	
	duplicates 	list holder_id crop_code
	*** 4 duplicate observations in terms of these variables
	*** doesn't seem like the differences in any of the dupes have anything to do with sales info
	*** therefore will collapse as in sec11, keeping relevant variables
	
	collapse	(sum) ph_s12q07 ph_s12q08, by(holder_id crop_code ///
					household_id household_id2 saq01 saq02 saq03 saq05)
	*** # of obs dropped by four, success!
	
	isid 		holder_id crop_code
	
* creating unique crop identifier
	tostring	crop_code, generate(crop_codeS)
	generate 	crop_id = holder_id + " " + crop_codeS
	isid		crop_id	
	drop		crop_codeS	

* creating unique region identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique region identifier"
	distinct	saq01 saq02, joint
	*** 61 distinct districts
	
	
* ***********************************************************************
* 2 - sales weights and prices
* ***********************************************************************	
	
* renaming key variables	
	rename		ph_s12q07 sales_qty_kg
	tab			sales_qty, missing
	*** not missing any values, there are 24 zeros
	
	rename		ph_s12q08 sales_val
	tab			sales_val, missing
	*** not missing any values, there are 23 zeros
	
* generate a price per kilogram
	gen 		price = sales_val/sales_qty
	*** this can be applied to harvested crops which weren't sold
	
	tab			price, missing
	*** missing 24 obs, because either sales_qty was zero
	*** will drop
	
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
	*** 78 distinct regions by crop

	distinct 	crop_code region zone, joint
	*** 215 distinct zones by crop
	
	distinct 	crop_code region zone woreda, joint
	*** 273 distinct woreda by crop
	
	distinct 	crop_code region zone woreda ea, joint
	*** 288 distinct eas by crop

	distinct 	crop_code region zone woreda ea holder_id, joint
	*** 620 distinct holders by crop (this is the dataset)
	
* summarize prices	
	sum 			price, detail
	*** mean = 8.35, max = 70, min = 0.13
	*** will do some imputations later
	
* make datasets with crop price information	

	preserve
	collapse 		(p50) p_holder=price (count) n_holder=price, by(crop_code holder_id ea woreda zone region)
	save 			"`export'/w2_sect12_pholder.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_ea=price (count) n_ea=price, by(crop_code ea woreda zone region)
	save 			"`export'/w2_sect12_pea.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_woreda=price (count) n_woreda=price, by(crop_code woreda zone region)
	save 			"`export'/w2_sect12_pworeda.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_zone=price (count) n_zone=price, by(crop_code zone region)
	save 			"`export'/w2_sect12_pzone.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_region=price (count) n_region=price, by(crop_code region)
	save 			"`export'/w2_sect12_pregion.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=price (count) n_crop=price, by(crop_code)
	save 			"`export'/w2_sect12_pcrop.dta", replace 
	restore	

* close the log
	log	close
	
/* END */