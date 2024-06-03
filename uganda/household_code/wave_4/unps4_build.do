* Project: WB Weather
* Created on: Aug 2020
* Created by: jdm
* Edited on: 24 May 24
* Edited by: jdm
* Stata v.18

* does
	* merges weather data into unps4 household data
	* does this for north and south seperately

* assumes
	* cleaned GHSY3 data
	* processed wave 3 weather data
	* customsave.ado

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global 	rootw  		"$data/weather_data/uganda/wave_4/refined/unpsy4_up"  
	global  rooth 		"$data/household_data/uganda/wave_4/refined"
	global  export 		"$data/merged_data/uganda/wave_4"
	global 	logout 		"$data/merged_data/uganda/logs"

* open log	
	cap log close
	log 	using 		"$logout/unps4_build", append

	
* **********************************************************************
* 1 - merge northern household data with rainfall data
* **********************************************************************

* import the .dta houeshold file
	use 		"$rooth/hhfinal_unps4.dta", clear

*keep northern	
	keep if		season == 1
	
* generate variable to record data source
	gen 		data = "unps4"
	lab var 	data "Data Source"

* define each file in the above local
	loc 		fileList : dir "$rootw" files "*rf_n.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
		* merge weather data with household data
			merge 	1:1 hh using "$rootw/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		*drop variables for all years but 2013
			drop 		mean_season_1983- dry_2012
			drop 		mean_period_total_season- z_total_season_2012
			drop 		mean_period_raindays- dev_raindays_2012
			drop 		mean_period_norain- dev_norain_2012
			drop 		mean_period_percent_raindays- dev_percent_raindays_2012
		
		* define file naming criteria
			loc 		sat = substr("`file'", 8, 5)		
		
		* rename variables by dropping the year suffix
			gen 		v01_`sat' = mean_season_2013 if year == 2013
			lab var		v01_`sat' "Mean Daily Rainfall"
		
			gen 		v02_`sat' = median_season_2013 if year == 2013
			lab var		v02_`sat' "Median Daily Rainfall"

			gen 		v03_`sat' = sd_season_2013 if year == 2013
			lab var		v03_`sat' "Variance of Daily Rainfall"

			gen 		v04_`sat' = skew_season_2013 if year == 2013
			lab var		v04_`sat' "Skew of Daily Rainfall"

			gen 		v05_`sat' = total_season_2013 if year == 2013
			lab var		v05_`sat' "Total Rainfall"

			gen 		v06_`sat' = dev_total_season_2013 if year == 2013
			lab var		v06_`sat' "Deviation in Total Rainfalll"

			gen 		v07_`sat' = z_total_season_2013 if year == 2013
			lab var		v07_`sat' "Z-Score of Total Rainfall"	

			gen 		v08_`sat' = raindays_2013 if year == 2013
			lab var		v08_`sat' "Rainy Days"

			gen 		v09_`sat' = dev_raindays_2013 if year == 2013
			lab var		v09_`sat' "Deviation in Rainy Days"

			gen 		v10_`sat' = norain_2013 if year == 2013	
			lab var		v10_`sat' "No Rain Days"

			gen 		v11_`sat' = dev_norain_2013 if year == 2013
			lab var		v11_`sat' "Deviation in No Rain Days"

			gen 		v12_`sat' = percent_raindays_2013 if year == 2013
			lab var		v12_`sat' "% Rainy Days"

			gen 		v13_`sat' = dev_percent_raindays_2013 if year == 2013
			lab var		v13_`sat' "Deviation in % Rainy Days"

			gen 		v14_`sat' = dry_2013 if year == 2013
			lab var		v14_`sat' "Longest Dry Spell"
		
		* drop year variables
			drop 		*2013
}

	
* **********************************************************************
* 2 - merge northern temperature data with household data
* **********************************************************************

