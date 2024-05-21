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
	* two purposes: generating price data and generating harvest weights

* assumes
	* raw lsms-isa data
	
* TO DO:
	* must find a unique ob identifier
	* like in pp_sect3, ph_sect9, & ph_sect11, many observtions from master are not being matched
	* must finish building out data cleaning - see wave 1 maybe	
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc root = "$data/household_data/ethiopia/wave_3/raw"
	loc export = "$data/household_data/ethiopia/wave_3/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv3_PHSEC12", append


* **********************************************************************
* 1 - preparing ESS (Wave 3) - Post Harvest Section 12
* **********************************************************************

* load data
	use "`root'/sect12_ph_w3.dta", clear

* dropping duplicates
	duplicates drop
	
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
	drop if crop_code == 119	// other, oil seed
	drop if crop_code == 123	// other, vegetable
	*** 4,913 obs dropped
	*** must check other crops

* generate unique identifier
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
	*** 64 distinct districts

* check for missing crop codes
	tab			crop_code, missing	
	*** this is supposed to be fruits and nuts 
	*** but still a few obs w/ maize and sorghum and the like
	*** like in Sect9, no crop codes are missing
	
* look for correlation b/w units of measure (harvest and sales)
	rename 		ph_s12q03_b unit_cd
	rename		ph_s12q0b unit_sale
	pwcorr		unit_cd unit_sale
	*** 0.9848 - very very very high

* create conversion key 
	merge 		m:1 crop_code unit_cd using "`root'/Crop_CF_Wave3_use.dta"
	*** 572 not matched from master (of 2,422)

	tab 		_merge
	drop		if _merge == 2
	drop		_merge

	
/* *********************************************************************
* X - dummy code
* **********************************************************************	

	gen 		hrv_wgt = mean_cf_nat * ph_s12q03_a if mean_cf_nat != .	
	
	mi set 		wide  
	mi xtset, 	clear 
	mi register imputed hrv_wgt 
	sort		holder_id crop_code, stable
	mi impute 	pmm hrv_wgt i.district_id, add(1) rseed(245780) ///
					noisily dots force knn(5) bootstrap 
	mi 			unset	
	
	drop 		hrv_wgt
	rename 		hrv_wgt_1_ hrv_wgt
	
	* renaming key variables	
	rename		ph_s12q07 sales_qty	
	gen			sales_qty_kg = sales_qty * mean_cf_nat if mean_cf_nat != .
	
	rename		ph_s12q08 sales_val
	gen 		price = sales_val/sales_qty_kg
	lab var		price "Sales price (BIRR/kg)" */	
	

* ***********************************************************************
* 2 - finding harvest weights
* ***********************************************************************	
	
* ***********************************************************************
* 2a - generating conversion factors
* ***********************************************************************	
	
