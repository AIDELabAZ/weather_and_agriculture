* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on 6 June 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 4 PP sec3
	* provides plot size, labor, fertilizer, irrigated
	* hierarchy: holder > parcel > field > crop
	* seems to correspond to Malawi ag-modC and ag-modJ
	
* assumes
	* access to raw data
	* distinct.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global		root 		 	"$data/household_data/ethiopia/wave_4/raw"  
	global		export 		 	"$data/household_data/ethiopia/wave_4/refined"
	global		logout 		 	"$data/household_data/ethiopia/logs"
	
* open log	
	cap log 	close
	log 		using			"$logout/wv4_PPSEC3", append


* **********************************************************************
* 1 - preparing ESS 2018/19 (Wave 4) - Post Planting Section 3 
* **********************************************************************

* load pp section 3 data
	use 		"$root/sect3_pp_w4.dta", clear

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
	*** 75 distinct district

* field status check
	rename 		s3q03 status, missing
	tab			status, missing
	*** 1 missing status

* dropping all plot obs that weren't cultivated	
	drop 		if status != 1
	* 5,962 dropped
	
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
	rename		saq14 sector
	rename		saq04 city
	rename		saq06 kebele
	rename		s3q02b local_unit
	
* destring zone and woreda
	gen			zone = saq02
	destring	zone, replace
	gen			woreda = saq03
	destring	woreda, replace
	gen			ea = saq05
	destring	ea, replace

* merge in land conversion factors	
	merge 		m:1 region zone woreda local_unit using "$root/ET_local_area_unit_conversion"
	*** 11,512 obs not matched from master data
	*** conversion facotrs only given for timad, boy, senga, and kert and not for all woredas 
	drop		if _merge == 2

	drop		zone woreda ea
	rename		saq02 zone
	rename 		saq03 woreda
	rename		saq05 ea
	
* create zone and region conversion factors by taking average	
	egen 		zone_mean = mean( conversion), by(region zone local_unit)
	egen 		region_mean = mean( conversion), by(region local_unit)
	egen 		country_mean = mean( conversion), by(local_unit)

	replace		conversion = 1 if local_unit == 1
	replace		conversion = 10000 if local_unit == 2
	replace		conversion = zone_mean if conversion == .
	replace		conversion = region_mean if conversion == .
	replace		conversion =country_mean if conversion == .
	*** now only missing 5,254

************************************************************************
**	2 - constructing conversion factors
************************************************************************	


* replace self-reported equal to missing if there is no conversion factor
* will not replace sef-reported if given in hectares, meters squared
	replace		conversion = 1 if local_unit == 1 & conversion == .
	*** 0 changes
	
	replace		conversion = 1 if local_unit == 2 & conversion == .	
	*** 0 changes 
	
	replace		s3q02a = . if conversion == .
	*** 5,254 changes
	

************************************************************************
**	3 - constructing area measurements
************************************************************************	

************************************************************************
**	3a - constructing area measurements (self-reported) 
************************************************************************	
	
* problem? There are over 12,000 obs with units of measure not included in the conversion file
	generate 	selfreport_ha = s3q02a / conversion
	summarize 	selfreport_ha, detail // resulting land area (hectares)
	
* massive outliers, all record in ha. most likely square meters if in top 95%
	sum 		s3q02a if local_unit == 1, detail
	replace		conversion = 10000 if s3q02a > 4 & local_unit == 1
	*** 16 changes made
	
	replace 	selfreport_ha = s3q02a / conversion

	
************************************************************************
**	3b - constructing area measurements (gps) 
************************************************************************	

* generate GPS land area of plot in hectares 
* as a starting point, we expect both to be more accurate than self-report
	generate 	gps = s3q08 / 10000 if s3q07 != 3
	summarize 	gps, detail

* compare GPS and self-report, and look for outliers in GPS 
	summarize 	gps, detail 	//	same command as above to easily access r-class stored results 
	list 		gps selfreport_ha if !inrange(gps,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) & !missing(gps)	
	*** looking at GPS and self-reported observations that are > ±3 Std. Dev's from the median 

