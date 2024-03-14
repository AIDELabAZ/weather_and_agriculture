* Project: WB Weather
* Created on: March 2024
* Created by: alj
* Edited on: 12 March 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop price / sales information 
	* directly follow from ag_d code - by JB
	*** plot tenure included in that file and not here
	
* assumes
	* access to MWI W5 raw data
	
* TO DO:
	* STOP AT 264 at labor days 

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
* 3 - soil and erosion and slope and wetlands
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
	tab				ag_d25_oth
	recode 			ag_d25a (9=1) if inlist(ag_d25_oth,"NO SOIL EROSION CONTROL")
	recode 			ag_d25a (9=3) if inlist(ag_d25_oth,"BOX RIDGES","RIDGES")
	recode 			ag_d25a (9=5) if inlist(ag_d25_oth,"PLANTED ELEPHANT GRASS","PLANTED GRASS SUGAR CANE","PLANTED KAPINGA","PLANTED KHONJE (SISAL)","PLANTED OTHER GRASS","PLANTED SISAL")
	recode 			ag_d25a (9=6) if inlist(ag_d25_oth,"PLANTED BAMBOO")
	recode 			ag_d25a (9=8) if inlist(ag_d25_oth,"WATER CHAINS","WATER WAY")
	list 			ag_d25a ag_d25b ag_d25_oth if ag_d25_oth == "BOX RIDGES AND ELEPHANT GRASS"
	recode 			ag_d25a (9=3) if ag_d25_oth =="BOX RIDGES AND ELEPHANT GRASS"
	recode 			ag_d25b (9=5) if ag_d25_oth =="BOX RIDGES AND ELEPHANT GRASS"
	recode 			ag_d25b (9=5) if inlist(ag_d25_oth,"PLANTED ELEPHANT GRASS","PLANTED SISAL")
	*** effectively no changes made in this process 
	
* make dummies for various erosion control structures 
	egen 			swc_terrace = anymatch(ag_d25a ag_d25b), values(2)
	label 			variable swc_terrace		"Plot has terraces to control erosion" 
	egen 			swc_bund_ec = anymatch(ag_d25a ag_d25b), values(3)
	label 			variable swc_bund_ec		"Plot has bunds to control erosion"
	egen 			swc_bund_wh = anymatch(ag_d25a ag_d25b), values(7)
	label 			variable swc_bund_wh		"Plot has bunds to harvest water"

* differentiation between bunds on basis of their intended use may be an overly fine distinction for some analyses 
	egen 			swc_bund_any = anymatch(ag_d25a ag_d25b), values(3 7)
	label 			variable swc_bund_any "plot has bunds"
	egen 			swc_gabion = anymatch(ag_d25a ag_d25b), values(4)
	label 			variable swc_gabion	"plot has gabions/sandbags to control erosion"
	egen 			swc_vetiver = anymatch(ag_d25a ag_d25b), values(5)
	label 			variable swc_vetiver "plot has vetiver grass to control erosion"
	egen 			swc_treebelt = anymatch(ag_d25a ag_d25b), values(6)
	label 			variable swc_treebelt "plot has tree belts to control erosion"
	egen 			swc_drainage = anymatch(ag_d25a ag_d25b), values(8)
	label 			variable swc_drainage "plot has drainage ditches to control erosion"

* make some overall categories 
	egen 			swc_any = anymatch(ag_d25a ag_d25b), values(2 3 4 5 6 7 8)
	label 			variable swc_any "plot has any erosion control structure"
	egen 			swc_mech = anymatch(ag_d25a ag_d25b), values(2 3 4 7 8)
	label 			variable swc_mech "plot has many mechanical erosion control structure"
	egen 			swc_bio = anymatch(ag_d25a ag_d25b), values(5 6)
	label 			variable swc_bio "plot has any biological erosion control measures"

* slope of plot
	tabulate 		ag_d26, missing
	generate 		slope = ag_d26
	label 			values slope slope
	label 			variable slope "predominant slope of plot" 
	bysort 			region: egen modeslope = mode(slope), minmode
	replace 		slope = modeslope if missing(slope)
	*** 59 changes 
	drop 			modeslope 

