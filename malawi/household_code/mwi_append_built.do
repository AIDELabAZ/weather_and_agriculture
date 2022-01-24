* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Stata v.16

* does
	* reads in merged data sets
	* appends merged data sets
	* outputs foure data sets
		* all Malawi data
		* cross section
		* short panel
		* long panel

* assumes
	* all Malawi data has been cleaned and merged with rainfall
	* customsave.ado
	* xfill.ado

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/merged_data/malawi"
	loc		export 	= 	"$data/regression_data/malawi"
	loc		logout 	= 	"$data/merged_data/malawi/logs"

* open log	
	cap 	log 	close 
	log 	using 		"`logout'/mwi_append_built", append

	
* **********************************************************************
* 1 - append cross section
* **********************************************************************

* import the first cross section file
	use 		"`root'/wave_1/cx1_merged.dta", clear

* append the second cross section file
	append		using "`root'/wave_3/cx2_merged.dta", force

* reformat case_id
	format %15.0g case_id

* drop duplicates (not sure why there are duplicats)
	duplicates 	tag case_id, generate(dup)
	drop if 	dup > 0 & qx_type == ""
	drop		dup

* create household, country, and data identifiers
	egen		cx_id = seq()
	lab var		cx_id "Cross section unique id"

	gen			country = "malawi"
	lab var		country "Country"

	gen			dtype = "cx"
	lab var		dtype "Data type"

* combine variables
	replace		hhweight	= hhweightR1 if hhweight == .
	replace		hh_x02 		= ag_c0a if hh_x02 == .
	replace		hh_x04		= ag_j0a if hh_x04 == .
	drop		hhweightR1 ag_c0a ag_j0a
	
* order variables
	order		country dtype region district urban ta strata cluster ///
				ea_id cx_id case_id hhid hhweight hh_x02 hh_x04

* save file
	qui: compress
	customsave 	, idvarname(case_id) filename("mwi_cx.dta") ///
		path("`export'") dofile(mwi_append_built) user($user)
	
	
* **********************************************************************
* 2 - append short panel
* **********************************************************************

* import the first short panel file
	use 		"`root'/wave_1/sp1_merged.dta", clear

* append the second short panel file
	append		using "`root'/wave_2/sp2_merged.dta", force

* reformat case_id
	format %15.0g case_id

* drop split-off households, keep only original households
	duplicates 	tag case_id year, generate(dup)
	drop if 	dup > 0 & splitoffR2 != 1
	drop if 	dup > 0 & tracking_R1_to_R2 ==1
	drop		dup
	duplicates 	tag case_id year, generate(dup)
	drop if		dup > 0 
	drop		dup

* create household, country, and data identifiers
	egen		sp_id = group(case_id)
	lab var		sp_id "Short panel household id"
	
	egen		spid = seq()
	lab var		spid "Short panel unique id"

	gen			country = "malawi"
	lab var		country "Country"

	gen			dtype = "sp"
	lab var		dtype "Data type"

* combine variables
	replace		urban		= urbanR2 if urban == .
	replace		strata 		= strataR2 if strata == .
	rename		hhweightR1 	hhweight
	drop		urbanR2- distance_R1_to_R2
	
* order variables
	order		country dtype region district urban ta strata cluster ///
				ea_id spid sp_id case_id y2_hhid hhweight
	
* save file
	qui: compress
	customsave 	, idvarname(spid) filename("mwi_sp.dta") ///
		path("`export'") dofile(mwi_append_built) user($user)


* **********************************************************************
* 3 - append long panel
* **********************************************************************
	
* import the first long panel file
	use 		"`root'/wave_1/lp1_merged.dta", clear

* append the second long panel file
	append		using "`root'/wave_2/lp2_merged.dta", force	
	
* reformat case_id
	format %15.0g case_id
	
* create household panel id for lp1 and lp2 using case_id
	egen		lp_id = group(case_id)
	lab var		lp_id "Long panel household id"	
	
* append the third long panel file	
	append		using "`root'/wave_4/lp3_merged.dta", force	

* fill in missing lpid for third long panel using y2_hhid
	egen		aux_id = group(y2_hhid)
	xtset 		aux_id
	xfill 		lp_id if aux_id != ., i(aux_id)
	drop		aux_id
	
* drop split-off households, keep only original households
	duplicates 	tag lp_id year, generate(dup)
	drop if		dup > 0 & mover_R1R2R3 == 1
	drop		dup
	duplicates 	tag case_id year, generate(dup)
	drop if 	dup > 0 & splitoffR2 != 1
	drop if 	dup > 0 & tracking_R1_to_R2 ==1
	drop		dup
	duplicates 	tag case_id year, generate(dup)
	drop if		dup > 0 
	drop		dup

* create household, country, and data identifiers
	sort		lp_id year
	egen		lpid = seq()
	lab var		lpid "Long panel unique id"

	gen			country = "malawi"
	lab var		country "Country"

	gen			dtype = "lp"
	lab var		dtype "Data type"

