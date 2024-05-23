* Project: WB Weather
* Created on: May 2024
* Created by: jdm
* Edited on: 21 May 2024
* Edited by: jdm
* Stata v.18

* does
	* merges weather data with Tanzania NPSY5-SDD data

* assumes
	* cleaned NPSY-SDD data
	* processed wave 6 (SDD) weather data

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		rootw 	= 	"$data/weather_data/tanzania/wave_6/refined/npsy5sdd_up"
	global		rooth 	= 	"$data/household_data/tanzania/wave_6/refined"
	global		export 	= 	"$data/merged_data/tanzania/wave_6"
	global		logout 	= 	"$data/merged_data/tanzania/logs"

* open log	
	cap log 	close 
	log 		using 		"$logout/npsy5sdd_build", append

	
* **********************************************************************
* 1 - merge rainfall data with household data
* **********************************************************************

* import the .dta houeshold file
	use 		"$rooth/hhfinal_npsy5sdd.dta", clear
	
* generate variable to record data source
	gen 		data = "npsy5sdd"
	lab var 	data "Data Source"
	
	rename		mover2019 mover
	
	replace		year = 2018
	
* define each file in the above local
	loc 		fileList : dir "$rootw" files "*rf.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
	* merge weather data with household data
		merge 	1:1 sdd_hhid using "$rootw/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		*drop variables for all years but 2018
			drop 		mean_season_1983- dry_2017
			drop 		mean_period_total_season- z_total_season_2017
			drop 		mean_period_raindays- dev_raindays_2017
			drop 		mean_period_norain- dev_norain_2017
			drop 		mean_period_percent_raindays- dev_percent_raindays_2017
		
		* define file naming criteria
			loc 		sat = substr("`file'", 10, 5)	
		
		* rename variables by dropping the year suffix
			gen 		v01_`sat' = mean_season_2018 if year == 2018
			lab var		v01_`sat' "Mean Daily Rainfall"
		
			gen 		v02_`sat' = median_season_2018 if year == 2018
			lab var		v02_`sat' "Median Daily Rainfall"

			gen 		v03_`sat' = sd_season_2018 if year == 2018
			lab var		v03_`sat' "Variance of Daily Rainfall"

			gen 		v04_`sat' = skew_season_2018 if year == 2018
			lab var		v04_`sat' "Skew of Daily Rainfall"

			gen 		v05_`sat' = total_season_2018 if year == 2018
			lab var		v05_`sat' "Total Rainfall"

			gen 		v06_`sat' = dev_total_season_2018 if year == 2018
			lab var		v06_`sat' "Deviation in Total Rainfalll"

			gen 		v07_`sat' = z_total_season_2018 if year == 2018
			lab var		v07_`sat' "Z-Score of Total Rainfall"	

			gen 		v08_`sat' = raindays_2018 if year == 2018
			lab var		v08_`sat' "Rainy Days"

			gen 		v09_`sat' = dev_raindays_2018 if year == 2018
			lab var		v09_`sat' "Deviation in Rainy Days"

			gen 		v10_`sat' = norain_2018 if year == 2018	
			lab var		v10_`sat' "No Rain Days"

			gen 		v11_`sat' = dev_norain_2018 if year == 2018
			lab var		v11_`sat' "Deviation in No Rain Days"

			gen 		v12_`sat' = percent_raindays_2018 if year == 2018
			lab var		v12_`sat' "% Rainy Days"

			gen 		v13_`sat' = dev_percent_raindays_2018 if year == 2018
			lab var		v13_`sat' "Deviation in % Rainy Days"

			gen 		v14_`sat' = dry_2018 if year == 2018
			lab var		v14_`sat' "Longest Dry Spell"
		
		* drop year variables
			drop 		*2018										
}

	
* **********************************************************************
* 2 - merge temperature data with household data
* **********************************************************************
	
* define each file in the above local
	loc 		fileList : dir "$rootw" files "*tp.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
	* merge weather data with household data
		merge 	1:1 sdd_hhid using "$rootw/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		* drop variables for all years but 2018
			drop 		mean_season_1983- tempbin1002017
			drop 		mean_gdd- z_gdd_2017
			
		* define file naming criteria
			loc 		sat = substr("`file'", 10, 5)
		
		* rename variables but dropping the year suffix
			gen 		v15_`sat' = mean_season_2018 if year == 2018
			lab var		v15_`sat' "Mean Daily Temperature"

			gen 		v16_`sat' = median_season_2018 if year == 2018
			lab var		v16_`sat' "Median Daily Temperature"

			gen 		v17_`sat' = sd_season_2018 if year == 2018
			lab var		v17_`sat' "Variance of Daily Temperature"

			gen 		v18_`sat' = skew_season_2018 if year == 2018
			lab var		v18_`sat' "Skew of Daily Temperature"	

			gen 		v19_`sat' = gdd_2018 if year == 2018
			lab var		v19_`sat' "Growing Degree Days (GDD)"	

			gen 		v20_`sat' = dev_gdd_2018 if year == 2018
			lab var		v20_`sat' "Deviation in GDD"	

			gen 		v21_`sat' = z_gdd_2018 if year == 2018
			lab var		v21_`sat' "Z-Score of GDD"	

			gen 		v22_`sat' = max_season_2018 if year == 2018
			lab var		v22_`sat' "Maximum Daily Temperature"

			gen 		v23_`sat' = tempbin202018 if year == 2018
			lab var		v23_`sat' "Temperature Bin 0-20"	

			gen 		v24_`sat' = tempbin402018 if year == 2018
			lab var		v24_`sat' "Temperature Bin 20-40"	

			gen 		v25_`sat' = tempbin602018 if year == 2018
			lab var		v25_`sat' "Temperature Bin 40-60"	

			gen 		v26_`sat' = tempbin802018 if year == 2018
			lab var		v26_`sat' "Temperature Bin 60-80"	

			gen 		v27_`sat' = tempbin1002018 if year == 2018
			lab var		v27_`sat' "Temperature Bin 80-100"
		
		* drop year variables
			drop 		*2018													
}

* create wide data set 	
	rename 			* *2018
	rename 			region2018 region
	rename 			district2018 district
	rename 			ward2018 ward
	rename 			ea2018 ea
	rename 			*hhid2018 *hhid
	
* drop unneeded variables
	drop			year2018

* prepare for export
	qui: compress
	sort sdd_hhid
	
* save file
	save 				"$export/npsy5sdd_merged.dta", replace
		
* close the log
	log	close

/* END */