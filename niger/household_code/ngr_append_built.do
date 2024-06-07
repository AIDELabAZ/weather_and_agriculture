* Project: WB Weather
* Created on: July 2020
* Created by: ek
* Edited on: 7 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in merged data sets
	* appends both complete data set (W1-W2)
	* outputs Niger data sets for analysis

* assumes
	* all Niger data has been cleaned and merged with rainfall
	* xfill.ado

* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		root 	= 	"$data/merged_data/niger"
	global		export 	= 	"$data/regression_data/niger"
	global		logout 	= 	"$data/merged_data/niger/logs"

* open log	
	cap 		log 		close 
	log 		using 		"$logout/ngr_append_built", append

	
* **********************************************************************
* 1 - merge first three waves of Niger household data
* **********************************************************************

* using merge rather than append
* import wave 1 niger
	use 			"$root/wave_1/ecvmay1_merged", clear
	
* append wave 2 file
	append			using "$root/wave_2/ecvmay2_merged", force	
		
	
* check the number of observations again
	count
	*** 3,951 observations 
	count if 		year == 2011
	*** wave 1 has 2,223
	count if 		year == 2014
	*** wave 2 has  1,728

* create household panel id
	sort			hid year
	egen			ngr_id = group(hid)
	lab var			ngr_id "Niger panel household id"
	
	drop			if extension == "1" | extension == "2"
	*** 39 observations deleted

	gen				country = "niger"
	lab var			country "Country"

	gen				dtype = "lp"
	lab var			dtype "Data type"
	
	isid			ngr_id year

* fill in missing aez
	xtset			ngr_id
	xfill			aez, i(ngr_id)
	*** 97 still missing

	replace			aez = 311 if aez == . & region == 1
	replace			aez = 312 if aez == . & region == 3
	replace			aez = 312 if aez == . & region == 4
	replace			aez = 312 if aez == . & region == 8
	*** 41 still missing

	replace			aez = 311 if aez == . & dept == 21
	replace			aez = 312 if aez == . & dept == 51
	replace			aez = 312 if aez == . & dept == 53
	replace			aez = 312 if aez == . & dept == 56
	replace			aez = 312 if aez == . & dept == 57
	replace			aez = 311 if aez == . & dept == 61
	replace			aez = 312 if aez == . & dept == 62
	replace			aez = 312 if aez == . & dept == 63
	replace			aez = 312 if aez == . & dept == 64
	replace			aez = 312 if aez == . & dept == 65
	replace			aez = 312 if aez == . & dept == 66
	replace			aez = 312 if aez == . & dept == 71
	replace			aez = 311 if aez == . & dept == 72
	replace			aez = 312 if aez == . & dept == 75
	*** 0 missing
	
* order variables
	drop			extension region dept canton enumeration clusterid ///
						hhid_y2
	
	order			country dtype ngr_id pw aez year 
	
	
* **********************************************************************
* 4 - End matter
* **********************************************************************

* create household, country, and data identifiers
	sort			ngr_id year
	egen			uid = seq()
	lab var			uid "unique id"
	
* order variables
	order			uid ngr_id
	
* save file
	qui: compress
	save			"$export/ngr_complete.dta", replace 

* close the log
	log	close

/* END */

