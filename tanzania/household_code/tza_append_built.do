* Project: WB Weather
* Created on: June 2020
* Created by: jdm
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in merged data sets
	* merges panel data sets (W1-W7)
	* creates extended panel data set (W1-W3, W5, W6)
	* creates new panel data set (W4, W7)
	* appends both to form complete data set (W1-W7)
	* outputs Tanzania data sets for analysis

* assumes
	* all Tanzania data has been cleaned and merged with rainfall
	* xfill.ado

* TO DO:
	* complete 
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		root  	= 	"$data/merged_data/tanzania"
	global		key		=	"$data/household_data/tanzania/wave_6/refined"
	global		export 	= 	"$data/regression_data/tanzania"
	global		logout 	= 	"$data/merged_data/tanzania/logs"

* open log	
	cap log close 
	log 	using 	"$logout/tza_append_built", append

* **********************************************************************
* 1 - merge first three waves of Tanzania data
* **********************************************************************

* using merge rather than append
* households were differently designated in each year 
* need to merge households together into panel key and then reshape 

* import the panel key file
	use 			"$key/sdd_panel_key", clear
	
* merge in wave 1 
* matching on y1_hhid - which identifies wave 1 respondents

	merge 			m:1 y1_hhid using "$root/wave_1/npsy1_merged", gen(_merge2008)
	*** 2,141 matched
	*** 2,756 not matched from master - for households in later waves
	*** 68 not matched from using - only appear in w1 

* merge in wave 2
* matching on y2_hhid which identifies wave 2 respondents 

	merge 			m:1 y2_hhid using "$root/wave_2/npsy2_merged", gen(_merge2010)
	*** 2,533 matched
	*** 2,432 not matched from master - for households in other waves
	*** 31 not matched from using - only appear in w2 
	
* merge in wave 3
* matching on y3_hhid which identifies wave 3 respondents 

	merge 			m:1 y3_hhid using "$root/wave_3/npsy3_merged", gen(_merge2012)
	*** 2,411 matched
	*** 2,585 not matched from master - for households in other waves
	*** 370 not matched from using - no households only in w3
	
* merge in wave 4xp
* matching on y4_hhid which identifies wave 4xp respondents 

	merge 			m:1 y4_hhid using "$root/wave_5/npsy4xp_merged", gen(_merge2014xp)
	*** 597 matched
	*** 4,769 not matched from master - for households in other waves
	*** 12 not matched from using - no households only in w4xp
	
* merge in wave 5-sdd
* matching on sdd_hhid which identifies wave 5-sdd respondents 

	merge 			m:1 sdd_hhid using "$root/wave_6/npsy5sdd_merged", gen(_merge2019)
	*** 483 matched
	*** 4,895 not matched from master - for households in other waves
	*** 78 not matched from using - no households only in w4xp
	
	
* **********************************************************************
* 2 - reshape and format panel
* **********************************************************************