* define each file in the above local
	loc 		fileList : dir "$rootw/`folder'" files "*tp_n.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
	* merge weather data with household data
		merge 	1:1 hh using "$rootw/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		* drop variables for all years but 2013
			drop 		mean_season_1983- tempbin1002012
			drop 		mean_gdd- z_gdd_2012
		
		* define file naming criteria
			loc 		sat = substr("`file'", 8, 5)	
		
		* rename variables but dropping the year suffix
			gen 		v15_`sat' = mean_season_2013 if year == 2013
			lab var		v15_`sat' "Mean Daily Temperature"

			gen 		v16_`sat' = median_season_2013 if year == 2013
			lab var		v16_`sat' "Median Daily Temperature"

			gen 		v17_`sat' = sd_season_2013 if year == 2013
			lab var		v17_`sat' "Variance of Daily Temperature"

			gen 		v18_`sat' = skew_season_2013 if year == 2013
			lab var		v18_`sat' "Skew of Daily Temperature"	

			gen 		v19_`sat' = gdd_2013 if year == 2013
			lab var		v19_`sat' "Growing Degree Days (GDD)"	

			gen 		v20_`sat' = dev_gdd_2013 if year == 2013
			lab var		v20_`sat' "Deviation in GDD"	

			gen 		v21_`sat' = z_gdd_2013 if year == 2013
			lab var		v21_`sat' "Z-Score of GDD"	

			gen 		v22_`sat' = max_season_2013 if year == 2013
			lab var		v22_`sat' "Maximum Daily Temperature"

			gen 		v23_`sat' = tempbin202013 if year == 2013
			lab var		v23_`sat' "Temperature Bin 0-20"	

			gen 		v24_`sat' = tempbin402013 if year == 2013
			lab var		v24_`sat' "Temperature Bin 20-40"	

			gen 		v25_`sat' = tempbin602013 if year == 2013
			lab var		v25_`sat' "Temperature Bin 40-60"	

			gen 		v26_`sat' = tempbin802013 if year == 2013
			lab var		v26_`sat' "Temperature Bin 60-80"	

			gen 		v27_`sat' = tempbin1002013 if year == 2013
			lab var		v27_`sat' "Temperature Bin 80-100"
		
		* drop year variables
			drop 		*2013
}

* save file
	isid				hh
	
	qui: compress
	
	save 			"$export/unps4_merged_n.dta", replace

	
* **********************************************************************
* 3 - merge southern household data with rainfall data
* **********************************************************************

* import the .dta houeshold file
	use 		"$rooth/hhfinal_unps4.dta", clear

* drop northern regions
	keep if		season == 0
	
* generate variable to record data source
	gen 		data = "unps4"
	lab var 	data "Data Source"
	
* define each file in the above local
	loc 		fileList : dir "$rootw" files "*rf_s.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
		* merge weather data with household data
			merge 	1:1 hh using "$rootw/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		*drop variables for all years but 2013
			drop 		mean_season_1983- dry_2012
			drop 		mean_period_total_season- z_total_season_2012
			drop 		mean_period_raindays- dev_raindays_2012
			drop 		mean_period_norain- dev_norain_2012
			drop 		mean_period_percent_raindays- dev_percent_raindays_2012
		
		* define file naming criteria
			loc 		sat = substr("`file'", 8, 5)	
		
		* rename variables by dropping the year suffix
			gen 		v01_`sat' = mean_season_2013 if year == 2013
			lab var		v01_`sat' "Mean Daily Rainfall"
		
			gen 		v02_`sat' = median_season_2013 if year == 2013
			lab var		v02_`sat' "Median Daily Rainfall"

			gen 		v03_`sat' = sd_season_2013 if year == 2013
			lab var		v03_`sat' "Variance of Daily Rainfall"

			gen 		v04_`sat' = skew_season_2013 if year == 2013
			lab var		v04_`sat' "Skew of Daily Rainfall"

			gen 		v05_`sat' = total_season_2013 if year == 2013
			lab var		v05_`sat' "Total Rainfall"

			gen 		v06_`sat' = dev_total_season_2013 if year == 2013
			lab var		v06_`sat' "Deviation in Total Rainfalll"

			gen 		v07_`sat' = z_total_season_2013 if year == 2013
			lab var		v07_`sat' "Z-Score of Total Rainfall"	

			gen 		v08_`sat' = raindays_2013 if year == 2013
			lab var		v08_`sat' "Rainy Days"

			gen 		v09_`sat' = dev_raindays_2013 if year == 2013
			lab var		v09_`sat' "Deviation in Rainy Days"

			gen 		v10_`sat' = norain_2013 if year == 2013
			lab var		v10_`sat' "No Rain Days"

			gen 		v11_`sat' = dev_norain_2013 if year == 2013
			lab var		v11_`sat' "Deviation in No Rain Days"

			gen 		v12_`sat' = percent_raindays_2013 if year == 2013
			lab var		v12_`sat' "% Rainy Days"

			gen 		v13_`sat' = dev_percent_raindays_2013 if year == 2013
			lab var		v13_`sat' "Deviation in % Rainy Days"

			gen 		v14_`sat' = dry_2013 if year == 2013
			lab var		v14_`sat' "Longest Dry Spell"
		
		* drop year variables
			drop 		*2013
}

	
* **********************************************************************
* 4 - merge southern temperature data with household data
* **********************************************************************

