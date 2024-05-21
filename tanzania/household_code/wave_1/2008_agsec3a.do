* Project: WB Weather
* Created on: May 2020
* Created by: McG
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Tanzania household variables, wave 1 Ag sec3a
	* plot details, inputs, 2008 long rainy season
	* generates irrigation and pesticide dummies, fertilizer variables, and labor variables 

* assumes
	* access to all raw data
	* distinct.ado

* TO DO:
	* completed

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global root 	"$data/household_data/tanzania/wave_1/raw"
	global export 	"$data/household_data/tanzania/wave_1/refined"
	global logout 	"$data/household_data/tanzania/logs"

* open log 
	cap log close 
	log using "$logout/wv1_AGSEC3A", append


* **********************************************************************
* 1 - prepare TZA 2008 (Wave 1) - Agriculture Section 3A 
* **********************************************************************

* load data
	use 		"$root/SEC_3A", clear
	
* dropping duplicates
	duplicates 		drop
	*** 0 obs dropped
	
* check for uniquie identifiers
	drop			if plotnum == ""
	isid			hhid plotnum
	*** 0 obs dropped
	
* generate unique observation id
	gen				plot_id = hhid + " " + plotnum
	lab var			plot_id "Unique plot id"
	isid			plot_id	

* must merge in regional identifiers from 2008_HHSECA to impute
	merge			m:1 hhid using "$export/HH_SECA"
	tab				_merge
	*** 982 not matched, from using
	
	drop if			_merge == 2
	drop			_merge
	
* unique district id
	sort			region district
	egen			uq_dist = group(region district)
	distinct		uq_dist
	*** 125 once again, good deal

* record if field was cultivated during long rains
	gen 			status = s3aq3==1 if s3aq3!=.
	lab var			status "=1 if field cultivated during long rains"
	***4,408 observations were cultivated (86%)

* drop uncultivated plots
	drop			if status == 0	

	
* ***********************************************************************
* 2 - generate fertilizer variables
* ***********************************************************************
	
* constructing fertilizer variables
	rename			s3aq43 fert_any
	replace			fert_any = 2 if fert_any == .
	*** assuming missing values mean no fertilizer was used
	*** 227 changes made
	
	rename			s3aq45 kilo_fert
	lab var			kilo_fert "fertilizer used (kg)"
	
	replace			kilo_fert = 0 if kilo_fert == .

* summarize fertilizer
	sum				kilo_fert, detail
	*** median 0, mean 52, max 150,000
	*** these numbers are way crazy compared to other waves

* replace any +3 s.d. away from median as missing
	replace			kilo_fert = . if kilo_fert > 5000
	replace			kilo_fert = . if plot_id == "13030170030453 M2"
	replace			kilo_fert = . if plot_id == "14030160020364 M1"
	sum				kilo_fert, detail
	replace			kilo_fert = . if kilo_fert > `r(p50)'+(3*`r(sd)')
	sum				kilo_fert, detail
	*** 55 changes made, max is now 400	
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed kilo_fert // identify kilo_fert as the variable being imputed
	sort			hhid plotnum, stable // sort to ensure reproducability of results
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
	*** imputed 57 values out of 4,408 total observations
	
	
* ***********************************************************************
* 3 - generate irrigation, pesticide, and herbicide dummies
* ***********************************************************************
	
* renaming irrigation
	rename			s3aq15 irrigated 
	replace			irrigated = 2 if irrigated == .
	
* constructing pesticide/herbicide variables
	gen				pesticide_any = 2
	gen				herbicide_any = 2
	replace			pesticide_any = 1 if s3aq50 == 1 | s3aq50 == 4
	replace			herbicide_any = 1 if s3aq50 == 2 | s3aq50 == 3
	lab define		pesticide_any 1 "Yes" 2 "No"
	lab values		pesticide_any pesticide_any
	lab values		herbicide_any pesticide_any
	
	