* combine variables
	replace		urban		= urbanR2 if urban == .
	replace		urban		= urbanR3 if urban == .
	replace		strata 		= strataR2 if strata == .
	replace		strata 		= strataR3 if strata == .
	rename		hhweightR1 	hhweight
	drop		urbanR2- distance_R1_to_R2 urbanR3- distance_R2_to_R3
	
* order variables
	order		country dtype region district urban ta strata cluster ///
				ea_id lpid lp_id case_id y2_hhid y3_hhid hhweight
	
* save file
	qui: compress
	customsave 	, idvarname(case_id) filename("mwi_lp.dta") ///
		path("`export'") dofile(mwi_append_built) user($user)

		
* **********************************************************************
* 4 - append all Malawi data
* **********************************************************************
	
* import the cross section file
	use 		"`export'/mwi_cx.dta", clear

* append the two panel files
	append		using "`export'/mwi_sp.dta", force	
	append		using "`export'/mwi_lp.dta", force	

* drop dry season values - we just focus on the rainy season (rs)
	drop		ds*

* create or rename variables for maize production (seed rate missing in data)
	rename		rsmz_harvestimp cp_hrv
	lab var 	cp_hrv "Harvest of maize (kg)"
		
	rename		rsmz_cultivatedarea cp_lnd
	lab var 	cp_lnd "Land area planted to maize (ha)"
		
	gen 		cp_yld = cp_hrv/cp_lnd
	lab var 	cp_yld "Yield of maize (kg/ha)"

	gen 		cp_lab = rsmz_labordaysimp/cp_lnd
	lab var 	cp_lab "Labor for maize (days/ha)"
		
	rename		rsmz_fert_inorgpct cp_frt
	lab var		cp_frt "Fertilizer (inorganic) for maize (kg/ha)"
		
	rename		rsmz_pest cp_pst
	lab var		cp_pst "Pesticide/Insecticide for maize (=1)"
		
	rename		rsmz_herb cp_hrb
	lab var		cp_hrb "Herbicide/Fungicide for maize (=1)"
		
	rename		rsmz_irrigationany cp_irr
	lab var		cp_irr "Irrigation for maize (=1)"

* convert kwacha into 2010 USD
* exchange rates come from world_bank_exchange_rates.xlsx
	replace		rs_harvest_valueimp = rs_harvest_valueimp/124.3845647 ///
					if year == 2008
	replace		rs_harvest_valueimp = rs_harvest_valueimp/134.2107246 ///
					if year == 2009
	replace		rs_harvest_valueimp = rs_harvest_valueimp/201.9788745 ///
					if year == 2012
	replace		rs_harvest_valueimp = rs_harvest_valueimp/310.8160671 ///
					if year == 2014
	replace		rs_harvest_valueimp = rs_harvest_valueimp/374.6410851 ///
					if year == 2015
		
* create or rename variables for total farm production (seed rate missing)
	rename		rs_harvest_valueimp tf_hrv
	lab var 	tf_hrv "Harvest of all crops (2010 USD)"
		
	rename		rs_cultivatedarea tf_lnd
	lab var 	tf_lnd "Land area planted to all crops (ha)"
		
	gen 		tf_yld = tf_hrv/tf_lnd
	lab var 	tf_yld "Yield of all crops (USD/ha)"
		
	gen 		tf_lab = rs_labordaysimp/tf_lnd
	lab var 	tf_lab "Labor for all crops (days/ha)"
		
	rename		rs_fert_inorgpct tf_frt
	lab var		tf_frt "Fertilizer (inorganic) for all crops (kg/ha)"
		
	rename		rs_pest tf_pst
	lab var		tf_pst "Pesticide/Insecticide for all crops (=1)"
		
	rename		rs_herb tf_hrb
	lab var		tf_hrb "Herbicide/Fungicide for all crops (=1)"
		
	rename		rs_irrigationany tf_irr
	lab var		tf_irr "Irrigation for all crops (=1)"
	
* rename household weights
	rename		hhweight pw
	
* drop unnecessary variables and reorder remaining
	drop		rs* case_id region district urban strata cluster ea_id spid ///
					y2_hhid y3_hhid hhid hh_x02 hh_x04 intmonth ///
					intyear qx_type ta lpid
	
	order		country dtype cx_id sp_id lp_id year aez pw tf_hrv tf_lnd tf_yld tf_lab ///
					tf_frt tf_pst tf_hrb tf_irr cp_hrv cp_lnd cp_yld cp_lab ///
					cp_frt cp_pst cp_hrb cp_irr

* replace missing variables
	replace		aez = 312 if lp_id == 320
	replace		aez = 312 if lp_id == 1142
				
* drop observations missing output
	drop 		if tf_hrv == . & cp_hrv == .
	*** drop observations are from those who cultivated dry but NOT rainy season
	
	replace		cp_pst = . if cp_hrv == .
	replace		cp_hrb = . if cp_hrv == .
				
* create household, country, and data identifiers
	egen			uid = seq()
	lab var			uid "unique id"
	
* order variables
	order			uid
	
* save file
	qui: compress
	customsave 	, idvarname(uid) filename("mwi_complete.dta") ///
		path("`export'") dofile(mwi_append_built) user($user)

* close the log
	log	close

/* END */
