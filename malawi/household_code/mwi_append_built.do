* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Edited on: 20 June 2024
* Edited by: jdm
* Stata v.18

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
	* need to sort out short panel
	* left off at building panel
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		root 		"$data/merged_data/malawi"
	global		export 		"$data/regression_data/malawi"
	global		logout 	 	"$data/merged_data/malawi/logs"

* open log	
	cap log 	close 
	log 		using 		"$logout/mwi_append_built", append

	
* **********************************************************************
* 1 - append cross section
* **********************************************************************

* import the long panel data frame
	use 		"$data/household_data/malawi/trackingfiles/Frame_hhIDs_v2.dta", clear

* import the first cross section file	
	preserve
	tempfile 	cx1
	keep if		wave == 1
	
	merge		1:1 case_id using "$root/wave_1/cx1_merged.dta", gen(cx1)

	keep if		cx1 == 2
	
	save 		`cx1'
	restore
	
* append the second cross section file
	keep if		wave == 3

	merge		m:1 case_id wave using "$root/wave_3/cx2_merged.dta", gen(cx2)
	
	keep if		cx2 == 2
	
	append 		using `cx1'

* drop duplicates (10), not sure why there are dups
	duplicates drop case_id, force

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

	isid		case_id
				
* save file
	qui: compress
	save 			"$export/mwi_cx.dta", replace
	
	
* **********************************************************************
* 2 - append short panel
* **********************************************************************
	
* import the long panel data frame
	use 		"$data/household_data/malawi/trackingfiles/Frame_hhIDs_v2.dta", clear

* import the first short panel file	
	preserve
	tempfile 	sp1
	keep if		wave == 1
	
	merge		1:1 case_id using "$root/wave_1/sp1_merged.dta", gen(sp1)

	keep if		sp1 == 2

	save 		`sp1'
	restore
	
* append the second short panel file
	keep if		wave == 2
	
	merge		1:1 y2_hhid using "$root/wave_2/sp2_merged.dta", gen(sp2)

	keep if		sp2 == 2
	
	append 		using `sp1', force
	

* drop split-off households, keep only original households
	duplicates 	tag case_id year, generate(dup)
	drop if 	dup > 0 & splitoffR2 != 1
	drop if 	dup > 0 & tracking_R1_to_R2 ==1
	drop		dup
	duplicates 	tag case_id year, generate(dup)
	drop if		dup > 0 
	drop		dup
	duplicates 	tag case_id, generate(dup)
	drop if		dup == 0 
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
	order		country dtype region district urban strata ///
				spid sp_id case_id y2_hhid
	
	isid		case_id year
	
* save file
	qui: compress
	save 			"$export/mwi_sp.dta", replace


* **********************************************************************
* 3 - append long panel
* **********************************************************************
	
* import the long panel data frame
	use 		"$data/household_data/malawi/trackingfiles/Frame_hhIDs_v2.dta", clear
	
* import the first long panel file
	preserve
	tempfile 	lp1
	keep if		wave == 1
	
	merge		1:1 case_id using "$root/wave_1/lp1_merged.dta", gen(lp1)

	keep if		lp1 == 3

	save 		`lp1'
	restore

* append the second long panel file
	preserve
	tempfile 	lp2
	keep if		wave == 2
	
	merge		1:1 y2_hhid wave using "$root/wave_2/lp2_merged.dta", gen(lp2)

	keep if		lp2 == 3

	save 		`lp2'
	restore
	
* append the third long panel file
	preserve
	tempfile 	lp3
	keep if		wave == 3
	
	merge		1:1 y3_hhid wave using "$root/wave_4/lp3_merged.dta", gen(lp3)

	keep if		lp3 == 3

	save 		`lp3'
	restore
	
* append the third long panel file
	preserve
	tempfile 	lp4
	keep if		wave == 4
	
	merge		1:1 y4_hhid wave using "$root/wave_6/lp4_merged.dta", gen(lp4)

	keep if		lp4 == 3

	save 		`lp4'
	restore

* append data sets
	use 		`lp1', clear
	append		using `lp2'
	append		using `lp3'
	append		using `lp4'
	
