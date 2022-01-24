* Project: WB Weather
* Created on: September 2020
* Created by: alj
* Last updated: 28 October 2020 
* Last updated by: jdm
* Stata v.16.1

* does
	* NOTE IT TAKES 2.5 HOURS TO RUN ALL REGRESSIONS
	* loads multi country data set
	* runs rainfall and temperature lineara combo regressions
	* outputs results file for analysis

* assumes
	* cleaned, merged (weather), and appended (waves) data
	* customsave.ado

* TO DO:
	* everything 
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		source	= 	"$data/regression_data"
	loc		results = 	"$data/results_data"
	loc		logout 	= 	"$data/regression_data/logs"

* open log	
	cap log close
	log 	using 		"`logout'/regressions_lc", append

	
* **********************************************************************
* 1 - read in cross country panel
* **********************************************************************

* read in data file
	use			"`source'/lsms_panel.dta", clear

	
* **********************************************************************
* 2 - regressions on weather data
* **********************************************************************


* create locals for total farm and just for maize
	loc		inputstf 	lntf_lab lntf_frt tf_pst tf_hrb tf_irr
	loc 	inputscp 	lncp_lab lncp_frt cp_pst cp_hrb cp_irr
	loc		rainmean 	v01* v03* v04* v02* v05* v07*
	loc		tempmean 	v15* v17* v18* v16* v19* v21*

* create file to post results to
	tempname 	reg_results_lc
	postfile 	`reg_results_lc' country str3 varr str3 satr str2 extr ///
					str3 vart str3 satt str2 extt str2 depvar str4 regname ///
					betarain serain betatemp setemp adjustedr loglike dfr ///
					using "`results'/reg_results_lc.dta", replace
					
* define loop through levels of the data type variable	
	levelsof 	country		, local(levels)
	foreach		l of 		local levels {
 
	* set panel id so it varies by dtype
		xtset		hhid
					
	* define loop through rainfall local
		foreach 	r of	varlist `rainmean' { 
	
		* define locals for rainfall naming conventions
			loc 	varr = 	substr("`r'", 1, 3)
			loc 	satr = 	substr("`r'", 5, 3)
			loc 	extr = 	substr("`r'", 9, 2)
			
		* define loop through temperature local
			foreach 	t of	varlist `tempmean' {
		    
			* define locals for temperature naming conventions
				loc 	vart = 	substr("`t'", 1, 3)
				loc 	satt = 	substr("`t'", 5, 3)
				loc 	extt = 	substr("`t'", 9, 2)

			* define pairs to compare for linear regressions
				if 	`"`varr'"' == "v01"	& `"`vart'"' == "v15" | ///
					`"`varr'"' == "v02" & `"`vart'"' == "v16" | ///
					`"`varr'"' == "v05" & `"`vart'"' == "v19" | ///
					`"`varr'"' == "v07" & `"`vart'"' == "v21" {
	
				* define pairs of extrations to compare
					if `"`extr'"' == `"`extt'"' {
						
				    * 2.1: Value of Harvest
		
					* weather
						reg 		lntf_yld `r' `t' if country == `l', vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("tf") ("reg1") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')
									
					* weather and fe	
						xtreg 		lntf_yld `r' `t' i.year if country == `l', fe vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("tf") ("reg2") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')

					* weather and inputs and fe
						xtreg 		lntf_yld `r' `t' `inputstf' i.year if country == `l', fe vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("tf") ("reg3") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')

					* 2.2: Quantity of Maize
		
					* weather
						reg 		lncp_yld `r' `t' if country == `l', vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("cp") ("reg1") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')

					* weather and fe	
						xtreg 		lncp_yld `r' `t' i.year if country == `l', fe vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("cp") ("reg2") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')

					* weather and inputs and fe
						xtreg 		lncp_yld `r' `t' `inputscp' i.year if country == `l', fe vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("cp") ("reg3") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')
				}
			}
			* define pairs to compare for quadratic regressions
				if 	`"`varr'"' == "v01" & `"`vart'"' == "v15" | ///
					`"`varr'"' == "v05" & `"`vart'"' == "v19" {
	
				* define pairs of extrations to compare
					if `"`extr'"' == `"`extt'"' {
				    
				    * 2.1: Value of Harvest
					
					* weather and squared weather
						reg 		lntf_yld c.`r'##c.`r' c.`t'##c.`t' if country == `l', vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("tf") ("reg4") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')
		
					* weather and squared weather and fe
						xtreg 		lntf_yld c.`r'##c.`r' c.`t'##c.`t' i.year if country == `l', fe vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("tf") ("reg5") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')
		
					* weather and squared weather and inputs and fe
						xtreg 		lntf_yld c.`r'##c.`r' c.`t'##c.`t' `inputstf' i.year if country == `l', fe vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("tf") ("reg6") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')

					* 2.2: Quantity of Maize
			
					* weather and squared weather
						reg 		lncp_yld c.`r'##c.`r' c.`t'##c.`t' if country == `l', vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("cp") ("reg4") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')
						
					* weather and squared weather and fe
						xtreg 		lncp_yld c.`r'##c.`r' c.`t'##c.`t' i.year if country == `l', fe vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("cp") ("reg5") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')
		
					* weather and squared weather and inputs and fe
						xtreg 		lncp_yld c.`r'##c.`r' c.`t'##c.`t' `inputscp' i.year if country == `l', fe vce(cluster hhid)
						post 		`reg_results_lc' (`l') ("`varr'") ("`satr'") ("`extr'") ///
										("`vart'") ("`satt'") ("`extt'") ("cp") ("reg6") ///
										(`=_b[`r']') (`=_se[`r']') (`=_b[`t']') (`=_se[`t']') ///
										(`=e(r2_a)') (`=e(ll)') (`=e(df_r)')
				}
			}	
		}
	}
}

