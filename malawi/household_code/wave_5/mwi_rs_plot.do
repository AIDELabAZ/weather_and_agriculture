* Project: WB Weather
* Created on: March 2024
* Created by: alj
* Edited on: 15 March 2024
* Edited by: alj 
* Stata v.18

* does
	* cleans crop price / sales information 
	* directly follow from rs_plot code - by JB

* assumes
	* access to MWI W5 raw data
	* access to previous files include g, i, c, d 
	
* TO DO:
	* done 
	* STOP AT 224

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
	log 	using 		"`logout'/mwi_ag_mod_rsplot", append


* **********************************************************************
* 1 - crop- and plot-level information, match to hh 
* **********************************************************************

* load data
	use 			"`export'/ag_mod_g.dta", clear
	merge m:1 case_id using "`root'/hh_mod_a_filt.dta", assert(2 3) keep(3) nogenerate	
	*** 26 observations missing cropid
	drop 			if cropid == . 
	*** 26 obs dropped
	isid 			case_id plotid cropid gardenid 
	*** dataset is identified at the household, plot, garden, crop level 
	

* **********************************************************************
* 2 - bring in price info 
* **********************************************************************

* merge price data into dataset
	merge m:1 cropid reside region district HHID  using "`temp'/ag_i1.dta", keep (1 3) nogenerate
	*** 25630 = 1, 7012 = 3
	merge m:1 cropid reside region district       using "`temp'/ag_i2.dta", keep (1 3) nogenerate
	*** 3065 = 1, 29577 = 3
	merge m:1 cropid reside region           	  using "`temp'/ag_i3.dta", keep (1 3) nogenerate
	*** 1598 = 1, 31044 = 3
	merge m:1 cropid reside                    	  using "`temp'/ag_i4.dta", keep (1 3) nogenerate
	*** 524 = 1 , 32118 = 3 
	merge m:1 cropid                           	  using "`temp'/ag_i5.dta", keep (1 3) nogenerate
	*** 32183 = 3 

* make imputed price, using median price where we have at least 10 observations
	tabstat 		n_ea p_ea n_dst p_dst n_rgn p_rgn n_urb p_urb p_crop, ///
						by(cropid) longstub statistics(n min p50 max) columns(statistics) format(%9.3g) 
	generate 		croppricei = .
	replace 		croppricei = p_ea if n_ea>=10
	*** 0 changes
	replace 		croppricei = p_dst if n_dst>=10 & missing(croppricei)
	*** 26049 changes
	replace 		croppricei = p_rgn if n_rgn>=10 & missing(croppricei)
	*** 3196 changes
	replace 		croppricei = p_urb if n_urb>=10 & missing(croppricei)
	*** 262 changes
	replace 		croppricei = p_crop if missing(croppricei)
	*** 1316 changes
	label 			variable croppricei	"imputed unit value of crop"

* investigate cases where crop price is missing
	tabulate 		cropid if missing(croppricei)	
	*** we have no price data for wheat (1), cabbage (5), tanaposi (22), pea (359), paprinka (6), and whatever "49" is (66)
	*** this shouldn't be a problem ... 
* the NSO does not collect price data on wheat, so we have little external basis to impute
	list 			cropid harvest if missing(croppricei), sepby(case_id)	
	*** but: some zero harvest values
* where harvest quantity is zero and price is missing, we will replace price = 1 to avoid losing the zero value
	replace 		croppricei=1 if missing(croppricei) & harvest==0
	*** 455 changes
	
* in full kitchen sink file, compares to cross section datasets (looking at panel)
* here, we'll assume that omitting these is fine and drop if no price
	drop			if croppricei == . 
	*** 4 observations deleted 
	
* confirm that we have prices for all crops	
	assert 			!missing(croppricei)
	
* **********************************************************************
* 3 - construction production info
* **********************************************************************

* construction production value, which can be aggregated across crops 
	generate 		harvest_value = harvest * croppricei
	assert 			!missing(harvest_value) 
	label 			variable harvest_value	"value of harvest (MWK)"