* constructing conversion factor - same procedure as sect9_ph_w3
* exploring conversion factors - are any the same across all regions and obs?
	tab 		unit_cd
	egen		unitnum = group(unit_cd)
	*** 60 units listed
	
	gen			cfavg = (mean_cf1 + mean_cf2 + mean_cf3 + mean_cf4 + mean_cf6 ///
							+ mean_cf7 + mean_cf12 + mean_cf99)/8
	pwcorr 		cfavg mean_cf_nat	
	*** correlation of 0.9999
	
	local 		units = 52
	forvalues	i = 1/`units'{
	    
		tab		unit_cd if unitnum == `i'
		tab 	cfavg if unitnum == `i', missing
	} 
	*** results! universal units  with some missing obs are:
	*** kilogram, gram, quintal, box, shekim (sm, md), kubaya (sm)
	*** sini (sm) - only one ob period, no need to replace
	
	*** "universal" with only one ob w/ a value
	*** none!
	
	*** no conversion values at all for:
	*** jenbe, jog, akumada/dawla/lekota (lg) bunch (sm, md, lg), 
	*** chinet (sm, md, lg), birchiko (sm), festal (md, lg),
	*** zorba/akara (sm, md)
	*** and 170 obs labelled 'other' missing cfs

* generating conversion factors
* starting with units found to be universal
	gen			cf = 1 if unit_cd == 1 				// kilogram
	replace		cf = .001 if unit_cd == 2 			// gram
	replace		cf = 100 if unit_cd == 3 			// quintal
	replace		cf = 48.05125 if unit_cd == 6 		// box
	replace		cf = 0.056 if unit_cd == 101 		// kubaya (sm)
	replace 	cf = 7.27 if unit_cd == 161			// shekim (sm)
	replace 	cf = 21.66 if unit_cd == 162		// shekim (md)
	
* now moving on to region specific units
	replace 	cf = mean_cf1 if saq01 == 1 & cf == .
	replace		cf = mean_cf2 if saq01 == 2 & cf == .	
	replace 	cf = mean_cf3 if saq01 == 3 & cf == .
	replace 	cf = mean_cf4 if saq01 == 4 & cf == .
	replace 	cf = mean_cf99 if saq01 == 5 & cf == .
	replace 	cf = mean_cf6 if saq01 == 6 & cf == .
	replace 	cf = mean_cf7 if saq01 == 7 & cf == .
	replace 	cf = mean_cf12 if saq01 == 12 & cf == .
	replace 	cf = mean_cf99 if saq01 == 13 & cf == .
	replace 	cf = mean_cf99 if saq01 == 15 & cf == .
	replace		cf = mean_cf_nat if cf == . & mean_cf_nat != . 
	*** 0 changes for the last line
	
* drop 'others'
	drop 		if unit_cd == 900
	
* checking veracity of kg estimates
	tab 		cf, missing
	*** missing 393 converstion factors
	
	sort		cf unit_cd
	*** missing obs are spread out across different units
	*** jenbe, jog, akumada/dawla/lekota (lg) bunch (sm, md, lg), birchiko (sm),
	*** chinet (sm, md, lg), esir (sm, md, lg), festal (md, lg), 
	*** joniya/kasha (sm, md, lg), kerchat/kemba (sm, md, lg),
	*** kunna/mishe/kefer/enkib (sm, md, lg), 
	*** madaberia/nuse/shera/cheret (sm, md, lg), medeb (sm, md, lg),
	*** piece/number (lg), sahin (sm, md, lg), 
	*** tasa/tanika/shember/selmon (sm, md, lg), zorba/akara (sm, md)

	*** some of the units above have lots of other obs w/ values, including
	*** esir (sm, md, lg), joniya/kasha (sm, md, lg), 
	*** kerchat/kemba (sm, md, lg), kunna/mishe/kefer/enkib (sm, md, lg), 
	*** madaberia/nuse/shera/cheret (sm, md, lg), medeb (sm, md, lg),
	*** piece/number (lg), sahin (sm, md, lg), 
	*** tasa/tanika/shember/selmon (sm, md, lg)
	
	*** some have no obs w/ cfs, including:
	*** jenbe, jog, akumada/dawla/lekota (lg) bunch (sm, md, lg), 
	*** chinet (sm, md, lg), birchiko (sm), festal (md, lg),
	*** zorba/akara (sm, md)

* filling in as many missing cfs as possible
* only using means of units w/ multiple other obs with values

	sum			cf if unit_cd == 61	// esir (sm), mean = 0.5155963
	replace 	cf = 0.5155963 if unit_cd == 61 & cf == .
	
	sum			cf if unit_cd == 62	// esir (md), mean = 0.8824194
	replace 	cf = 0.8824194 if unit_cd == 62 & cf == .
	
	sum			cf if unit_cd == 63	// esir (lg), mean = 1.907071
	replace 	cf = 1.907071 if unit_cd == 63 & cf == .

	sum			cf if unit_cd == 81	// joniya/kasha (sm), mean = 29.08775
	replace 	cf = 29.08775 if unit_cd == 81 & cf == .
	
	sum			cf if unit_cd == 82	// joniya/kasha (md), mean = 62.46047
	replace 	cf = 62.46047 if unit_cd == 82 & cf == .
	
	sum			cf if unit_cd == 83	// joniya/kasha (lg), mean = 96.2272
	replace 	cf = 96.2272 if unit_cd == 83 & cf == .	

	sum			cf if unit_cd == 91	// kerchat/kemba (sm), mean = 7.609826
	replace 	cf = 7.609826 if unit_cd == 91 & cf == .
	
	sum			cf if unit_cd == 92	// kerchat/kemba (md), mean = 13.02528
	replace 	cf = 13.02528 if unit_cd == 92 & cf == .
	
	sum			cf if unit_cd == 93	// kerchat/kemba (lg), mean = 22.836
	replace 	cf = 22.836 if unit_cd == 93 & cf == .

	sum			cf if unit_cd == 111	// kunna/mishe/kefer/enkib (sm), mean = 4.8624
	replace 	cf = 4.8624 if unit_cd == 111 & cf == .
	
	sum			cf if unit_cd == 112	// kunna/mishe/kefer/enkib (md), mean = 3.575765
		*** the mean medium observation is smaller than the mean small observation
	
	replace 	cf = 3.575765 if unit_cd == 112 & cf == .
	
	sum			cf if unit_cd == 113	// kunna/mishe/kefer/enkib (lg), mean = 12.327
	replace 	cf = 12.327 if unit_cd == 113 & cf == .
	
	sum			cf if unit_cd == 121	// madaberia/nuse/shera/cheret (sm), mean = 28.28729
	replace 	cf = 28.28729 if unit_cd == 121 & cf == .
	
	sum			cf if unit_cd == 122	// madaberia/nuse/shera/cheret (md), mean = 55.9465
	replace 	cf = 55.9465 if unit_cd == 122 & cf == .
	
	sum			cf if unit_cd == 123	// madaberia/nuse/shera/cheret (lg), mean = 93.53575
	replace 	cf = 93.53575 if unit_cd == 123 & cf == .

	sum			cf if unit_cd == 131	// medeb (sm), mean = 0.1902564
	replace 	cf = 0.1902564 if unit_cd == 131 & cf == .
	
	sum			cf if unit_cd == 132	// medeb (md), mean = 0.8734783 
	replace 	cf = 0.8734783  if unit_cd == 132 & cf == .
	
	sum			cf if unit_cd == 133	// medeb (lg), mean = 1.492613
	replace 	cf = 1.492613 if unit_cd == 133 & cf == .	

	sum			cf if unit_cd == 151	// sahin (sm), mean = 1.176931
	replace 	cf = 1.176931 if unit_cd == 151 & cf == .
	
	sum			cf if unit_cd == 152	// sahin (md), mean = 0.73625 
		*** odd that the mean value for sahin (med) is smaller than for sahin (sm)
		
	replace 	cf = 0.73625 if unit_cd == 152 & cf == .
	
	sum			cf if unit_cd == 153	// sahin (lg), mean = 5.46625
	replace 	cf = 5.46625 if unit_cd == 153 & cf == .

	sum			cf if unit_cd == 181	// tasa/tanika/shember/selmon (sm), mean = 0.2553478
	replace 	cf = 0.2553478 if unit_cd == 181 & cf == .
	
	sum			cf if unit_cd == 182	// tasa/tanika/shember/selmon (md), mean = 0.2662195
	replace 	cf = 0.2662195 if unit_cd == 182 & cf == .
	
	sum			cf if unit_cd == 183	// tasa/tanika/shember/selmon (lg), mean = 0.8717742 
	replace 	cf = 0.8717742 if unit_cd == 183 & cf == .

	sum			cf if unit_cd == 143	// piece/number (lg), mean = 6.92 
	replace 	cf = 6.92 if unit_cd == 143 & cf == .	
	
* check results
	sort		cf unit_cd
	*** 26 obs still missing cfs
	*** units include jenbe, jog, birchiko (sm), bunch (sm, md, lg),
	***'chinet (sm, md, lg), festal (md, lg), zorba/akara (sm, md) 
	*** not sure how to address this

* investigating crops in obs missing cf
	tab			crop_code if cf == .
	* 11 of 26 obs are kale
	* also included is cassava, sorghum, pumpkins, sweet potato, among others
	
* for now, dropping obs with no known cf		
	drop		if cf == .
	*** 26 obs dropped

	
* ***********************************************************************
* 2b - constructing harvest weights and imputing outliers
* ***********************************************************************	
	
* renaming key variables	
	rename		ph_s12q03_a hvst_qty
	tab			hvst_qty, missing
	*** not missing any values
	
* generate harvest weight in kilograms	
	gen			hvst_qty_kg = hvst_qty * cf
	tab			hvst_qty_kg, missing
	*** mssing the 26 values w/ no cf value
	
	rename		hvst_qty_kg hrvqty_selfr		

* summarize value of harvest
	sum			hrvqty_selfr, detail
	*** median 10.53, mean 219.5952, max 200,800 - max is huge!
	*** s.d. of 4,496 being driven by that one ob (next largest is 66,063)
	*** this large 200k ob is one of the few where unit_sale and unit_cd don't match - sketchy
	
*** i really want to drop those top two obs before throwing out outliers!	
	replace		hrvqty_selfr = . if hrvqty_selfr > 50000
	sum			hrvqty_selfr, detail

* replace any +3 s.d. away from median as missing
	replace		hrvqty_selfr = . if hrvqty_selfr > `r(p50)'+(3*`r(sd)')
	*** replaced only top 2 values, max is now 10,958
	*** the max still seems high...
	*** standard deviation is now 411
	*** if we had dropped the top two obs first 27 obs would be replaced = .
	
