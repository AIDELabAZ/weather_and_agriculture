* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Niger, WAVE 2 (2014), POST PLANTING, AG AS2AP1
	* creates binaries for pesticide and herbicide use
	* creates binaries and kg for fertilizer use
	* cleans labor post planting - prep labor 
	* outputs clean data file ready for combination with wave 2 plot data

* assumes
	* access to all raw data
	* mdesc.ado
	
* TO DO:
	* complete
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=	"$data/household_data/niger/wave_2/raw"
	loc		export	=	"$data/household_data/niger/wave_2/refined"
	loc		logout	=	"$data/household_data/niger/logs"

* open log	
	cap		log 	close
	log 	using 	"`logout'/2014_as2ap1", append
	
	
* **********************************************************************
* 1 - determine pesticide and herbicide use 
* **********************************************************************
		
* import the first relevant data file
	use				"`root'/ECVMA2_AS2AP1", clear 	
	
* need to rename for English
	rename 			PASSAGE visit
	label 			var visit "number of visit"
	rename			GRAPPE clusterid
	label 			var clusterid "cluster number"
	rename			MENAGE hh_num
	label 			var hh_num "household number - not unique id"
	rename 			EXTENSION extension 
	label 			var extension "extension of household"
	*** will need to do these in every file
	rename 			AS01Q01 field 
	label 			var field "field number"
	rename 			AS01Q03 parcel 
	label 			var parcel "parcel number"
	
* create new household id for merging with weather 
	tostring		clusterid, replace 
	gen str2 		hh_num1 = string(hh_num,"%02.0f")
	tostring		extension, replace
	egen			hhid_y2 = concat( clusterid hh_num1 extension  )
	destring		hhid_y2, replace
	order			hhid_y2 clusterid hh_num hh_num1 extension 
	
* create new household id for merging with year 1 
	egen			hid = concat( clusterid hh_num1  )
	destring		hid, replace
	order			hhid_y2 hid clusterid hh_num hh_num1 
	
* need to destring variables for later use in imputes 	
	destring 		clusterid, replace
	
* hhid_y2 field parcel to uniquely identify
	describe
	sort 			hhid_y2 field parcel  
	isid 			hhid_y2 field parcel

* determine cultivated plot
	rename 			AS02AQ04 cultivated
	label 			var cultivated "plot (parcel) cultivated"
* drop if not cultivated
	keep 			if cultivated == 1
	*** 301 observations dropped

* **********************************************************************
* 2 - determine pesticide and herbicide use - binaries 
* **********************************************************************

* binary for pesticide use
	rename			AS02AQ13A pest_any
	lab var			pest_any "=1 if any pesticide was used"
	replace			pest_any = 0 if pest_any == 2
	replace 		pest_any = . if pest_any == 9
	tab				pest_any
	*** 341 - 6.64 percent use pesticide 
	*** pesticide == insecticide
	*** question asked about insecticide - in dta file downloaded, designated at pesticide
	*** wondering if there is another pesticide question - have not yet found 

* binary for herbicide / fungicide - label as herbicide use
	generate		herb_any = . 
	replace			herb_any = 1 if AS02AQ14A == 1
	replace			herb_any = 0 if AS02AQ14A == 2
	replace			herb_any = 1 if AS02AQ15A == 1
	replace			herb_any = 0 if AS02AQ15A == 2
	lab var			herb_any "=1 if any herbicide was used"
	tab 			herb_any 
	*** includes both question about herbicide (AS02AQ15A) and fungicide (AS02AQ14A) 
	
* check if any missing values
	count			if pest_any == . 
	count			if herb_any == .
	*** 5 pest and 5 herb missing, change these to "no"
	
* convert missing values to "no"
	replace			pest_any = 0 if pest_any == .
	replace			herb_any = 0 if herb_any == .
	

* **********************************************************************
* 3 - determine fertilizer use - binary and kg 
* **********************************************************************
	
* create conversion units - kgs, tiya
	gen 			kgconv = 1 
	gen 			tiyaconv = 3
	*** will not create conversion for black and white sachet - will impute theses values 	
	
* create fert_any variable
	egen 			fert_any = rsum(AS02AQ09B AS02AQ10B AS02AQ11B AS02AQ12B)
	*** gets addressed later - but build now

* create amount of fertilizer value (kg)
** UREA 
	replace AS02AQ09C = . if AS02AQ09C == 9 
	rename AS02AQ09C ureaunits
	rename AS02AQ09B ureaquant
	gen kgurea = ureaquant*kgconv if ureaunits == 1
	replace kgurea = ureaquant*tiyaconv if ureaunits == 2
	replace kgurea = . if ureaunits == 3
	replace kgurea = . if ureaunits == 4
	tab kgurea 
** DAP
	replace AS02AQ10C = . if AS02AQ10C == 9 
	rename AS02AQ10C dapunits
	rename AS02AQ10B dapquant
	gen kgdap = dapquant*kgconv if dapunits == 1
	replace kgdap = dapquant*tiyaconv if dapunits == 2
	replace kgdap = . if dapunits == 3
	replace kgdap = . if dapunits == 4
	tab kgdap 
