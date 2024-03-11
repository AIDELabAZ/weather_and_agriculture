* Project: WB Weather
* Created on: March 2024
* Created by: alj
* Edited on: 11 March 2024
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
	log 	using 		"`logout'/mwi_ag_mod_i", append


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
	
	*** PAUSE HERE NEED C AND D... 

* **********************************************************************
* ? - end matter, clean up to save
* **********************************************************************

	compress
	describe
	summarize 
	
* save data
	save 			"`export'/ag_mod_i.dta", replace

* close the log
	log			close

/* END */