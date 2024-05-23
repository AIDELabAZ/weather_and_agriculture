* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 3 PP sec3
	* provides plot size, labor, fertilizer, irrigated
	* hierarchy: holder > parcel > field > crop
	* seems to correspond to Malawi ag-modC and ag-modJ
	
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
	log using "`logout'/wv3_PPSEC3", append


* **********************************************************************
* 1 - preparing ESS 2015/16 (Wave 3) - Post Planting Section 3 
* **********************************************************************

* load pp section 3 data
	use 		"`root'/sect3_pp_w3.dta", clear

* dropping duplicates
	duplicates 	drop

* investigate unique identifier
	describe
	sort 		holder_id ea_id parcel_id field_id
	isid 		holder_id parcel_id field_id

* creating district identifier
	egen 		district_id = group( saq01 saq02)
	lab var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 69 distinct districts

* field status check
	rename 		pp_s3q03 status, missing
	tab			status, missing
	*** none missing status

* dropping all plot obs that weren't cultivated	
	drop 		if status != 1
	* 10,061 dropped

* drop observations with a missing field_id
	summarize 	if missing(parcel_id,field_id)
	drop 		if missing(parcel_id,field_id)
	isid 		holder_id parcel_id field_id
	
* creating parcel identifier
	rename		parcel_id parcel
	tostring	parcel, replace
	generate 	parcel_id = holder_id + " " + parcel
	
* creating unique field identifier
	rename		field_id field
	tostring	field, replace
	generate 	field_id = holder_id + " " + parcel + " " + field
	isid 		field_id

* create conversion key 
	rename		saq01 region
	rename		saq02 zone
	rename 		saq03 woreda
	rename		saq05 ea
	rename		pp_s3q02_c local_unit
	merge 		m:1 region zone woreda local_unit using "`root'/ET_local_area_unit_conversion.dta"
	*** 13,748 obs not matched from master data
	*** why is this...
	*** conversion facotrs only given for timad, boy, senga, and kert
	*** but measurements are also given in tilm, medeb, rope, ermija, and other
	*** will set self-reported value = . if no conversion factor is given
	
	drop		if _merge == 2
	

************************************************************************
**	2 - constructing conversion factors
************************************************************************	

* replace self-reported equal to missing if there is no conversion factor
* will not replace sef-reported if given in hectares, meters squared
	replace		conversion = 10000 if local_unit == 1 & conversion == .
	*** 465 changes
	
	replace		conversion = 1 if local_unit == 2 & conversion == .	
	*** 329 changes 
	
	replace		pp_s3q02_a = . if conversion == .
	*** 12,948 changes


************************************************************************
**	3 - constructing area measurements
************************************************************************	

************************************************************************
**	3a - constructing area measurements (self-reported) 
************************************************************************	
	
* problem? There are over 12,000 obs with units of measure not included in the conversion file
	summarize 	local_unit, detail // Quantity of land units, self-reported
	generate 	selfreport_sqm = conversion * pp_s3q02_a if local_unit !=0
	summarize 	selfreport_sqm, detail // resulting land area (sq. meters)
	generate 	selfreport_ha = selfreport_sqm * 0.0001
	summarize 	selfreport_ha, detail // resulting land area (hectares)
	

************************************************************************
**	3b - constructing area measurements (gps & rope-and-compass) 
************************************************************************	

* generate GPS & rope-and-compass land area of plot in hectares 
* as a starting point, we expect both to be more accurate than self-report 
	summarize 	pp_s3q04 pp_s3q08_a
	generate 	gps = pp_s3q05_a * 0.0001 if pp_s3q04 == 1
	generate 	rap = pp_s3q08_b * 0.0001 if pp_s3q08_a == 1
	summarize 	gps rap, detail

* compare GPS and self-report, and look for outliers in GPS 
	summarize 	gps, detail 	//	same command as above to easily access r-class stored results 
	list 		gps rap selfreport_ha if !inrange(gps,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) & !missing(gps)	
	*** looking at GPS and self-reported observations that are > ±3 Std. Dev's from the median 

