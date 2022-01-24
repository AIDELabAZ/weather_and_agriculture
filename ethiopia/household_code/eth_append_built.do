* Project: WB Weather
* Created on: Aug 2020
* Created by: mcg
* Stata v.16

* does
	* reads in merged data sets
	* appends merged data sets
	* outputs appended ethiopia panel with all three waves


* assumes
	* all ethiopia data has been cleaned and merged with rainfall
	* customsave.ado
	* xfill.ado

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/merged_data/ethiopia"
	loc		export 	= 	"$data/regression_data/ethiopia"
	loc		logout 	= 	"$data/merged_data/ethiopia/logs"

* open log	
	cap log close
	log 	using 		"`logout'/eth_append_build", append
	
	
* **********************************************************************
* 1 - append data
* **********************************************************************

* import wave 1 dataset
	use 		"`root'/wave_1/essy1_merged.dta", clear

* append wave 2 dataset
	append		using "`root'/wave_2/essy2_merged.dta", force
	
* append wave 3 dataset
	append		using "`root'/wave_3/essy3_merged", force	
	
* check the number of observations again
	count
	*** 7312 observations 
	count if 		year == 2011
	*** wave 1 has 1694
	count if 		year == 2013
	*** wave 2 has 2900
	count if 		year == 2015
	*** wave 3 has 2718
	
* drop observations missing year 1 household id
	drop if			household_id == ""
	
* dropping 2017 weather data
	drop			*2017

* generate ethiopia panel id
	egen			eth_id = group(household_id)
	lab var			eth_id "Ethiopia panel household id"	

* generate country and data types
	gen				country = "ethiopia"
	lab var			country "Country"

	gen				dtype = "lp"
	lab var			dtype "Data type"
	
	isid			eth_id year
	
* generate one variable for sampling weight
	gen				weight = pw
	tab				weight, missing
	
	replace			weight = pw2 if weight == .
	replace			weight = pw_w3 if weight == .
	tab 			weight, missing
	
	drop			pw pw2 pw_w3
	
	rename			weight pw
	lab var			pw "Household Sample Weight"
	
* drop variables
	drop			region zone woreda ea household_id2 household_id
	
	order			country dtype eth_id year aez pw
	
	
* **********************************************************************
* 4 - end matter
* **********************************************************************

* create household, country, and data identifiers
	sort			eth_id year
	egen			uid = seq()
	lab var			uid "Unique id"
	
* order variables
	order			uid

	
* save file
	qui: compress
	customsave 	, idvarname(uid) filename("eth_complete.dta") ///
		path("`export'") dofile(eth_append_built) user($user)

* close the log
	log	close

/* END */
