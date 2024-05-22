* Project: WB Weather
* Created on: Feb 2024
* Created by: reece
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 7 (NPSY5) Ag sec3a
	* plot details, inputs, 2020 long rainy season
	* generates irrigation and pesticide dummies, fertilizer variables, and labor variables 
	
* assumes
	* access to all raw data
	* distinct.ado
	* cleaned hh_seca.dta

* TO DO:
	* done

	
* **********************************************************************
**#0 - setup
* **********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_7/raw"
	global export 	"$data/household_data/tanzania/wave_7/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv7_AGSEC3A", append

	
* ***********************************************************************
**#1 - prepare TZA 2020 (Wave 7) - Agriculture Section 3A 
* ***********************************************************************

* load data
	use 		"$root/ag_sec_3a", clear

* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped

* check for uniquie identifiers
	rename 			prevplot_id plotnum
	isid			y5_hhid plot_id

	
* must merge in regional identifiers from 2020_HHSECA to impute
	merge			m:1 y5_hhid using "$export/HH_SECA"
	tab				_merge
	*** 1,780 not matched, from using

	drop if			_merge == 2
	drop			_merge
	
* unique district id
	sort			region district
	egen			uq_dist = group(region district)
	distinct		uq_dist
	*** 195 distinct districts

* record if field was cultivated during long rains
	gen 			status = ag3a_03 == 1 if ag3a_03 != .
	lab var			status "=1 if field cultivated during long rains"
	tab 			status
	*** 3,838 observations were cultivated (68.5%)

* drop uncultivated plots
	drop			if status == 0	
	*** 1,765 obs deleted
	
	
* ***********************************************************************
**#2 - generate fertilizer variables
* ***********************************************************************

* constructing fertilizer variables
	rename			ag3a_47 fert_any
	replace			fert_any = 2 if fert_any == .
	*** assuming missing values mean no fertilizer was used
	*** 957 changes made
	
	replace			ag3a_49 = 0 if ag3a_49 == .
	replace			ag3a_56 = 0 if ag3a_56 == .
	gen				kilo_fert = ag3a_49 + ag3a_56
	***ag3a_49= first type ag3a_56= second type

* summarize fertilizer
	sum				kilo_fert, detail
	*** median 0, mean 10.98, max 2000, s.d. 59.74
	*** the top three obs are 1000+ kg
	*** the next highest ob is 900

* replace any +3 s.d. away from median as missing
	replace			kilo_fert = . if kilo_fert > 5000
	sum				kilo_fert, detail
	replace			kilo_fert = . if kilo_fert > `r(p50)'+(3*`r(sd)')
	sum				kilo_fert, detail
	*** replaced 60 values, max is now 150
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed kilo_fert // identify kilo_fert as the variable being imputed
	sort			y5_hhid plot_id, stable // sort to ensure reproducability of results
	mi impute 		pmm kilo_fert i.uq_dist, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset

* how did the imputation go?
	tab				mi_miss
	tabstat			kilo_fert kilo_fert_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			kilo_fert = kilo_fert_1_
	drop			kilo_fert_1_
	*** imputed 60 values out of 4,795 total observations	

	
* ***********************************************************************
**#3 - generate irrigation, pesticide, and herbicide dummies
* ***********************************************************************
	
* renaming irrigation
	rename			ag3a_18 irrigated 
	replace			irrigated = 2 if irrigated == .
	*** 957 changes
	
* constructing pesticide/herbicide variables
	gen				pesticide_any = 2
	gen				herbicide_any = 2
	replace			pesticide_any = 1 if ag3a_65a == 1
	replace			herbicide_any = 1 if ag3a_60 == 1
	lab define		pesticide_any 1 "Yes" 2 "No"
	lab values		pesticide_any pesticide_any
	lab values		herbicide_any pesticide_any	
	*** 605 used pesticide, 286 used herbicide_any
	

* ***********************************************************************
**#4 - generate labor variables
* ***********************************************************************

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* in this survey we can't tell gender or age of household members
* since we can't match household members we deal with each activity seperately

