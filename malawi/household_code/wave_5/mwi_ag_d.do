* Project: WB Weather
* Created on: March 2024
* Created by: alj
* Edited on: 11 March 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop price / sales information 
	* directly follow from ag_d code - by JB
	*** plot tenure included in that file and not here
	
* assumes
	* access to MWI W5 raw data
	
* TO DO:
	* done 
	* stop at line 93 rn 

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_5/raw"	
	loc		export 	= 	"$data/household_data/malawi/wave_5/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"
	loc 	temp 	= 	"$data/household_data/malawi/wave_5/tmp"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_ag_mod_d", append


* **********************************************************************
* 1 - setup to clean plot  
* **********************************************************************

* load data
	use 			"`root'/ag_mod_d.dta", clear
	
	describe 
	sort 			case_id HHID gardenid plotid 	
	capture 		: noisily : isid case_id gardenid plotid
	duplicates 		report case_id gardenid plotid 
	*** none

* **********************************************************************
* 2 -  cash crop
* **********************************************************************
	 
	egen 			crop_cash = anymatch(ag_d20a ag_d20b ag_d20c ag_d20d ag_d20e), values(5/10 37/39 47) 
	label 			variable crop_cash	"plot is planted withcash crops (tobacco, cotton, sunflower, paprika, sugar cane)"
	
	
* **********************************************************************
* 3 - soil and erosion 
* **********************************************************************

* bring in spatial variables for merge merge to conversion factor database
	merge m:1 case_id using "`root'/hh_mod_a_filt.dta", keepusing(region district reside) assert(2 3) keep(3) nogenerate
	*** (all) 26120 matched

* soil type of plot 
	tab 			ag_d21, missing
	*** 59 missing
	*** 773 other 
	recode 			ag_d21 (4=1) if inlist(ag_d21_oth,"BETWEEN MCHENGA AND MAKANDE","BETWEEN SANDY AND MAKANDE","DAMBO SAND""MAKANDE AND MCHENGA","MAKANDE AND SANDY")
	recode 			ag_d21 (4=2) if inlist(ag_d21_oth,"LOAM & SANDY SOIL","LOAM AND SANDY SOIL","LOAM SOIL")
	generate 		soiltype = ag_d21 
	label 			define soiltype 1 "Sandy" 2 "Between sandy & clay" 3 "Clay"
	label 			values soiltype soiltype
	label 			variable soiltype "predominant soil type of plot" 
* need to impute missing - use region
	bysort 			region : egen modesoil = mode(soiltype), minmode
	replace 		soiltype = modesoil if missing(soiltype)
	*** 59 changes made 
	drop 			modesoil
	
* erosion control 
	tab 			ag_d25a, missing
	tab				ag_d25a_oth
	recode 			ag_d25a (9=1) if inlist(ag_d25a_os,"NO SOIL EROSION CONTROL")
	recode 			ag_d25a (9=3) if inlist(ag_d25a_os,"BOX RIDGES","RIDGES")
	recode 			ag_d25a (9=5) if inlist(ag_d25a_os,"PLANTED ELEPHANT GRASS","PLANTED GRASS SUGAR CANE","PLANTED KAPINGA","PLANTED KHONJE (SISAL)","PLANTED OTHER GRASS","PLANTED SISAL")
	recode 			ag_d25a (9=6) if inlist(ag_d25a_os,"PLANTED BAMBOO")
	recode 			ag_d25a (9=8) if inlist(ag_d25a_os,"WATER CHAINS","WATER WAY")
	list 			ag_d25a ag_d25b ag_d25b_os if ag_d25a_os=="BOX RIDGES AND ELEPHANT GRASS"
	recode 			ag_d25a (9=3) if ag_d25a_os=="BOX RIDGES AND ELEPHANT GRASS"
	recode 			ag_d25b (9=5) if ag_d25a_os=="BOX RIDGES AND ELEPHANT GRASS"
	tabulate 		ag_d25b_oth if ag_d25b=="Other (Specify)" 	
	recode 			ag_d25b (9=5) if inlist(ag_d25b_os,"PLANTED ELEPHANT GRASS","PLANTED SISAL")
	
	******** STOP HERE

*	Make dummies for various erosion control structures 
egen swc_terrace = anymatch(ag_d25a ag_d25b), values(2)
label variable swc_terrace		"Plot has terraces to control erosion" 
egen swc_bund_ec = anymatch(ag_d25a ag_d25b), values(3)
label variable swc_bund_ec		"Plot has bunds to control erosion"
egen swc_bund_wh = anymatch(ag_d25a ag_d25b), values(7)
label variable swc_bund_wh		"Plot has bunds to harvest water"
*	differentiation between bunds on basis of their intended use may be an overly fine distinction for some analyses 
egen swc_bund_any = anymatch(ag_d25a ag_d25b), values(3 7)
label variable swc_bund_any		"Plot has bunds"
egen swc_gabion = anymatch(ag_d25a ag_d25b), values(4)
label variable swc_gabion		"Plot has gabions/sandbags to control erosion"
egen swc_vetiver = anymatch(ag_d25a ag_d25b), values(5)
label variable swc_vetiver		"Plot has vetiver grass to control erosion"
egen swc_treebelt = anymatch(ag_d25a ag_d25b), values(6)
label variable swc_treebelt		"Plot has tree belts to control erosion"
egen swc_drainage = anymatch(ag_d25a ag_d25b), values(8)
label variable swc_drainage		"Plot has drainage ditches to control erosion"

*	Make some overall categories 
egen swc_any = anymatch(ag_d25a ag_d25b), values(2 3 4 5 6 7 8)
label variable swc_any			"Plot has any erosion control structure"
egen swc_mech = anymatch(ag_d25a ag_d25b), values(2 3 4 7 8)
label variable swc_mech			"Plot has any mechanical erosion control structure"
egen swc_bio = anymatch(ag_d25a ag_d25b), values(5 6)
label variable swc_bio			"Plot has any biological erosion control measures"


*	Slope of plot
tabulate ag_d26, missing
generate slope = ag_d26
label copy AG_D20 slope
label values slope slope
label variable slope			"Predominant slope of plot" 
bysort ea_id : egen modeslope = mode(slope), minmode
replace slope = modeslope if missing(slope)
drop modeslope 


*	Plot is in dambo area
tabulate ag_d27, missing
generate dambo = (ag_d27=="Yes":AG_D21)
label variable dambo			"Plot is in swamp/wetland" 




* **********************************************************************
* ? - end matter, clean up to save
* **********************************************************************

	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_d.dta", replace

* close the log
	log			close

/* END */