* Project: WB Weather
* Created on: Feb 2024
* Created by: alj
* Edited on: 24 May 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop harvest information 
	* directly follow from ag_g code - by JB

* assumes
	* access to MWI W5 raw data
	
* TO DO:
	* complete

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		root 	= 	"$data/household_data/malawi/wave_6/raw"	
	global		export 	= 	"$data/household_data/malawi/wave_6/refined"
	global		logout 	= 	"$data/household_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"$logout/mwi_ag_mod_g_19", append


* **********************************************************************
* 1 - clean for conversion 
* **********************************************************************

* load data
	use 			"$root/ag_mod_g_19.dta", clear
	
	capture 		: noisily : isid y4_hhid gardenid plotid crop_code, missok	
	duplicates 		report y4_hhid gardenid plotid crop_code
	* none 

* identify cases where units do not match
	bysort 			y4_hhid gardenid plotid crop_code : egen min9 = min(ag_g13b)
	*** 882 missing
	bysort 			y4_hhid gardenid plotid crop_code : egen max9 = max(ag_g13b)
	*** 882 missing
	generate 		flag2 = ((min9!=max9)) 
	*** 0 observations 
	* list			case_id gardenid plotid crop_code if flag2==1, sepby(case_id)	
	
	generate 		hasall  = (!mi(ag_g13a) & !mi(ag_g13b) & !mi(ag_g13c))
	generate 		hassome = (!mi(ag_g13a) | !mi(ag_g13b) | !mi(ag_g13c))
	tabulate 		hasall hassome
	tabulate		hasall
	*** 9984 total - 0 = 885, 1 = 9099 
	tabulate 		hassome 
	drop 			hasall hassome
	
* generate variables for merge with conversion factor database
	generate 		unit = ag_g13b
* about 600 observations with _oth - many with kgs but "odd sizes" 
	generate		conversion_other = . 
	replace 		ag_g13b_oth = strlower(ag_g13b_oth)
	*** 33 changes
	*** making uppercase lowercase instead
	replace			conversion_other = 90 if strpos(ag_g13b_oth, "90") > 0 
	*** 0 changes
	replace			conversion_other = 60 if strpos(ag_g13b_oth, "60") > 0 
	*** 1 changes
	replace			conversion_other = 70 if strpos(ag_g13b_oth, "70") > 0 
	*** 22 changes
	replace			conversion_other = 80 if strpos(ag_g13b_oth, "80") > 0 
	*** 0 change
	replace			conversion_other = 90 if strpos(ag_g13b_oth, "09") > 0 
	*** 0 change
	replace			conversion_other = 10 if strpos(ag_g13b_oth, "10") > 0 	
	*** 0 change 
	replace			conversion_other = 5 if strpos(ag_g13b_oth, "5") > 0 	
	*** 26 changes 
	replace			conversion_other = 20 if strpos(ag_g13b_oth, "20") > 0 	
	*** 2 change
	replace			conversion_other = 30 if strpos(ag_g13b_oth, "30") > 0 
	*** 0 changes
	replace			conversion_other = 40 if strpos(ag_g13b_oth, "40") > 0 	
	*** 1 changes 
 * condition (shelled / unshelled)
	generate 		condition = ag_g13c
	**** 884 missing
* drop 			if missing(crop_code,unit,condition)		
	recode 			condition (1 2 = 3) if inlist(crop_code,5,28,31,32,33,37,42)
	*** 681 changes made 
	
* prepare for conversion 
* need district variables 
	merge m:1 y4_hhid using "$root/hh_mod_a_filt_19.dta", keepusing(region) assert (2 3) keep (3) nogenerate	
	**** 9984 = all matched
	
	gen unit_code = ag_g13b
	tostring unit_code, replace
	
	replace region = region/100

* bring in conversion file 
	merge m:1 crop_code region unit_code condition using "$root/ihs_seasonalcropconversion_factor_2020.dta"
	*** 7313 matched, 2671 not matched = 1, 614 not matched = 2
	drop if _merge == 2 
	tabulate 		crop_code unit if _merge==1
	*** could drop if == 1, but we know that we have some of these, from conversion_other - so will keep
	
* **********************************************************************
* 2 - clean for crop  
* **********************************************************************
	
* make condensed crop codes
	inspect 		crop_code
	recode crop_code (5/10=5)(11/16=11)(17/26=17), generate(cropid)
	*** 2356 differences between crop_code and cropid

* define cropid label for common cropid across survey rounds
* this is adapted from file "label_cropid.do" in "tools" in MWI kitchen sink 
#delimit
label define cropid
	1 "Maize Local"
	2 "Maize Composite/OPV"
	3 "Maize Hybrid"
	4 "Maize Hybrid Recycled"
	5 "Tobacco"
	11 "Groundnut" 
	17 "Rice" 
	27 "Ground Bean (Nzama)" 
	28 "Sweet Potato" 
	29 "Irish (Malawi) Potato"
	30 "Wheat"
	31 "Finger Millet (Mawere)"
	32 "Sorghum"
	33 "Pearl Millet (Mchewere)"
	34 "Beans"
	35 "Soyabean" 
	36 "Pigeon Pea (Nandolo)"
	37 "Cotton"
	38 "Sunflower"
	39 "Sugar Cane"
	40 "Cabbage"
	41 "Tanaposi"
	42 "Pumpkin Leaves (Nkhwani)"
	43 "Okra (Therere)"
	44 "Tomato"
	45 "Onion"
	46 "Pea"
	47 "Paprika"
	48 "Other (Specify)"
	;
#delimit cr

	label 		values cropid cropid
	inspect 	cropid
	
* **********************************************************************
* 3 - clean for harvest  
* **********************************************************************
		
* make harvest quantity
	generate 		harv = ag_g13a * conversion
	*** 10598 observations (with 3258 to missing)
	
	*** WHY UNIT == 13? 
	replace			harv = ag_g13a * conversion_other if unit == 13 & harv == . 
	*** 85 changes made
	bysort 			y4_hhid gardenid plotid unit cropid : egen harvest = sum(harv)
	label 			variable harvest "Harvest quantity (kg)" 

* instance of harvest area reported less than planted area
	tabulate 		ag_g10, missing
	bysort 			y4_hhid unit cropid : egen harvest_losses = max(ag_g10=="YES":L01)
	label 			variable harvest_losses	"Harvested area less than planted area"

* legume intercropping at plot level 
	label 			list cropid	
	bysort 			y4_hhid unit (cropid) : egen max = max(cropid)
	*** 6 missing values generated
	bysort 			y4_hhid unit (cropid) : egen min = min(cropid)
	*** 6 missing values generated 
	egen 			legume = anymatch(cropid), values(11 27 34/36)			
	*** indicates that crop is a legume 
	bysort 			y4_hhid unit (cropid) : egen plot_legume = max(legume)
	generate 		intercrop_legume = (min!=max & plot_legume==1)
	label 			variable intercrop_legume "Plot was intercropped with legumes"

* restrict to one observation per plot per crop
	bysort 			y4_hhid plotid gardenid cropid : keep if _n==1
	*** 596 observations deleted 
	
* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************

* restrict to variables of interest 
	keep  			y4_hhid plotid gardenid cropid harvest harvest_losses intercrop_legume
	order 			y4_hhid plotid gardenid cropid harvest harvest_losses intercrop_legume
	
	compress
	describe
	summarize 
	
* save data
	save 			"$export/ag_mod_g_19.dta", replace

* close the log
	log			close

/* END */