*change missing to zero and then back again
		mvdecode		ag3a_72c_1 ag3a_72c_2 ag3a_72c_3 ag3a_72c_4 ///
						ag3a_72c_5 ag3a_72c_6 ag3a_72c_7 ag3a_72c_8 ag3a_72c_9 ag3a_72c_10 ///
						ag3a_72g_1 ag3a_72g_2 ag3a_72g_3 ag3a_72g_4 ///
						ag3a_72g_5 ag3a_72g_6 ag3a_72g_7 ag3a_72g_8 ag3a_72g_9 ag3a_72g_10 ///
						ag3a_72k_1 ag3a_72k_2 ag3a_72k_3 ag3a_72k_4 ///
						ag3a_72k_5 ag3a_72k_6 ag3a_72k_7 ag3a_72k_8 ag3a_72k_9 ag3a_72k_10, mv(0)

		mvencode		ag3a_72c_1 ag3a_72c_2 ag3a_72c_3 ag3a_72c_4 ///
						ag3a_72c_5 ag3a_72c_6 ag3a_72c_7 ag3a_72c_8 ag3a_72c_9 ag3a_72c_10 ///
						ag3a_72g_1 ag3a_72g_2 ag3a_72g_3 ag3a_72g_4 ///
						ag3a_72g_5 ag3a_72g_6 ag3a_72g_7 ag3a_72g_8 ag3a_72g_9 ag3a_72g_10 ///
						ag3a_72k_1 ag3a_72k_2 ag3a_72k_3 ag3a_72k_4 ///
						ag3a_72k_5 ag3a_72k_6 ag3a_72k_7 ag3a_72k_8 ag3a_72k_9 ag3a_72k_10, mv(0)						
	*** this allows us to impute only the variables we change to missing
	*** in wave6 there are 10 members (wave4 had 6), however basic info doc says there should be 6 members here as well- revisit
						
* summarize household individual labor for land prep to look for outliers
	sum				ag3a_72c_1 ag3a_72c_2 ag3a_72c_3 ag3a_72c_4 ///
						ag3a_72c_5 ag3a_72c_6 ag3a_72c_7 ag3a_72c_8 ag3a_72c_9 ag3a_72c_10
	*** no obs > 92, two obs = 92

* summarize household individual labor for weeding/ridging to look for outliers
	sum				ag3a_72g_1 ag3a_72g_2 ag3a_72g_3 ag3a_72g_4 ///
						ag3a_72g_5 ag3a_72g_6 ag3a_72g_7 ag3a_72g_8 ag3a_72g_9 ag3a_72g_10 
	*** one obs at 228
	
* summarize household individual labor for harvest to look for outliers
	sum				ag3a_72k_1 ag3a_72k_2 ag3a_72k_3 ag3a_72k_4 ///
						ag3a_72k_5 ag3a_72k_6 ag3a_72k_7 ag3a_72k_8 ag3a_72k_9 ag3a_72k_10
	*** no obs > 144, one obs = 144
	*** four obs = 120
	*** seems large compared to other labor variables and wave4
	
* no imputation necessary as no values are dropped
	
* compiling labor inputs
	egen			hh_labor_days = rsum(ag3a_72c_1 ag3a_72c_2 ag3a_72c_3 ag3a_72c_4 ///
						ag3a_72c_5 ag3a_72c_6 ag3a_72c_7 ag3a_72c_8 ag3a_72c_9 ag3a_72c_10 ///
						ag3a_72g_1 ag3a_72g_2 ag3a_72g_3 ag3a_72g_4 ///
						ag3a_72g_5 ag3a_72g_6 ag3a_72g_7 ag3a_72g_8 ag3a_72g_9 ag3a_72g_10 ///
						ag3a_72k_1 ag3a_72k_2 ag3a_72k_3 ag3a_72k_4 ///
						ag3a_72k_5 ag3a_72k_6 ag3a_72k_7 ag3a_72k_8 ag3a_72k_9 ag3a_72k_10)
	*** seems pretty comparable to wave4
	*** no missing values