* close the post file and open the data file
	postclose	`reg_results_lc' 


* **********************************************************************
* 3 - clean post file
* **********************************************************************
	
* load post file
	loc		results = 	"$data/results_data"

	use 		"`results'/reg_results_lc", clear

* drop the cross section FE results
	drop if		loglike == .
	
* create country type variable
	lab def		country 1 "Ethiopia" 2 "Malawi" 3 "Mali" ///
					4 "Niger" 5 "Nigeria" 6 "Tanzania" ///
					7 "Uganda"
	lab val		country country
	lab var		country "Country"

* create variables for statistical testing
	gen 		tstat_rain = betarain/serain
	lab var		tstat_rain "t-statistic for rainfall"
	gen 		pval_rain = 2*ttail(dfr,abs(tstat_rain))
	lab var		pval_rain "p-value for rainfall"
	
	gen 		tstat_temp = betatemp/setemp
	lab var		tstat_temp "t-statistic for temperature"
	gen 		pval_temp = 2*ttail(dfr,abs(tstat_temp))
	lab var		pval_temp "p-value temperature"

* label variables
	rename		betarain beta_rain
	lab var		beta_rain "Coefficient on rainfall"
	rename		serain se_rain
	lab var		se_rain "Standard error on rainfall"
	rename		betatemp beta_temp
	lab var		beta_temp "Coefficient on temperature"
	rename		setemp se_temp
	lab var		se_temp "Standard error on temperature"
	lab var		adjustedr "Adjusted R^2"
	lab var		loglike "Log likelihood"
	lab var		dfr "Degrees of freedom"

* create unique id variable
	egen 		reg_id = group(country varr satr extr vart satt extt depvar regname)
	lab var 	reg_id "unique regression id"
	
* create variable to record the name of the rainfall variable
	sort		varr
	gen 		aux_varr = 1 if varr == "v01"
	replace 	aux_varr = 2 if varr == "v02"
	replace 	aux_varr = 5 if varr == "v05"
	replace 	aux_varr = 7 if varr == "v07"

* create variable to record the name of the temperature variable
	sort		vart
	gen			aux_vart = 15 if vart == "v15"
	replace 	aux_vart = 16 if vart == "v16"
	replace 	aux_vart = 19 if vart == "v19"
	replace 	aux_vart = 21 if vart == "v21"

* order and label the varaiable
	lab def		varname 	1 "Mean Daily Rainfall" ///
							2 "Median Daily Rainfall" ///
							3 "Variance of Daily Rainfall" ///
							4 "Skew of Daily Rainfall" ///
							5 "Total Rainfall" ///
							6 "Deviation in Total Rainfall" ///
							7 "Z-Score of Total Rainfall" ///
							8 "Rainy Days" ///
							9 "Deviation in Rainy Days" ///
							10 "No Rain Days" ///
							11 "Deviation in No Rain Days" ///
							12 "% Rainy Days" ///
							13 "Deviation in % Rainy Days" ///
							14 "Longest Dry Spell" ///
							15 "Mean Daily Temperature" ///
							16 "Median Daily Temperature" ///
							17 "Variance of Daily Temperature" ///
							18 "Skew of Daily Temperature" ///
							19 "Growing Degree Days (GDD)" ///
							20 "Deviation in GDD" ///
							21 "Z-Score of GDD" ///
							22 "Maximum Daily Temperature" 
	lab val		aux_varr varname
	lab var		aux_varr "Rainfall variable name"
	lab val		aux_vart varname
	lab var		aux_vart "Temperature variable name"
	drop 		varr vart
	rename 		aux_varr var_rain
	rename 		aux_vart var_temp
	order		var_rain, after(extr)
	order		var_temp, after(extt)
	
* create variable to record the name of the rainfall satellite
	sort		satr
	gen 		aux_satr = 1 if satr == "rf1"
	replace 	aux_satr = 2 if satr == "rf2"
	replace 	aux_satr = 3 if satr == "rf3"
	replace 	aux_satr = 4 if satr == "rf4"
	replace 	aux_satr = 5 if satr == "rf5"
	replace 	aux_satr = 6 if satr == "rf6"

