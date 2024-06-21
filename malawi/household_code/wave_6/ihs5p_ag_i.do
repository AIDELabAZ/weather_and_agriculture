* Project: WB Weather
* Created on: March 2024
* Created by: alj
* Edited on: 3 June 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop price / sales information 
	* directly follow from ag_i code - by JB

* assumes
	* access to MWI W6 raw data
	
* TO DO:
	* done 

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_6/raw"	
	loc		export 	= 	"$data/household_data/malawi/wave_6/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"
	loc 	temp 	= 	"$data/household_data/malawi/wave_6/tmp"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_ag_mod_i_19", append


* **********************************************************************
* 1 - setup to clean plot  
* **********************************************************************

* load data
	use 			"`root'/ag_mod_i_19.dta", clear
	
* describe 
	describe
	sort 			y4_hhid crop_code
	capture : 		noisily : isid y4_hhid crop_code, missok	
	*** not yet identified at household x plot level, but with missing plot id
	duplicates 		report y4_hhid crop_code
	*** no surplus (no dups)

* generate variables for merge with conversion factor database 
	generate 		unit      = ag_i02b
	generate 		condition = ag_i02c
	tabulate 		crop_code if !missing(crop_code) & !missing(ag_i02b) & !missing(ag_i02c), plot
	drop 			if missing(crop_code)	
	*** restrict dataset to the set of observations where crop is recorded
	*** 25 observations dropped

* get rid of condition information where it was entered inappropriately
	recode 			condition (1 2 = 3) if inlist(crop_code,5,28,31,32,33,37,42) 
	*** 74 observations redone

* bring in spatial variables for merge merge to conversion factor database
	merge m:1 y4_hhid using "`root'/hh_mod_a_filt_19.dta", keepusing(region district reside) assert(2 3) keep(3) nogenerate
	*** (all) 7264 matched
	
	gen unit_code = ag_i02b
	tostring unit_code, replace

	replace region = region/100
	
* bring in conversion factor to construct quantity 
	merge m:1 crop_code region unit_code condition using "`root'/ihs_seasonalcropconversion_factor_2020_up.dta", keep(1 3) generate(_conversion)	
	*** only 1636 matched
	tabulate 		crop_code unit_code if _conversion==1
	drop 			_conversion
	*** of not matched - MANY sell nothing 
	
* also include other conversion code 
	generate		conversion_other = . 
	replace 		ag_i02b_oth = strlower(ag_i02b_oth)
	*** 33 changes
	*** making uppercase lowercase instead
	replace			conversion_other = 90 if strpos(ag_i02b_oth, "90") > 0 
	*** 7 changes
	replace			conversion_other = 60 if strpos(ag_i02b_oth, "60") > 0 
	*** 0 changes
	replace			conversion_other = 70 if strpos(ag_i02b_oth, "70") > 0 
	*** 4 changes
	replace			conversion_other = 5 if strpos(ag_i02b_oth, "5") > 0 	
	*** 3 changes 
	replace			conversion_other = 30 if strpos(ag_i02b_oth, "30") > 0 
	*** 0 changes
	replace			conversion_other = 40 if strpos(ag_i02b_oth, "40") > 0 	
	*** 0 change 
	
* **********************************************************************
* 2 - clean for crop type 
* **********************************************************************
	
* make condensed crop codes
	inspect 		crop_code
	recode crop_code (5/10=5)(11/16=11)(17/26=17), generate(cropid)
	*** 658 differences between crop_code and cropid

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

	label 			values cropid cropid
	inspect 		cropid	

* **********************************************************************
* 3 - clean for harvest  
* **********************************************************************
		
* make sale quantity
	generate 		quant = ag_i02a * conversion 
	*** 5628 missing values generated
	replace			quant = ag_i02a * conversion_other if quant == .
	*** 14 changes 
	drop 			if quant == . 
	tabstat 		quant, by(cropid) statistics(n min p50 max) columns(statistics) format(%9.3g)
	bysort 			cropid : egen median = median(quant)
	bysort 			cropid : egen stddev = sd(quant)
	generate 		quantoutlier = ((quant > median+(3*stddev)) | (quant < median-(3*stddev)))
	list 			cropid quant if quantoutlier==1 & !missing(quant), sepby(cropid) 
	drop 			median stddev quantoutlier
	*** we will do imputations with quantity / plot area 