* ***********************************************************************
* 4 - generate labor variables
* ***********************************************************************

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* in this survey we can't tell gender or age of household members
* since we can't match household members we deal with each activity seperately

*change missing to zero and then back again
	mvdecode		s3aq61_1 s3aq61_2 s3aq61_3 s3aq61_4 s3aq61_5 s3aq61_6 ///
						s3aq61_7 s3aq61_8 s3aq61_9 s3aq61_10 s3aq61_11 ///
						s3aq61_12 s3aq61_13 s3aq61_14 s3aq61_15 s3aq61_16 ///
						s3aq61_17  s3aq61_18 s3aq61_19 s3aq61_20 s3aq61_21 ///
						s3aq61_22 s3aq61_23 s3aq61_24 s3aq61_25 s3aq61_26 ///
						s3aq61_27 s3aq61_28 s3aq61_29 s3aq61_30 s3aq61_31 ///
						s3aq61_32 s3aq61_33 s3aq61_34 s3aq61_35 s3aq61_36, mv(0)

	mvencode		s3aq61_1 s3aq61_2 s3aq61_3 s3aq61_4 s3aq61_5 s3aq61_6 ///
						s3aq61_7 s3aq61_8 s3aq61_9 s3aq61_10 s3aq61_11 ///
						s3aq61_12 s3aq61_13 s3aq61_14 s3aq61_15 s3aq61_16 ///
						s3aq61_17  s3aq61_18 s3aq61_19 s3aq61_20 s3aq61_21 ///
						s3aq61_22 s3aq61_23 s3aq61_24 s3aq61_25 s3aq61_26 ///
						s3aq61_27 s3aq61_28 s3aq61_29 s3aq61_30 s3aq61_31 ///
						s3aq61_32 s3aq61_33 s3aq61_34 s3aq61_35 s3aq61_36, mv(0)
	*** this allows us to impute only the variables we change to missing				
						
* summarize household individual labor for land prep to look for outliers
	sum				s3aq61_1 s3aq61_2 s3aq61_3 s3aq61_4 s3aq61_5 s3aq61_6 ///
						s3aq61_7 s3aq61_8 s3aq61_9 s3aq61_10 s3aq61_11 ///
						s3aq61_12
	replace			s3aq61_1 = . if s3aq61_1 > 90 // 97 changes
	replace			s3aq61_2 = . if s3aq61_2 > 90 // 115 changes
	replace			s3aq61_3 = . if s3aq61_3 > 90 // 50 changes
	replace			s3aq61_4 = . if s3aq61_4 > 90 // 19 changes
	replace			s3aq61_5 = . if s3aq61_5 > 90 // 16 changes
	replace			s3aq61_6 = . if s3aq61_6 > 90 // 8 changes
	replace			s3aq61_8 = . if s3aq61_8 > 90 // 1 change
	replace			s3aq61_11 = . if s3aq61_11 > 90 // 1 change
	replace			s3aq61_12 = . if s3aq61_12 > 90 // 1 change
	** 308 changes made

* summarize household individual labor for weeding to look for outliers
	sum				 s3aq61_13 s3aq61_14 s3aq61_15 s3aq61_16 s3aq61_17 ///
						s3aq61_18 s3aq61_19 s3aq61_20 s3aq61_21 s3aq61_22 ///
						s3aq61_23 s3aq61_24
	replace			s3aq61_13 = . if s3aq61_13 > 90 // 100 changes
	replace			s3aq61_14 = . if s3aq61_14 > 90 // 84 changes
	replace			s3aq61_15 = . if s3aq61_15 > 90 // 43 changes
	replace			s3aq61_16 = . if s3aq61_16 > 90 // 31 changes
	replace			s3aq61_17 = . if s3aq61_17 > 90 // 19 changes
	replace			s3aq61_18 = . if s3aq61_18 > 90 // 4 changes
	*** 281 changes made
	
