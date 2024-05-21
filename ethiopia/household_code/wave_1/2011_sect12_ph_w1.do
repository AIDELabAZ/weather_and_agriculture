* Project: WB Weather
* Created on: July 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 1 PH sec12
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
	loc root = "$data/household_data/ethiopia/wave_1/raw"
	loc export = "$data/household_data/ethiopia/wave_1/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv1_PHSEC12", append


* **********************************************************************
* 1 - preparing ESS (Wave 1) - Post Harvest Section 12
* **********************************************************************

* load data
	use 		"`root'/sect12_ph_w1.dta", clear

* dropping duplicates
	duplicates drop
	
* drop any obs w/out sales data
	drop		if ph_s12q06 == 2 & ph_s12q07 == .
	*** 4,559 obs dropped
	
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
	*** 1,944 obs dropped
	
* checking unique identifier
	drop		if crop_code == .
	*** 873 obs dropped (!)
	
	describe
	sort 		holder_id crop_code
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
	*** 58 distinct districts
	
	
* ***********************************************************************
* 2 - sales weights and prices
* ***********************************************************************	
	
* renaming key variables	
	rename		ph_s12q07 sales_qty_kg
	tab			sales_qty, missing
	*** missing 80 obs, there is 1 zero
	
	rename		ph_s12q08 sales_val
	tab			sales_val, missing
	*** missing 79 obs, there are 2 zeros
	
* generate a price per kilogram
	gen 		price = sales_val/sales_qty
	*** this can be applied to harvested crops which weren't sold
	
	tab			price, missing
	*** missing 82 obs, because of missing sales_qty or sales_val
	*** will drop
	
	drop		if price == .
	*** 82 obs dropped, left with 414 observations
	
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
	*** 16 distinct crops
	
	distinct 	crop_code region, joint
	*** 63 distinct regions by crop

	distinct 	crop_code region zone, joint
	*** 161 distinct zones by crop
	
	distinct 	crop_code region zone woreda, joint
	*** 203 distinct woreda by crop
	
	distinct 	crop_code region zone woreda ea, joint
	*** 214 distinct eas by crop

	distinct 	crop_code region zone woreda ea holder_id, joint
	*** 414 distinct holders by crop (this is the dataset)
	
* summarize prices	
	sum 			price, detail
	*** mean = 9.23, max = 80, min = 0 (?)
	*** will do some imputations later
	
* make datasets with crop price information	

	preserve
	collapse 		(p50) p_holder=price (count) n_holder=price, by(crop_code holder_id ea woreda zone region)
	save 			"`export'/w1_sect12_pholder.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_ea=price (count) n_ea=price, by(crop_code ea woreda zone region)
	save 			"`export'/w1_sect12_pea.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_woreda=price (count) n_woreda=price, by(crop_code woreda zone region)
	save 			"`export'/w1_sect12_pworeda.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_zone=price (count) n_zone=price, by(crop_code zone region)
	save 			"`export'/w1_sect12_pzone.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_region=price (count) n_region=price, by(crop_code region)
	save 			"`export'/w1_sect12_pregion.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=price (count) n_crop=price, by(crop_code)
	save 			"`export'/w1_sect12_pcrop.dta", replace 
	restore	

* close the log
	log	close
	
/* END */