* impute missing harvest weights using predictive mean matching 
	mi set 		wide //	declare the data to be wide. 
	mi xtset, 	clear //	this is a precautinary step to clear any xtset that the analyst may have had in place previously
	mi register imputed hrvqty_selfr //	identify hrvqty_selfr as the variable being imputed 
	sort		holder_id crop_code, stable // sort to ensure reproducability of results
	mi impute 	pmm hrvqty_selfr i.district_id, add(1) rseed(245780) ///
					noisily dots force knn(5) bootstrap 
	mi 			unset

* summarize results of imputation
	tabulate 	mi_miss	//	this binary = 1 for the full set of observations where plotsize_GPS is missing
	tabstat 	hrvqty_selfr hrvqty_selfr_1_, by(mi_miss) ///
					statistics(n mean min max) columns(statistics) longstub ///
					format(%9.3g) 
	*** 4,427 imputations made
	
	drop		mi_miss	

* manipulate variables for export
	drop		hrvqty_selfr
	rename 		hrvqty_selfr_1_ hrvqty_selfr
	label 		variable hrvqty_selfr		"Harvest Weight, kg (self-reported)"
	sum 		hrvqty_selfr, detail
	
* generate maize harvest weights
	gen 		mz_hrv = hrvqty_selfr if crop_code == 2

	