* GPS on the larger side vs self-report
	tabulate 	gps if gps>2, plot	// GPS doesn't seem outrageous, 22 obs > 10 ha
	* in Wave 1 there were NO GPS measured fields > 10 ha

	sort 		gps		
	list 		gps rap selfreport_ha if gps>3 & !missing(gps), sep(0)	
	*** large gps values are sometimes way off from the self-reported

* GPS on the smaller side vs self-report 
	summarize 	gps if gps<0.002 // ~3,000 obs
	tabulate 	gps if gps<0.002, plot		
	*** like wave 1, data distirubtion is somewhat lumpy due to the precision constraints of the technology 
	*** including 430 obs that Stata recognizes as gps = 0 (and one that's negative)
	
	sort 		gps					
	list 		gps selfreport_ha if gps<0.002, sep(0)	// GPS tends to be less than self-reported size


************************************************************************
**	3c - evaluating various area measurements 
************************************************************************		
	
* evaluating correlations between various measures
	pwcorr 		gps rap 
	*** 0.6912 correlation
	
	pwcorr 		gps rap if !inrange(gps,0.002,4)
	*** 0.6984 - correlation outside this range similar to overall
	
	pwcorr 		gps rap if inrange(gps,0.002,4) 
	*** 0.7772 - higher than outside the central range
	
	pwcorr 		selfreport_ha rap 	
	*** 0.2006 correlation - low
	
	pwcorr 		selfreport_ha gps	
	*** 0.0019 correlation - very very low
	
	pwcorr 		selfreport_ha gps if inrange(gps,0.002,4) ///
					& inrange(selfreport_ha,0.002,4)
	*** 0.6811 - much much higher when range is restricted for both	
	
*	twoway 		(scatter selfreport_ha gps if inrange(gps,0.002,4) ///
					& inrange(selfreport_ha,0.002,4))


************************************************************************
**	3d - constructing overall plotsize
************************************************************************					

* make plotsize using GPS area if it is within reasonable range
	generate 	plotsize = gps
	replace 	plotsize = rap if plotsize == . & rap != . // replace missing values with rap
	summarize 	selfreport_ha gps rap plotsize, detail	
	*** we have some self-report information where we are missing plotsize 
	
	summarize 	selfreport_ha if missing(plotsize), detail
	*** 109 obs w/ selfreport_ha missing plotsize
	
* replace any zero values as missing
	replace		plotsize = . if plotsize <= 0

* impute missing plot sizes using predictive mean matching 
	mi set 		wide //	declare the data to be wide. 
	mi xtset, 	clear //	this is a precautinary step to clear any xtset that the analyst may have had in place previously
	mi register imputed plotsize //	identify plotsize as the variable being imputed 
	sort		holder_id parcel field, stable // sort to ensure reproducability of results
	mi impute 	pmm plotsize selfreport_ha i.district_id, add(1) rseed(245780) ///
					noisily dots force knn(5) bootstrap 
	mi 			unset

* summarize results of imputation
	tabulate 	mi_miss	//	this binary = 1 for the full set of observations where plotsize_GPS is missing
	tabstat 	gps rap selfreport_ha plotsize plotsize_1_, by(mi_miss) ///
					statistics(n mean min max) columns(statistics) longstub ///
					format(%9.3g) 
	*** 109 imputations made
	
	drop		mi_miss

* verify that there is nothing to be done to get a plot size for the observations where plotsize_GPS_1_ is missing
	list 		gps rap selfreport_ha plotsize if missing(plotsize_1_), sep(0)
	*** there are some missing values that we have GPS for
	
	replace 	plotsize_1_ = gps if missing(plotsize_1_) & !missing(gps) & gps > 0 // replace with existing gps values
	drop 		if missing(plotsize_1_) // drop remaining missing values

* manipulate variables for export
	rename 		(plotsize plotsize_1_)(plotsize_raw plotsize)
	label 		variable plotsize		"Plot Size (ha)"
	sum 		plotsize, detail
	*** i'm not a fan of the one negative plotsize
	

************************************************************************
**	4 - constructing other variables of interest
************************************************************************

************************************************************************
**	4a - irrigation and labor
************************************************************************

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* in this survey we can't tell gender or age of household members
* since we can't match household members we deal with each activity seperately

* look at irrigation dummy
	generate 	irrigated = pp_s3q12 if pp_s3q12 >= 1
	label 		variable irrigated "Is field irrigated?"

* household non-harvest labor
* replace weeks worked equal to zero if missing
	replace		pp_s3q27_b = 0 if pp_s3q27_b == . 
	replace		pp_s3q27_f = 0 if pp_s3q27_f == . 
	replace		pp_s3q27_j = 0 if pp_s3q27_j == . 
	replace		pp_s3q27_n = 0 if pp_s3q27_n == . 
	
* find average # of days worked by first worker reported (most obs)
	sum 		pp_s3q27_c pp_s3q27_g pp_s3q27_k pp_s3q27_o
	*** pp_s3q27_c has by far the most obs, mean is 2.59
	
* replace days per week worked equal to 2.59 if missing and weeks were worked 
	replace		pp_s3q27_c = 2.59 if pp_s3q27_c == . &  pp_s3q27_b != 0 
	replace		pp_s3q27_g = 2.42 if pp_s3q27_g == . &  pp_s3q27_f != 0  
	replace		pp_s3q27_k = 2.37 if pp_s3q27_k == . &  pp_s3q27_j != 0  
	replace		pp_s3q27_o = 2.2 if pp_s3q27_o == . &  pp_s3q27_n != 0  
	
* replace days per week worked equal to 0 if missing and no weeks were worked
	replace		pp_s3q27_c = 0 if pp_s3q27_c == . &  pp_s3q27_b == 0 
	replace		pp_s3q27_g = 0 if pp_s3q27_g == . &  pp_s3q27_f == 0  
	replace		pp_s3q27_k = 0 if pp_s3q27_k == . &  pp_s3q27_j == 0  
	replace		pp_s3q27_o = 0 if pp_s3q27_o == . &  pp_s3q27_n == 0  
	
	summarize	pp_s3q27_b pp_s3q27_c pp_s3q27_f pp_s3q27_g pp_s3q27_j ///
					pp_s3q27_k pp_s3q27_n pp_s3q27_o
	*** it looks like the above approach works

* other hh labor
* there is an assumption here
	/* 	survey instrument splits question into # of men, total # of days
		where pp_s3q29_a is # of men and pp_s3q29_b is total # of days (men)
		there is also women (c & d)
		the assumption is that total # of days is the total
		and therefore does not require being multiplied by # of men
		there are weird obs that make this assumption shakey
		where # of men = 3 and total # of days = 1 for example
		the same dilemna/assumption applies to hired labor (pp_s3q28_*)
		this can be revised if we think this assumption is shakey */

* replace total days = 0 if total days is missing
	replace		pp_s3q29_b = 0 if pp_s3q29_b == . 
	replace		pp_s3q29_d = 0 if pp_s3q29_d == . 	
	
* replace total days = 0 if total days is missing, hired labor
	replace		pp_s3q28_b = 0 if pp_s3q28_b == . 
	replace		pp_s3q28_e = 0 if pp_s3q28_e == . 	
	
* generating individual household labor rates
	generate	laborhh_1 = pp_s3q27_b * pp_s3q27_c
	generate	laborhh_2 = pp_s3q27_f * pp_s3q27_g
	generate	laborhh_3 = pp_s3q27_j * pp_s3q27_k
	generate	laborhh_4 = pp_s3q27_n * pp_s3q27_o
	generate	laborhi_m = pp_s3q28_b
	generate	laborhi_f = pp_s3q28_e
	generate	laborfr_m = pp_s3q29_b
	generate	laborfr_f = pp_s3q29_d
	
	summarize	labor*	
	
* one outlying value to be addressed in laborhi_m
	replace 	laborhi_m = 273 if laborhi_m > 273

* generate aggregate hh and hired labor variables	
	generate 	laborday_hh = laborhh_1 + laborhh_2 + laborhh_3 + laborhh_4
	generate 	laborday_hired = laborhi_m + laborhi_f
	gen			laborday_free = laborfr_m + laborfr_f
	
* check to make sure things look all right
	sum			laborday*
	
* combine hh and hired labor into one variable 
	generate 	labordays_plant = laborday_hh + laborday_hired + laborday_free
	drop 		laborday_hh laborday_hired laborday_free laborhh_1- laborfr_f
	label var 	labordays_plant "Total Days of Non-harvest Labor"
	

************************************************************************
**	4b - fertilizer
************************************************************************

* look at fertilizer use
	generate	fert_any = 1 if pp_s3q15 == 1 | pp_s3q18 ==1 | pp_s3q20a_1 == 1 ///
					| pp_s3q20a == 1
	replace		fert_any = 0 if fert_any == . 
	
* constructing continuous fertilizer variable
* making any missing ob zero if there is a value for another inorganic fertilizer
* variable in the same observation	
	generate 	fert_u = pp_s3q16  // urea
	replace		fert_u = 0 if pp_s3q16 == . & (pp_s3q19 != . | pp_s3q20a_2 != . ///
					| pp_s3q20a_7 != .)
	
	generate 	fert_d = pp_s3q19 // DAP
	replace		fert_d = 0 if pp_s3q19 == . & (pp_s3q16 != . | pp_s3q20a_2 != . ///
					| pp_s3q20a_7 != .)
	
	generate 	fert_n = pp_s3q20a_2 // NPS
	replace		fert_n = 0 if pp_s3q20a_2 == . & (pp_s3q16 != . | pp_s3q19 != . ///
					| pp_s3q20a_7 != .)
	*** unit of measure not specified, assuming kg
					
	generate 	fert_o = pp_s3q20a_7 // other chemical fertilizer
	replace		fert_o = 0 if pp_s3q20a_7 == . & (pp_s3q16 != . | pp_s3q19 != . ///
					| pp_s3q20a_2 != .)
	*** unit of measure not specified, assuming kg
	
	generate 	kilo_fert = fert_u + fert_d + fert_n + fert_o
	label var 	kilo_fert "Kilograms of fertilizer applied (Urea and DAP only)"
	drop 		fert_u fert_d fert_n fert_o
	*** kilo_fert only captures Urea, DAP, NPS, and other inorganics - 5,172 obs
	*** no quantities are provided for compost, manure, or organic fertilizer
	*** will attempt to impute missing values
	
	replace		kilo_fert = 0 if fert_any == 0 & kilo_fert == .
	*** 11,401 changes made
	
* summarize fertilizer
	sum				kilo_fert, detail
	*** median 0, mean 24.5, max 10,000

* replace any +3 s.d. away from median as missing
	replace			kilo_fert = . if kilo_fert > `r(p50)'+(3*`r(sd)')
	*** replaced 125 values, mean is now 7.77, max is now 801
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed kilo_fert // identify kilo_fert as the variable being imputed
	sort			holder_id parcel field, stable // sort to ensure reproducability of results
	mi impute 		pmm kilo_fert i.district_id, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset
	
* how did the imputation go?
	tab				mi_miss
	tabstat			kilo_fert kilo_fert_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			kilo_fert = kilo_fert_1_
	lab var			kilo_fert "fertilizer use (kg), imputed"
	drop			kilo_fert_1_ 
	*** 125 imputations made
	

* ***********************************************************************
* 5 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid
	rename 		household_id2 hhid2
	rename		pp_s3q03b purestand
	
* restrict to variables of interest 
* this is how world bank has their do-file set up
* if we want to keep all identifiers (i.e. region, zone, etc) we can do that easily
	keep  		holder_id- pp_s3q0a purestand kilo_fert labordays_plant plotsize ///
					irrigated fert_any field_id
	order 		holder_id- saq06

* final preparations to export
	isid 		holder_id parcel field
	isid		field_id
	compress
	describe
	summarize
	sort 		holder_id parcel field
	save 		"`export'/PP_SEC3.dta", replace

* close the log
	log	close
	
/* END */