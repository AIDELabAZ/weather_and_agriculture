* Project: WB Weather
* Created on: September 2020
* Created by: jdm
* Stata v.16.1

* does
	* NOTE IT TAKES 3.5 HOURS TO RUN ALL REGRESSIONS
	* loads multi country data set
	* runs rainfall and temperature regressions
	* outputs results file for analysis

* assumes
	* cleaned, merged (weather), and appended (waves) data
	* customsave.ado

* TO DO:
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
	log 	using 		"`logout'/regressions", append

	
* **********************************************************************
* 1 - read in cross country panel
* **********************************************************************

* read in data file
	use			"`source'/lsms_panel.dta", clear

	
* **********************************************************************
* 2 - regressions on weather data
* **********************************************************************

* create locals for total farm and just for maize
	loc 	inputscp 	lncp_lab lncp_frt cp_pst cp_hrb cp_irr
	loc		inputstf 	lntf_lab lntf_frt tf_pst tf_hrb tf_irr
	loc		weather 	v*

* create file to post results to
	tempname 	reg_results
	postfile 	`reg_results' country str3 sat str2 ext str2 depvar str4 regname str3 varname ///
					betarain serain adjustedr loglike dfr ///
					using "`results'/reg_results.dta", replace
					
* define loop through levels of the data type variable	
levelsof 	country		, local(levels)
foreach l of local levels {
	
	* set panel id so it varies by dtype
		xtset		hhid
		
	* rainfall			
		foreach 	v of varlist `weather' { 

		* define locals for naming conventions
			loc 	sat = 	substr("`v'", 5, 3)
			loc 	ext = 	substr("`v'", 9, 2)
			loc 	varn = 	substr("`v'", 1, 3)

		* 2.1: Value of Harvest
		
		* weather
			reg 		lntf_yld `v' if country == `l', vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("tf") ("reg1") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')

		* weather and fe	
			xtreg 		lntf_yld `v' i.year if country == `l', fe vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("tf") ("reg2") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')

		* weather and inputs and fe
			xtreg 		lntf_yld `v' `inputstf' i.year if country == `l', fe vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("tf") ("reg3") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')
			
		* weather and squared weather
			reg 		lntf_yld c.`v'##c.`v' if country == `l', vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("tf") ("reg4") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')
		
		* weather and squared weather and fe
			xtreg 		lntf_yld c.`v'##c.`v' i.year if country == `l', fe vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("tf") ("reg5") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')
		
		* weather and squared weather and inputs and fe
			xtreg 		lntf_yld c.`v'##c.`v' `inputstf' i.year if country == `l', fe vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("tf") ("reg6") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')

		* 2.2: Quantity of Maize
		
		* weather
			reg 		lncp_yld `v' if country == `l', vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("cp") ("reg1") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')

		* weather and fe	
			xtreg 		lncp_yld `v' i.year if country == `l', fe vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("cp") ("reg2") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')

		* weather and inputs and fe
			xtreg 		lncp_yld `v' `inputscp' i.year if country == `l', fe vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("cp") ("reg3") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')
			
		* weather and squared weather
			reg 		lncp_yld c.`v'##c.`v' if country == `l', vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("cp") ("reg4") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')
		
		* weather and squared weather and fe
			xtreg 		lncp_yld c.`v'##c.`v' i.year if country == `l', fe vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("cp") ("reg5") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')
		
		* weather and squared weather and inputs and fe
			xtreg 		lncp_yld c.`v'##c.`v' `inputscp' i.year if country == `l', fe vce(cluster hhid)
			post 		`reg_results' (`l') ("`sat'") ("`ext'") ("cp") ("reg6") ///
						("`varn'") (`=_b[`v']') (`=_se[`v']') (`=e(r2_a)') ///
						(`=e(ll)') (`=e(df_r)')

	}
}

* close the post file and open the data file
	postclose	`reg_results' 
	use 		"`results'/reg_results", clear

* drop the cross section FE results
	drop if		loglike == .
	
* create country type variable
	lab def		country 1 "Ethiopia" 2 "Malawi" 3 "Mali" ///
					4 "Niger" 5 "Nigeria" 6 "Tanzania" ///
					7 "Uganda"
	lab val		country country
	lab var		country "Country"
	