* make maize specific production variables, as maize can reasonably be aggregated in kg terms 
	label 			list cropid
	generate 		mz_harvest = harvest if ///
						inlist(cropid,"Maize Local":cropid,"Maize Composite/OPV":cropid,"Maize Hybrid":cropid,"Maize Hybrid Recycled":cropid, "Maize Hybrid Recycled": cropid)
	*** 20783 missing generated
	generate 		mz_harvest_losses = harvest_losses if /// 
						inlist(cropid,"Maize Local":cropid,"Maize Composite/OPV":cropid,"Maize Hybrid":cropid,"Maize Hybrid Recycled":cropid, "Maize Hybrid Recycled": cropid)

* look at variable labels pre-collapse 
	describe 		harvest harvest_losses intercrop_legume harvest_value


* collapse crop x plot data to plot level 
	collapse 		(max) mz_harvest_losses harvest_losses intercrop_legume /*
*/	(sum) 			mz_harvest harvest_value, by(case_id plotid)
	label 			variable mz_harvest	"maize harvest quantity (kg)"
	recode 			mz_harvest (0=.) if missing(mz_harvest_losses)	
	*** set zero values = missing where no maize was cultivated 
	*** 2789 changes 
	label 			variable mz_harvest_losses	"maize harvest area less than maize planted area"
	label 			variable harvest_losses	"harvest area less than planted area"
	label 			variable intercrop_legume "plot was intercropped with legumes"
	label 			variable harvest_value "value of harvest (MWK)"
	
* save temporary file for merge below
	save "`temp'/mods_g_i_plotlevel.dta", replace 
	
* create plot-level datasets
	use 			"`export'/ag_mod_c.dta", clear
	merge 1:1 case_id plotid gardenid HHID using "`export'/ag_mod_d.dta", generate(_D)
	*** 17657 matched
	*** 36 unmatched from using 
	tabulate 		plotid _D if _D!=3	
	*** these are records for which we have no plot size 
	merge m:1 case_id plotid using "`temp'/mods_g_i_plotlevel.dta", generate(_G)
	*** 17469 matched
	*** 224 unmatched from master 

	merge m:1 case_id using "`root'/hh_mod_a_filt.dta", assert(2 3) keep(3) nogenerate
	*** 17693 matched 
	
* **********************************************************************
* 4 - yield 
* **********************************************************************	

* in general, we will construct production variables on a per hectare basis, and conduct imputation on the per hectare variables. We will then create 
* 'imputed' versions of the non-per hectare variables (e.g. harvest, cropvalue) by multiplying the imputed per hectare vars by plotsize. 
* this approach relies on the assumptions that the 1) GPS measurements are reliable, and 2) outlier values are due to errors in the respondent's 
* self-reported production quantities.
	
* construct maize yield
	generate 		mz_yield = mz_harvest / plotsize, after(mz_harvest)
	label 			variable mz_yield "maize yield (kg/ha)"
	tabstat 		mz_yield, statistics(n mean min p75 p90 p95 p99 max) columns(statistics) format(%9.3g) longstub

* impute yield outliers
	summarize 		mz_yield
	bysort 			region : egen stddev = sd(mz_yield) if !inlist(mz_yield,.,0)
	*** 4229 missing values
	recode 			stddev (.=0)
	*** 4229 changes made 
	bysort 			region : egen median = median(mz_yield) if !inlist(mz_yield,.,0)
	bysort 			region : egen replacement = median(mz_yield) if /// 
							(mz_yield <= median + (3 * stddev)) & (mz_yield >= median - (3 * stddev)) & !inlist(mz_yield,.,0)
	bysort 			region : egen maxrep = max(replacement)
	bysort 			region : egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		mz_yieldimp = mz_yield, after(mz_yield)
	*** 3285 missing values generated
	replace  		mz_yieldimp = maxrep if !((mz_yield < median + (3 * stddev)) & (mz_yield > median - (3 * stddev))) & !inlist(mz_yield,.,0) & !mi(maxrep)
	*** 41 changes made 
	tabstat 		mz_yield mz_yieldimp, f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** before imp: 17486 = mean, with median = 2722
	*** after imp: 10423 = mean, with median = 2719 
	drop 			stddev median replacement maxrep minrep
	la var 			mz_yieldimp "maize yield (kg/ha), imputed"