* per https://www.stata.com/support/faqs/data-management/problems-with-reshape/ 
* create local which will contain all variable names that you want to reshape 
	unab 			vars : *2008 
	local			stubs: subinstr local vars "2008" "", all
	
	reshape 		long `stubs', ///
						i(y1_hhid y2_hhid y3_hhid y4_hhid sdd_hhid ///
							region district ward ea) j(year)
	*** some issues with weight variable
	*** this is because no observations for weight 2008 - clean up at end 

* count how many observations we have
	count 
	*** starting with way too many observations - 32,736

	duplicates 		drop
	*** 0 dropped 

* drop empty obsevations (empty because of the reshape)
	drop 			if tf_hrv == .
	* 24,012 dropped 

* drop movers
	drop 			if mover2010 == 1
	*** 847 observations dropped
	drop 			if mover2012 == 1
	*** 882 observations 
	drop 			if mover2014 == 2
	*** 240 observations 
	drop 			if mover2018 == 2
	*** 181 observations 

* check the number of observations again
	count
	*** 6,574 observations 
	*** wave 1 has 2,001 > 1,875 observations in WB working paper
	*** wave 2 has 2,013 > 1,801 observations in WB working paper
	*** wave 3 has 1,899 < 2,093 observations in WB working paper
	*** wave 4xp has 349 observations
	*** wave 5-sdd has 312 observations

* create household, country, and data identifiers
* need to first replace empty places - otherwise will create hhid = . 
	replace 		y1_hhid = "0" if y1_hhid == ""
	replace 		y2_hhid = "0" if y2_hhid == ""
	replace 		y3_hhid = "0" if y3_hhid == ""
	replace 		y4_hhid = "0" if y4_hhid == ""
	replace 		sdd_hhid = "0" if sdd_hhid == ""
	
	egen			tza_lp_id = group(y1_hhid y2_hhid y3_hhid y4_hhid sdd_hhid)
	lab var			tza_lp_id "Tanzania long panel household id"
	*** 6,995 observations from 3,014 households	
	
	gen				country = "tanzania"
	lab var			country "Country"

	gen				dtype = "lp"
	lab var			dtype "Data type"
	
	isid			tza_lp_id year

* identify single observations
	duplicates 		tag tza_lp_id, generate(dup)
	tab				dup
	*** 867 individuals only show up once
	*** 775 show up in all 5
	
* drop unnecessary variables
	drop			mover2010 mover2012 mover2014 mover2018 _merge dup
						
* order variables
	order			country dtype region district ward ea strataid clusterid ///
						tza_lp_id hhweight year
			
* label household variables	
	lab var			strataid  "Design Strata"
	lab var			clusterid "Unique Cluster Identification"	
	lab var			hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var			year "Year"
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
	
* fill in missing aez values
	replace			aez = 313 if aez == . & region == 55
	replace			aez = 313 if aez == . & region == 54
	replace			aez = 313 if aez == . & region == 51
	replace			aez = 313 if aez == . & region == 9
	replace			aez = 313 if aez == . & region == 8
	replace			aez = 313 if aez == . & region == 6
	lab var			aez "Agro-ecological zone"
	*** 887 missing observations. no geovars collected after wave 3
	
* save file
	qui: compress
	save			"$export/tza_lp.dta", replace
		
		
* **********************************************************************
* 4 - generate wave 4 cross section Tanzania 
* **********************************************************************

* import the first cross section file
	use 			"$root/wave_4/npsy4_merged", clear

* merge in npsy5 (wave 7)
	append			using "$root/wave_7/npsy5_merged", force
	
* create household, country, and data identifiers
	drop if			mover2020 == 2
	drop if			y4_hhid == ""
	*** 468 and 121 observations dropped
	
	egen			tza_sp_id = group(y4_hhid)
	lab var			tza_sp_id "Tanzania short panel household id"

* identify single observations
	duplicates 		tag tza_sp_id, generate(dup)
	tab				dup
	*** 4 households that split but were not reorded as such
	
* keep original households
	drop if			y5_hhid == "3206-001-06"
	drop if			y5_hhid == "4386-001-03"
	drop if			y5_hhid == "8624-001-08"
	drop if			y5_hhid == "4766-001-04"
	drop if			y5_hhid == "4766-001-10"

	gen				country = "tanzania"
	lab var			country "Country"

	gen				dtype = "sp"
	lab var			dtype "Data type"

	isid			tza_sp_id year
	
* order variables
	order			country dtype region district ward ea strataid clusterid ///
						tza_sp_id hhweight year
						
	drop			mover2020 dup
		
* label household variables	
	lab var			strataid  "Design Strata"
	lab var			clusterid "Unique Cluster Identification"	
	lab var			hhweight "Household Weights (Trimmed & Post-Stratified)"
	lab var			year "Year"
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
	
* save file
	qui: compress
	save			"$export/tza_sp.dta", replace
		
		
* **********************************************************************
* 4 - append all Tanzania data
* **********************************************************************

* import the cross section file
	use 			"$export/tza_lp.dta", clear

* append the two panel files
	append			using "$export/tza_sp.dta", force	

* rename household weight
	rename			hhweight pw

* drop variables
	drop			region district ward ea strataid clusterid aez
	
	rename			tza_lp_id lp_id
	rename			tza_sp_id sp_id
	
	order			country dtype lp_id sp_id year pw	
		
* create household, country, and data identifiers
	sort			lp_id sp_id year
	gen				tza_id = lp_id
	replace			tza_id = 2812 + sp_id if tza_id == .
	lab var			tza_id "Tanzania panel id"
	
	egen			uid = seq()
	lab var			uid "unique id"
	
* order variables
	order			uid
	
* save file
	qui: compress
	save			"$export/tza_complete.dta", replace

* close the log
	log	close

/* END */