* summarize household individual labor for harvest to look for outliers
	sum				s3aq61_25 s3aq61_26 s3aq61_27 s3aq61_28 s3aq61_29 s3aq61_30 ///
						s3aq61_31 s3aq61_32 s3aq61_33 s3aq61_34 s3aq61_35 ///
						s3aq61_36
	replace			s3aq61_25 = . if s3aq61_25 > 90 // 126 changes
	replace			s3aq61_26 = . if s3aq61_26 > 90 // 111 changes
	replace			s3aq61_27 = . if s3aq61_27 > 90 // 62 changes
	replace			s3aq61_28 = . if s3aq61_28 > 90 // 34 changes
	replace			s3aq61_29 = . if s3aq61_29 > 90 // 22 changes
	replace			s3aq61_30 = . if s3aq61_30 > 90 // 7 changes
	*** 362 changes made

* impute missing values (lots of imputations)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	
	* impute s3aq61_1
		mi register		imputed s3aq61_1 // identify s3aq61_1 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_1 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_2
		mi register		imputed s3aq61_2 // identify s3aq61_2 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_2 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	* impute s3aq61_3
		mi register		imputed s3aq61_3 // identify s3aq61_3 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_3 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_4
		mi register		imputed s3aq61_4 // identify s3aq61_4 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_4 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_5
		mi register		imputed s3aq61_5 // identify s3aq61_5 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_5 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	* impute s3aq61_6
		mi register		imputed s3aq61_6 // identify s3aq61_6 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_6 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_8
		mi register		imputed s3aq61_8 // identify s3aq61_8 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_8 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_11
		mi register		imputed s3aq61_11 // identify s3aq61_11 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_11 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_12
		mi register		imputed s3aq61_12 // identify s3aq61_12 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_12 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	* impute s3aq61_13
		mi register		imputed s3aq61_13 // identify s3aq61_13 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_13 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_14
		mi register		imputed s3aq61_14 // identify s3aq61_14 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_14 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_15
		mi register		imputed s3aq61_15 // identify s3aq61_15 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_15 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	* impute s3aq61_16
		mi register		imputed s3aq61_16 // identify s3aq61_16 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_16 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_17
		mi register		imputed s3aq61_17 // identify s3aq61_17 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_17 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_18
		mi register		imputed s3aq61_18 // identify s3aq61_18 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_18 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_25
		mi register		imputed s3aq61_25 // identify s3aq61_25 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_25 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	* impute s3aq61_26
		mi register		imputed s3aq61_26 // identify s3aq61_26 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_26 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_27
		mi register		imputed s3aq61_27 // identify s3aq61_27 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_27 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_28
		mi register		imputed s3aq61_28 // identify s3aq61_28 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_28 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	* impute s3aq61_29
		mi register		imputed s3aq61_29 // identify s3aq61_29 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_29 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute s3aq61_30
		mi register		imputed s3aq61_30 // identify s3aq61_30 as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm s3aq61_30 i.uq_dist, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	mi 				unset

* replace values with imputed values
	replace			s3aq61_1 = s3aq61_1_1_
	replace			s3aq61_2 = s3aq61_2_2_
	replace			s3aq61_3 = s3aq61_3_3_
	replace			s3aq61_4 = s3aq61_4_4_
	replace			s3aq61_5 = s3aq61_5_5_
	replace			s3aq61_6 = s3aq61_6_6_
	replace			s3aq61_8 = s3aq61_8_7_
	replace			s3aq61_11 = s3aq61_11_8_
	replace			s3aq61_12 = s3aq61_12_9_
	replace			s3aq61_13 = s3aq61_13_10_
	replace			s3aq61_14 = s3aq61_14_11_
	replace			s3aq61_15 = s3aq61_15_12_
	replace			s3aq61_16 = s3aq61_16_13_
	replace			s3aq61_17 = s3aq61_17_14_
	replace			s3aq61_18 = s3aq61_18_15_
	replace			s3aq61_25 = s3aq61_25_16_
	replace			s3aq61_26 = s3aq61_26_17_
	replace			s3aq61_27 = s3aq61_27_18_
	replace			s3aq61_28 = s3aq61_28_19_
	replace			s3aq61_29 = s3aq61_29_20_
	replace			s3aq61_30 = s3aq61_30_21_
	drop			mi_miss1- s3aq61_30_21_
	
