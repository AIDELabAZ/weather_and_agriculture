* Project: WB Weather
* Created on: July 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 2 PH sec9
	* seems to roughly correspong to Malawi ag-modG and ag-modM
	* contains harvest weights and other info (dates, etc.)
	* hierarchy: holder > parcel > field > crop

* assumes
	* raw lsms-isa data
	* distinct.ado
	
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
	log using "`logout'/wv2_PHSEC9", append


* **********************************************************************
* 0.1 - cleaning conversion data 
* **********************************************************************

* load conversion data for cleaning
	use			"`root'/Crop_CF_Wave2.dta", clear
	
	duplicates 	report crop_code unit_cd
	duplicates 	list crop_code unit_cd
	
* dropping duplicates
	duplicates drop
	*** 5 duplicats dropped
	
	duplicates 	list crop_code unit_cd
	
* hard coding other dupicates out
	drop 		if crop_code == 72 & unit_cd == 11
	*** esir, coffee: does not appear in master data
	
	drop		if crop_code == 6 & unit_cd == 11 & mean_cf_nat < 1
	*** esir, sorghum: using cffs from wv3 as reference
	
	drop		if crop_code == 60 & unit_cd == 7 & mean_cf_nat > 10
	*** kunna, potatoes: using cffs from wv3 as reference
	
	drop		if crop_code == 63 & unit_cd == 7 & mean_cf_nat > 25
	*** kunna, tomatoes: using cffs from wv3 as 
	
* double checking work
	isid		unit_cd crop_code
	
* save cleaned dataset
	save 		"`export'/Crop_CF_Wave2_cleaned", replace
	
	
* **********************************************************************
* 1 - preparing ESS 2013/14 (Wave 2) - Post Harvest Section 9
* **********************************************************************

* load data
	use 		"`root'/sect9_ph_w2.dta", clear
	
* dropping duplicates
	duplicates drop
	*** 0 obs dropped 

* check # of maize obs
	tab			crop_code
	*** 3,270 maize obs
	
* drop if obs haven't harvested crop
	tab			ph_s9q03, missing
	*** 3,362 answered no
	*** 121 missing
	
	sum 		ph_s9q05 ph_s9q04_a if ph_s9q03 == .
	*** obs for both variables exist when ph_s9q03 == .
	
	replace 	ph_s9q03 = 1 if ph_s9q04_a != . | ph_s9q05 != .
	*** 77 changes made
	
	drop 		if ph_s9q03 != 1
	
* drop trees and other perennial crops
	tab		crop_code
	
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
	
	tab		crop_code
	*** remaining crop mix looks okay
	*** although there's some stuff that i don't know what it is
				
* finding unique identifier
	describe
	sort 		holder_id parcel_id field_id crop_code
	isid 		holder_id parcel_id field_id crop_code, missok
	
* creating parcel identifier
	rename		parcel_id parcel
	tostring	parcel, replace
	generate 	parcel_id = holder_id + " " + ea_id + " " + parcel
	
* creating field identifier
	rename		field_id field
	tostring	field, replace
	generate 	field_id = holder_id + " " + ea_id + " " + parcel + " " + field
	
* creating unique crop identifier
	tostring	crop_code, generate(crop_codeS)
	generate 	crop_id = holder_id + " " + ea_id + " " + parcel + " " ///
					+ field + " " + crop_codeS
	isid		crop_id
	drop		crop_codeS

* creating district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 72 distinct districts
	*** down from pp sect3 & sect4, likely due to drops
	
* check for missing crop codes
	tab			crop_code, missing
	** no missing crop codes in this wave =]

* create conversion key 
	rename		ph_s9q04_b_cf unit_cd
	tab 		unit_cd, missing
	*** missing only 2,415 units of measure
	
	merge 		m:1 crop_code unit_cd using "`export'/Crop_CF_Wave2_cleaned"
	*** 2,719 obs not matched from master data
	
	tab 		unit_cd _merge, missing
	*** all obs listed as other have no match

	drop		if _merge == 2
	drop		_merge

	
* ***********************************************************************
* 2 - finding harvest weights
* ***********************************************************************	

* ***********************************************************************
* 2a - generating conversion factors
* ***********************************************************************	
	
* creating harvest (kg) based on self reported values
* self reported values listed in various units of measure
	rename		ph_s9q04_a hrvqty_self
	rename 		ph_s9q05 hrvqty_self_kgest	
	