* ***********************************************************************
* 3 - cleaning and keeping harvest quantities
* ***********************************************************************

*renaming variables of interest
	rename 		household_id hhid
	rename 		household_id2 hhid2	
	rename 		saq01 region
	rename		saq02 zone
	rename 		saq03 woreda
	rename 		saq05 ea 
	drop		hvst_qty
	rename		hrvqty_selfr hvst_qty	

* generate section id variable
	gen			sec = 12
	
* restrict to variables of interest
	keep  		holder_id- crop_code hvst_qty mz_hrv sec
	order 		holder_id- crop_code

* final preparations to export
	isid 		holder_id crop_code
	compress
	describe
	summarize 
	sort 		holder_id ea_id crop_code
	save 		"`export'/PH_SEC12.dta", replace

* ***********************************************************************
* 4 - going after sales price info
* ***********************************************************************		
		
* **********************************************************************
* 4.0 - setup
* **********************************************************************

* clear existing data
	clear all

* define paths
	loc root = "$data/household_data/ethiopia/wave_3/raw"
	loc export = "$data/household_data/ethiopia/wave_3/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv3_PHSEC12", append


* **********************************************************************
* 4.1 - preparing ESS (Wave 3) - Post Harvest Section 12
* **********************************************************************

* load data
	use "`root'/sect12_ph_w3.dta", clear

* dropping duplicates
	duplicates drop
	
* drop those obs w/out sales data
	drop		if ph_s12q06 != 1
	*** 4,704 obs dropped
	
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
	drop if crop_code == 119	// other, oil seed
	drop if crop_code == 123	// other, vegetable
	*** 2,118 obs dropped
	*** at this point only 513 obs remain