* GPS on the larger side vs self-report
	tabulate 	gps if gps>2, plot	// GPS doesn't seem outrageous, 2 obs > 10 ha
	* in Wave 1 there were NO GPS measured fields > 10 ha

	sort 		gps		
	list 		gps selfreport_ha if gps>3 & !missing(gps), sep(0)	
	*** most large gps values are similar to self-reported
	*** where they differ i assume conversion factor was wrong

	
* GPS on the smaller side vs self-report 
	summarize 	gps if gps<0.002 // 
	tabulate 	gps if gps<0.002, plot		
	*** like wave 1, data distirubtion is somewhat lumpy due to the precision constraints of the technology 
	*** including 1 obs that Stata recognizes as gps = 0
	
************************************************************************
**	3c - evaluating various area measurements 
************************************************************************		
	
* evaluating correlations between various measures
	pwcorr 		gps selfreport_ha
	*** 0.26 correlation
	
	pwcorr 		gps selfreport_ha if !inrange(gps,0.002,4)
	*** 0.02 - correlation outside this range similar to overall
	
	pwcorr 		selfreport_ha gps if inrange(gps,0.002,4) ///
					& inrange(selfreport_ha,0.002,4)
	*** 0.50 - much much higher when range is restricted for both	
	
*	twoway 		(scatter selfreport_ha gps if inrange(gps,0.002,4) ///
					& inrange(selfreport_ha,0.002,4))


************************************************************************
**	3d - constructing overall plotsize
************************************************************************					

* make plotsize using GPS area if it is within reasonable range
	generate 	plotsize = gps
	
	summarize 	selfreport_ha if missing(plotsize), detail
	*** 31 obs w/ selfreport_ha missing plotsize
	
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
	tabstat 	gps selfreport_ha plotsize plotsize_1_, by(mi_miss) ///
					statistics(n mean min max) columns(statistics) longstub ///
					format(%9.3g) 
	*** 31 imputations made
	
	drop		mi_miss

* verify that there is nothing to be done to get a plot size for the observations where plotsize_GPS_1_ is missing
	list 		gps selfreport_ha plotsize if missing(plotsize_1_), sep(0)
	*** there are some missing values that we have GPS for
	
	replace 	plotsize_1_ = gps if missing(plotsize_1_) & !missing(gps) & gps > 0 // replace with existing gps values
	drop 		if missing(plotsize_1_) // drop remaining missing values

* manipulate variables for export
	rename 		(plotsize plotsize_1_)(plotsize_raw plotsize)
	label 		variable plotsize		"Plot Size (ha)"
	sum 		plotsize, detail


************************************************************************
**	4 - constructing other variables of interest
************************************************************************

* look at irrigation dummy
	generate 	irrigated = 1 if s3q17 == 1
	replace		irrigated = 0 if irrigated == .
	label 		variable irrigated "Is field irrigated?"

	
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

* household non-harvest labor
* replace weeks worked equal to zero if missing
	replace		s3q29b = 0 if s3q29b == . 
	replace		s3q29f = 0 if s3q29f == . 
	replace		s3q29j = 0 if s3q29j == . 
	replace		s3q29n = 0 if s3q29n == . 
	
* find average # of days worked by first worker reported (most obs)
	sum 		s3q29c s3q29g s3q29k s3q29o
	*** s3q29c has by far the most obs, mean is 2.58
	
* replace days per week worked equal to 2.59 if missing and weeks were worked 
	replace		 s3q29c = 2.59 if  s3q29c == . &   s3q29b != 0 
	replace		 s3q29g = 2.42 if  s3q29g == . &   s3q29f != 0  
	replace		 s3q29k = 2.37 if  s3q29k == . &   s3q29j != 0  
	replace		 s3q29o = 2.2 if  s3q29o == . &   s3q29n != 0  
	
* replace days per week worked equal to 0 if missing and no weeks were worked
	replace		 s3q29c = 0 if  s3q29c == . &   s3q29b == 0 
	replace		 s3q29g = 0 if  s3q29g == . &   s3q29f == 0  
	replace		 s3q29k = 0 if  s3q29k == . &   s3q29j == 0  
	replace		 s3q29o = 0 if  s3q29o == . &   s3q29n == 0  
	
	summarize	 s3q29b  s3q29c  s3q29f  s3q29g  s3q29j ///
					 s3q29k  s3q29n  s3q29o
	*** it looks like the above approach works