** NPK
	replace AS02AQ11C = . if AS02AQ11C == 9 
	rename AS02AQ11C npkunits
	rename AS02AQ11B npkquant
	gen npkkg = npkquant*kgconv if npkunits == 1
	replace npkkg = npkquant*tiyaconv if npkunits == 2
	replace npkkg = . if npkunits == 3
	replace npkkg = . if npkunits == 4
	tab npkkg 
** BLEND 
	replace AS02AQ12C = . if AS02AQ12C == 9 
	rename AS02AQ12C blendunits
	rename AS02AQ12B blendquant
	gen blendkg = blendquant*kgconv if blendunits == 1
	replace blendkg = blendquant*tiyaconv if blendunits == 2
	replace blendkg = . if blendunits == 3
	replace blendkg = . if blendunits == 4
	tab blendkg 

*total use 
	egen fert_use = rsum(kgurea kgdap npkkg blendkg)
	count  if fert_use != . 
	count  if fert_use == . 
	replace fert_use = . if blendunits == 4
	*** 10 changes made 
	
	*** need to replace those in sachets equal to . because those will be replaced with 0s in summation 
	replace fert_use = . if ureaunits == 3
	*** 43 changes made
	replace fert_use = . if ureaunits == 4
	*** 12 changes made
	replace fert_use = . if dapunits == 3
	*** 3 changes made
	replace fert_use = . if dapunits == 4
	*** 1 change made
	replace fert_use = . if npkunits == 3
	*** 24 changes made
	replace fert_use = . if npkunits == 4
	*** 0 changes made
	replace fert_use = . if blendunits == 3
	*** 9 changes made 
	
* create fertilizer binary value
	replace			fert_any = 1 if fert_any > 0 
	tab 			fert_any, missing
	lab var			fert_any "=1 if any fertilizer was used"
	*** 1,123 use some sort of fertilizer (22%), none missing
	
* summarize fertilizer
	sum				fert_use, detail
	*** median 0, mean 5.5, max 297
	*** relaly low values ... 

* replace any +3 s.d. away from median as missing
	replace			fert_use = . if fert_use > `r(p50)'+(3*`r(sd)')
	*** replaced 129 values, max is now 
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed fert_use // identify kilo_fert as the variable being imputed
	sort			hhid_y2 field parcel, stable // sort to ensure reproducability of results
	mi impute 		pmm fert_use i.clusterid, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 				unset
	
* how did the imputation go?
	tab				mi_miss
	tabstat			fert_use fert_use_1_, by(mi_miss) ///
						statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g) 
	replace			fert_use = fert_use_1_
	lab var			fert_use "fertilizer use (kg), imputed"
	drop			fert_use_1_
	*** imputed 231 values out of 5139 total observations	
	
* check for missing values
	count 			if fert_use == !.
	count			if fert_use == .
	*** 4145 total values
	*** 0 missing values 
	
	
* **********************************************************************
* 4 - determine labor allocation 
* **********************************************************************

* per Palacios-Lopez et al. (2017) in Food Policy, we cap labor per activity
* 7 days * 13 weeks = 91 days for land prep and planting
* 7 days * 26 weeks = 182 days for weeding and other non-harvest activities
* 7 days * 13 weeks = 91 days for harvesting
* we will also exclude child labor_days
* will not disaggregate gender / age - pool together, as with other rounds 
* in line with others, will deal with each activity seperately

* create household member labor 
* AS02AQ1*A identified HH ID of laborer 
* AS02AQ1*B identifies number of days that person worked 

	gen				hh_1 = AS02AQ17B
	replace			hh_1 = 0 if hh_1 == .
	
	gen				hh_2 = AS02AQ18B
	replace			hh_2 = 0 if hh_2 == .
	
	gen				hh_3 = AS02AQ19B
	replace			hh_3 = 0 if hh_3 == .
	
	gen				hh_4 = AS02AQ20B
	replace			hh_4 = 0 if hh_4 == .
	
	gen				hh_5 = AS02AQ21B
	replace			hh_5 = 0 if hh_5 == .
	
	gen				hh_6 = AS02AQ22B
	replace			hh_6 = 0 if hh_6 == .
	*** this calculation is for up to 6 members of the household that were laborers
	*** per the survey, these are laborers from the main rainy season
	*** includes labor for clearing, burning, fertilizing - would here include combination of land prep (91 day max)
	*** does not include harvest labor or planting labor 
	
