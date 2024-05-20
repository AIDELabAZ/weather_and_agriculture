* Project: WB Weather
* Created on: July 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 2 PH sec10
	* seems to roughly correspong to Malawi ag-modD and ag-modK
	* contains post harvest labor information on a crop level
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
	log using "`logout'/wv2_PHSEC10", append


* **********************************************************************
* 1 - preparing ESS 2013/14 (Wave 2) - Post Harvest Section 10
* **********************************************************************

* load data
	use 		"`root'/sect10_ph_w2.dta", clear
	
* dropping duplicates
	duplicates drop
	
* unique identifier can only be generated including crop code as some fields are mixed
	describe
	sort 		holder_id parcel_id field_id crop_code
	isid 		holder_id parcel_id field_id crop_code
	
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

* drop observations with a missing crop_id
	summarize 	if missing(parcel_id,field_id,crop_code)
	drop 		if missing(parcel_id,field_id,crop_code)
	*** no obs dropped
	
	isid 		holder_id parcel_id field_id crop_code

* creating district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 74 distinct districts
	*** same as pp sect3 and sect 4, good	

	
* **********************************************************************
* 2 - collecting labor variables
* **********************************************************************	
	
* following same procedure as pp_w3 for continuity

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* in this survey we can't tell gender or age of household members
* since we can't match household members we deal with each activity seperately

* totaling hired labor
* there is an assumption here
	/* 	survey instrument splits question into # of men, total # of days
		where ph_s10q01_a is # of men and ph_s10q01_b is total # of days (men)
		there is also women (d & e)
		the assumption is that total # of days is the total
		and therefore does not require being multiplied by # of men
		there are weird obs that make this assumption shakey
		where # of men = 3 and total # of days = 1 for example
		the same dilemna/assumption applies to free labor (ph_s10q03_*)
		this can be revised if we think this assumption is shakey */
	replace		ph_s10q01_b = 0 if ph_s10q01_b == . 
	replace		ph_s10q01_e = 0 if ph_s10q01_e == .
	rename	 	ph_s10q01_b laborhi_m
	rename	 	ph_s10q01_e laborhi_f

* totaling free labor
	replace 	ph_s10q03_b = 0 if ph_s10q03_b == .
	replace 	ph_s10q03_d = 0 if ph_s10q03_d == .
	rename 		ph_s10q03_b laborfr_m
	rename 		ph_s10q03_d laborfr_f

* totaling household labor
* replace weeks worked equal to zero if missing
	replace		ph_s10q02_b = 0 if ph_s10q02_b == . 
	replace		ph_s10q02_f = 0 if ph_s10q02_f == . 
	replace		ph_s10q02_j = 0 if ph_s10q02_j == . 
	replace		ph_s10q02_n = 0 if ph_s10q02_n == . 
	replace		ph_s10q02_r = 0 if ph_s10q02_r == . 
	replace		ph_s10q02_v = 0 if ph_s10q02_v == . 
	replace		ph_s10q02_z = 0 if ph_s10q02_z == . 
	replace		ph_s10q02_na = 0 if ph_s10q02_na == . 	
	
* find average # of days worked by worker reported (most obs)
	sum 		ph_s10q02_c ph_s10q02_g ph_s10q02_k ph_s10q02_o ph_s10q02_s ///
					ph_s10q02_w ph_s10q02_ka ph_s10q02_oa
	
* replace days per week worked equal to average if missing and weeks were worked 
	replace		ph_s10q02_c = 2.46 if ph_s10q02_c == . &  ph_s10q02_b != 0 
	replace		ph_s10q02_g = 2.35 if ph_s10q02_g == . &  ph_s10q02_f != 0  
	replace		ph_s10q02_k = 2.34 if ph_s10q02_k == . &  ph_s10q02_j != 0  
	replace		ph_s10q02_o = 2.33 if ph_s10q02_o == . &  ph_s10q02_n != 0 
	replace		ph_s10q02_s = 2.19 if ph_s10q02_s == . &  ph_s10q02_r != 0 
	replace		ph_s10q02_w = 2.5 if ph_s10q02_w == . &  ph_s10q02_v != 0  
	replace		ph_s10q02_ka = 4.5 if ph_s10q02_ka == . &  ph_s10q02_z != 0  
	replace		ph_s10q02_oa = 2.5 if ph_s10q02_oa == . &  ph_s10q02_na != 0 
	