* hired labor
* there is an assumption here
	/* 	survey instrument splits question into # of men, total # of days
		where s3q30a is # of men and s3q30b is total # of days (men)
		there is also women (c & d)
		the assumption is that total # of days is the total
		and therefore does not require being multiplied by # of men
		there are weird obs that make this assumption shakey */
		
* replace hired = 0 if hired is missing
	replace		s3q30a = 0 if s3q30a == . 
	replace		s3q30d = 0 if s3q30d == . 	
	replace		s3q31a = 0 if s3q31a == . 	
	replace		s3q31c = 0 if s3q31c == . 	
	
* replace total days = 0 if total days is missing, hired labor
	replace		s3q30b = 0 if s3q30b == . 
	replace		s3q30e = 0 if s3q30e == . 	
	replace		s3q31b = 0 if s3q31b == . 
	replace		s3q31d = 0 if s3q31d == . 	
	
* generating individual household labor rates
	generate	laborhh_1 = s3q29b * s3q29c
	generate	laborhh_2 = s3q29f * s3q29g
	generate	laborhh_3 = s3q29j * s3q29k
	generate	laborhh_4 = s3q29n * s3q29o
	generate	laborhi_m = s3q30b
	generate	laborhi_f = s3q30e
	generate	laborfr_m = s3q31b
	generate	laborfr_f = s3q31d
	
	summarize	labor*	
	
* one outlying value to be addressed in laborfr_m
	replace 	laborfr_m = 150 if laborfr_m > 273

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
	generate	fert_any = 1 if s3q21 == 1 | s3q22 == 1 | s3q23 == 1 | s3q24 == 1
	replace		fert_any = 0 if fert_any == . 
	
* constructing continuous fertilizer variable
* making any missing ob zero if there is a value for another inorganic fertilizer
* variable in the same observation	
	generate 	fert_u = s3q21a  // urea
	replace		fert_u = 0 if s3q21a == . & (s3q22a != . | s3q23a != . ///
					| s3q24a != .)
	
	generate 	fert_d = s3q22a // DAP
	replace		fert_d = 0 if s3q22a == . & (s3q21a != . | s3q23a != . ///
					| s3q24a != .)
	
	generate 	fert_n = s3q23a // NPS
	replace		fert_n = 0 if s3q23a == . & (s3q21a != . | s3q22a != . ///
					| s3q24a != .)
	*** unit of measure not specified, assuming kg
					
	generate 	fert_o = s3q24a // other chemical fertilizer
	replace		fert_o = 0 if s3q24a == . & (s3q21a != . | s3q22a != . ///
					| s3q23a != .)
	*** unit of measure not specified, assuming kg
	
	generate 	kilo_fert = fert_u + fert_d + fert_n + fert_o
	label var 	kilo_fert "Kilograms of fertilizer applied"
	drop 		fert_u fert_d fert_n fert_o
	*** kilo_fert only captures Urea, DAP, NPS, and other inorganics - 3,909 obs
	*** no quantities are provided for compost, manure, or organic fertilizer
	*** will attempt to impute missing values
	
	replace		kilo_fert = 0 if fert_any == 0 & kilo_fert == .
	*** 9,453 changes made
	
* summarize fertilizer
	replace		kilo_fert = . if kilo_fert > 20000
	*** median 0, mean 27.5, max 50,000

* replace any +3 s.d. away from median as missing
	sum				kilo_fert, detail
	replace			kilo_fert = . if kilo_fert > `r(p50)'+(2*`r(sd)')
	*** replaced 17 values, mean is now 13, max is now 20000

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
	*** 21 imputations made
	

* ***********************************************************************
* 5 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid
	rename		s3q04 purestand
	
* restrict to variables of interest 
* this is how world bank has their do-file set up
* if we want to keep all identifiers (i.e. region, zone, etc) we can do that easily
	keep  		holder_id- saq09 purestand kilo_fert labordays_plant plotsize ///
					irrigated fert_any parcel_id field_id
	order 		holder_id- saq09

* final preparations to export
	isid 		holder_id parcel field
	isid		field_id
	compress
	describe
	summarize
	sort 		holder_id parcel field
	
	save 		"$export/PP_SEC3.dta", replace

* close the log
	log	close
	
/* END */