* Project: WB Weather
* Created on: June 2020
* Created by: jdm
* Edited by: alj
* Stata v.16

* does
	* reads in merged data sets
	* merges panel data sets (W1-W3)
	* creates cross sectional data set (W4)
	* appends both to form complete data set (W1-W4)
	* outputs Tanzania data sets for analysis

* assumes
	* all Tanzania data has been cleaned and merged with rainfall
	* customsave.ado
	* xfill.ado

* TO DO:
	* complete 
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root  	= 	"$data/merged_data/tanzania"
	loc		key		=	"$data/household_data/tanzania/wave_3/refined"
	loc		export 	= 	"$data/regression_data/tanzania"
	loc		logout 	= 	"$data/merged_data/tanzania/logs"

* open log	
	cap log close 
	log 	using 	"`logout'/tza_append_built", append

* **********************************************************************
* 1 - merge first three waves of Tanzania data
* **********************************************************************

* using merge rather than append
* households were differently designated in each year 
* need to merge households together into panel key and then reshape 

* import the panel key file
	use 			"`key'/panel_key", clear
	
* merge in wave 1 
* matching on y1_hhid - which identifies wave 1 respondents

	merge 			m:1 y1_hhid using "`root'/wave_1/npsy1_merged"
	*** 2101 matched
	*** 2909 not matched from master - for households in w2 and w3
	*** 104 not matched from using - only appear in w1 
	
	rename 			_merge _merge2008
	
* merge in wave 2
* matching on y2_hhid which identifies wave 2 respondents 

	merge 			m:1 y2_hhid using "`root'/wave_2/npsy2_merged"
	*** 2341 matched
	*** 2773 not matched from master - for households in w1 or w3
	*** 59 not matched from using - only appear in w2 
	
	rename 			_merge _merge2010 
		
* merge in wave 3
* matching on y3_hhid which identifies wave 2 respondents 

	merge 			m:1 y3_hhid using "`root'/wave_3/npsy3_merged"
	*** 2658 matched
	*** 2515 not matched from master - for households in w1 or w2
	*** 0 not matched from using - no households only in w3
	
	rename 			_merge _merge2012 
	
	
* **********************************************************************
* 2 - reshape and format panel
* **********************************************************************

* per https://www.stata.com/support/faqs/data-management/problems-with-reshape/ 
* create local which will contain all variable names that you want to reshape 
	unab 			vars : *2008 
	local			stubs: subinstr local vars "2008" "", all
	
	reshape 		long `stubs', ///
						i(y1_hhid y2_hhid y3_hhid region ///
						district ward ea) j(year)
	*** takes about 90 seconds to run
	*** some issues with weight variable
	*** this is because no observations for weight 2008 - clean up at end 

* count how many observations we have
	count 
	*** starting with way too many observations - 15519

	duplicates 		drop
	*** 0 dropped 

* drop empty obsevations (empty because of the reshape)
	drop 			if tf_hrv == .
	* 8256 dropped 

* drop movers
	drop 			if mover2010 == 1
	*** 713 observations dropped
	drop 			if mover2012 == 1
	*** 760 observations 

* check the number of observations again
	count
	*** 5790 observations 
	*** wave 1 has 1875 observations 
	*** wave 2 has 2116, but 315 movers = 1801 total
	*** wave 3 has 2658 but 565 movers = 2093 total
	*** should be a total of 5769 - 21 too many
	*** no good way to figure out what these 21 observations are
	*** so going to include for now 

* create household, country, and data identifiers
* need to first replace empty places - otherwise will create hhid = . 
	replace 		y1_hhid = "0" if y1_hhid == ""
	replace 		y2_hhid = "0" if y2_hhid == ""
	replace 		y3_hhid = "0" if y3_hhid == ""
	
	egen			tza_id = group(y1_hhid y2_hhid y3_hhid)
	lab var			tza_id "Tanzania panel household id"

	gen				country = "tanzania"
	lab var			country "Country"

	gen				dtype = "lp"
	lab var			dtype "Data type"
	
	isid			tza_id year

* drop unnecessary variables
	drop			y1_hhid y2_hhid y3_hhid mover2010 mover2012 _merge
						
* order variables
	order			country dtype region district ward ea strataid clusterid ///
						tza_id hhweight year
				
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

* label satellites variables
	loc	sat			rf* tp*
	foreach v of varlist `sat' {
		lab var 		`v' "Satellite/Extraction"		
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
	*** 35 missing observations replaced
	
* save file
	qui: compress
	customsave 	, idvarname(tza_id) filename("tza_lp.dta") ///
		path("`export'") dofile(tza_append_built) user($user)
		
		
* **********************************************************************
* 4 - generate wave 4 cross section Tanzania 
* **********************************************************************

* import the first cross section file
	use 			"`root'/wave_4/npsy4_merged", clear

* create household, country, and data identifiers
	egen			cx_id = seq()
	lab var			cx_id "Cross section unique id"

	gen				country = "tanzania"
	lab var			country "Country"

	gen				dtype = "cx"
	lab var			dtype "Data type"

* order variables
	order			country dtype region district ward ea strataid clusterid ///
						cx_id hhweight year
	
	drop y4_hhid

* save file
	qui: compress
	customsave 	, idvarname(cx_id) filename("tza_cx.dta") ///
		path("`export'") dofile(tza_append_built) user($user)
		
		
* **********************************************************************
* 4 - append all Tanzania data
* **********************************************************************

* import the cross section file
	use 		"`export'/tza_lp.dta", clear

* append the two panel files
	append		using "`export'/tza_cx.dta", force	

* rename household weight
	rename		hhweight pw

* drop variables
	drop			region district ward ea strataid clusterid
	
	rename			tza_id lp_id
	
	order			country dtype cx_id lp_id year aez pw	
		
* create household, country, and data identifiers
	sort			lp_id cx_id year
	egen			uid = seq()
	lab var			uid "unique id"
	
* order variables
	order			uid
	
* save file
	qui: compress
	customsave 	, idvarname(uid) filename("tza_complete.dta") ///
		path("`export'") dofile(tza_append_built) user($user)

* close the log
	log	close

/* END */