* replace days per week worked equal to 0 if missing and no weeks were worked
	replace		ph_s10q02_c = 0 if ph_s10q02_c == . &  ph_s10q02_b == 0 
	replace		ph_s10q02_g = 0 if ph_s10q02_g == . &  ph_s10q02_f == 0  
	replace		ph_s10q02_k = 0 if ph_s10q02_k == . &  ph_s10q02_j == 0  
	replace		ph_s10q02_o = 0 if ph_s10q02_o == . &  ph_s10q02_n == 0 
	replace		ph_s10q02_s = 0 if ph_s10q02_s == . &  ph_s10q02_r == 0 
	replace		ph_s10q02_w = 0 if ph_s10q02_w == . &  ph_s10q02_v == 0  
	replace		ph_s10q02_ka = 0 if ph_s10q02_ka == . &  ph_s10q02_z == 0  
	replace		ph_s10q02_oa = 0 if ph_s10q02_oa == . &  ph_s10q02_na == 0 
	
	summarize	ph_s10q02_b ph_s10q02_c ph_s10q02_f ph_s10q02_g ph_s10q02_j ///
					ph_s10q02_k ph_s10q02_n ph_s10q02_o ph_s10q02_r ph_s10q02_s ///
					ph_s10q02_v ph_s10q02_w ph_s10q02_z ph_s10q02_ka ///
					ph_s10q02_na ph_s10q02_oa
	*** it looks like the above approach works
	
	generate	laborhh_1 = ph_s10q02_b * ph_s10q02_c
	generate	laborhh_2 = ph_s10q02_f * ph_s10q02_g
	generate	laborhh_3 = ph_s10q02_j * ph_s10q02_k
	generate	laborhh_4 = ph_s10q02_n * ph_s10q02_o
	generate	laborhh_5 = ph_s10q02_r * ph_s10q02_s
	generate	laborhh_6 = ph_s10q02_v * ph_s10q02_w
	generate	laborhh_7 = ph_s10q02_z * ph_s10q02_ka
	generate	laborhh_8 = ph_s10q02_na * ph_s10q02_oa
	
	summarize	labor*	
	*** maxes shouldn't be greater than 91
	*** laborhi_m, laborfr_m, laborhh_1, laborhh_2, laborhh_3, laborhh_4 all have maxes > 91
	
	summarize 	laborhi_m laborfr_m laborhh_1 laborhh_2 laborhh_3 laborhh_4, detail
	*** only one large outlier for laborhi_m, laborfr_m
	*** many outliers for laborhh_1 - laborhi_4
	
* dropping outliers
	replace 	laborhi_m = 91 if laborhi_m > 91 // 1 change
	replace 	laborfr_f = 91 if laborfr_m > 91 // 1 change
	replace 	laborhh_1 = . if laborhh_1 > 91 // 74 drops
	replace 	laborhh_2 = . if laborhh_2 > 91 // 36 drops
 	replace 	laborhh_3 = . if laborhh_3 > 91 // 6 drop
	replace 	laborhh_4 = . if laborhh_4 > 91 // 4 drop
	
* impute missing values (only need to do four variables)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	
	* impute laborhh_1
		mi register		imputed laborhh_1 // identify laborhh_1 as the variable being imputed
		sort			holder_id parcel field crop_code, stable // sort to ensure reproducability of results
		mi impute 		pmm laborhh_1 i.district_id, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
	* impute laborhh_2
		mi register		imputed laborhh_2 // identify laborhh_2 as the variable being imputed
		sort			holder_id parcel field crop_code, stable // sort to ensure reproducability of results
		mi impute 		pmm laborhh_2 i.district_id, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
	* impute laborhh_3
		mi register		imputed laborhh_3 // identify laborhh_3 as the variable being imputed
		sort			holder_id parcel field crop_code, stable // sort to ensure reproducability of results
		mi impute 		pmm laborhh_3 i.district_id, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
							
	* impute laborhh_4
		mi register		imputed laborhh_4 // identify laborhh_4 as the variable being imputed
		sort			holder_id parcel field crop_code, stable // sort to ensure reproducability of results
		mi impute 		pmm laborhh_4 i.district_id, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
	mi 				unset	
	
* replace values with imputed values
	replace			laborhh_1 = laborhh_1_1_
	replace			laborhh_2 = laborhh_2_2_
	replace			laborhh_3 = laborhh_3_3_
	replace			laborhh_4 = laborhh_4_4_
	drop			laborhh_1_1_- laborhh_4_4_
	
	summarize		labor*
	
* generate aggregate hh and hired labor variables	
	generate 	laborday_hh = laborhh_1 + laborhh_2 + laborhh_3 + laborhh_4 + ///
					laborhh_5 + laborhh_6 + laborhh_7 + laborhh_8
	generate 	laborday_hired = laborhi_m + laborhi_f
	gen			laborday_free = laborfr_m + laborfr_f
	
* check to make sure things look all right
	sum			laborday*
	
* combine hh and hired labor into one variable 
	generate 	labordays_harv = laborday_hh + laborday_hired + laborday_free
	drop 		laborday_hh laborday_hired laborday_free laborhh_1- laborhh_8 ///
					laborhi_m laborhi_f laborfr_m laborfr_f
	label var 	labordays_harv "Total Days of Harvest Labor"	
	
	
* ***********************************************************************
* 3 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid
	rename 		household_id2 hhid2
	rename 		saq01 region
	rename 		saq02 zone
	rename 		saq03 woreda
	rename		saq05 ea

*	Restrict to variables of interest
	keep  		holder_id- ph_s10q00c crop_id labordays_harv
	order 		holder_id- crop_code

* final preparations to export
	isid 		crop_id
	compress
	describe
	summarize
	sort 		holder_id ea_id parcel field crop_code
	save 		"`export'/PH_SEC10.dta", replace

* close the log
	log	close