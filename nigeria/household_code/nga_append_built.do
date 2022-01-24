* Project: WB Weather
* Created on: July 2020
* Created by: ek
* Stata v.16

* does
	* reads in merged data sets
	* appends all three to form complete data set (W1-W3)
	* outputs Nigeria data sets for analysis

* assumes
	* all Nigeria data has been cleaned and merged with rainfall
	* customsave.ado

* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc 	weight	= 	"$data/household_data/nigeria/wave_3/raw"  
	loc		root 	= 	"$data/merged_data/nigeria"
	loc		export 	= 	"$data/regression_data/nigeria"
	loc		logout 	= 	"$data/merged_data/nigeria/logs"

* open log	
	cap 	log 	close 
	log 	using 	"`logout'/nga_append_built", append

	
* **********************************************************************
* 1 - merge first three waves of Nigeria household data
* **********************************************************************

* using merge rather than append
* import wave 1 nigeria
	
	use 			"`root'/wave_1/ghsy1_merged", clear
	*** at the moment I believe that all three waves of nigeria identify hh's the same
	
* append wave 2 file
	append			using "`root'/wave_2/ghsy2_merged", force	
	
* append wave 3 file 
	append			using "`root'/wave_3/ghsy3_merged", force	
	
* check the number of observations again
	count
	*** 8384 observations 
	count if 		year == 2010
	*** wave 1 has 2833
	count if 		year == 2012
	*** wave 2 has 2768
	count if 		year == 2015
	*** wave 3 has 2783

* **********************************************************************
* 2 - merge in sampling weights
* **********************************************************************
	
	merge			m:1 hhid using "`weight'/HHTrack"
	*** all in master matched
	
	keep			if _merge == 3
	
	gen				pw = wt_wave1 if year == 2010
	replace			pw = wt_wave2 if year == 2012
	replace			pw = wt_wave3 if year == 2015
	replace			pw = wt_w2v2 if pw == .
	lab var			pw "Final household weight"
	
	drop			hhstatus_w1v1 - _merge
	
* generate panel id
	sort			hhid year
	egen			nga_id = group(hhid)
	lab var			nga_id "Nigeria panel household id"

	gen				country = "nigeria"
	lab var			country "Country"

	gen				dtype = "lp"
	lab var			dtype "Data type"
	
	isid			nga_id year

* drop variables
	drop			zone state lga sector ea hhid
	
	order			country dtype nga_id pw aez year 

	
* **********************************************************************
* 4 - End matter
* **********************************************************************

* create household, country, and data identifiers
	sort			nga_id year
	egen			uid = seq()
	lab var			uid "unique id"
	
* order variables
	order			uid nga_id
	
* save file
	qui: compress
	customsave 	, idvarname(uid) filename("nga_complete.dta") ///
		path("`export'") dofile(nga_append_built) user($user)

* close the log
	log	close

/* END */

