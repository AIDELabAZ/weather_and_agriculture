* Project: WB Weather
* Created on: March 2024
* Created by: reece
* Edited on: March 28 
* Edited by: reece
* Stata v.18

* does
	* cleans Tanzania household variables, wave 6 (NPSY5-SDD) Ag sec3a
	* plot details, inputs, 2018 long rainy season
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
	global root 	"$data/household_data/tanzania/wave_6/raw"
	global export 	"$data/household_data/tanzania/wave_6/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv6_AGSEC3A", append
	
* ***********************************************************************
**#1 - prepare TZA 2019 (Wave 6) - Agriculture Section 3A 
* ***********************************************************************

* load data
	use 		"$root/ag_sec_3a", clear

* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped

* check for unique identifiers
	drop		if missing(plotnum)
	isid		sdd_hhid plotnum
	*** 0 obs dropped
	
* generating unique observation id for each ob
	tostring	plotnum, gen(plotnum_str)
	generate 	plot_id = sdd_hhid + " " + plotnum_str
	lab var		plot_id "Unique plot identifier"
	isid 		plot_id
	*** type mismatch- need to convert plotnum to string variable
	
* must merge in regional identifiers from 2008_HHSECA to impute
	merge			m:1 sdd_hhid using "$export/HH_SECA"
	tab				_merge
	*** 97 not matched, from using

	drop if			_merge == 2
	drop			_merge
	
* unique district id
	sort			region district
	egen			uq_dist = group(region district)
	distinct		uq_dist
	*** 127 distinct districts

* record if field was cultivated during long rains
	gen 			status = ag3a_03==1 if ag3a_03!=.
	lab var			status "=1 if field cultivated during long rains"
	tab 			status
	*** 1031 observations were cultivated (51%)

* drop uncultivated plots
	drop			if status == 0	
	*** 999 obs deleted
	
	
* ***********************************************************************
**#2 - generate fertilizer variables
* ***********************************************************************

* constructing fertilizer variables
	rename			ag3a_47 fert_any
	replace			fert_any = 2 if fert_any == .
	*** assuming missing values mean no fertilizer was used
	*** 275 changes made
	
	replace			ag3a_49 = 0 if ag3a_49 == .
	replace			ag3a_56 = 0 if ag3a_56 == .
	gen				kilo_fert = ag3a_49 + ag3a_56

* summarize fertilizer
	sum				kilo_fert, detail
	*** median 0, mean 8.06, max 1000, s.d. 46.07
	*** the top two obs are 600 kg and 500 kg
	*** the next highest ob is 400

* replace any +3 s.d. away from median as missing
	replace			kilo_fert = . if kilo_fert > 5000
	sum				kilo_fert, detail
	replace			kilo_fert = . if kilo_fert > `r(p50)'+(3*`r(sd)')
	sum				kilo_fert, detail
	*** replaced 22 values, max is now 125

* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed kilo_fert // identify kilo_fert as the variable being imputed
	sort			sdd_hhid plotnum, stable // sort to ensure reproducability of results
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
	*** imputed 22 values out of 1306 total observations	

	
* ***********************************************************************
**#3 - generate irrigation, pesticide, and herbicide dummies
* ***********************************************************************
	
* renaming irrigation
	rename			ag3a_18 irrigated 
	replace			irrigated = 2 if irrigated == .
	*** 275 changes made
	
* constructing pesticide/herbicide variables
	gen				pesticide_any = 2
	gen				herbicide_any = 2
	replace			pesticide_any = 1 if ag3a_65a == 1
	replace			herbicide_any = 1 if ag3a_60 == 1
	lab define		pesticide_any 1 "Yes" 2 "No"
	lab values		pesticide_any pesticide_any
	lab values		herbicide_any pesticide_any
	
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

* merge in labor days data 
	merge			1:1 sdd_hhid plotnum using "$root/AG_SEC_3A_time"
	tab				_merge
	*** 999 not matched, from using

	drop if			_merge == 2
	drop			_merge

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
						
* summarize household individual labor for land prep to look for outliers
	sum				ag3a_72c_1 ag3a_72c_2 ag3a_72c_3 ag3a_72c_4 ///
						ag3a_72c_5 ag3a_72c_6 ag3a_72c_7 ag3a_72c_8 ag3a_72c_9 ag3a_72c_10
	*** no obs > 70

* summarize household individual labor for weeding/ridging to look for outliers
	sum				ag3a_72g_1 ag3a_72g_2 ag3a_72g_3 ag3a_72g_4 ///
						ag3a_72g_5 ag3a_72g_6 ag3a_72g_7 ag3a_72g_8 ag3a_72g_9 ag3a_72g_10 
	*** no obs > 60
	