* make self-reported unit value
	generate 		cropprice = ag_i03 / quant
	label 			variable cropprice	"Self-Reported unit value of crops sold"
	tabstat 		cropprice, by(cropid) statistics(n min p50 max) columns(statistics) format(%9.3g) 
	bysort 			cropid : egen median = median(cropprice)
	bysort 			cropid : egen stddev = sd(cropprice)
	generate 		croppriceoutlier = ((cropprice > median+(3*stddev)) | (cropprice < median-(3*stddev)))
	list 			cropid quant ag_i03 cropprice if croppriceoutlier==1 & !missing(cropprice), sepby(cropid) 
	drop 			median stddev croppriceoutlier
	
* **********************************************************************
* 4 - prices
* **********************************************************************

* make datasets with crop price information
* in other files "ta" exists, but that is not represented in wave 5, so omitted from this process 

	preserve
		collapse (p50) p_ea = cropprice (count) n_ea=cropprice, by(cropid reside region district y4_hhid)
		save "`temp'/ag_i1.dta", replace 
	restore
	
	preserve
		collapse (p50) p_dst = cropprice (count) n_ta=cropprice, by(cropid reside region district)
		save "`temp'/ag_i2.dta", replace 
	restore
	
	preserve
		collapse (p50) p_rgn = cropprice (count) n_dst=cropprice, by(cropid reside region)
		save "`temp'/ag_i3.dta", replace 
	restore
	
	preserve
		collapse (p50) p_urb = cropprice (count) n_rgn=cropprice, by(cropid reside)
		save "`temp'/ag_i4.dta", replace 
	restore
	
	preserve
		collapse (p50) p_crop = cropprice (count) n_urb=cropprice, by(cropid)
		save "`temp'/ag_i5.dta", replace 
	restore

* merge price data back into dataset
	merge m:1 cropid reside region district y4_hhid  using "`temp'/ag_i1.dta", assert(3) nogenerate
	merge m:1 cropid reside region district       using "`temp'/ag_i2.dta", assert(3) nogenerate
	merge m:1 cropid reside region           	  using "`temp'/ag_i3.dta", assert(3) nogenerate
	merge m:1 cropid reside                    	  using "`temp'/ag_i4.dta", assert(3) nogenerate
	merge m:1 cropid                           	  using "`temp'/ag_i5.dta", assert(3) nogenerate

* make imputed price, using median price where we have at least 10 observations
	tabstat 		n_ea p_ea n_dst p_dst n_rgn p_rgn n_urb p_urb p_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	generate 		croppricei = .
	replace 		croppricei = p_ea if n_ea>=10
	*** 0 changes
	replace 		croppricei = p_dst if n_dst>=10 & missing(croppricei)
	*** 1507 changes
	replace 		croppricei = p_rgn if n_rgn>=10 & missing(croppricei)
	*** 87 changes
	replace 		croppricei = p_urb if n_urb>=10 & missing(croppricei)
	*** 36 changes
	replace 		croppricei = p_crop if missing(croppricei)
	*** 20 changes
	label 			variable croppricei	"imputed unit value of crop"

* make total value of all household crop sales
	replace 		cropprice = croppricei if missing(cropprice) & !missing(quant) 
	bysort 			y4_hhid (cropid) : egen cropsales_value = sum(quant * cropprice)
	label 			variable cropsales_value	"self-reported value of crop sales" 
	bysort 			y4_hhid (cropid) : egen cropsales_valuei = sum(quant * croppricei)
	label 			variable cropsales_valuei	"imputed value of crop sales" 

* restrict to one observation per crop
	bysort y4_hhid (cropid) : keep if _n==1
	*** 532 observations deleted

* **********************************************************************
* 5 - end matter, clean up to save
* **********************************************************************

* restrict to variables of interest 
	keep  			y4_hhid cropsales_value cropsales_valuei
	order 			y4_hhid cropsales_value cropsales_valuei
	
	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_i.dta", replace

* close the log
	log			close

/* END */