* exploring conversion factors - are any the same across all regions and obs?
	tab 		unit_cd
	egen		unitnum = group(unit_cd)
	*** 21 units listed
	
	gen			cfavg = (mean_cf1 + mean_cf2 + mean_cf3 + mean_cf4 + mean_cf6 ///
							+ mean_cf7 + mean_cf12 + mean_cf99)/8
	pwcorr 		cfavg mean_cf_nat	
	*** correlation of 0.9994 - this will work
	
	local 		units = 21
	forvalues	i = 1/`units'{
	    
		tab		unit_cd if unitnum == `i'
		tab 	cfavg if unitnum == `i', missing
	} 
	*** results! universal units are:
	*** kilogram, kuintal, festal, jerikan, shekim

* generating conversion factors
* starting with units found to be universal
	gen			cf = 1 if unit_cd == 1 			// kilogram
	replace		cf = 100 if unit_cd == 2		// kuintal
	replace		cf = 3.207 if unit_cd == 112	// festal
	replace		cf = 13.82212 if unit_cd == 127	// jerikan
	replace		cf = 21.66 if unit_cd == 152	// shekim
	
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
	
* checking veracity of kg estimates
	tab 		cf, missing
	*** missing 2,415 - slightly fewer than missed merges due to univeral units
	
	tab			cf if hrvqty_self != ., missing
	tab			hrvqty_self if cf == ., missing
	*** there are 2,415 self report harvest quanities w/out a conversion factor
	
	tab			hrvqty_self if cf != ., missing
	

* ***********************************************************************
* 2b - constructing harvest weights
* ***********************************************************************		
	
	gen			hrvqty_self_converted = hrvqty_self * cf
	pwcorr		hrvqty_self_converted hrvqty_self_kgest
	*** correlation of 0.3365 - not so good
	*** i'm inclined to take the surveyor's estimate over the converted kgs
	*** being that the conversion factors are region wide averages
	*** the surveyor may have been able to estimate based on more local info
	
	gen			hrvqty_selfr = hrvqty_self_kgest
	replace		hrvqty_selfr = hrvqty_self_converted if hrvqty_selfr == . 
	*** only 2 changes made in this step

	tab			hrvqty_selfr, missing
	*** missing 9 obs
	
	sum 		hrvqty_selfr, detail
	*** mean qty 174 kg, this seems plausible
	*** max at 40K - less plausible
	*** there are 3 obs = 0, crop damage?
	
	
* ***********************************************************************
* 2c - resolving zero values
* ***********************************************************************		

* crop damage
	rename 		ph_s9q11 damaged
	rename 		ph_s9q13 damaged_pct
	tab 		damaged_pct damaged, missing
	tab 		hrvqty_selfr damaged, missing
	*** crop damage reported on 3 of 3 obs w/ harv quantity = 0
	*** what about 100% crop damage on other obs?
	
	tab 		damaged_pct if hrvqty_selfr == 0
	*** 2 hundos, one at 50%	

	generate 	destroyed = 1 if damaged == 1 & damaged_pct == 100
	gen 		destroyed_lite = 1 if damaged_pct == 100
	replace		destroyed = 0 if destroyed == .
	replace 	destroyed_lite = 0 if destroyed_lite == .
	pwcorr		destroyed destroyed_lite
	*** correlation of 1 - interchangable
	
	tab			damaged_pct
	tab 		destroyed, missing
	*** 21 obs reporting 100% crop damage
	*** 1 ob reporting 500%, 1 reporting 801%, I'm assuming the decimal got moved
	
* let's take stock of where we're at so far			
	sort 		hrvqty_selfr 
	tab			hrvqty_self if hrvqty_selfr == 0, missing
	*** one ob has non-zero self reported values
	*** two are listed as destroyed (100% crop damage)
	
	tab			hrvqty_self_converted if hrvqty_selfr == 0, missing
	*** 3 of 3 missing, due to missing conversion factors
	
	tab 		unit_cd if hrvqty_selfr == 0, missing
	*** 3 of 3 missing
	
* will replace one ob not reported as destroyed but with a hrvqty_selfr == 0 as missing
* i'm confident in this because the farmer did report a value, but no cf was given
* will be caught up in the imputation in the next section

* i'm a little bit cautious about the 17 obs w/ reported weights listed as destroyed
	tab			hrvqty_selfr if destroyed == 1, missing
	*** if we assume the 500% value was actually meant to be 50%
	*** then it's not implausible that these 17 listed as 100% were meant to be 10%
	*** will leave this be for now...
	
	
* ***********************************************************************
* 2d - resolving missing values
* ***********************************************************************		

* summarize value of harvest
	sum				hrvqty_selfr, detail
	*** median 60, mean 174, max 40,000 - max is huge!

* replace any +3 s.d. away from median as missing
	replace			hrvqty_selfr = . if hrvqty_selfr > `r(p50)'+(3*`r(sd)')
	*** replaced 110 values, max is now 2,200
	
* impute missing harvest weights using predictive mean matching 
	mi set 		wide //	declare the data to be wide. 
	mi xtset, 	clear //	this is a precautinary step to clear any xtset that the analyst may have had in place previously
	mi register imputed hrvqty_selfr //	identify hrvqty_selfr as the variable being imputed 
	sort		holder_id parcel field crop_code, stable // sort to ensure reproducability of results
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
* 3 - cleaning and keeping
* ***********************************************************************

* renaming key variables	
	rename 		saq01 region
	rename		saq02 zone
	rename 		saq03 woreda
	rename 		saq05 ea 
	rename		hrvqty_selfr hvst_qty

* purestand or mixed and if mixed what percent was planted with this crop?
	rename		ph_s9q01 purestand
	rename		ph_s9q02 mixedcrop_pct

* renaming some variables of interest
	rename 		household_id hhid
	rename 		household_id2 hhid2	
	
* restrict to variables of interest 
* this is how world bank has their do-file set up
* if we want to keep all identifiers (i.e. region, zone, etc) we can do that easily
	keep  		holder_id- crop_code crop_id mz_hrv hvst_qty ///
					purestand mixedcrop_pct
	*** keeping purestand/mixed as a precaution
	
	order 		holder_id- crop_code
	
* renaming and relabelling variables
	lab var			mz_hrv "Quantity of Maize Harvested (kg)"
	lab var 		crop_code "Crop Identifier"
	lab var			crop_id "Unique Crop ID Within Plot"

* final preparations to export
	isid 			holder_id field parcel crop_code
	isid			crop_id
	compress
	describe
	summarize 
	sort 		holder_id ea_id parcel field crop_code
	save		"`export'/PH_SEC9.dta", replace

* close the log
	log	close