* generate hired labor by gender and activity
	gen				plant_w = ag3a_74_1a
	gen				plant_m = ag3a_74_1b
	gen				other_w = ag3a_74_2a
	gen				other_m = ag3a_74_2b
	gen				hrvst_w = ag3a_74_3a
	gen				hrvst_m = ag3a_74_3b

* summarize hired individual labor to look for outliers
	sum				plant* other* hrvst* if ag3a_73 == 1

* replace outliers with missing
	replace			plant_w = . if plant_w > 90  // 0 changes
	replace			plant_m = . if plant_m > 90 // 3 changes
	replace			other_w = . if other_w > 181 // 1 changes
	replace			other_m = . if other_m > 181 // 3 changes
	replace			hrvst_w = . if hrvst_w > 90 // 2 change
	replace			hrvst_m = . if hrvst_m > 90 // 1 change

* impute missing values (need to do it for men and women's planting and harvesting)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	
	* impute women's planting labor
		mi register		imputed plant_w // identify kilo_fert as the variable being imputed
		sort			y5_hhid plot_id, stable // sort to ensure reproducability of results
		mi impute 		pmm plant_w i.uq_dist if ag3a_73 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
	* impute women's harvest labor
		mi register		imputed hrvst_w // identify kilo_fert as the variable being imputed
		sort			y5_hhid plot_id, stable // sort to ensure reproducability of results
		mi impute 		pmm hrvst_w i.uq_dist if ag3a_73 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute men's planting labor
		mi register		imputed plant_m // identify kilo_fert as the variable being imputed
		sort			y5_hhid plot_id, stable // sort to ensure reproducability of results
		mi impute 		pmm plant_m i.uq_dist if ag3a_73 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
	* impute men's harvest labor
		mi register		imputed hrvst_m // identify kilo_fert as the variable being imputed
		sort			y5_hhid plot_id, stable // sort to ensure reproducability of results
		mi impute 		pmm hrvst_m i.uq_dist if ag3a_73 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	mi 				unset
	
* how did the imputation go?
	replace			plant_w = plant_w_1_ // 1 change
	replace			hrvst_w = hrvst_w_2_ // 3 changes
	replace			plant_m = plant_m_3_ // 4 changes
	replace			hrvst_m = hrvst_m_4_ // 2 changes
	drop			mi_miss1- hrvst_m_4_
	
* generate total hired labor days
	egen			hired_labor_days = rsum(plant_w plant_m other_w ///
						other_m hrvst_w hrvst_m)

* generate total labor days (household plus hired)
	gen				labor_days = hh_labor_days + hired_labor_days
	

* **********************************************************************
**#5 - end matter, clean up to save
* **********************************************************************

* keep what we want, get rid of the rest
	keep			y5_hhid plotnum plot_id irrigated fert_any kilo_fert ///
						pesticide_any herbicide_any labor_days plotnum ///
						region district y5_rural clusterid strataid ///
						hhweight
	order			y5_hhid plot_id plotnum
	
* renaming and relabelling variables
	lab var			y5_hhid "Unique Household Identification NPS Y5"
	lab var			y5_rural "Cluster Type"
	lab var			hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var			plotnum "Old plot number"
	lab var			plot_id "Plot Identifier"
	lab var			clusterid "Unique Cluster Identification"
	lab var			strataid "Design Strata"
	lab var			region "Region Code"
	lab var			district "District Code"
	lab var			labor_days "Total Labor (days), Imputed"
	lab var			irrigated "Is plot irrigated?"
	lab var			pesticide_any "Was Pesticide Used?"
	lab var			herbicide_any "Was Herbicide Used?"	
	lab var			kilo_fert "Fertilizer Use (kg), Imputed"
	
* prepare for export
	isid			y5_hhid plot_id
	compress
	describe
	summarize 
	sort 			y5_hhid plot_id
	save 			"$export/2020_AGSEC3A.dta", replace

* close the log
	log	close

/* END */