* check for unique identifiers
	isid		hh_id_obs year

* create household, country, and data identifiers
	sort		hh_id_obs year
	rename		hh_id_obs lp_id
	lab var		lp_id "Long panel household id"
	
	
	egen		lpid = seq()
	lab var		lpid "Long panel unique id"

	gen			country = "malawi"
	lab var		country "Country"

	gen			dtype = "lp"
	lab var		dtype "Data type"

* order variables
	order		country dtype region district urban ta strata cluster ///
				ea_id case_id lpid y2_hhid y3_hhid y4_hhid lp_id
	
	isid		lp_id year
	
* save file
	qui: compress
	save 			"$export/mwi_lp.dta", replace
	

* **********************************************************************
* 4 - append all Malawi data
* **********************************************************************
	
* import the cross section file
	use 		"$export/mwi_cx.dta", clear

* append the two panel files
	append		using "$export/mwi_sp.dta", force	
	append		using "$export/mwi_lp.dta", force	
	
* drop dry season values - we just focus on the rainy season (rs)
	drop		ds*

* create or rename variables for maize production (seed rate missing in data)
	replace		cp_hrv = rsmz_harvestimp if cp_hrv == .
	lab var 	cp_hrv "Harvest of maize (kg)"
		
	replace		cp_lnd = rsmz_cultivatedarea if cp_lnd == .
	lab var 	cp_lnd "Land area planted to maize (ha)"
		
	replace		cp_yld = cp_hrv/cp_lnd
	lab var 	cp_yld "Yield of maize (kg/ha)"

	replace		cp_lab = rsmz_labordaysimp/cp_lnd
	lab var 	cp_lab "Labor for maize (days/ha)"
		
	replace		cp_frt = rsmz_fert_kg if cp_frt == . 
	lab var		cp_frt "Fertilizer (inorganic) for maize (kg/ha)"
		
	replace		cp_pst = rsmz_pest if cp_pst == . 
	lab var		cp_pst "Pesticide/Insecticide for maize (=1)"
		
	replace		cp_hrb = rsmz_herb if cp_hrb == . 
	lab var		cp_hrb "Herbicide/Fungicide for maize (=1)"
		
	replace		cp_irr = rsmz_irrigationany if cp_irr == .
	lab var		cp_irr "Irrigation for maize (=1)"

* convert kwacha into 2015 USD
* exchange rates come from world_bank_exchange_rates.xlsx
	replace		rs_harvest_valueimp = rs_harvest_valueimp/184.65 ///
					if year == 2008
	replace		rs_harvest_valueimp = rs_harvest_valueimp/184.17 ///
					if year == 2009
	replace		rs_harvest_valueimp = rs_harvest_valueimp/395.68 ///
					if year == 2012
	replace		rs_harvest_valueimp = rs_harvest_valueimp/499.61 ///
					if year == 2014
	replace		rs_harvest_valueimp = rs_harvest_valueimp/700.49 ///
					if year == 2015
	*** 2018 converted in file
		
* create or rename variables for total farm production (seed rate missing)
	replace		tf_hrv = rs_harvest_valueimp if tf_hrv == .
	lab var 	tf_hrv "Harvest of all crops (2015 USD)"
		
	replace		tf_lnd = rs_cultivatedarea if tf_lnd == .
	lab var 	tf_lnd "Land area planted to all crops (ha)"
		
	replace		tf_yld = tf_hrv/tf_lnd
	lab var 	tf_yld "Yield of all crops (USD/ha)"
		
	replace		tf_lab = rs_labordaysimp/tf_lnd
	lab var 	tf_lab "Labor for all crops (days/ha)"
		
	replace		tf_frt = rs_fert_inorgkg if tf_frt == .
	lab var		tf_frt "Fertilizer (inorganic) for all crops (kg/ha)"
		
	replace		tf_pst = rs_pest if tf_pst == .
	lab var		tf_pst "Pesticide/Insecticide for all crops (=1)"
		
	replace		tf_hrb = rs_herb if tf_hrb == .
	lab var		tf_hrb "Herbicide/Fungicide for all crops (=1)"
		
	replace		tf_irr = rs_irrigationany if tf_irr == .
	lab var		tf_irr "Irrigation for all crops (=1)"