* inferring imputed harvest quantity from imputed yield value 
	generate 		mz_harvestimp = mz_yieldimp * plotsize, after(mz_harvest)
	*** 3258 missing generated 
	la 				var mz_harvestimp "maize harvest quantity (kg), imputed"

* construct production value per hectare
	generate 		harvest_valueha = harvest_value / plotsize, after(harvest_value)
	*** 258 missing values
	label 			variable harvest_valueha "value of harvest per hectare (MWK/ha)"

* impute value per hectare outliers 
	summarize 		harvest_valueha
	bysort 			region : egen stddev = sd(harvest_valueha) if !inlist(harvest_valueha,.,0)
	recode 			stddev (.=0)
	bysort 			region : egen median = median(harvest_valueha) if !inlist(harvest_valueha,.,0)
	bysort 			region : egen replacement = median(harvest_valueha) if ///
							(harvest_valueha <= median + (3 * stddev)) & (harvest_valueha >= median - (3 * stddev)) & !inlist(harvest_valueha,.,0)
	bysort 			region : egen maxrep = max(replacement)
	bysort 			region : egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		harvest_valuehaimp = harvest_valueha, after(harvest_valueha)
	*** 258 missing values
	replace  		harvest_valuehaimp = maxrep if !((harvest_valueha < median + (3 * stddev)) & (harvest_valueha > median - (3 * stddev))) & !inlist(harvest_valueha,.,0) & !mi(maxrep)
	*** 65 changes made
	tabstat 		harvest_valueha harvest_valuehaimp, f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	drop 			stddev median replacement maxrep minrep
	label 			variable harvest_valuehaimp	"value of harvest per hectare (MWK/ha), imputed"

* inferring imputed harvest value from imputed harvest value per hectare
	generate 		harvest_valueimp = harvest_valuehaimp * plotsize, after(harvest_value)
	*** 238 missing values
	label 			variable harvest_valueimp "value of harvest (MWK), imputed"

* generate labor days per hectare
	generate 		labordays_ha = labordays / plotsize, after(labordays)
	*** 36 missing values 
	label 			variable labordays_ha "days of labor per hectare (Days/ha)"
	summarize 		labordays labordays_ha
	
	*** PAY ATTENTION HERE

* impute labor outliers, right side only 
	summarize 		labordays_ha, detail
	bysort 			region : egen stddev = sd(labordays_ha) if !inlist(labordays_ha,.,0)
	recode			stddev (.=0)
	bysort 			region : egen median = median(labordays_ha) if !inlist(labordays_ha,.,0)
	bysort 			region : egen replacement = median(labordays_ha) if 
							(labordays_ha <= median + (3 * stddev)) /*& (labordays_ha >= median - (3 * stddev))*/ & !inlist(labordays_ha,.,0)
	bysort 			region : egen maxrep = max(replacement)
	bysort 			region : egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		labordays_haimp = labordays_ha, after(labordays_ha)
	replace 		labordays_haimp = maxrep if !((labordays_ha < median + (3 * stddev)) /*& (labordays_ha > median - (3 * stddev))*/) & !inlist(labordays_ha,.,0) & !mi(maxrep)
	tabstat 		labordays_ha labordays_haimp, f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	drop 			stddev median replacement maxrep minrep
	label 			variable labordays_haimp "days of labor per hectare (Days/ha), imputed"
	
* make labor days based on imputed labor days per hectare
	generate labordaysimp = labordays_haimp * plotsize, after(labordays)
	label variable labordaysimp			"Days of labor on plot, imputed"
	tabstat labordays labordaysimp, f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub

	
* **********************************************************************
* ? - end matter, clean up to save
* **********************************************************************

	compress
	describe
	summarize 
	
* save data
	save 			"`export'/rs_plot.dta", replace

* close the log
	log			close

/* END */