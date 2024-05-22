* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 4 extended panel Ag sec4a
	* kind of a crop roster, with harvest weights, long rainy season
	* generates weight harvested, harvest month, percentage of plot planted with given crop, value of seed purchases
	
* assumes
	* access to all raw data
	* mdesc.ado
	* cleaned hh_seca.dta

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_5/raw"
	global export 	"$data/household_data/tanzania/wave_5/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv5_AGSEC4A", append


* ***********************************************************************
* 1 - TZA 2014 (Wave 4) - Agriculture Section 4A 
* *********************1*************************************************

* load data
	use 			"$root/ag_sec_4a", clear

* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped

* rename variables of interest
	rename 			zaocode crop_code
	
* create percent of area to crops
	gen				pure_stand = ag4a_01 == 1
	lab var			pure_stand "=1 if crop was pure stand"
	gen				any_pure = pure_stand == 1
	lab var			any_pure "=1 if any crop was pure stand"
	gen				any_mixed = pure_stand == 0
	lab var			any_mixed "=1 if any crop was mixed"
	gen				percent_field = 0.25 if ag4a_02 == 1
	lab var			percent_field "percent of field crop was on"

	replace			percent_field = 0.50 if ag4a_02==2
	replace			percent_field = 0.75 if ag4a_02==3
	replace			percent_field = 1 if pure_stand==1
	duplicates		list y4_hhid plotnum crop_code
	*** there are 6 duplicates
	
* drop the duplicates
	duplicates		drop y4_hhid plotnum zaoname, force
	*** percent_field and pure_stand variables are the same, so dropping duplicates
	*** drops 4 duplicate obs, the 2 remaining are 'chilies' and 'OTHER'
	*** since they're not maize, I will collapse at the end of the do-file

* create total area on field (total on plot across ALL crops)
	bys 			y4_hhid plotnum: egen total_percent_field = total(percent_field)
	replace			percent_field = percent_field / total_percent_field ///
						if total_percent_field > 1	
	*** 3,039 changes made

* check for missing values
	mdesc 				crop_code ag4a_28
	*** 1,541 obs missing crop code
	*** 1,721 obs missing harvest weight
	
* drop if crop code is missing
	drop				if crop_code == .
	*** 1,541 observations dropped

* drop if no harvest occured during long rainy season
	drop				if ag4a_19 != 1
	*** 181 obs dropped

* replace missing weight 
	replace 			ag4a_28 = 0 if ag4a_28 == .
	*** no changes made	

* generate hh x plot x crop identifier
*	isid				y4_hhid plotnum crop_code // no unique id, mentioned above
	gen		 			plot_id = y4_hhid + " " + plotnum
	lab var				plot_id "plot id"
	tostring 			crop_code, generate(crop_num)
	gen str23 			crop_id = y4_hhid + " " + plotnum + " " + crop_num
	duplicates report 	crop_id
	lab var				crop_id "unique crop id"
	*** 2 duplicate crop_ids	
	
* must merge in regional identifiers from 2008_HHSECA to impute
	merge			m:1 y4_hhid using "$export/HH_SECA"
	tab				_merge
	*** 1,564 not matched, from using
	
	drop if			_merge == 2
	drop			_merge
	
* unique district id
	sort			region district
	egen			uq_dist = group(region district)
	distinct		uq_dist
	*** 157 distinct districts

	
* ***********************************************************************
* 2 - generate harvest variables
* ***********************************************************************	

* other variables of interest
	rename 				ag4a_28 wgt_hvsted
	rename				ag4a_29 hvst_value
	tab					hvst_value, missing
	*** hvst_value missing no observations

*currency conversion to 2015 usd
	replace				hvst_value = hvst_value/1755.0802
	*** Value comes from World Bank: world_bank_exchange_rates.xlxs

* summarize value of harvest
	sum				hvst_value, detail
	*** median 47.86, mean 131.73, max 13,959.48

* replace any +3 s.d. away from median as missing
	replace			hvst_value = . if hvst_value > `r(p50)'+(3*`r(sd)')
	*** replaced 61 values, max is now 1,118.26
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed hvst_value // identify kilo_fert as the variable being imputed
	sort			y4_hhid plotnum crop_num, stable // sort to ensure reproducability of results
	mi impute 		pmm hvst_value i.uq_dist i.crop_code, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss
	tabstat			hvst_value hvst_value_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			hvst_value = hvst_value_1_
	lab var				hvst_value "Value of harvest (2010 USD)"
	drop			hvst_value_1_
	*** imputed 61 values out of 5,400 total observations	
	
* generate new varaible for measuring mize harvest
	gen					mz_hrv = wgt_hvsted if crop_code == 11
	gen					mz_damaged = 1 if crop_code == 11 & mz_hrv == 0
	tab					mz_damaged, missing
	*** no obs with damaged maize harvest leading to zero harvested

* summarize value of harvest
	replace			mz_hrv = . if mz_hrv > 20000
	sum				mz_hrv, detail
	*** median 300, mean 641, max 11,200
	
* replace any +3 s.d. away from median as missing
	replace			mz_hrv = . if mz_hrv > `r(p50)' + (3*`r(sd)')
	*** replaced 46 values, max is now 3,600

* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed mz_hrv // identify kilo_fert as the variable being imputed
	sort			y4_hhid plotnum crop_num, stable // sort to ensure reproducability of results
	mi impute 		pmm mz_hrv i.uq_dist if crop_code == 11, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset	

* how did the imputation go?
	tab				mi_miss1 if crop_code == 11
	tabstat			mz_hrv mz_hrv_1_ if crop_code == 11, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			mz_hrv = mz_hrv_1_  if crop_code == 11
	lab var			mz_hrv "Quantity of maize harvested (kg)"
	drop			mz_hrv_1_
	*** imputed 46 values out of 2,024 total observations	
	
	
* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************
	
* keep what we want, get rid of what we don't
	keep 				y4_hhid plotnum plot_id crop_code crop_id clusterid ///
							strataid hhweight region district ward ea ///
							any_* pure_stand percent_field mz_hrv hvst_value ///
							mz_damaged y4_rural

	order				y4_hhid plotnum plot_id crop_code crop_id clusterid ///
							strataid hhweight region district ward ea
	
* renaming and relabelling variables
	lab var			y4_hhid "Unique Household Identification NPS Y4"
	lab var			y4_rural "Cluster Type"
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
	duplicates		report y4_hhid plotnum crop_code
	*** there are 2 duplicates
	
	collapse (sum)	hvst_value percent_field , by(y4_hhid ///
						plotnum plot_id crop_code crop_id clusterid ///
						strataid hhweight region district ward ea ///
						any_* pure_stand mz_hrv mz_damaged)
	** two fewer obs, should be the dupes from line 63

* prepare for export
	isid			y4_hhid plotnum crop_code
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/AG_SEC4A.dta", replace

* close the log
	log	close

/* END */