* plot is in dambo area
	tabulate 		ag_d27, missing
	generate 		dambo = 1 if ag_d27 == 1
	replace			dambo = 0 if dambo == . 
	label 			variable dambo "plot is in swamp/wetland" 
	
* **********************************************************************
* 4 - fertilizer
* **********************************************************************

* omitting kgs of organic as there is no reliable conversion factor 

* inorganic
	tab 			ag_d38
	describe 		ag_d38*
	tabstat 		ag_d39a ag_d39b ag_d39d ag_d39e ag_d39f ag_d39g ag_d39i ag_d39j, by(ag_d38) statistics(n mean) columns(statistics) longstub format(%9.3g)
	
* as an intermediate step, make dummies for non-missing type and quantity 
* details for a first application and second application. 
	generate 		fert_inorg1 = (!missing(ag_d39a) & !missing(ag_d39b) & !missing(ag_d39c))	
	*** type, quantity and unit for first application are non-missing
	generate 		fert_inorg2 = (!missing(ag_d39f) & !missing(ag_d39g) & !missing(ag_d39h))	
	*** type, quantity and unit for second application are non-missing

	generate 		fert_inorg_any = (fert_inorg1==1 | fert_inorg2==1)
	label 			variable fert_inorg_any	"inorganic fertilizer was applied on plot"

	egen 			fert_inorg_n = rowtotal(fert_inorg1 fert_inorg2)
	label 			variable fert_inorg_n "number of applications of inorganic fertilizer on plot"

	drop 			fert_inorg1 fert_inorg2
	
* **********************************************************************
* 5 - irrigation
* **********************************************************************
	
	tabulate 		ag_d28a ag_d28b, missing
	tabulate 		ag_d28_oth 
	egen 			irrigation_any = anymatch(ag_d28a ag_d28b), values(1 2 3 4 5 6 8) 
	replace			irrigation_any = 0 if ag_d28a == 7
	label 			variable irrigation_any	"plot has any system of irrigation" 

* **********************************************************************
* 6 - pesticide, insecticide, fungicide 
* **********************************************************************

* pesticide, disaggregating by type (insecticide, herbicide, fungicide) 
	tabulate 		ag_d40, missing
	describe 		ag_d41*
	tabulate 		ag_d41a, missing
	tabulate 		ag_d41a_oth if ag_d41a=="OTHER PESTICIDE/HERBICIDE(SPECIFY)":AG_D35A
	recode 			ag_d41a (11=8) if inlist(ag_d41a_oth,"2.4D","BULLET","ROUNDUP")
	summarize 		ag_d41b ag_d41c 

* dummies for use of one of three pesticide types 
	generate 		insecticide_any =	((ag_d41a == 7 & !missing(ag_d41b) & !missing(ag_d41c)) ///
						| (ag_d41e == 7 & !missing(ag_d41f) & !missing(ag_d41g)))
	label 			variable insecticide_any "insecticide was applied on plot" 
	generate 		herbicide_any =	((ag_d41a == 8 & !missing(ag_d41b) & !missing(ag_d41c)) ///
						| (ag_d41e == 8 & !missing(ag_d41f) & !missing(ag_d41g)))
	label 			variable herbicide_any "herbicide was applied on plot" 
	generate 		fungicide_any =	((ag_d41a == 9  & !missing(ag_d41b) & !missing(ag_d41c)) ///
						| (ag_d41e == 9 & !missing(ag_d41f) & !missing(ag_d41g)))
	label 			variable fungicide_any "fungicide was applied on plot" 

* make overall pesticide dummy, which also includes fumigants and 'other, specify' types 
	generate 		pesticide_any =	((!missing(ag_d41a) & !missing(ag_d41b) & !missing(ag_d41c)) ///
						| (!missing(ag_d41e) & !missing(ag_d41f) & !missing(ag_d41g)))
	label 			variable pesticide_any	"any pesticide was applied on plot" 
	

* **********************************************************************
* 7 - labor days
* **********************************************************************

* family labor days
		describe 		ag_d42*	ag_d43* ag_d44* 
		*** includes land prep and planting; weeding, fertilizing, other non-harvest; and harvest 

