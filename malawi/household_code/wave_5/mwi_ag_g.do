* Project: WB Weather
* Created on: Feb 2024
* Created by: alj
* Edited on: 8 May 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop harvest information 
	* directly follow from ag_g code - by JB

* assumes
	* access to MWI W5 raw data
	
* TO DO:
	* complete
	* file merge issue line 100 

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_5/raw"	
	loc		export 	= 	"$data/household_data/malawi/wave_5/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_ag_mod_g", append


* **********************************************************************
* 1 - clean for conversion 
* **********************************************************************

* load data
	use 			"`root'/ag_mod_g.dta", clear
	
	capture 		: noisily : isid case_id gardenid plotid crop_code, missok	
	*** not yet identified at household x plot level, but with missing plot id
	duplicates 		report case_id gardenid plotid crop_code
	* none 

* identify cases where units do not match
	bysort 			case_id gardenid plotid crop_code : egen min9 = min(ag_g13b)
	bysort 			case_id gardenid plotid crop_code : egen max9 = max(ag_g13b)	
	generate 		flag2 = ((min9!=max9)) 
	*** 0 observations 
	* list			case_id gardenid plotid crop_code if flag2==1, sepby(case_id)	
	
	generate 		hasall  = (!mi(ag_g13a) & !mi(ag_g13b) & !mi(ag_g13c))
	generate 		hassome = (!mi(ag_g13a) | !mi(ag_g13b) | !mi(ag_g13c))
	tabulate 		hasall hassome
	tabulate		hasall
	*** 32,688 total - 0 = 1800 (5.5%), 1 = 30877 (94.5%)
	tabulate 		hassome 
	*** 32677 total - 0 = 68 (0.21%), 1 = 32609 (99.8%) 
	drop 			hasall hassome
	
* generate variables for merge with conversion factor database
	generate 		unit = ag_g13b
* about 600 observations with _oth - many with kgs but "odd sizes" 
	generate		conversion_other = . 
	replace 		ag_g13b_oth = strlower(ag_g13b_oth)
	*** 312 changes
	*** making uppercase lowercase instead
	replace			conversion_other = 90 if strpos(ag_g13b_oth, "90") > 0 
	*** 179 changes
	replace			conversion_other = 60 if strpos(ag_g13b_oth, "60") > 0 
	*** 3 changes
	replace			conversion_other = 70 if strpos(ag_g13b_oth, "70") > 0 
	*** 49 changes
	replace			conversion_other = 80 if strpos(ag_g13b_oth, "80") > 0 
	*** 1 change
	replace			conversion_other = 90 if strpos(ag_g13b_oth, "09") > 0 
	*** 1 change
	replace			conversion_other = 10 if strpos(ag_g13b_oth, "10") > 0 	
	*** 1 change 
	replace			conversion_other = 5 if strpos(ag_g13b_oth, "5") > 0 	
	*** 19 changes 
	replace			conversion_other = 20 if strpos(ag_g13b_oth, "20") > 0 	
	*** 1 change
	replace			conversion_other = 30 if strpos(ag_g13b_oth, "30") > 0 
	*** 2 changes
	replace			conversion_other = 40 if strpos(ag_g13b_oth, "40") > 0 	
	*** 5 changes 
 * condition (shelled / unshelled)
	generate 		condition = ag_g13c
* drop 			if missing(crop_code,unit,condition)		
	recode 			condition (1 2 = 3) if inlist(crop_code,5,28,31,32,33,37,42)
	*** 2231 changes made 
	
* prepare for conversion 
* need district variables 
	merge m:1 case_id using "`root'/hh_mod_a_filt.dta", keepusing(region) assert (2 3) keep (3) nogenerate	
	
* bring in conversion file 
	merge m:1 crop_code region unit condition using "`root'/ihs_seasonalcropconversion_factor_2020_up.dta", keep(1 3) generate(_conversion)
	
	tabulate 		crop_code unit if _conversion==1
	*** could drop if == 1, but we know that we have some of these, from conversion_other - so will keep
	*** 24,274 matched, 8,403 not matched
	
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
	*** 24274 observations (and another 8403 to missing)
	
	*** WHY UNIT == 13? 
	replace			harv = ag_g13a * conversion_other if unit == 13 & harv == . 
	*** 24 changes made
	bysort 			case_id HHID gardenid plotid unit cropid : egen harvest = sum(harv)
	label 			variable harvest "Harvest quantity (kg)" 

* instance of harvest area reported less than planted area
	tabulate 		ag_g10, missing
	bysort 			case_id unit cropid : egen harvest_losses = max(ag_g10=="YES":L01)
	label 			variable harvest_losses	"Harvested area less than planted area"

* legume intercropping at plot level 
	label 			list cropid	
	bysort 			case_id unit (cropid) : egen max = max(cropid)
	*** 26 missing values generated
	bysort 			case_id unit (cropid) : egen min = min(cropid)
	*** 26 missing values generated 
	egen 			legume = anymatch(cropid), values(11 27 34/36)			
	*** indicates that crop is a legume 
	bysort 			case_id unit (cropid) : egen plot_legume = max(legume)
	generate 		intercrop_legume = (min!=max & plot_legume==1)
	label 			variable intercrop_legume "Plot was intercropped with legumes"

* restrict to one observation per plot per crop
	bysort 			case_id plotid gardenid cropid : keep if _n==1
	*** 9 observations deleted 
	
* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************

* restrict to variables of interest 
	keep  			case_id HHID plotid gardenid cropid harvest harvest_losses intercrop_legume
	order 			case_id HHID plotid gardenid cropid harvest harvest_losses intercrop_legume
	
	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_g.dta", replace

* close the log
	log			close

/* END */