* define each file in the above local
	loc 		fileList : dir "$rootw" files "*tp_s.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
	* merge weather data with household data
		merge 	1:1 hh using "$rootw/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		* drop variables for all years but 2013
			drop 		mean_season_1983- tempbin1002012
			drop 		mean_gdd- z_gdd_2012
		
		* define file naming criteria
			loc 		sat = substr("`file'", 8, 5)
		
		* rename variables but dropping the year suffix
			gen 		v15_`sat' = mean_season_2013 if year == 2013
			lab var		v15_`sat' "Mean Daily Temperature"

			gen 		v16_`sat' = median_season_2013 if year == 2013
			lab var		v16_`sat' "Median Daily Temperature"

			gen 		v17_`sat' = sd_season_2013 if year == 2013
			lab var		v17_`sat' "Variance of Daily Temperature"

			gen 		v18_`sat' = skew_season_2013 if year == 2013
			lab var		v18_`sat' "Skew of Daily Temperature"	

			gen 		v19_`sat' = gdd_2013 if year == 2013
			lab var		v19_`sat' "Growing Degree Days (GDD)"	

			gen 		v20_`sat' = dev_gdd_2013 if year == 2013
			lab var		v20_`sat' "Deviation in GDD"	

			gen 		v21_`sat' = z_gdd_2013 if year == 2013
			lab var		v21_`sat' "Z-Score of GDD"	

			gen 		v22_`sat' = max_season_2013 if year == 2013
			lab var		v22_`sat' "Maximum Daily Temperature"

			gen 		v23_`sat' = tempbin202013 if year == 2013
			lab var		v23_`sat' "Temperature Bin 0-20"	

			gen 		v24_`sat' = tempbin402013 if year == 2013
			lab var		v24_`sat' "Temperature Bin 20-40"	

			gen 		v25_`sat' = tempbin602013 if year == 2013
			lab var		v25_`sat' "Temperature Bin 40-60"	

			gen 		v26_`sat' = tempbin802013 if year == 2013
			lab var		v26_`sat' "Temperature Bin 60-80"	

			gen 		v27_`sat' = tempbin1002013 if year == 2013
			lab var		v27_`sat' "Temperature Bin 80-100"
		
		* drop year variables
			drop 		*2013
}

* save file
	isid				hh
	
	qui: compress
	
	save 			"$export/unps4_merged_s.dta", replace

	
* **********************************************************************
* 5 - append northern and southern data sets
* **********************************************************************

* import northern data
	use 			"$export/unps4_merged_n.dta", clear

* append southern data
	append			using "$export/unps4_merged_s.dta", force

* check to verify that there are observations for all variables
	sum
	*** missing observations in z-gdd
	*** this is because those osbervations always have the same number of gdd
	*** thus, they have no standard deviation and thus a z-score of infinity
	*** we recode these as zeros because a z-score equal to 0 represents an element equal to the mean
	
* replace missing z-gdd with missing
	loc	zgdd			v21_*
	foreach v of varlist `zgdd'{
	    replace		`v' = 0 if `v' == .
	}		
	
	qui: compress
	summarize 
	
* save file
	save 			"$export/unps4_merged.dta", replace

* erase northern and southern files
	erase			"$export/unps4_merged_n.dta"
	erase			"$export/unps4_merged_s.dta"

* close the log
	log	close

/* END */