* generate unique identifier
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
	*** 55 distinct districts

* check for missing crop codes
	tab			crop_code, missing	
	*** this is supposed to be fruits and nuts 
	*** but still a few obs w/ maize and sorghum and the like
	*** like in Sect9, no crop codes are missing
	
* look for correlation b/w units of measure (harvest and sales)
	rename 		ph_s12q03_b unit_cd
	rename		ph_s12q0b unit_sale
	tab			unit_sale, missing
	pwcorr		unit_cd unit_sale
	*** 0.9848 - very very very high, same as abov depsite dropped obs
	
	drop 		unit_cd
	rename 		unit_sale unit_cd

* create conversion key 
	merge 		m:1 crop_code unit_cd using "`root'/Crop_CF_Wave3_use.dta"
	*** 114 not matched from master (of 513)

	tab 		_merge
	drop		if _merge == 2
	drop		_merge
	

* ***********************************************************************
* 4.2 - constructing prices
* ***********************************************************************	
	
* ***********************************************************************
* 4.2a - generating conversion factors
* ***********************************************************************	
	
* constructing conversion factor - same procedure as sect9_ph_w3
* exploring conversion factors - are any the same across all regions and obs?
	tab 		unit_cd, missing
	drop 		if unit_cd == 900
	*** drop obs w/ unit of measure listed as 'other'
	
	egen		unitnum = group(unit_cd)
	*** 36 units listed
	
	gen			cfavg = (mean_cf1 + mean_cf2 + mean_cf3 + mean_cf4 + mean_cf6 ///
							+ mean_cf7 + mean_cf12 + mean_cf99)/8
	pwcorr 		cfavg mean_cf_nat	
	*** correlation of 1
	
	local 		units = 36
	forvalues	i = 1/`units'{
	    
		tab		unit_cd if unitnum == `i'
		tab 	cfavg if unitnum == `i', missing
	} 
	*** results! universal units  with some missing obs are:
	*** kilogram, gram, quintal, sahin (md)

	*** "universal" with only one ob w/ a value
	*** joniya/kasha (sm, lg), kerchat/kemba (lg), kunna/mishe/kefer/enkib (md),
	
	*** no conversion values at all for:
	*** jenbe, jog, chinet (md, lg), kubaya (sm), kunna/mishe/kefer/enkib (sm),
	*** zorba/akara (md)

* generating conversion factors
* starting with units found to be universal
	gen			cf = 1 if unit_cd == 1 				// kilogram
	replace		cf = .001 if unit_cd == 2 			// gram
	replace		cf = 100 if unit_cd == 3 			// quintal
	replace 	cf = .596 if unit_cd == 152			// sahin (md)
	
* now moving on to region specific units
	replace 	cf = mean_cf1 if saq01 == 1 & cf == .
	replace		cf = mean_cf2 if saq01 == 2 & cf == .	
	replace 	cf = mean_cf3 if saq01 == 3 & cf == .
	replace 	cf = mean_cf4 if saq01 == 4 & cf == .
	replace 	cf = mean_cf99 if saq01 == 5 & cf == .
	replace 	cf = mean_cf6 if saq01 == 6 & cf == .
	replace 	cf = mean_cf7 if saq01 == 7 & cf == .
	replace 	cf = mean_cf12 if saq01 == 12 & cf == .
	replace 	cf = mean_cf99 if saq01 == 13 & cf == .
	replace 	cf = mean_cf99 if saq01 == 15 & cf == .
	replace		cf = mean_cf_nat if cf == . & mean_cf_nat != . 
	*** 0 changes for the last line
	
* drop 'others'
	drop 		if unit_cd == 900
	
* checking veracity of kg estimates
	tab 		cf, missing
	*** missing 86 converstion factors
	
	sort		cf unit_cd
	*** missing obs are spread out across different units
	*** jenbe, chinet (md, lg), esir (sm, md, lg), joniya/kasha (sm, lg),
	*** kerchat/kemba (sm, md, lg), kubaya (sm), kunna/mishe/kefer/enkib (sm, md),
	*** madaberia/nuse/shera/cheret (sm, md, lg), medeb (sm, md), sahin (sm, lg),
	*** tasa/tanika/shember/selmon (sm), zorba/akara (md)

	*** some of the units above have lots of other obs w/ values, including
	*** esir (sm, md, lg), kerchat/kemba (sm, md), 
	*** madaberia/nuse/shera/cheret (sm, md, lg), medeb (sm, md), sahin (sm, lg),
	*** tasa/tanika/shember/selmon (sm), 
	
	*** some are "universal" with only one ob w/ a value and many obs missing
	*** joniya/kasha (sm, lg), kerchat/kemba (lg), kunna/mishe/kefer/enkib (md),
	
	*** some have no obs w/ cfs, including:
	*** jenbe, chinet (md, lg), kubaya (sm), kunna/mishe/kefer/enkib (sm),
	*** zorba/akara (md)

* filling in as many missing cfs as possible

* dropping those obs w/ no conversion information at all
	drop 		if unit_cd == 7 	// jenbe
	drop 		if unit_cd == 52 	// chinet (md)
	drop 		if unit_cd == 53 	// chinet (lg)
	drop 		if unit_cd == 101	// kubaya (sm)
	drop 		if unit_cd == 111 	// kunna/mishe/kefer/enkib (sm)
	drop 		if unit_cd == 192 	// zorba/akara (md)
	*** six drops made
	
* generating new unit numbering	
	drop 		unitnum
	egen		unitnum = group(unit_cd)

* using means of units w/ multiple other obs with values as cf
	local 		units = 30
	forvalues	i = 1/`units'{
	    
		sum		cf if unitnum == `i'
		replace cf = `r(mean)' if unitnum == `i' & cf == .
	} 
	