* family labor during land prep / planting
		describe 		ag_d42*	
		generate 		famlbrdays1_1 = ag_d42b1*ag_d42c1	
		generate 		famlbrdays1_2 = ag_d42b2*ag_d42c2 	
		generate 		famlbrdays1_3 = ag_d42b3*ag_d42c3 	
		generate 		famlbrdays1_4 = ag_d42b4*ag_d42c4 	
		generate 		famlbrdays1_5 = ag_d42b5*ag_d42c5 	
		generate 		famlbrdays1_6 = ag_d42b6*ag_d42c6 	
		generate 		famlbrdays1_7 = ag_d42b7*ag_d42c7 	
		generate 		famlbrdays1_8 = ag_d42b8*ag_d42c8 	
		generate 		famlbrdays1_9 = ag_d42b9*ag_d42c9 	
		generate 		famlbrdays1_10 = ag_d42b10*ag_d42c10 	
		generate 		famlbrdays1_11 = ag_d42b11*ag_d42c11 	
		tabstat 		famlbrdays1_1 famlbrdays1_2 famlbrdays1_3 famlbrdays1_4 famlbrdays1_5 famlbrdays1_6 ///
							famlbrdays1_7 famlbrdays1_8 famlbrdays1_9 famlbrdays1_10 famlbrdays1_11 , ///
							statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		egen famlbrdays1 = rowtotal(famlbrdays1_1 famlbrdays1_2 famlbrdays1_3 famlbrdays1_4 famlbrdays1_5 famlbrdays1_6 ///
							famlbrdays1_7 famlbrdays1_8 famlbrdays1_9 famlbrdays1_10 famlbrdays1_11)
		
* family labor during weeding / fertilizing / other non-harvest activity	
		describe 		ag_d43*	
		generate 		famlbrdays2_1 = ag_d43b1*ag_d43c1	
		generate 		famlbrdays2_2 = ag_d43b2*ag_d43c2 	
		generate 		famlbrdays2_3 = ag_d43b3*ag_d43c3 	
		generate 		famlbrdays2_4 = ag_d43b4*ag_d43c4 	
		generate 		famlbrdays2_5 = ag_d43b5*ag_d43c5 	
		generate 		famlbrdays2_6 = ag_d43b6*ag_d43c6 	
		generate 		famlbrdays2_7 = ag_d43b7*ag_d43c7 	
		generate 		famlbrdays2_8 = ag_d43b8*ag_d43c8 	
		generate 		famlbrdays2_9 = ag_d43b9*ag_d43c9 	
		generate 		famlbrdays2_10 = ag_d43b10*ag_d43c10 	
		generate 		famlbrdays2_11 = ag_d43b11*ag_d43c11 	
		tabstat 		famlbrdays2_1 famlbrdays2_2 famlbrdays2_3 famlbrdays2_4 famlbrdays2_5 famlbrdays2_6 ///
							famlbrdays2_7 famlbrdays2_8 famlbrdays2_9 famlbrdays2_10 famlbrdays2_11 , ///
							statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		egen famlbrdays2 = rowtotal(famlbrdays2_1 famlbrdays2_2 famlbrdays2_3 famlbrdays2_4 famlbrdays2_5 famlbrdays2_6 ///
							famlbrdays2_7 famlbrdays2_8 famlbrdays2_9 famlbrdays2_10 famlbrdays2_11)

* family labor during harvest
		describe 		ag_d44* 	
		generate 		famlbrdays3_1 = ag_d44b1*ag_d44c1	
		generate 		famlbrdays3_2 = ag_d44b2*ag_d44c2 	
		generate 		famlbrdays3_3 = ag_d44b3*ag_d44c3 	
		generate 		famlbrdays3_4 = ag_d44b4*ag_d44c4 	
		generate 		famlbrdays3_5 = ag_d44b5*ag_d44c5 	
		generate 		famlbrdays3_6 = ag_d44b6*ag_d44c6 	
		generate 		famlbrdays3_7 = ag_d44b7*ag_d44c7 	
		generate 		famlbrdays3_8 = ag_d44b8*ag_d44c8 	
		generate 		famlbrdays3_9 = ag_d44b9*ag_d44c9 	
		generate 		famlbrdays3_10 = ag_d44b10*ag_d44c10 	
		generate 		famlbrdays3_11 = ag_d44b11*ag_d44c11 	
		tabstat 		famlbrdays3_1 famlbrdays3_2 famlbrdays3_3 famlbrdays3_4 famlbrdays3_5 famlbrdays3_6 ///
							famlbrdays3_7 famlbrdays3_8 famlbrdays3_9 famlbrdays3_10 famlbrdays3_11 , ///
							statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		egen famlbrdays3 = rowtotal(famlbrdays3_1 famlbrdays3_2 famlbrdays3_3 famlbrdays3_4 famlbrdays3_5 famlbrdays3_6 ///
							famlbrdays3_7 famlbrdays3_8 famlbrdays3_9 famlbrdays3_10 famlbrdays3_11)

