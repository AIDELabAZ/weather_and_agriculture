* Project: WB Weather
* Created on: May 2020
* Created by: ek
* Stata v.16

* does
	* merges weather data into ngr household data

* assumes
	* cleaned Ngr household data
	* processed wave 1 weather data
	* customsave.ado

* TO DO:
	* adapt the code from nigera to niger

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		rootw 	= 	"$data/weather_data/niger/wave_1/refined"
	loc		rooth 	= 	"$data/household_data/niger/wave_1/refined"
	loc		export 	= 	"$data/merged_data/niger/wave_1"
	loc		logout 	= 	"$data/merged_data/niger/logs"
	
* open log	
	cap 	log			 close
	log 	using 		"`logout'/ECVMA_2011_build", append

	
* **********************************************************************
* 1 - merge all household data with rainfall data
* **********************************************************************

* import the .dta houeshold file
	use 		"`rooth'/hhfinal_ecvma1.dta", clear
	
* generate variable to record data source
	gen 		data = "ecvmay1"
	lab var 	data "Data Source"
	
* define local with all sub-folders in it
	loc 		folderList : dir "`rootw'" dirs "ecvmay1_rf*"

* define local with all files in each sub-folder	
	foreach 	folder of local folderList {

	* define each file in the above local
		loc 		fileList : dir "`rootw'/`folder'" files "*.dta"
	
	* loop through each file in the above local
		foreach 	file in `fileList' {	
	
		* merge weather data with household data
			merge 	1:1 hid using "`rootw'/`folder'/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		*drop variables for all years but 2011
			drop 		mean_season_1983- dry_2010 mean_season_2012- dry_2017
			drop 		mean_period_total_season- z_total_season_2010 ///
						dev_total_season_2012- z_total_season_2017
			drop 		mean_period_raindays- dev_raindays_2010 ///
						dev_raindays_2012- dev_raindays_2017
			drop 		mean_period_norain- dev_norain_2010 ///
						dev_norain_2012- dev_norain_2017
			drop 		mean_period_percent_raindays- dev_percent_raindays_2010 ///
						dev_percent_raindays_2012 - dev_percent_raindays_2017
		
		* define file naming criteria
			loc 		sat = substr("`file'", 12, 3)
			loc 		ext = substr("`file'", 9, 2)
			
		* generate variable to record extraction method
			gen 		`sat'_`ext' = "`sat'_`ext'"
			lab var 	`sat'_`ext' "Satellite/Extraction"			
		
		* rename variables by dropping the year suffix
			gen 		v01_`sat'_`ext' = mean_season_2011 if year == 2011
			lab var		v01_`sat'_`ext' "Mean Daily Rainfall"
		
			gen 		v02_`sat'_`ext' = median_season_2011 if year == 2011
			lab var		v02_`sat'_`ext' "Median Daily Rainfall"

			gen 		v03_`sat'_`ext' = sd_season_2011 if year == 2011
			lab var		v03_`sat'_`ext' "Variance of Daily Rainfall"

			gen 		v04_`sat'_`ext' = skew_season_2011 if year == 2011
			lab var		v04_`sat'_`ext' "Skew of Daily Rainfall"

			gen 		v05_`sat'_`ext' = total_season_2011 if year == 2011
			lab var		v05_`sat'_`ext' "Total Rainfall"

			gen 		v06_`sat'_`ext' = dev_total_season_2011 if year == 2011
			lab var		v06_`sat'_`ext' "Deviation in Total Rainfalll"

			gen 		v07_`sat'_`ext' = z_total_season_2011 if year == 2011
			lab var		v07_`sat'_`ext' "Z-Score of Total Rainfall"	

			gen 		v08_`sat'_`ext' = raindays_2011 if year == 2011
			lab var		v08_`sat'_`ext' "Rainy Days"

			gen 		v09_`sat'_`ext' = dev_raindays_2011 if year == 2011
			lab var		v09_`sat'_`ext' "Deviation in Rainy Days"

			gen 		v10_`sat'_`ext' = norain_2011 if year == 2011	
			lab var		v10_`sat'_`ext' "No Rain Days"

			gen 		v11_`sat'_`ext' = dev_norain_2011 if year == 2011
			lab var		v11_`sat'_`ext' "Deviation in No Rain Days"

			gen 		v12_`sat'_`ext' = percent_raindays_2011 if year == 2011
			lab var		v12_`sat'_`ext' "% Rainy Days"

			gen 		v13_`sat'_`ext' = dev_percent_raindays_2011 if year == 2011
			lab var		v13_`sat'_`ext' "Deviation in % Rainy Days"

			gen 		v14_`sat'_`ext' = dry_2011 if year == 2011
			lab var		v14_`sat'_`ext' "Longest Dry Spell"
		
		* drop year variables
			drop 		*2011
		}
}

