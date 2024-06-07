* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Edited on: 7 June 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 5 PH sec11
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
	global		root 		 	"$data/household_data/ethiopia/wave_5/raw"  
	global		export 		 	"$data/household_data/ethiopia/wave_5/refined"
	global		logout 		 	"$data/household_data/ethiopia/logs"
	
* open log	
	cap log 	close
	log 		using			"$logout/wv5_PHSEC11", append


* **********************************************************************
* 1 - preparing ESS (Wave 5) - Post Harvest Section 11
* **********************************************************************

* load data
	use 		"$root/sect11_ph_w5.dta", clear

* dropping duplicates
	duplicates 	drop
	format 		%4.0g harvestedcrop_id
	rename		s11q01 crop_code
	
* unique identifier can only be generated including crop code as some fields are mixed
	describe
	sort 		holder_id harvestedcrop_id
	isid 		holder_id harvestedcrop_id

* creating unique crop identifier
	drop if		crop_code == .
	*** 0 dropped
	
	tostring	harvestedcrop_id, generate(crop_codeS)
	generate 	crop_id = holder_id + " " + crop_codeS
	isid		crop_id
	drop		crop_codeS
	rename		harvestedcrop_id crop
	
* creating district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 59 distinct districts
	*** same as ph sect10, finally one that matches!
	
* drop if obs haven't sold any crop
	tab			s11q07
	*** 4,768 answered no
	
	tab			s11q11a s11q07, missing
	*** sales data not present for all obs that answered no
	
	drop 		if s11q07 == 2
	
* create conversion key 
	rename		s11q03a2 unit_cd
	merge 		m:1 crop_code unit_cd using "$export/Crop_CF_Wave5.dta"
	*** 1,192 not matched from master

	tab 		_merge
	drop		if _merge == 2
	drop		_merge


* **********************************************************************
* 2 - generating sales values and sales quantities
* **********************************************************************
	
* ***********************************************************************
* 2a - generating conversion factors
* ***********************************************************************	
	