* aggregate family labor 							
		egen 			famlbrdays = rowtotal(famlbrdays1 famlbrdays2 famlbrdays3)
		summarize 		famlbrdays, detail
		list 			case_id plotid famlbrdays1 famlbrdays2 famlbrdays3 if famlbrdays>300
		*** does not address at this point in the code 
		*** somewhere in the neighbhorhood of 85 or so? 
				
* hired labor days
		describe 		ag_d46* ag_d47* ag_d48*
		*** includes land prep and planting; weeding, fertilizing, other non-harvest; and harvest 
		*** includes adult males, adult females, and children 
		
* hired labor during land prep and planting 		
		egen 			hirelbrdays1 = rowtotal(ag_d46a1 ag_d46a2 ag_d46a3)	
		tabstat 		hirelbrdays1, statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		
* hired labor during weeding, fertilizing, and other non-harvest 
		egen 			hirelbrdays2 = rowtotal(ag_d47a1 ag_d47a2 ag_d47a3)	
		tabstat 		hirelbrdays2, statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		
* hired labor during harvest
		egen 			hirelbrdays3 = rowtotal(ag_d48a1 ag_d48a2 ag_d48a3)	
		tabstat 		hirelbrdays3, statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub
		
* aggregate hired labor 
		egen 			hirelbrdays = rowtotal(hirelbrdays1 hirelbrdays2 hirelbrdays3)
		summarize 		hirelbrdays, detail
		list 			case_id plotid hirelbrdays1 hirelbrdays2 hirelbrdays3 if hirelbrdays>100
		*** about 106 total 
		list 			case_id plotid hirelbrdays1 hirelbrdays2 hirelbrdays3 if hirelbrdays>150
		*** about 59 total 
		
		
* free labor / exchange days
		describe 		ag_d50* ag_d51*	
		*** all activities, for adult males, adult females, and children

* exchange days 		
		egen 			freelbrdays1 = rowtotal(ag_d50a ag_d50b ag_d50c)		
		tabstat 		freelbrdays1, statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub

* free days 
		egen 			freelbrdays2 = rowtotal(ag_d51a ag_d51b ag_d51c)		
		tabstat 		freelbrdays2, statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub

* aggregate free labor
		egen 			freelbrdays = rowtotal(freelbrdays1 freelbrdays2)
		summarize 		freelbrdays, detail
		list 			case_id plotid freelbrdays1 freelbrdays2 if freelbrdays>50
		*** 29 total 
		
* total days of labor on all activities from all sources
		egen 			labordays = rowtotal(famlbrdays hirelbrdays freelbrdays)
		summarize 		labordays, detail
		list 			case_id plotid famlbrdays hirelbrdays freelbrdays if labordays>300
		*** somewhere aroudn 120-130 

* outlier checks without add'l information
		label 			variable labordays		"days of labor on plot" 

* hire labor dummy
	generate 			hirelabor_any = (hirelbrdays>0)
	label 				variable hirelabor_any	"any labor hired on plot" 

* the cover crop and tillage questions are not available in IHS3
* not included here in line with that
* and we do not really use in this project

* **********************************************************************
* 8 - end matter, clean up to save
* **********************************************************************

	keep  			case_id plotid gardenid HHID crop_cash soiltype swc_* slope dambo irrigation_any fert_inorg_any ///
						fert_inorg_n insecticide_any herbicide_any fungicide_any pesticide_any labordays hirelabor_any
	order 			case_id plotid gardenid HHID crop_cash soiltype swc_* slope dambo irrigation_any fert_inorg_any ///
						fert_inorg_n insecticide_any herbicide_any fungicide_any pesticide_any labordays hirelabor_any

	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_d.dta", replace

* close the log
	log			close

/* END */