* **********************************************************************
* 2 - merge temperature data with household data
* **********************************************************************

* define local with all sub-folders in it
	loc 		folderList : dir "`rootw'" dirs "ecvmay1_t*"

* define local with all files in each sub-folder	
	foreach 	folder of local folderList {

* define each file in the above local
	loc 		fileList : dir "`rootw'/`folder'" files "*.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
	* merge weather data with household data
		merge 	1:1 hid using "`rootw'/`folder'/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		* drop variables for all years but 2011
			drop 		mean_season_1983- tempbin1002010 ///
						mean_season_2012- tempbin1002017
			drop 		mean_gdd- z_gdd_2010 dev_gdd_2012- z_gdd_2017
		
		* define file naming criteria
			loc 		sat = substr("`file'", 13, 1)
			loc 		ext = substr("`file'", 9, 2)
			
		* generate variable to record extraction method
			gen 		tp`sat'_`ext' = "tp`sat'_`ext'"
			lab var 	tp`sat'_`ext' "Satellite/Extraction"
		
		* rename variables but dropping the year suffix
			gen 		v15_tp`sat'_`ext' = mean_season_2011 if year == 2011
			lab var		v15_tp`sat'_`ext' "Mean Daily Temperature"

			gen 		v16_tp`sat'_`ext' = median_season_2011 if year == 2011
			lab var		v16_tp`sat'_`ext' "Median Daily Temperature"

			gen 		v17_tp`sat'_`ext' = sd_season_2011 if year == 2011
			lab var		v17_tp`sat'_`ext' "Variance of Daily Temperature"

			gen 		v18_tp`sat'_`ext' = skew_season_2011 if year == 2011
			lab var		v18_tp`sat'_`ext' "Skew of Daily Temperature"	

			gen 		v19_tp`sat'_`ext' = gdd_2011 if year == 2011
			lab var		v19_tp`sat'_`ext' "Growing Degree Days (GDD)"	

			gen 		v20_tp`sat'_`ext' = dev_gdd_2011 if year == 2011
			lab var		v20_tp`sat'_`ext' "Deviation in GDD"	

			gen 		v21_tp`sat'_`ext' = z_gdd_2011 if year == 2011
			lab var		v21_tp`sat'_`ext' "Z-Score of GDD"	

			gen 		v22_tp`sat'_`ext' = max_season_2011 if year == 2011
			lab var		v22_tp`sat'_`ext' "Maximum Daily Temperature"

			gen 		v23_tp`sat'_`ext' = tempbin202011 if year == 2011
			lab var		v23_tp`sat'_`ext' "Temperature Bin 0-20"	

			gen 		v24_tp`sat'_`ext' = tempbin402011 if year == 2011
			lab var		v24_tp`sat'_`ext' "Temperature Bin 20-40"	

			gen 		v25_tp`sat'_`ext' = tempbin602011 if year == 2011
			lab var		v25_tp`sat'_`ext' "Temperature Bin 40-60"	

			gen 		v26_tp`sat'_`ext' = tempbin802011 if year == 2011
			lab var		v26_tp`sat'_`ext' "Temperature Bin 60-80"	

			gen 		v27_tp`sat'_`ext' = tempbin1002011 if year == 2011
			lab var		v27_tp`sat'_`ext' "Temperature Bin 80-100"
		
		* drop year variables
			drop 		*2011
	}
}

* save file
	
	qui: compress
	summarize 

	customsave 	, idvar(hid) filename("ecvmay1_merged.dta") ///
		path("`export'") dofile(ecvmay1_build) user($user)

	
* close the log
	log	close

/* END */