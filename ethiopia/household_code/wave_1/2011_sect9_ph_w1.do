* Project: WB Weather
* Created on: July 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 1 PH sec9
	* seems to roughly correspong to Malawi ag-modG and ag-modM
	* contains self reported harvest weights and other info (dates, etc.)
	* also contains weights of crop-cutting
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
	loc root = "$data/household_data/ethiopia/wave_1/raw"
	loc export = "$data/household_data/ethiopia/wave_1/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv1_PHSEC9", append


* **********************************************************************
* 1 - preparing ESS 2011/12 (Wave 1) - Post Harvest Section 9
* **********************************************************************

* load conversion data for cleaning
	use 		"`root'/sect9_ph_w1.dta", clear
	
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
	drop if crop_code == 118	// other, pulses (?)
	drop if crop_code == 119	// other, oil seed
	drop if crop_code == 120	// other, cereal
	drop if crop_code == 121	// other, case crops
	drop if crop_code == 123	// other, vegetable
	*** 1,164 obs dropped	
	
* unique identifier can only be generated including crop code as some fields are mixed (pp_s4q02)
	describe
	sort 		holder_id household_id parcel_id field_id crop_code
	isid 		holder_id household_id parcel_id field_id crop_code, missok

* drop observations with a missing field_id
	summarize 	if missing(parcel_id,field_id,crop_code)
	drop 		if missing(parcel_id,field_id,crop_code)
	isid 		holder_id household_id parcel_id field_id crop_code
	
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

* creating unique district identifier
	egen district_id = group( saq01 saq02)
	*** 64 distinct districts


* **********************************************************************
* 2 - harvest weights
* **********************************************************************		
	
* **********************************************************************
* 2a - finding crop cut weights and dried weights
* **********************************************************************	
	
* date of harvest
	generate 	year = 2012 	// I'm making an assumption here because all the months are in the early part of the year
	gen 		edate = mdy(ph_s9q02_b, ph_s9q02_a, year)
	format 		edate %d
	drop 		year
	rename 		edate cutting_date
	label 		variable cutting_date "Date of crop cutting"

* fresh weight and dry weight, not sure what we're interested in...
	generate 	fresh_wgt_kilo = ph_s9q03_a
	replace 	fresh_wgt_kilo = 0 if ph_s9q03_a == . & ph_s9q03_b != .
	generate	fresh_wgt_gram = ph_s9q03_b
	replace 	fresh_wgt_gram = 0 if ph_s9q03_b == . & ph_s9q03_a != .
	generate 	fresh_wgt = fresh_wgt_kilo + 0.001*fresh_wgt_gram
	drop		fresh_wgt_kilo fresh_wgt_gram

* CONSIDER MISSING VALUES - must keep a & b as nulls if BOTH are missing
* must fill in a zero for a if b is equal to something and vice versa

* date of dry weighing
	generate 	year = 2012 	// I'm making an assumption here because all the months are in the early part of the year
	gen 		edate = mdy(ph_s9q04_b, ph_s9q04_a, year)
	format 		edate %d
	drop 		year
	rename 		edate drywgh_date
	label 		variable drywgh_date "Date of dry weighing of crop"

* dry weight
	generate	dry_wgt_kilo = ph_s9q05_a
	replace 	dry_wgt_kilo = 0 if ph_s9q05_a == . & ph_s9q05_b != .
	generate	dry_wgt_gram = ph_s9q05_b
	replace 	dry_wgt_gram = 0 if ph_s9q05_b == . & ph_s9q05_a != .
	generate 	dry_wgt = dry_wgt_kilo + 0.001*dry_wgt_gram

* checking results
	sum			fresh_wgt dry_wgt
	
	
* **********************************************************************
* 2b - self reported values
* **********************************************************************	

* self-reported weights
	generate	sr_wgt_kilo = ph_s9q12_a
	replace		sr_wgt_kilo = 0 if ph_s9q12_a == . & ph_s9q12_b != .
	gen			sr_wgt_gram = ph_s9q12_b
	replace		sr_wgt_gram = 0 if ph_s9q12_b ==. & ph_s9q12_a != .
	gen			sr_wgt = sr_wgt_kilo + 0.001*sr_wgt_gram
	
	sum			sr_wgt
	tab			sr_wgt
	*** 4,051 obs, mean - 161.34, max - 9500, 125 obs = 0

* crop damage
	tab		ph_s9q09, missing
	

* ***********************************************************************
* 2b.1 - resolving zero values
* ***********************************************************************		

* crop damage
	rename 		ph_s9q09 damaged
	rename 		ph_s9q11 damaged_pct
	rename		sr_wgt hrvqty_selfr
	tab 		damaged_pct damaged, missing
	tab 		hrvqty_selfr damaged, missing
	*** crop damage reported on 122 of 125 obs w/ harv quantity = 0
	*** what about 100% crop damage on other obs?
	
	tab 		damaged_pct if hrvqty_selfr == 0
	*** 117 hundos, 4 at 99%, 1 at 75%	

	generate 	destroyed = 1 if damaged == 1 & damaged_pct == 100
	gen 		destroyed_lite = 1 if damaged_pct == 100
	replace		destroyed = 0 if destroyed == .
	replace 	destroyed_lite = 0 if destroyed_lite == .
	pwcorr		destroyed destroyed_lite
	*** correlation of 1 - interchangable
	
	tab			damaged_pct
	tab 		destroyed, missing
	*** 180 obs reporting 100% crop damage
	
	tab 		destroyed if hrvqty_selfr == 0
	*** for 117 obs, crop is listed as destroyed
	
	tab 		damaged_pct if hrvqty_selfr == 0, missing
	*** for 4 more obs, damaged_pct listed as 99%, practically destoryed
	*** damaged_pct = 75% for one other ob, missing for other three
	
* four values have self-reported harvest weights of zero with inconsistent or missing damage info
* i'm willing to take the farmers' word on these four and assume that one way or another they harvested no crop

* i'm a little bit cautious about the 8 obs w/ reported weights listed as destroyed
	tab			hrvqty_selfr if destroyed == 1, missing
	*** will leave this be for now...
	
	
* ***********************************************************************
* 2b.2 - resolving missing values
* ***********************************************************************		

* summarize value of harvest
	sum				hrvqty_selfr, detail
	*** median 65, mean 161.34, max 9,500 - max is huge!

* replace any +3 s.d. away from median as missing
	replace			hrvqty_selfr = . if hrvqty_selfr > `r(p50)'+(3*`r(sd)')
	*** replaced 55 values, max is now 1,100
	
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
	*** 2,586 imputations made
	
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

* renaming some variables of interest
	rename 		household_id hhid
	
* restrict to variables of interest 
* this is how world bank has their do-file set up
* if we want to keep all identifiers (i.e. region, zone, etc) we can do that easily
	keep  		holder_id- crop_code crop_id mz_hrv hvst_qty ///
					fresh_wgt dry_wgt
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
	sort 			holder_id ea_id parcel field crop_code
	save			"`export'/PH_SEC9.dta", replace

* close the log
	log	close
	
/* END */