* compiling labor inputs
	egen			hh_labor_days = rsum(s3aq61_1 s3aq61_2 s3aq61_3 s3aq61_4 ///
						s3aq61_5 s3aq61_6 s3aq61_7 s3aq61_8 s3aq61_9 s3aq61_10 ///
						s3aq61_11 s3aq61_12 s3aq61_13 s3aq61_14 s3aq61_15 ///
						s3aq61_16 s3aq61_17  s3aq61_18 s3aq61_19 s3aq61_20 ///
						s3aq61_21 s3aq61_22 s3aq61_23 s3aq61_24 s3aq61_25 ///
						s3aq61_26 s3aq61_27 s3aq61_28 s3aq61_29 s3aq61_30 ///
						s3aq61_31 s3aq61_32 s3aq61_33 s3aq61_34 s3aq61_35 ///
						s3aq61_36)

* generate hired labor by gender and activity
	gen				plant_w = s3aq63_2
	gen				plant_m = s3aq63_1
	gen				other_w = s3aq63_5
	gen				other_m = s3aq63_4
	gen				hrvst_w = s3aq63_8
	gen				hrvst_m = s3aq63_7

* summarize hired individual labor to look for outliers
	sum				plant* other* hrvst* if s3aq62 == 1

* replace outliers with missing
	replace			plant_w = . if plant_w > 90
	replace			plant_m = . if plant_m > 90
	replace			other_w = . if other_w > 181
	replace			other_m = . if other_m > 181 
	replace			hrvst_w = . if hrvst_w > 90 // 1 change
	replace			hrvst_m = . if hrvst_m > 90 // 1 change
	*** only 2 values replaced

* impute missing values (only need to do it for women's planting and harvesting)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	
	* impute women's harvest labor
		mi register		imputed hrvst_w // identify kilo_fert as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm hrvst_w i.uq_dist if s3aq62 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap

	* impute men's harvest labor
		mi register		imputed hrvst_m // identify kilo_fert as the variable being imputed
		sort			hhid plotnum, stable // sort to ensure reproducability of results
		mi impute 		pmm hrvst_m i.uq_dist if s3aq62 == 1, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	mi 				unset
	
* how did the imputation go?
	replace			hrvst_w = hrvst_w_1_ // 4 changes
	replace			hrvst_m = hrvst_m_2_ // 3 changes
	drop			mi_miss1- hrvst_m_2_
	*** smaller version of the same issue in other waves

* generate total hired labor days
	egen			hired_labor_days = rsum(plant_w plant_m other_w ///
						other_m hrvst_w hrvst_m)

* generate total labor days (household plus hired)
	gen				labor_days = hh_labor_days + hired_labor_days	
	
	
* **********************************************************************
* 5 - end matter, clean up to save
* **********************************************************************

* keep what we want, get rid of the rest
	keep			hhid plotnum plot_id irrigated fert_any kilo_fert ///
						pesticide_any herbicide_any labor_days plotnum ///
						region district ward ea y1_rural clusterid strataid ///
						hhweight
	order			hhid plotnum plot_id
	
* renaming and relabelling variables
	lab var			hhid "Unique Household Identification NPS Y1"
	lab var			y1_rural "Cluster Type"
	lab var			hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var			plotnum "Plot ID Within household"
	lab var			plot_id "Unique Plot Identifier"
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
	isid			hhid plotnum
	compress
	describe
	summarize 
	sort 			plot_id
	save 			"$export/AG_SEC3A.dta", replace

* close the log
	log	close

/* END */