* rename household weights
	rename		hhweight pw
	replace		pw = hh_wgt if pw == .
	
* drop unused production variables
	drop 		rs*
	
	order		country dtype cx_id sp_id lp_id year aez pw tf_hrv tf_lnd tf_yld tf_lab ///
					tf_frt tf_pst tf_hrb tf_irr cp_hrv cp_lnd cp_yld cp_lab ///
					cp_frt cp_pst cp_hrb cp_irr
	
* drop unnecessary variables and reorder remaining
	drop		region district urban strata cluster ea_id spid ///
					y2_hhid y3_hhid hhid hh_x02 hh_x04 intmonth ///
					intyear qx_type ta lpid
			
* drop observations missing output
	drop 		if tf_hrv == . & cp_hrv == .
	*** drop observations are from those who cultivated dry but NOT rainy season
	
	replace		cp_pst = . if cp_hrv == .
	replace		cp_hrb = . if cp_hrv == .
	
* label household variables	
	lab var			year "Year"
	lab var			tf_lnd	"Total farmed area (ha)"
	lab var			tf_hrv	"Total value of harvest (2015 USD)"
	lab var			tf_yld	"value of yield (2015 USD/ha)"
	lab var			tf_lab	"labor rate (days/ha)"
	lab var			tf_frt	"fertilizer rate (kg/ha)"
	lab var			tf_pst	"Any plot has pesticide"
	lab var			tf_hrb	"Any plot has herbicide"
	lab var			tf_irr	"Any plot has irrigation"
	lab var			cp_lnd	"Total maize area (ha)"
	lab var			cp_hrv	"Total quantity of maize harvest (kg)"
	lab var			cp_yld	"Maize yield (kg/ha)"
	lab var			cp_lab	"labor rate for maize (days/ha)"
	lab var			cp_frt	"fertilizer rate for maize (kg/ha)"
	lab var			cp_pst	"Any maize plot has pesticide"
	lab var			cp_hrb	"Any maize plot has herbicide"
	lab var			cp_irr	"Any maize plot has irrigation"
	lab var 		data "Data Source"	

* generate remote sensing product variables
	gen				sat1 = 1
	order			sat1, before(v01_arc2r)
	gen				sat2 = 2
	order			sat2, before(v01_chirp)
	gen				sat3 = 3
	order			sat3, before(v01_cpcrf)
	gen				sat4 = 4
	order			sat4, before(v01_erarf)
	gen				sat5 = 5
	order			sat5, before(v01_merra)
	gen				sat6 = 6
	order			sat6, before(v01_tamsa)
	gen				sat7 = 7
	order			sat7, before(v15_cpctp)
	gen				sat8 = 8
	order			sat8, before(v15_eratp)
	gen				sat9 = 9
	order			sat9, before(v15_merra)
	lab define 		sat 1 "ARC2" 2 "CHIRPS" 3 "CPC" 4 "ERA5" 5 "MERRA-2" ///
						6 "TAMSAT" 7 "CPC" 8 "ERA5" 9 "MERRA-2"
						
* label satellites variables
	loc	sat			sat*
	foreach v of varlist `sat' {
		lab var 		`v' "Satellite/Extraction"
		lab val 		`v' sat
	}

* rename rainfall variables
foreach var of varlist *arc2r {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf1
	}
foreach var of varlist *chirp {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf2
	}
foreach var of varlist *cpcrf {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf3
	}
foreach var of varlist *erarf {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf4
	}
foreach var of varlist v01_merra - v14_merra {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf5
	}
foreach var of varlist *tamsa {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf6
	}
foreach var of varlist *cpctp {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf7
	}
foreach var of varlist *eratp {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf8
	}
foreach var of varlist v15_merra - v27_merra {
		loc 		dat = substr("`var'", 1, 3)
		rename		`var' `dat'_rf9
	}
	
