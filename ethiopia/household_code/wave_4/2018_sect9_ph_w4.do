* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 3 PH sec9
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
	global		root 		 	"$data/household_data/ethiopia/wave_4/raw"  
	global		export 		 	"$data/household_data/ethiopia/wave_4/refined"
	global		logout 		 	"$data/household_data/ethiopia/logs"
	
* open log	
	cap log 	close
	log 		using			"$logout/wv4_PHSEC9", append

* **********************************************************************
* 1 - fix duplicate observation in crop conversion data
* **********************************************************************

* unlike in other waves, there is a duplicate in the conv data
* need to take care of the duplicate first before merging later

* load data
	use 		"$root/Crop_CF_Wave4.dta", clear
	
* drop duplicates
	duplicates 	drop crop_code unit_cd, force
	*** two dropped
	
* save data
	save		"$export/Crop_CF_Wave4.dta", replace

* **********************************************************************
* 2 - preparing ESS (Wave 4) - Post Harvest Section 9
* **********************************************************************

* load data
	use 		"$root/sect9_ph_w4.dta", clear

* dropping duplicates
	duplicates 	drop
	format 		%4.0g crop_id
	rename		s9q00b crop_code
	*** 0 obs dropped 
	
	isid 		holder_id parcel_id field_id crop_id
	
	duplicates 	drop holder_id parcel_id field_id crop_code, force
	*** 8 observations of 14,094 dropped
	
	isid		holder_id parcel_id field_id crop_code
		
* check # of maize obs
	tab			crop_code
	*** 1,925 maize obs
	
* drop if obs haven't harvested crop
	tab			s9q04, missing
	*** 2,103 answered no
	
	drop 		if s9q04 == 2
	*** 2,098 dropped

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
	* about 5,000 dropped
		
* creating parcel identifier
	rename		parcel_id parcel
	tostring	parcel, replace
	generate 	parcel_id = holder_id + " " + ea_id + " " + parcel
	
* creating field identifier
	rename		field_id field
	tostring	field, replace
	generate 	field_id = holder_id + " " + ea_id + " " + parcel + " " + field
	
* creating unique crop identifier
	rename		crop_id crop
	tostring	crop, generate(crop_idS)
	generate 	crop_id = holder_id + " " + ea_id + " " + parcel + " " ///
					+ field + " " + crop_idS
	isid		crop_id
	drop		crop_idS

* creating district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 69 distinct districts
	*** 3 less than in sec4, 6 less than in sect3
	
* check for missing crop codes
	tab			crop_code, missing
	** no missing crop codes in this wave =]

* create conversion key 
	rename		s9q05b unit_cd
	tab 		unit_cd, missing
	*** none missing units of measure
	
	merge 		m:1 crop_code unit_cd using "$export/Crop_CF_Wave4.dta"
	*** 924 obs not matched from master data
	*** a third are "other"
	
	drop		if _merge == 2
	drop		_merge


* ***********************************************************************
* 3 - finding harvest weights
* ***********************************************************************	

* ***********************************************************************
* 3a - generating conversion factors
* ***********************************************************************	
	
* creating harvest (kg) based on self reported values
* self reported values listed in various units of measure
	rename		s9q05a hrvqty_self
	rename 		s9q06 hrvqty_self_kgest	
	