* checking results	
	tab			cf, missing
	*** no conversion factors missing for obs that remain
	
	
* ***********************************************************************
* 4.2b - constructing harvest weights and prices
* ***********************************************************************	
	
* renaming key variables	
	rename		ph_s12q07 sales_qty
	tab			sales_qty, missing
	*** not missing any values
	
	rename		ph_s12q08 sales_val
	tab 		sales_val
	*** not missing any sales values
	
* converting sales quantity to kilos
	gen			sales_qty_kg = sales_qty * cf
	
* generate a price per kilogram
	gen 		price = sales_val/sales_qty_kg
	*** this can be applied to harvested crops which weren't sold
	
	lab var		price "Sales Price (BIRR/kg)"

	
* ***********************************************************************
* 4.3 - generating price dataset
* ***********************************************************************	
	
* renaming regional variables
	rename 		saq01 region
	rename 		saq02 zone
	rename 		saq03 woreda
	rename 		saq05 ea	
	
* distinct geographical areas by crop
	distinct 	crop_code, joint
	*** 20 distinct crops
	
	distinct 	crop_code region, joint
	*** 76 distinct regions by crop

	distinct 	crop_code region zone, joint
	*** 207 distinct zones by crop
	
	distinct 	crop_code region zone woreda, joint
	*** 243 distinct woreda by crop
	
	distinct 	crop_code region zone woreda ea, joint
	*** 257 distinct eas by crop

	distinct 	crop_code region zone woreda ea holder_id, joint
	*** 490 distinct holders by crop (this is the dataset)
	
* summarize prices	
	sum 			price, detail
	*** mean = 21.76, max = 363.64, min = 0.3
	
* make datasets with crop price information	

	preserve
	collapse 		(p50) p_holder=price (count) n_holder=price, by(crop_code holder_id ea woreda zone region)
	save 			"`export'/w3_sect12_pholder.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_ea=price (count) n_ea=price, by(crop_code ea woreda zone region)
	save 			"`export'/w3_sect12_pea.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_woreda=price (count) n_woreda=price, by(crop_code woreda zone region)
	save 			"`export'/w3_sect12_pworeda.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_zone=price (count) n_zone=price, by(crop_code zone region)
	save 			"`export'/w3_sect12_pzone.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_region=price (count) n_region=price, by(crop_code region)
	save 			"`export'/w3_sect12_pregion.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=price (count) n_crop=price, by(crop_code)
	save 			"`export'/w3_sect12_pcrop.dta", replace 
	restore	