* label rainfall variables	
	loc	v01			v01*
	foreach v of varlist `v01' {
		lab var 		`v' "Mean Daily Rainfall"	
	}	
	
	loc	v02			v02*
	foreach v of varlist `v02' {
		lab var 		`v' "Median Daily Rainfall"
	}					
	
	loc	v03			v03*
	foreach v of varlist `v03' {
		lab var 		`v' "Variance of Daily Rainfall"
	}					
	
	loc	v04			v04*
	foreach v of varlist `v04' {
		lab var 		`v'  "Skew of Daily Rainfall"
	}					
	
	loc	v05			v05*
	foreach v of varlist `v05' {
		lab var 		`v'  "Total Rainfall"
	}					
	
	loc	v06			v06*
	foreach v of varlist `v06' {
		lab var 		`v' "Deviation in Total Rainfalll"
	}					
	
	loc	v07			v07*
	foreach v of varlist `v07' {
		lab var 		`v' "Z-Score of Total Rainfall"	
	}					
	
	loc	v08			v08*
	foreach v of varlist `v08' {
		lab var 		`v' "Rainy Days"
	}					
	
	loc	v09			v09*
	foreach v of varlist `v09' {
		lab var 		`v' "Deviation in Rainy Days"	
	}					
	
	loc	v10			v10*
	foreach v of varlist `v10' {
		lab var 		`v' "No Rain Days"
	}					
	
	loc	v11			v11*
	foreach v of varlist `v11' {
		lab var 		`v' "Deviation in No Rain Days"
	}					
	
	loc	v12			v12*
	foreach v of varlist `v12' {
		lab var 		`v' "% Rainy Days"	
	}					
	
	loc	v13			v13*
	foreach v of varlist `v13' {
		lab var 		`v' "Deviation in % Rainy Days"	
	}					
	
	loc	v14			v14*
	foreach v of varlist `v14' {
		lab var 		`v' "Longest Dry Spell"	
	}									

* label weather variables	
	loc	v15			v15*
	foreach v of varlist `v15' {
		lab var 		`v' "Mean Daily Temperature"
	}
	
	loc	v16			v16*
	foreach v of varlist `v16' {
		lab var 		`v' "Median Daily Temperature"
	}
	
	loc	v17			v17*
	foreach v of varlist `v17' {
		lab var 		`v' "Variance of Daily Temperature"
	}
	
	loc	v18			v18*
	foreach v of varlist `v18' {
		lab var 		`v' "Skew of Daily Temperature"	
	}
	
	loc	v19			v19*
	foreach v of varlist `v19' {
		lab var 		`v' "Growing Degree Days (GDD)"	
	}
	
	loc	v20			v20*
	foreach v of varlist `v20' {
		lab var 		`v' "Deviation in GDD"		
	}
	
	loc	v21			v21*
	foreach v of varlist `v21' {
		lab var 		`v' "Z-Score of GDD"	
	}
	
	loc	v22			v22*
	foreach v of varlist `v22' {
		lab var 		`v' "Maximum Daily Temperature"
	}
	
	loc	v23			v23*
	foreach v of varlist `v23' {
		lab var 		`v' "Temperature Bin 0-20"	
	}
	
	loc	v24			v24*
	foreach v of varlist `v24' {
		lab var 		`v' "Temperature Bin 20-40"	
	}
	
	loc	v25			v25*
	foreach v of varlist `v25' {
		lab var 		`v' "Temperature Bin 40-60"
	}
	
	loc	v26			v26*
	foreach v of varlist `v26' {
		lab var 		`v' "Temperature Bin 60-80"		
	}
	
	loc	v27			v27*
	foreach v of varlist `v27' {
		lab var 		`v' "Temperature Bin 80-100"	
	}
					
* create household, country, and data identifiers
	egen			mwi_id = group(cx_id)
	sum				mwi_id
	replace			mwi_id = `r(max)' + sp_id if sp_id != .

	egen			lpid = group(lp_id)
	sum				mwi_id
	replace			mwi_id = `r(max)' + lpid if lpid != .
	
	distinct		mwi_id
	isid			mwi_id year
	lab var			mwi_id "Malawi panel household id"
	
	egen			uid = seq()
	lab var			uid "unique id"
	
* order variables
	order			uid mwi_id
	
* save file
	qui: 			compress
	save 			"$export/mwi_complete.dta", replace
	
* close the log
	log	close

/* END */
