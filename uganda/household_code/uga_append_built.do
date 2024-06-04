* Project: WB Weather
* Created on: Aug 2020
* Created by: ek
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in merged data sets
	* appends all three to form complete data set (W1-W3)
	* outputs Uganda data sets for analysis

* assumes
	* all Uganda data has been cleaned and merged with rainfall

* TO DO:
	* NEED TO SORT OUT HOUSEHOLD ID
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		raw		=	"$data/household_data/uganda/wave_7/refined"
	global		root 	= 	"$data/merged_data/uganda"
	global		export 	= 	"$data/regression_data/uganda"
	global		logout 	= 	"$data/merged_data/uganda/logs"

* open log	
	cap log 	close 
	log 		using 		"$logout/uga_append_built", append

	
* **********************************************************************
* 1 - append first three waves of Uganda household data
* **********************************************************************

* import wave 1 Uganda	
	use 			"$root/wave_1/unps1_merged", clear
	
* append wave 2 file
	append			using "$root/wave_2/unps2_merged", force	
	
* append wave 3 file 
	append			using "$root/wave_3/unps3_merged", force

* append wave 4 file 
	append			using "$root/wave_4/unps4_merged", force
	
	rename			hhid hh_1_4
	lab var 		hh_1_4 "Panel ID for waves 1-4"
	
* append wave 5 file 
	append			using "$root/wave_5/unps5_merged", force
		
* append wave 7 household key file 
	append			using "$raw/2018_gsec1.dta", force	
	
	rename			HHID hh_4_7
	lab var 		hh_4_7 "Panel ID for waves 4-7"
	
* append wave 8 file 
	append			using "$root/wave_8/unps8_merged", force	
	
* generate panel ID
* start with hh in waves 1-4
	sort			hh_1_4
	egen			pnl_hhid = group(hh_1_4)
	order 			hh_1_4 hh_4_7 hh_7_8 hhid year, before(pnl_hhid)
	
* now fill in pnl_hhid with households that match on wave 4-7
	egen 			hh47 = group(hh_4_7)
	sort 			hh47
	xtset 			hh47
	xfill 			hh_1_4 if hh_1_4 == "" & hh47 != ., i(hh47)
	
* now fill in pnl_hhid with households that match on wave 7-8
	egen 			hh78 = group(hh_7_8)
	sort 			hh78
	xtset 			hh78
	xfill 			hh_4_7 if hh_4_7 == "" & hh78 != ., i(hh78)
	xfill 			hh47 if hh47 == . & hh78 != ., i(hh78)

	sort 			hh47
	xtset 			hh47
	xfill 			hh_1_4 if hh_1_4 == "" & hh47 != ., i(hh47)
	
	drop			pnl_hhid
	sort			hh_1_4
	egen			pnl_hhid = group(hh_1_4)
	
	drop			hh47
	sort			hh_4_7
	egen			hh47 = group(hh_4_7) if pnl_hhid == .
	
	sum 			pnl_hhid
	replace			pnl_hhid = hh47 + `r(max)' if pnl_hhid == .
	
	drop			hh78
	sort			hh_7_8
	egen			hh78 = group(hh_7_8) if pnl_hhid == .
	
	sum 			pnl_hhid
	replace			pnl_hhid = hh78 + `r(max)' if pnl_hhid == .
	
	egen			hh8 = group(hhid) if pnl_hhid == .
	
	sum 			pnl_hhid
	replace			pnl_hhid = hh8 + `r(max)' if pnl_hhid == .
	*** one household seems to have an extra observation in 2018
	*** H3350501 or 456103859120412ba80e3e5d4c19890d
	*** the duplicate has ebcbdd6393f1445392d57880f2c6f016 for hh_7_8
	*** i imagine this is an artifact of not actually have the wave 7 data
	
* drop wave 7. this is temporary until i integrate wave 7 is missing
	drop if			data == ""
	
* check the number of observations again
	distinct 		pnl_hhid
	*** 11,696 observations from 5,110 households 
	count if 		year == 2009
	*** wave 1 has 1,883
	count if 		year == 2010
	*** wave 2 has 1,886
	count if 		year == 2011
	*** wave 3 has 2,022
	count if 		year == 2013
	*** wave 4 has 2,190
	count if 		year == 2015
	*** wave 5 has 1,870
	count if 		year == 2019
	*** wave 8 has 1,845

* generate uganda panel id	
	egen			uga_id = group(pnl_hhid)
	lab var			uga_id "Uganda panel household id"	

* generate country and data types	
	gen				country = "uganda"
	lab var			country "Country"

	gen				dtype = "lp"
	lab var			dtype "Data type"

	isid			uga_id year

* generate one variable for sampling weight
	gen				pw = wgt09wosplits  
	
	replace			pw = wgt10 if pw == .
	replace			pw = wgt11 if pw == .
	replace			pw = wgt13 if pw == .
	replace			pw = wgt15 if pw == .
*	replace			pw = wgt18 if pw == .
	replace			pw = wgt19 if pw == .
	tab 			pw, missing
	drop			if pw == .
	lab var			pw "Household Sample Weight"

* drop variables
	drop			region district county subcounty parish ///
						wgt09wosplits season wgt10 wgt11 hh ///
						wgt13 rotate wgt15 wgt18 subreg wgt19 ///
						hh_1_4 hh_4_7 hh_7_8 hhid pnl_hhid hh47 hh78 hh8
	
	order			country dtype uga_id year aez pw

* label household variables	
	lab var			tf_lnd	"Total farmed area (ha)"
	lab var			tf_hrv	"Total value of harvest (2010 USD)"
	lab var			tf_yld	"value of yield (2010 USD/ha)"
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
		
					
	
* **********************************************************************
* 4 - End matter
* **********************************************************************

* create household, country, and data identifiers
	egen			uid = seq()
	lab var			uid "unique id"
	
* order variables
	order			uid
	
* save file
	qui: compress
	save			"$export/uga_complete.dta", replace

* close the log
	log	close

/* END */

