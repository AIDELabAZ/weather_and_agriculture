* Project: WB Weather
* Created on: March 2024
* Created by: alj
* Edited on: 6 March 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop price / sales information 
	* directly follow from ag_i code - by JB

* assumes
	* access to MWI W5 raw data
	
* TO DO:
	* same issues as in mwi_ag_g - links not working???

* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_5/raw"	
	loc		export 	= 	"$data/household_data/malawi/wave_5/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"`logout'/mwi_ag_mod_i", append


* **********************************************************************
* 1 - setup to clean plot  
* **********************************************************************

* load data
	use 			"`root'/ag_mod_i.dta", clear
	
* describe 
	describe
	sort 			case_id crop_code
	capture : 		noisily : isid case_id crop_code, missok	
	*** not yet identified at household x plot level, but with missing plot id
	duplicates 		report case_id crop_code
	*** no surplus (no dups)

* generate variables for merge with conversion factor database 
	generate 		unit      = ag_i02b
	generate 		condition = ag_i02c
	tabulate 		crop_code if !missing(crop_code) & !missing(ag_i02b) & !missing(ag_i02c), plot
	drop 			if missing(crop_code)	
	*** restrict dataset to the set of observations where crop is recorded
	*** 19 observations dropped

* get rid of condition information where it was entered inappropriately
	recode 			condition (1 2 = 3) if inlist(crop_code,5,28,31,32,33,37,42) 
	*** 272 observations redone

* bring in spatial variables for merge merge to conversion factor database
	merge m:1 case_id using "$`root'/hh_mod_a_filt.dta'", keepusing(region district reside) assert(2 3) keep(3) nogenerate
	*** (all) 26120 matched
	
* bring in conversion factor to construct quantity 
	merge m:1 crop_code region unit condition using "$`root'/ihs_seasonalcropconversion_factor_2020_up.dta", keep(1 3) generate(_conversion)	
	tabulate 		crop_code unit if _conversion==1
	drop 			_conversion
	
* **********************************************************************
* 2 - clean for crop type 
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
		
*** carried code below

*	make sale quantity
generate quant = ag_i02a * conversion
tabstat quant, by(cropid) statistics(n min p50 max) columns(statistics) format(%9.3g)
bysort cropid : egen median = median(quant)
bysort cropid : egen stddev = sd(quant)
generate quantoutlier = ((quant > median+(3*stddev)) | (quant < median-(3*stddev)))
list cropid quant if quantoutlier==1 & !missing(quant), sepby(cropid) 
drop median stddev quantoutlier
	*	we will do imputations with quantity / plot area 


*	make self-reported unit value
generate cropprice = ag_i03 / quant
label variable cropprice	"Self-Reported unit value of crops sold"
tabstat cropprice, by(cropid) statistics(n min p50 max) columns(statistics) format(%9.3g) 
bysort cropid : egen median = median(cropprice)
bysort cropid : egen stddev = sd(cropprice)
generate croppriceoutlier = ((cropprice > median+(3*stddev)) | (cropprice < median-(3*stddev)))
list cropid quant ag_i03 cropprice if croppriceoutlier==1 & !missing(cropprice), sepby(cropid) 
drop median stddev croppriceoutlier


*	make datasets with crop price information
	preserve
collapse (p50) p_ea=cropprice (count) n_ea=cropprice, by(cropid urban region district ta ea_id)
save "${Malawi}/tmp/${database}/plot/ag_i1.dta", replace 
	restore
	preserve
collapse (p50) p_ta=cropprice (count) n_ta=cropprice, by(cropid urban region district ta)
save "${Malawi}/tmp/${database}/plot/ag_i2.dta", replace 
	restore
	preserve
collapse (p50) p_dst=cropprice (count) n_dst=cropprice, by(cropid urban region district)
save "${Malawi}/tmp/${database}/plot/ag_i3.dta", replace 
	restore
	preserve
collapse (p50) p_rgn=cropprice (count) n_rgn=cropprice, by(cropid urban region)
save "${Malawi}/tmp/${database}/plot/ag_i4.dta", replace 
	restore
	preserve
collapse (p50) p_urb=cropprice (count) n_urb=cropprice, by(cropid urban)
save "${Malawi}/tmp/${database}/plot/ag_i5.dta", replace 
	restore
	preserve
collapse (p50) p_crop=cropprice (count) n_crop=cropprice, by(cropid)
save "${Malawi}/tmp/${database}/plot/ag_i6.dta", replace 
	restore


*	merge price data back into dataset
merge m:1 cropid urban region district ta ea_id using "${Malawi}/tmp/${database}/plot/ag_i1.dta", assert(3) nogenerate
merge m:1 cropid urban region district ta       using "${Malawi}/tmp/${database}/plot/ag_i2.dta", assert(3) nogenerate
merge m:1 cropid urban region district          using "${Malawi}/tmp/${database}/plot/ag_i3.dta", assert(3) nogenerate
merge m:1 cropid urban region                   using "${Malawi}/tmp/${database}/plot/ag_i4.dta", assert(3) nogenerate
merge m:1 cropid urban                          using "${Malawi}/tmp/${database}/plot/ag_i5.dta", assert(3) nogenerate
merge m:1 cropid                                using "${Malawi}/tmp/${database}/plot/ag_i6.dta", assert(3) nogenerate

*	make imputed price, using median price where we have at least 10 observations
tabstat n_ea p_ea n_dst p_dst n_rgn p_rgn n_urb p_urb p_crop, by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
generate croppricei = .
replace croppricei = p_ea if n_ea>=10
replace croppricei = p_ta if n_ta>=10 & missing(croppricei)
replace croppricei = p_dst if n_dst>=10 & missing(croppricei)
replace croppricei = p_rgn if n_rgn>=10 & missing(croppricei)
replace croppricei = p_urb if n_urb>=10 & missing(croppricei)
replace croppricei = p_crop if missing(croppricei)
label variable croppricei	"Imputed unit value of crop"


*	make total value of all household crop sales
replace cropprice = croppricei if missing(cropprice) & !missing(quant) 
bysort case_id (cropid) : egen cropsales_value = sum(quant * cropprice)
label variable cropsales_value	"Self-reported value of crop sales" 
bysort case_id (cropid) : egen cropsales_valuei = sum(quant * croppricei)
label variable cropsales_valuei	"Implied value of crop sales" 


*	restrict to one observation per crop
bysort case_id (cropid) : keep if _n==1


*	Restrict to variables of interest 
keep  case_id cropsales_value cropsales_valuei
order case_id cropsales_value cropsales_valuei
	
	
* **********************************************************************
* ? - end matter, clean up to save
* **********************************************************************

* restrict to variables of interest 
	*keep  			case_id HHID plotid gardenid cropid harvest harvest_losses intercrop_legume
	*order 			case_id HHID plotid gardenid cropid harvest harvest_losses intercrop_legume
	
	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_i.dta", replace

* close the log
	log			close

/* END */