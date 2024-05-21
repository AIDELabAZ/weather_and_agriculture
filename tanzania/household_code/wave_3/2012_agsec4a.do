* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 3 Ag sec4a
	* kind of a crop roster, with harvest weights, long rainy season
	* generates weight harvested, harvest month, percentage of plot planted with given crop
	
* assumes
	* access to all raw data
	* mdesc.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_3/raw"
	global export 	"$data/household_data/tanzania/wave_3/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv3_AGSEC4A", append


	
* ***********************************************************************
* 1 - prepare TZA 2012 (Wave 3) - Agriculture Section 4A 
* ***********************************************************************

* load data
	use				"$root/AG_SEC_4A", clear
	
* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped

* rename variables of interest
	rename			zaocode crop_code
	
* create percent of area to crops
	gen				pure_stand = ag4a_01 == 1
	gen				any_pure = pure_stand == 1
	gen				any_mixed = pure_stand == 0
	
	gen				percent_field = 0.25 if ag4a_02 == 1
	replace			percent_field = 0.50 if ag4a_02==2
	replace			percent_field = 0.75 if ag4a_02==3
	replace			percent_field = 1 if pure_stand==1
	duplicates		report y3_hhid plotnum zaoname
	*** there are 20 duplicates

* drop the duplicates
	duplicates		drop y3_hhid plotnum zaoname, force
	*** percent_field and pure_stand variables are the same, so dropping duplicates
	
* create total area on field (total on plot across ALL crops)
	bys 			y3_hhid plotnum: egen total_percent_field = total(percent_field)
	replace			percent_field = percent_field / total_percent_field ///
						if total_percent_field > 1

* check for missing values
	mdesc 			crop_code ag4a_28
	*** 2,249 obs missing crop code
	*** 2,714 obs missing harvest weight
	
* drop if crop code is missing
	drop				if crop_code == .
	*** 2,249 observations dropped

* drop if no harvest occured during long rainy season
	drop				if ag4a_19 != 1
	*** 464 obs dropped
	
* replace missing weight 
	replace 			ag4a_28 = 0 if ag4a_28 == .
	*** one value changed
	
* generate hh x plot x crop identifier
	gen		 			plot_id = y3_hhid + " " + plotnum
	tostring 			crop_code, generate(crop_num)
	gen str20 			crop_id = y3_hhid + " " + plotnum + " " + crop_num
	duplicates report 	crop_id
	*** five duplicate crop_ids

* must merge in regional identifiers from 2008_HHSECA to impute
	merge			m:1 y3_hhid using "$export/HH_SECA"
	tab				_merge
	*** 1,710 not matched
	
	drop if			_merge == 2
	drop			_merge
	
* unique district id
	sort			region district
	egen			uq_dist = group(region district)
	distinct		uq_dist
	*** 130 distinct districts
	
	
* ***********************************************************************
* 2 - generate harvest variables
* ***********************************************************************

* other variables of interest
	rename 				ag4a_28 wgt_hvsted
	rename				ag4a_29 hvst_value
	tab					hvst_value, missing
	*** hvst_value missing no observations

* currency conversion to 2015 usd
	replace				hvst_value = hvst_value/1901.6280
	*** Value comes from World Bank: world_bank_exchange_rates.xlxs

* summarize value of harvest
	sum				hvst_value, detail
	*** median 36.81, mean 107.58, max 16,659.41

* replace any +3 s.d. away from median as missing
	replace			hvst_value = . if hvst_value > `r(p50)'+(3*`r(sd)')
	*** replaced 111 values, max is now 1,054
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed hvst_value // identify kilo_fert as the variable being imputed
	sort			y3_hhid plotnum crop_num, stable // sort to ensure reproducability of results
	mi impute 		pmm hvst_value i.uq_dist i.crop_code, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss
	tabstat			hvst_value hvst_value_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			hvst_value = hvst_value_1_
	drop			hvst_value_1_
	*** imputed 64 values out of 7,447 total observations		

* generate new varaible for measuring maize harvest
	gen				mz_hrv = wgt_hvsted if crop_code == 11
	gen				mz_damaged = 1 if crop_code == 11 & mz_hrv == 0

* summarize value of harvest
	sum				mz_hrv, detail
	*** median 200, mean 501, max 40,000

* replace any +3 s.d. away from median as missing
	replace			mz_hrv = . if mz_hrv > `r(p50)' + (3*`r(sd)')
	*** replaced 41 values, max is now 3,700
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed mz_hrv // identify kilo_fert as the variable being imputed
	sort			y3_hhid plotnum crop_num, stable // sort to ensure reproducability of results
	mi impute 		pmm mz_hrv i.uq_dist if crop_code == 11, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss1 if crop_code == 11
	tabstat			mz_hrv mz_hrv_1_ if crop_code == 11, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			mz_hrv = mz_hrv_1_  if crop_code == 11
	drop			mz_hrv_1_
	*** imputed 41 values out of 2,868 total observations			

	
* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************
							
* keep what we want, get rid of what we don't
	keep 				y3_hhid plotnum plot_id crop_code crop_id clusterid ///
							strataid hhweight region district ward ea ///
							any_* pure_stand percent_field mz_hrv hvst_value ///
							mz_damaged y3_rural

	order				y3_hhid plotnum plot_id crop_code crop_id clusterid ///
							strataid hhweight region district ward ea
	
* renaming and relabelling variables
	lab var			y3_hhid "Unique Household Identification NPS Y3"
	lab var			y3_rural "Cluster Type"
	lab var			hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var			plotnum "Plot ID Within household"
	lab var			plot_id "Plot Identifier"
	lab var			clusterid "Unique Cluster Identification"
	lab var			strataid "Design Strata"
	lab var			region "Region Code"
	lab var			district "District Code"
	lab var			ward "Ward Code"
	lab var			ea "Village / Enumeration Area Code"	
	lab var			mz_hrv "Quantity of Maize Harvested (kg)"
	lab var			mz_damaged "Was Maize Harvest Damaged to the Point of No Yield"
	lab var			hvst_value "Value of Harvest (2015 USD)"
	lab var 		crop_code "Crop Identifier"
	lab var			crop_id "Unique Crop ID Within Plot"
	lab var			pure_stand "Is Crop Planted in Full Area of Plot (Purestand)?"
	lab var			any_pure "Is Crop Planted in Full Area of Plot (Purestand)?"
	lab var			any_mixed "Is Crop Planted in Less Than Full Area of Plot?"
	lab var			percent_field "Percent of Field Crop Was Planted On"
							
* check for duplicates
	duplicates		report y3_hhid plotnum crop_code
	*** there are 3 duplicates

* drop the duplicates
	duplicates		drop y3_hhid plotnum crop_code, force
	*** the duplicates are all the same, so dropping duplicates
	
* prepare for export
	isid			y3_hhid plotnum crop_code
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/AG_SEC4A.dta", replace

* close the log
	log	close

/* END */