* exploring conversion factors - are any the same across all regions and obs?
	tab 		unit_cd
	egen		unitnum = group(unit_cd)
	*** 41 units listed
	
	gen			cfavg = (mean_cf1 + mean_cf2 + mean_cf3 + mean_cf4 + mean_cf6 ///
							+ mean_cf7 + mean_cf12 + mean_cf99)/8
	pwcorr 		cfavg mean_cf_nat	
	*** correlation of 0.9998 - this will work
	
	local 		units = 41
	forvalues	i = 1/`units'{
	    
		tab		unit_cd if unitnum == `i'
		tab 	cfavg if unitnum == `i', missing
	} 
	*** results! universal units are:
	*** kilogram, gram, quintal, box/casa, and jenbe
	*** shekim (small, medium, and large)
	*** also, jenbe, bunch and chinets (small, medium, and large) and other
	*** have no conversion factors given

* generating conversion factors
* starting with units found to be universal
	gen			cf = 1 if unit_cd == 1 			// kilogram
	replace		cf = .001 if unit_cd == 2 		// gram
	replace		cf = 100 if unit_cd == 3 		// quintal
	replace		cf = 48.05125 if unit_cd == 6 	// box/casa
	replace		cf = 7.27 if unit_cd == 161		// shekim
	replace		cf = 21.66 if unit_cd == 162
	replace		cf = 41 if unit_cd == 163
	
* then use conversion factors from past rounds for ones missing in this wave
	replace		cf = 31.487 if unit_cd == 7 	// jenbe
	replace		cf = 9.6 if unit_cd == 41		// bunches
	replace		cf = 17.5 if unit_cd == 42
	replace		cf = 19.08 if unit_cd == 43	
	
* using chinets from previous rounds
	replace 	cf = 30 if unit_cd == 51		// chinets
	replace 	cf = 50 if unit_cd == 52
	replace 	cf = 70 if unit_cd == 53
	
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
	*** missing 708 - fewer than missed merges due to univeral units
	
	tab			cf if hrvqty_self != ., missing
	tab			hrvqty_self if cf != ., missing
	*** there are no self report harvest quanities w/out a conversion factor
	
	
* ***********************************************************************
* 3b - constructing harvest weights
* ***********************************************************************		
	
	gen			hrvqty_self_converted = hrvqty_self * cf
	pwcorr		hrvqty_self_converted hrvqty_self_kgest
	*** correlation of 0.13 - terrible esp compared to wave 3 which was .54
	
	sum			hrvqty_self_converted hrvqty_self_kgest
	*** self-report mean 230, min .001, max 55,000
	*** surveyor	mean 362, min -350, max 510,000
	
	*** in previous waves we have used surveyor's estimates
	*** this wave i'm inclined to take the converted kgs over the surveyor's estimate
	*** being that the surveyor reports negative as well as values over 100k
	
	gen			hrvqty_selfr = hrvqty_self_converted
	replace		hrvqty_selfr = hrvqty_self_kgest if hrvqty_selfr == . 
	*** only 708 changes made in this step

	sum 		hrvqty_selfr, detail
	*** mean qty 219 kg, this seems plausible
	*** max at 55K - less plausible
	*** there are 8 obs = 0

* unlike previous waves with many zeros, we only have 8
* they all are missing conversion factors
* surveyors reported zero so will keep them
	
* unlike other waves there are also no missing values
	
	
* ***********************************************************************
* 2d - resolving outliers
* ***********************************************************************		

* summarize value of harvest
	sum				hrvqty_selfr, detail
	*** median 28, mean 219, max 55,000 - max is huge!

* replace any +3 s.d. away from median as missing
	replace			hrvqty_selfr = . if hrvqty_selfr > `r(p50)'+(3*`r(sd)')
	*** replaced 33 values, max is now 3,258
	
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
	*** 33 imputations made
	
	drop		mi_miss	

* manipulate variables for export
	drop		hrvqty_selfr
	rename 		hrvqty_selfr_1_ hrvqty_selfr
	label 		variable hrvqty_selfr		"Harvest Weight, kg (self-reported)"
	sum 		hrvqty_selfr, detail
	
* generate maize harvest weights
	gen 		mz_hrv = hrvqty_selfr if crop_code == 2
	

* ***********************************************************************
* 5 - cleaning and keeping
* ***********************************************************************

* renaming key variables	
	rename 		saq01 region
	rename		saq02 zone
	rename 		saq03 woreda
	rename 		saq05 ea 
	rename		hrvqty_selfr hvst_qty

* purestand or mixed and if mixed what percent was planted with this crop?
	rename		s9q02 purestand
	rename		s9q03 mixedcrop_pct

* renaming some variables of interest
	rename 		household_id hhid
	
* generate section id variable
	gen			sec = 9
	
* restrict to variables of interest 
* this is how world bank has their do-file set up
* if we want to keep all identifiers (i.e. region, zone, etc) we can do that easily
	keep  		holder_id- crop_code crop_id mz_hrv hvst_qty ///
					purestand mixedcrop_pct sec
	*** keeping purestand/mixed as a precaution
	
	order 		holder_id- crop_code
	
* renaming and relabelling variables
	lab var			region "Region Code"
	lab var			zone "Zone Code"
	lab var			woreda "Woreda Code"
	lab var			ea "Village / Enumeration Area Code"	
	lab var			mz_hrv "Quantity of Maize Harvested (kg)"
	lab var 		crop_code "Crop Identifier"
	lab var			crop_id "Unique Crop ID"
	lab var			crop "Unique Crop ID Within Plot"

* final preparations to export
	isid 			holder_id field parcel crop_code
	isid			crop_id
	compress
	describe
	summarize 
	sort 			holder_id ea_id parcel field crop_code
	
	save			"$export/PH_SEC9.dta", replace

* close the log
	log	close