* create data type variables
*	lab define 	dtype 0 "cx" 1 "lp" 2 "sp"
*	label val 	data dtype

* create variables for statistical testing
	gen 		tstat = betarain/serain
	lab var		tstat "t-statistic"
	gen 		pval = 2*ttail(dfr,abs(tstat))
	lab var		pval "p-value"
	gen 		ci_lo =  betarain - invttail(dfr,0.025)*serain
	lab var		ci_lo "Lower confidence interval"
	gen 		ci_up =  betarain + invttail(dfr,0.025)*serain
	lab var		ci_up "Upper confidence interval"

* label variables
	rename		betarain beta
	lab var		beta "Coefficient"
	rename		serain stdrd_err
	lab var		stdrd_err "Standard error"
	lab var		adjustedr "Adjusted R^2"
	lab var		loglike "Log likelihood"
	lab var		dfr "Degrees of freedom"

* create unique id variable
	egen 		reg_id = group(country sat ext depvar regname varname)
	lab var 	reg_id "unique regression id"
	
* create variable to record the name of the rainfall variable
	sort		varname
	gen 		aux_var = 1 if varname == "v01"
	replace 	aux_var = 2 if varname == "v02"
	replace 	aux_var = 3 if varname == "v03"
	replace 	aux_var = 4 if varname == "v04"
	replace 	aux_var = 5 if varname == "v05"
	replace 	aux_var = 6 if varname == "v06"
	replace 	aux_var = 7 if varname == "v07"
	replace 	aux_var = 8 if varname == "v08"
	replace 	aux_var = 9 if varname == "v09"
	replace 	aux_var = 10 if varname == "v10"
	replace 	aux_var = 11 if varname == "v11"
	replace 	aux_var = 12 if varname == "v12"
	replace 	aux_var = 13 if varname == "v13"
	replace 	aux_var = 14 if varname == "v14"
	replace 	aux_var = 15 if varname == "v15"
	replace 	aux_var = 16 if varname == "v16"
	replace 	aux_var = 17 if varname == "v17"
	replace 	aux_var = 18 if varname == "v18"
	replace 	aux_var = 19 if varname == "v19"
	replace 	aux_var = 20 if varname == "v20"
	replace 	aux_var = 21 if varname == "v21"
	replace 	aux_var = 22 if varname == "v22"

* order and label the varaiable
	order 		aux_var, after(varname)
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
	lab val		aux_var varname
	lab var		aux_var "Variable name"
	drop 		varname
	rename 		aux_var varname
	drop		if varname == .
	
* create variable to record the name of the satellite
	sort 		sat
	egen 		aux_sat = group(sat)

* order and label the varaiable
	order 		aux_sat, after(sat)
	lab def		sat 	1 "Rainfall 1" ///
						2 "Rainfall 2" ///
						3 "Rainfall 3" ///
						4 "Rainfall 4" ///
						5 "Rainfall 5" ///
						6 "Rainfall 6" ///
						7 "Temperature 1" ///
						8 "Temperature 2" ///
						9 "Temperature 3" 
	lab val		aux_sat sat	
	lab var		aux_sat "Satellite source"
	drop 		sat
	rename 		aux_sat sat

* create variable to record the extraction method
	sort 		ext
	egen 		aux_ext = group(ext)
	replace		aux_ext = 11 if aux_ext == 1
	replace		aux_ext = aux_ext - 1
	
* order and label the varaiable
	order 		aux_ext, after(ext)
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
	lab val		aux_ext ext
	lab var		aux_ext "Extraction method"
	drop 		ext
	rename 		aux_ext ext

* create variable to record the dependent variable
	sort 		depvar
	egen 		aux_dep = group(depvar)

* order and label the varaiable
	order 		aux_dep, after(depvar)
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
	order 		aux_reg, after(regname)
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

order	reg_id
	
* save complete results
	loc		results = 	"$data/results_data"
	
	compress
	
	customsave 	, idvarname(reg_id) filename("lsms_complete_results.dta") ///
		path("`results'") dofile(regression) user($user)

* close the log
	log	close

/* END */