* summarize household individual labor for harvest to look for outliers
	sum				ag3a_72k_1 ag3a_72k_2 ag3a_72k_3 ag3a_72k_4 ///
						ag3a_72k_5 ag3a_72k_6 ag3a_72k_7 ag3a_72k_8 ag3a_72k_9 ag3a_72k_10
	*** no obs > 60

* no imputation necessary as no values are dropped

* compiling labor inputs
	egen			hh_labor_days = rsum(ag3a_72c_1 ag3a_72c_2 ag3a_72c_3 ag3a_72c_4 ///
						ag3a_72c_5 ag3a_72c_6 ag3a_72c_7 ag3a_72c_8 ag3a_72c_9 ag3a_72c_10 ag3a_72g_1 ag3a_72g_2 ag3a_72g_3 ag3a_72g_4 ///
						ag3a_72g_5 ag3a_72g_6 ag3a_72g_7 ag3a_72g_8 ag3a_72g_9 ag3a_72g_10 ag3a_72k_1 ag3a_72k_2 ag3a_72k_3 ag3a_72k_4 ///
						ag3a_72k_5 ag3a_72k_6 ag3a_72k_7 ag3a_72k_8 ag3a_72k_9 ag3a_72k_10)

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
	replace			plant_w = . if plant_w > 90  // 1 change
	replace			plant_m = . if plant_m > 90 // 4 changes
	replace			other_w = . if other_w > 181 // 1 change
	replace			other_m = . if other_m > 181 // 1 change
	replace			hrvst_w = . if hrvst_w > 90 // 0 changes
	replace			hrvst_m = . if hrvst_m > 90 // 2 changes


* impute missing values (need to do it for men and women's planting and harvesting)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	
	* impute women's planting labor
		mi register		imputed plant_w // identify kilo_fert as the variable being imputed
		sort			sdd_hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm plant_w i.uq_dist if ag3a_73 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
	* impute women's harvest labor
		mi register		imputed hrvst_w // identify kilo_fert as the variable being imputed
		sort			sdd_hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm hrvst_w i.uq_dist if ag3a_73 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute men's planting labor
		mi register		imputed plant_m // identify kilo_fert as the variable being imputed
		sort			sdd_hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm plant_m i.uq_dist if ag3a_73 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
	* impute men's harvest labor
		mi register		imputed hrvst_m // identify kilo_fert as the variable being imputed
		sort			sdd_hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm hrvst_m i.uq_dist if ag3a_73 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	mi 				unset
	
* how did the imputation go?
	replace			plant_w = plant_w_1_ // 1 changes
	replace			hrvst_w = hrvst_w_1_ // 0 changes
	replace			plant_w = plant_w_2_ // 1 changes
	replace			hrvst_w = hrvst_w_2_ // 0 changes
	replace			plant_m = plant_m_3_ // 0 changes
	replace			hrvst_m = hrvst_m_3_ // 2 change
	drop			mi_miss1- hrvst_m_3_


* generate total hired labor days
	egen			hired_labor_days = rsum(plant_w plant_m other_w ///
						other_m hrvst_w hrvst_m)

* generate total labor days (household plus hired)
	gen				labor_days = hh_labor_days + hired_labor_days
	

* **********************************************************************
**#5 - end matter, clean up to save
* **********************************************************************

* keep what we want, get rid of the rest
	keep			sdd_hhid plotnum plot_id irrigated fert_any kilo_fert ///
						pesticide_any herbicide_any labor_days plotnum ///
						region district ward ea sdd_rural clusterid strataid ///
						hhweight
	order			sdd_hhid plotnum plot_id
	
* renaming and relabelling variables
	lab var			sdd_hhid "Unique Household Identification NPS SDD"
	lab var			sdd_rural "Cluster Type"
	lab var			hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var			plotnum "Plot ID Within household"
	lab var			plot_id "Unquie Plot Identifier"
	lab var			clusterid "Unique Cluster Identification"
	lab var			strataid "Design Strata"
	lab var			region "Region Code"
	lab var			district "District Code"
	lab var			ward "Ward Code"
	lab var			ea "Village / Enumeration Area Code"
	lab var			labor_days "Total Labor (days), Imputed"
	lab var			irrigated "Is plot irrigated?"
	lab var			pesticide_any "Was Pesticide Used?"
	lab var			herbicide_any "Was Herbicide Used?"	
	lab var			kilo_fert "Fertilizer Use (kg), Imputed"
	
* prepare for export
	isid			sdd_hhid plot_id
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/2019_AGSEC3A.dta", replace

* close the log
	log	close

/* END */
