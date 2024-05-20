* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 3 PH sec9
	* seems to roughly correspong to Malawi ag-modD and ag-modK
	* contains labor information on a crop level
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
	loc root = "$data/household_data/ethiopia/wave_3/raw"
	loc export = "$data/household_data/ethiopia/wave_3/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv3_PHSEC10", append


* **********************************************************************
* 1 - preparing ESS (Wave 3) - Post Harvest Section 10
* **********************************************************************

* load data
	use 		"`root'/sect10_ph_w3.dta", clear

* dropping duplicates
	duplicates drop
	
* one ob missing local ids, even though holder_id has 4 other obs and crop_code is present	
	replace 	household_id = "07070100903022" ///
					if holder_id == "0707010090302201" & household_id == ""
	replace 	household_id2 = "070701088800903022" ///
					if holder_id == "0707010090302201" & household_id2 == ""
	replace 	rural = 1 if holder_id == "0707010090302201" & rural == .
	replace 	pw_w3 = 3452.8 if holder_id == "0707010090302201" & pw_w3 == .
	replace 	ea_id = "07070100903" ///
					if holder_id == "0707010090302201" & ea_id == ""
	replace 	saq01 = 7 if holder_id == "0707010090302201" & saq01 == .
	replace 	saq02 = 7 if holder_id == "0707010090302201" & saq02 == .
	replace 	saq03 = 1 if holder_id == "0707010090302201" & saq03 == .
	replace 	saq04 = 9 if holder_id == "0707010090302201" & saq04 == .
	replace 	saq05 = 3 if holder_id == "0707010090302201" & saq05 == .
	replace 	saq06 = 22 if holder_id == "0707010090302201" & saq06 == .
	replace 	ph_saq07 = 1 if holder_id == "0707010090302201" & ph_saq07 == .

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
	*** 69 distinct districts
	*** same as pp sect3, and ph sect9, good

	
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
	
* find average # of days worked by worker reported (most obs)
	sum 		ph_s10q02_c ph_s10q02_g ph_s10q02_k ph_s10q02_o
	*** ph_s10q02_c - 2.3, ph_s10q02_g - 2.22
	*** ph_s10q02_k - 2.18, ph_s10q02_o - 2.16
	
* replace days per week worked equal to average if missing and weeks were worked 
	replace		ph_s10q02_c = 2.3 if ph_s10q02_c == . &  ph_s10q02_b != 0 
	replace		ph_s10q02_g = 2.22 if ph_s10q02_g == . &  ph_s10q02_f != 0  
	replace		ph_s10q02_k = 2.18 if ph_s10q02_k == . &  ph_s10q02_j != 0  
	replace		ph_s10q02_o = 2.16 if ph_s10q02_o == . &  ph_s10q02_n != 0 
	
* replace days per week worked equal to 0 if missing and no weeks were worked
	replace		ph_s10q02_c = 0 if ph_s10q02_c == . &  ph_s10q02_b == 0 
	replace		ph_s10q02_g = 0 if ph_s10q02_g == . &  ph_s10q02_f == 0  
	replace		ph_s10q02_k = 0 if ph_s10q02_k == . &  ph_s10q02_j == 0  
	replace		ph_s10q02_o = 0 if ph_s10q02_o == . &  ph_s10q02_n == 0 
	
	summarize	ph_s10q02_b ph_s10q02_c ph_s10q02_f ph_s10q02_g ph_s10q02_j ///
					ph_s10q02_k ph_s10q02_n ph_s10q02_o
	*** it looks like the above approach works
	
	generate	laborhh_1 = ph_s10q02_b * ph_s10q02_c
	generate	laborhh_2 = ph_s10q02_f * ph_s10q02_g
	generate	laborhh_3 = ph_s10q02_j * ph_s10q02_k
	generate	laborhh_4 = ph_s10q02_n * ph_s10q02_o
	
	summarize	labor*	
	*** maxes shouldn't be greater than 91
	*** laborhi_m, laborfr_f, laborhh_1, laborhh_2, laborhh_3 all have maxes > 91
	
	summarize 	laborhi_m laborfr_f laborhh_1 laborhh_2 laborhh_3, detail
	*** only one large outlier for laborhi_m, laborfr_f, & laborhh_3
	*** many outliers for laborhh_1, fewer for laborhh_2
	
* dropping outliers
	replace 	laborhi_m = . if laborhi_m > 91 // 1 drop
	replace 	laborfr_f = . if laborfr_f > 91 // 1 drop
	replace 	laborhh_1 = . if laborhh_1 > 91 // 104 drops
	replace 	laborhh_2 = . if laborhh_2 > 91 // 26 drops
 	replace 	laborhh_3 = . if laborhh_3 > 91 // 1 drop
	
* impute missing values (only need to do four variables)
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	
	* impute laborhi_m 
		mi register		imputed laborhi_m // identify laborhi_m as the variable being imputed
		sort			holder_id parcel field crop_code, stable // sort to ensure reproducability of results
		mi impute 		pmm laborhi_m i.district_id, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
	* impute laborfr_f
		mi register		imputed laborfr_f // identify laborfr_f as the variable being imputed
		sort			holder_id parcel field crop_code, stable // sort to ensure reproducability of results
		mi impute 		pmm laborfr_f i.district_id, add(1) rseed(245780) ///
							noisily dots force knn(5) bootstrap
	
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
	
	mi 				unset	
	
* replace values with imputed values
	replace			laborhi_m = laborhi_m_1_
	replace			laborfr_f = laborfr_f_2_
	replace			laborhh_1 = laborhh_1_3_
	replace			laborhh_2 = laborhh_2_4_
	replace			laborhh_3 = laborhh_3_5_
	drop			laborhi_m_1_- laborhh_3_5_
	
* generate aggregate hh and hired labor variables	
	generate 	laborday_hh = laborhh_1 + laborhh_2 + laborhh_3 + laborhh_4
	generate 	laborday_hired = laborhi_m + laborhi_f
	gen			laborday_free = laborfr_m + laborfr_f
	
* check to make sure things look all right
	sum			laborday*
	
* combine hh and hired labor into one variable 
	generate 	labordays_harv = laborday_hh + laborday_hired + laborday_free
	drop 		laborday_hh laborday_hired laborday_free laborhh_1- laborhh_4 ///
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
	keep  		holder_id- crop_code crop_id labordays_harv
	order 		holder_id- crop_code

* final preparations to export
	isid 		crop_id
	compress
	describe
	summarize
	*** one ob is missing ea, other obs w/ same ea id exist
	
	replace		ea = 6 if ea == .
	summarize
	sort 		holder_id ea_id parcel field crop_code
	save		"`export'/PH_SEC10.dta", replace

* close the log
	log	close