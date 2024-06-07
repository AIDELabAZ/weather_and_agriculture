* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Edited on: 7 June 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 5 PH sec9
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
	global		root 		 	"$data/household_data/ethiopia/wave_5/raw"  
	global		export 		 	"$data/household_data/ethiopia/wave_5/refined"
	global		logout 		 	"$data/household_data/ethiopia/logs"
	
* open log	
	cap log 	close
	log 		using			"$logout/wv5_PHSEC10", append


* **********************************************************************
* 1 - preparing ESS (Wave 5) - Post Harvest Section 10
* **********************************************************************

* load data
	use 		"$root/sect10_ph_w5.dta", clear

* dropping duplicates
	duplicates  drop
	format 		%4.0g crop_id
	rename		s9q00b crop_code

* unique identifier can only be generated including crop code as some fields are mixed
	describe
	sort 		holder_id parcel_id field_id crop_id
	isid 		holder_id parcel_id field_id crop_id
	
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
	tostring	crop, generate(crop_codeS)
	generate 	crop_id = holder_id + " " + ea_id + " " + parcel + " " ///
					+ field + " " + crop_codeS
	isid		crop_id
	drop		crop_codeS

* creating district identifier
	egen 		district_id = group( saq01 saq02)
	label var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 59 distinct districts
	*** close but different from all other sections

	
* **********************************************************************
* 2 - collecting labor variables
* **********************************************************************	
	
* following same procedure as pp_w4 for continuity

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
	replace		s10q01a = 0 if s10q01a == . 
	replace		s10q01d = 0 if s10q01d == .
	rename	 	s10q01a laborhi_m
	rename	 	s10q01d laborhi_f

* totaling free labor
	replace 	s10q03a = 0 if s10q03a == .
	replace 	s10q03c = 0 if s10q03c == .
	rename 		s10q03a laborfr_m
	rename 		s10q03c laborfr_f

* totaling household labor
* replace weeks worked equal to zero if missing
	replace		s10q02b = 0 if s10q02b == . 
	replace		s10q02f = 0 if s10q02f == . 
	replace		s10q02j = 0 if s10q02j == . 
	replace		s10q02n = 0 if s10q02n == . 
	   
* find average # of days worked by worker reported (most obs)
	sum 		s10q02c s10q02g s10q02k s10q02o
	*** s10q02c - 2.26, s10q02g - 2.22
	*** s10q02k - 2.18, s10q02o - 2.09
	
* replace days per week worked equal to average if missing and weeks were worked 
	replace		s10q02c = 2.26 if s10q02c == . &  s10q02b != 0 
	replace		s10q02g = 2.22 if s10q02g == . &  s10q02f != 0  
	replace		s10q02k = 2.18 if s10q02k == . &  s10q02j != 0  
	replace		s10q02o = 2.09 if s10q02o == . &  s10q02n != 0 
	
* replace days per week worked equal to 0 if missing and no weeks were worked
	replace		s10q02c = 0 if s10q02c == . &  s10q02b == 0 
	replace		s10q02g = 0 if s10q02g == . &  s10q02f == 0  
	replace		s10q02k = 0 if s10q02k == . &  s10q02j == 0  
	replace		s10q02o = 0 if s10q02o == . &  s10q02n == 0 
	
	summarize	s10q02b s10q02c s10q02f s10q02g s10q02j ///
					s10q02k s10q02n s10q02o
	*** it looks like the above approach works
	
	generate	laborhh_1 = s10q02b * s10q02c
	generate	laborhh_2 = s10q02f * s10q02g
	generate	laborhh_3 = s10q02j * s10q02k
	generate	laborhh_4 = s10q02n * s10q02o
	
	summarize	labor*	
	*** maxes shouldn't be greater than 91
	*** three have maxes > 91
	
	summarize 	laborhi_m laborfr_f laborhh_1 laborhh_2 laborhh_3, detail
	*** only a few outliers for laborhh_1 laborhh_2 laborhh_3
	
* dropping outliers
	replace 	laborhh_1 = . if laborhh_1 > 91 // 19 drops
	replace 	laborhh_2 = . if laborhh_2 > 91 // 3 drops
 	replace 	laborhh_3 = . if laborhh_3 > 91 // 2 drop
	
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
	
	mi 				unset	
	
* replace values with imputed values
	replace			laborhh_1 = laborhh_1_1_
	replace			laborhh_2 = laborhh_1_1_
	replace			laborhh_3 = laborhh_3_3_
	drop			laborhh_1_1_- laborhh_3_3_

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
	rename 		saq01 region
	rename 		saq02 zone
	rename 		saq03 woreda
	rename		saq05 ea

	lab var 		crop_code "Crop Identifier"
	lab var			crop_id "Unique Crop ID"
	lab var			crop "Unique Crop ID Within Plot"
	
*	Restrict to variables of interest
	keep  		holder_id- saq09 crop_code crop_id labordays_harv
	order 		holder_id- crop

* final preparations to export
	isid 		crop_id
	compress
	describe
	summarize

	sort 		holder_id ea_id parcel field crop
	
	save 		"$export/PH_SEC10.dta", replace

* close the log
	log	close