* hired labor days   
	tab 			AS02AQ24A
	*** 647 hired labor, 4487 did not
	
	gen				hired_men = .
	replace			hired_men = AS02AQ24B if AS02AQ24A == 1
	replace			hired_men = 0 if AS02AQ24A == 2
	replace			hired_men = 0 if AS02AQ24A == 9 
	replace			hired_men = 0 if AS02AQ24B == 999
	replace 		hired_men = 0 if hired_men == .  

	gen				hired_women = .
	replace			hired_women = AS02AQ24C if AS02AQ24A == 1
	replace			hired_women = 0 if AS02AQ24A == 2
	replace			hired_women = 0 if AS02AQ24A == 9 
	replace			hired_women = 0 if AS02AQ24C == 999
	replace 		hired_women = 0 if hired_women == .  
	*** we do not include child labor days
	
* mutual labor days from other households
	tab 			AS02AQ23A
	*** 417 received mutual labor, 4718 did not, 4 missing 
	
	gen 			mutual_men = .
	replace			mutual_men = AS02AQ23B if AS02AQ23A == 1
	replace			mutual_men = 0 if AS02AQ23A == 2
	replace			mutual_men = 0 if AS02AQ23A == 9 
	replace			mutual_men = 0 if AS02AQ23B == 999
	replace 		mutual_men = 0 if mutual_men == . 

	gen 			mutual_women = .
	replace			mutual_women = AS02AQ23C if AS02AQ23A == 1
	replace			mutual_women = 0 if AS02AQ23A == 2
	replace			mutual_women = 0 if AS02AQ23A == 9 
	replace			mutual_women = 0 if AS02AQ23C == 999 
	replace			mutual_women = 0 if mutual_women == . 
	*** we do not include child labor days

	
* **********************************************************************
* 5 - impute labor outliers
* **********************************************************************
	
* summarize household individual labor for land prep to look for outliers
	sum				hh_1 hh_2 hh_3 hh_4 hh_5 hh_6 hired_men hired_women mutual_men mutual_women
	*** hh_1, hh_2, hh_3, hired_men, mutual_men, mutual_women are all greater than the minimum (91 days)
	
* generate local for variables that contain outliers
	loc				labor hh_1 hh_2 hh_3 hh_4 hh_5 hh_6 hired_men hired_women mutual_men mutual_women

* replace zero to missing, missing to zero, and outliers to missing
	foreach var of loc labor {
	    mvdecode 		`var', mv(0)
		mvencode		`var', mv(0)
	    replace			`var' = . if `var' > 90
	}
	*** 18 outliers changed to missing

* impute missing values (only need to do six variables - set new local)
	loc 			laborimp hh_1 hh_2 hh_3 hired_men mutual_men mutual_women
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously


* impute each variable in local		
	foreach var of loc laborimp {
		mi register			imputed `var' // identify variable to be imputed
		sort				hhid_y2 field parcel, stable 
		// sort to ensure reproducability of results
		mi impute 			pmm `var' i.clusterid, add(1) rseed(245780) ///
								noisily dots force knn(5) bootstrap
	}						
	mi 				unset	
	
* summarize imputed variables
	sum				hh_1_1_ hh_2_2_ hh_3_3_ hired_men_4_ mutual_men_5_ mutual_women_6_ 
	*** all values seem fine
	
	replace			hh_1 = hh_1_1_
	replace			hh_2 = hh_2_2_	
	replace 		hh_3 = hh_3_3_
	replace 		hired_men = hired_men_4_ 
	replace			mutual_men = mutual_men_5_
	replace			mutual_women = mutual_women_6_ 

* total labor days for harvest
	egen			hh_prep_labor = rowtotal(hh_1 hh_2 hh_3 hh_4 hh_5 hh_6)
	egen			hired_prep_labor  = rowtotal(hired_men hired_women)
	egen			mutual_prep_labor = rowtotal(mutual_men mutual_women)
	egen			prep_labor = rowtotal(hh_prep_labor hired_prep_labor)
	lab var			prep_labor "total labor for prep (days) - no free labor"
	egen 			prep_labor_all = rowtotal(hh_prep_labor hired_prep_labor mutual_prep_labor)  
	lab var			prep_labor_all "total labor for prep (days) - with free labor"

* check for missing values
	mdesc			prep_labor prep_labor_all
	*** no missing values
	
	sum 			prep_labor prep_labor_all
	*** which is used will not make that much of a difference, except for max
	*** with free labor: average = 11.8, max = 270
	*** without free labor: average = 11.4, max = 180

	
* **********************************************************************
* 6 - combine planting and harvest labor 
* **********************************************************************

	keep 			hhid_y2 hid clusterid hh_num hh_num1 extension field parcel pest_any ///
					fert_any fert_use herb_any prep_labor prep_labor_all
	
* create unique household-plot identifier
	isid				hhid_y2 field parcel 
	sort				hhid_y2 field parcel, stable 
	egen				plot_id = group(hhid_y2 field parcel)
	lab var				plot_id "unique field and parcel identifier"
	

* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************
	label var 		hhid_y2 "unique id - match w2 with weather"
	label var		hid "unique id - match w2 with w1 (no extension)"
	label var 		hh_num1 "household id - string changed, not unique"

	compress
	describe
	summarize

* save file
		save 			"`export'/2014_as2ap1.dta", replace

* close the log
	log	close

/* END */