* constructing conversion factor - same procedure as sect9_ph_w4
* exploring conversion factors - are any the same across all regions and obs?
	tab 		unit_cd
	egen		unitnum = group(unit_cd)
	*** 44 units listed
	
	gen			cfavg = (mean_cf1 + mean_cf2 + mean_cf3 + mean_cf4 + mean_cf6 ///
							+ mean_cf7 + mean_cf12 + mean_cf99)/8
	pwcorr 		cfavg mean_cf_nat	
	*** correlation of 0.9999 - this will work
	
	local 		units = 59
	forvalues	i = 1/`units'{
	    
		tab		unit_cd if unitnum == `i'
		tab 	cfavg if unitnum == `i', missing
	} 
	*** results! universal units are:
	*** kilogram, gram, quintal, box, jenbe
	*** shekim, zorba, zelela (small, medium, and large)
	*** missing units are:
	*** lt, cl, melekiya
	*** chinets (small, medium, and large) and other
	*** have no conversion factors given

* generating conversion factors
* starting with units found to be universal
	gen			cf = 1 if unit_cd == 1 			// kilogram
	replace		cf = .001 if unit_cd == 2 		// gram
	replace		cf = 100 if unit_cd == 3 		// quintal
	replace		cf = 1 if unit_cd == 4 			// liters
	replace		cf = .001 if unit_cd == 5 		// cm
	replace		cf = 48.05125 if unit_cd == 6 	// box/casa
	replace 	cf = 31.487 if unit_cd == 7		// jenbe
	replace		cf = 9.6 if unit_cd == 41		// zelela (small)
	replace		cf = 17.5 if unit_cd == 42
	replace		cf = 19.08 if unit_cd == 43
	replace		cf = .4 if unit_cd == 132		// medeb (small)
	replace		cf = 7.27 if unit_cd == 161		// shekim
	replace		cf = 21.66 if unit_cd == 162
	replace		cf = 41 if unit_cd == 163
	replace		cf = .16 if unit_cd == 191		// zorba (small)
	replace		cf = .27 if unit_cd == 192
	replace		cf = .57 if unit_cd == 193
	
* using chinets from previous rounds
	replace 	cf = 30 if unit_cd == 51		// chinets
	replace 	cf = 50 if unit_cd == 52
	replace 	cf = 70 if unit_cd == 53
	replace		cf = 1.92 if unit_cd == 63		// esir (large)
	replace		cf = 1.415 if unit_cd == 71
	replace		cf = 6.769 if unit_cd == 73		//  festal

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
	*** missing 220 converstion factors
	
	tab 		unit_cd if cf == .
	*** most of the units missing are other values
	*** all units labelled 'other' missing a conversion factor

* filling in as many missing cfs as possible
	sum			cf if unit_cd == 111, detail	// kunna/mishe/kefer/enkib (sm)
	replace 	cf = `r(p50)' if unit_cd == 111 & cf == .
	
	sum			cf if unit_cd == 112, detail	// kunna/mishe/kefer/enkib (md)
	replace 	cf = `r(p50)' if unit_cd == 112 & cf == .
	
	sum			cf if unit_cd == 113, detail	// kunna/mishe/kefer/enkib (lg)
	replace 	cf = `r(p50)' if unit_cd == 113 & cf == .
	
	sum			cf if unit_cd == 121, detail	// madaberia/nuse/shera/cheret (sm)
	replace 	cf = `r(p50)' if unit_cd == 121 & cf == .
	
	sum			cf if unit_cd == 122, detail	// madaberia/nuse/shera/cheret (md)
	replace 	cf = `r(p50)' if unit_cd == 122 & cf == .
	
	sum			cf if unit_cd == 123, detail	// madaberia/nuse/shera/cheret (lg)
	replace 	cf = `r(p50)' if unit_cd == 123 & cf == .
	
	sum			cf if unit_cd == 182, detail	// tasa/tanika/shember/selmon (md)
	replace 	cf = `r(p50)' if unit_cd == 182 & cf == .
	
	sum			cf if unit_cd == 183, detail	// tasa/tanika/shember/selmon (lg)
	replace 	cf = `r(p50)' if unit_cd == 183 & cf == .
	
* check results
	tab 		unit_cd if cf == .
	*** 163 obs still missing cfs, 78 are labelled 'other'

	
* ***********************************************************************
* 2b - constructing harvest weights and prices
* ***********************************************************************	
	
* renaming key variables	
	rename		s11q11a sales_qty
	tab			sales_qty, missing
	*** not missing any values
	
	rename		s11q12 sales_val
	
* converting sales quantity to kilos
	gen			sales_qty_kg = sales_qty * cf
	tab 		sales_val
	*** 9 missing any sales values
	
	drop if		sales_val == .
	
* generate a price per kilogram
	gen 		price = sales_val/sales_qty_kg
	drop if		price == .
	*** this can be applied to harvested crops which weren't sold
	
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
	*** 72 distinct crops
	
	distinct 	crop_code region, joint
	*** 223 distinct regions by crop

	distinct 	crop_code region zone, joint
	*** 615 distinct zones by crop
	
	distinct 	crop_code region zone woreda, joint
	*** 771 distinct woreda by crop
	
	distinct 	crop_code region zone woreda ea, joint
	*** 771 distinct eas by crop

	distinct 	crop_code region zone woreda ea holder_id, joint
	*** 2453 distinct holders by crop (this is the dataset)
	
* summarize prices	
	replace			price = 3508.772 if price > 3508.772
	sum 			price, detail
	*** mean = 151, max = 3,508, min = 0.004
	*** will do some imputations later
	
* make datasets with crop price information	
	preserve
	collapse 		(p50) p_holder=price (count) n_holder=price, by(crop_code holder_id ea woreda zone region)
	save 			"$export/w5_sect11_pholder.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_ea=price (count) n_ea=price, by(crop_code ea woreda zone region)
	save 			"$export/w5_sect11_pea.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_woreda=price (count) n_woreda=price, by(crop_code woreda zone region)
	save 			"$export/w5_sect11_pworeda.dta", replace 	
	restore
	
	preserve
	collapse 		(p50) p_zone=price (count) n_zone=price, by(crop_code zone region)
	save 			"$export/w5_sect11_pzone.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_region=price (count) n_region=price, by(crop_code region)
	save 			"$export/w5_sect11_pregion.dta", replace 
	restore
	
	preserve
	collapse 		(p50) p_crop=price (count) n_crop=price, by(crop_code)
	save 			"$export/w5_sect11_pcrop.dta", replace 
	restore	
	
* merge price data back into dataset
	merge 			m:1 crop_code ea woreda zone region	        using "$export/w5_sect11_pea.dta", assert(3) nogenerate
	merge 			m:1 crop_code woreda zone region	        using "$export/w5_sect11_pworeda.dta", assert(3) nogenerate
	merge 			m:1 crop_code zone region	        		using "$export/w5_sect11_pzone.dta", assert(3) nogenerate
	merge 			m:1 crop_code region						using "$export/w5_sect11_pregion.dta", assert(3) nogenerate
	merge 			m:1 crop_code 						        using "$export/w5_sect11_pcrop.dta", assert(3) nogenerate


* ***********************************************************************
* 4 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid

*	Restrict to variables of interest
	keep  		holder_id- crop_code price crop_id p_ea- n_crop
	order 		holder_id- crop_code price crop_id

* final preparations to export
	isid 		holder_id crop
	compress
	describe
	summarize 
	sort 		holder_id ea_id crop
	
	save		 "$export/PH_SEC11.dta", replace

* close the log
	log	close