* Project: WB Weather
* Created on: Nov 20, 2023
* Created by: reece
* Stata v.18

* does
	* reads in Mali, WAVE 1 (2014), EACIS2C_P2
	* cleans plot size (hecatres)


* assumes
	* customsave.ado
	* mdesc.ado

* TO DO:
	* go back to hid, fix isid error
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root	=		"$data/household_data/mali/wave_1/raw"
	global	export	=		"$data/household_data/mali/wave_1/refined"
	global	logout	= 		"$data/household_data/mali/logs"
	
* open log
	cap 	log 	close
	log 	using	"$logout/eacis2c_p2", append 

	
* **********************************************************************
* 1 - describing plot size - self-reported and GPS
* **********************************************************************
	
* import the first relevant data file
	use				"$root/EACIS2C_p2", clear
	
* dropping duplicates
	duplicates 		drop	
	
	rename 			passage visit
	label 			var visit "number of visit - wave number"
	rename			grappe clusterid
	label 			var clusterid "cluster number"
	rename			menage hh_num
	label 			var hh_num "household number - not unique id"
	rename 			s2cq00 ord 
	label 			var ord "number of order"
	rename 			s2cq01 field 
	label 			var field "field number"
	rename 			s2cq02 parcel 
	label 			var parcel "parcel number"
	
* creat household id 	
	egen 			hid = concat(clusterid hh_num)
	label 			var hid "Household identifier"
	destring		hid, replace
	order			hid
	
* need to include hid field parcel to uniquely identify
	sort 			hid field parcel
	isid 			hid field parcel
*isid error- 

* determine cultivated plot
	rename 			s2cq03 cultivated
	label 			var cultivated "plot cultivated"
	
	***1= cultivated 2= in fallow

* drop if not cultivated
	keep 			if cultivated == 1
	
* binary for pesticide use
	rename			s2cq29a pest_any
	lab var			pest_any "=1 if any pesticide was used"
	replace			pest_any = 0 if pest_any == 0
	replace 		pest_any = 1 if pest_any > 0
	tab				pest_any
	***question asks about quantity of pesticide used
	***1=grams 2=kg 3=liters 4=sachet(not sure about this unit, translates to "bag") 0=no pesticide used
	***85.84 percent use pesticide
	
* binary for herbicide / fungicide - label as herbicide use
	generate		herb_any = . 
	replace			herb_any = 1 if s2cq29e > 0 & s2cq29e != 99
	replace			herb_any = 0 if s2cq29e == . | s2cq29e == 99
	replace			herb_any = 1 if s2cq29c > 0 & s2cq29c != 99
	replace			herb_any = 0 if s2cq29c == . | s2cq29c == 99
	lab var			herb_any "=1 if any herbicide was used"
	tab 			herb_any 
	*** includes both question about herbicide (s2cq29e) and fungicide (s2cq29c) 
	***17.28 percent use herbicide/fungicide
	
* check if any missing values
	count			if pest_any == . 
	count			if herb_any == .
	*** 0 pest and 371 herb missing, change these to "no"
	
* convert missing values to "no"
	replace			pest_any = 0 if pest_any == .
	replace			herb_any = 0 if herb_any == .
	
	
* **********************************************************************
* 2 - determine fertilizer use - binary and kg 
* **********************************************************************

* create fertilizer binary value
	egen 			fert_any = rsum(as02aq11a as02aq12a as02aq13a as02aq14a)
	replace			fert_any = 1 if fert_any > 0 
	tab 			fert_any, missing
	lab var			fert_any "=1 if any fertilizer was used"
	***
	*** 805 use some sort of fertilizer (13.04%), none missing
	
* create conversion units - kgs, tiya
	gen 			kgconv = 1 
	gen 			tiyaconv = 3
	
* create amount of fertilizer value (kg)
	*** Units are measured in kilogram bags of various sizes, will convert to kg's where appropriate
	*** 99 appears to reflect a null or missing value
** UREA 
	replace as02aq11a = . if as02aq11a == 99 
	rename as02aq11b ureaunits
	rename as02aq11a ureaquant
	tab ureaunits
	gen kgurea = ureaquant*kgconv if ureaunits == 1
	replace kgurea = ureaquant*tiyaconv if ureaunits == 6
	replace kgurea = ureaquant*5 if ureaunits == 2
	replace kgurea = ureaquant*10 if ureaunits == 3
	replace kgurea = ureaquant*25 if ureaunits == 4
	replace kgurea = ureaquant*50 if ureaunits == 5
	replace kgurea = . if ureaunits == 8
	replace kgurea = . if ureaunits == 7
	tab kgurea 
** DAP
	replace as02aq12a = . if as02aq12a == 99 
	rename as02aq12b dapunits
	rename as02aq12a dapquant
	tab dapunits
	gen kgdap = dapquant*kgconv if dapunits == 1
	replace kgdap = dapquant*tiyaconv if dapunits == 6
	replace kgdap = dapquant*5 if dapunits == 2
	replace kgdap = dapquant*10 if dapunits == 3
	replace kgdap = dapquant*25 if dapunits == 4
	replace kgdap = dapquant*50 if dapunits == 5
	replace kgdap = . if dapunits == 7
	tab kgdap 
** NPK
	replace as02aq13a = . if as02aq13a == 99 
	rename as02aq13b npkunits
	rename as02aq13a npkquant
	tab npkunits
	gen npkkg = npkquant*kgconv if npkunits == 1
	replace npkkg = npkquant*tiyaconv if npkunits == 6
	replace npkkg = npkquant*5 if npkunits == 2
	replace npkkg = npkquant*10 if npkunits == 3
	replace npkkg = npkquant*25 if npkunits == 4
	replace npkkg = npkquant*50 if npkunits == 5
	replace npkkg = . if npkunits == 7
	replace npkkg = . if npkunits == 8
	tab npkkg 
** BLEND 
	rename as02aq14b blendunits
	rename as02aq14a blendquant
	tab blendunits
	replace blendquant = . if blendquant == 99 
	gen blendkg = blendquant*kgconv if blendunits == 1
	replace blendkg = blendquant*tiyaconv if blendunits == 4
	replace blendkg = blendquant*5 if blendunits == 2
	replace blendkg = blendquant*50 if blendunits == 3
	replace blendkg = . if blendunits == 5
	tab blendkg 

*total use 
	egen fert_use = rsum(kgurea kgdap npkkg blendkg)
	count  if fert_use != . 
	count  if fert_use == . 
	
* summarize fertilizer
	sum				fert_use, detail
	*** median - 0 , mean - 9.786, max - 2750

* replace any +3 s.d. away from median as missing
	replace			fert_use = . if fert_use > `r(p50)'+(3*`r(sd)')
	*** replaced 51 values, max is now 250 
	
* impute missing values
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed fert_use // identify fert_use as the variable being imputed
	sort			hid field parcel, stable // sort to ensure reproducability of results
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
	*** imputed 51 values out of 6174 total observations	
	
* check for missing values
	mdesc fert_use
	*** 6174 total values
	*** 0 missing values 	