* create variable to record the name of the temperature satellite
	sort		satt
	gen			aux_satt = 7 if satt == "tp1"
	replace 	aux_satt = 8 if satt == "tp2"
	replace 	aux_satt = 9 if satt == "tp3"

* order and label the satellite
	lab def		sat 	1 "Rainfall 1" ///
						2 "Rainfall 2" ///
						3 "Rainfall 3" ///
						4 "Rainfall 4" ///
						5 "Rainfall 5" ///
						6 "Rainfall 6" ///
						7 "Temperature 1" ///
						8 "Temperature 2" ///
						9 "Temperature 3" 
	lab val		aux_satr satr	
	lab var		aux_satr "Rainfall satellite source"
	drop 		satr
	rename 		aux_satr sat_rain
	lab val 	aux_satt satt
	lab var 	aux_satt "Temperature satellite source"
	drop 		satt
	rename 		aux_satt sat_temp 

* create variable to record the name of the rainfall extraction
	sort		extr
	gen 		aux_extr = 1 if extr == "x1"
	replace 	aux_extr = 2 if extr == "x2"
	replace 	aux_extr = 3 if extr == "x3"
	replace 	aux_extr = 4 if extr == "x4"
	replace 	aux_extr = 5 if extr == "x5"
	replace 	aux_extr = 6 if extr == "x6"
	replace 	aux_extr = 7 if extr == "x7"
	replace 	aux_extr = 8 if extr == "x8"
	replace 	aux_extr = 9 if extr == "x9"
	replace 	aux_extr = 0 if extr == "x0"

* create variable to record the name of the temperature extraction
	sort		extt
	gen 		aux_extt = 1 if extt == "x1"
	replace 	aux_extt = 2 if extt == "x2"
	replace 	aux_extt = 3 if extt == "x3"
	replace 	aux_extt = 4 if extt == "x4"
	replace 	aux_extt = 5 if extt == "x5"
	replace 	aux_extt = 6 if extt == "x6"
	replace 	aux_extt = 7 if extt == "x7"
	replace 	aux_extt = 8 if extt == "x8"
	replace 	aux_extt = 9 if extt == "x9"
	replace 	aux_extt = 0 if extt == "x0"
	
* order and label the varaiable
	lab def		ext 	1 "Extraction 1" ///
						2 "Extraction 2" ///
						3 "Extraction 3" ///
						4 "Extraction 4" ///
						5 "Extraction 5" ///
						6 "Extraction 6" ///
						7 "Extraction 7" ///
						8 "Extraction 8" ///
						9 "Extraction 9" ///
						10 "Extraction 10"
	lab val		aux_extr extr
	lab var		aux_extr "Rainfall extraction method"
	drop 		extr
	rename 		aux_extr ext_rain
	lab val		aux_extt extt
	lab var		aux_extt "Temperature extraction method"
	drop 		extt
	rename 		aux_extt ext_temp
	
* create variable to record the dependent variable
	sort 		depvar
	egen 		aux_dep = group(depvar)

* order and label the varaiable
	lab def		depvar 	1 "Quantity" ///
						2 "Value"
	lab val		aux_dep depvar
	lab var		aux_dep "Dependent variable"
	drop 		depvar
	rename 		aux_dep depvar
	
* create variable to record the regressions specification
	sort 		regname
	gen 		aux_reg = 1 if regname == "reg1"
	replace 	aux_reg = 2 if regname == "reg2"
	replace 	aux_reg = 3 if regname == "reg3"
	replace 	aux_reg = 4 if regname == "reg4"
	replace 	aux_reg = 5 if regname == "reg5"
	replace 	aux_reg = 6 if regname == "reg6"

* order and label the varaiable
	lab def		regname 	1 "Weather Only" ///
							2 "Weather + FE" ///
							3 "Weather + FE + Inputs" ///
							4 "Weather + Weather^2" ////
							5 "Weather + Weather^2 + FE" ///
							6 "Weather + Weather^2 + FE + Inputs" ///
							7 "Weather + Year FE" ///
							8 "Weather + Year FE + Inputs" ///
							9 "Weather + Weather^2 + Year FE" ///
							10 "Weather + Weather^2 + Year FE + Inputs"
	lab val		aux_reg regname
	lab var		aux_reg "Regression Name"
	drop 		regname
	rename 		aux_reg regname

	order		reg_id country sat_rain ext_rain var_rain sat_temp ext_temp ///
					var_temp depvar regname beta_rain se_rain tstat_rain ///
					tstat_temp beta_temp se_temp tstat_temp pval_temp
	
* save complete results
	compress
	
	customsave 	, idvarname(reg_id) filename("lsms_complete_results_lc.dta") ///
		path("`results'") dofile(regressions-linear-combo) user($user)

* close the log
	log	close

/* END */