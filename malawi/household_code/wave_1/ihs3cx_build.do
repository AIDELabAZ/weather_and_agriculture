* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Stata v.16

* does
	* merges weather data with Malawi IHS3 cross section

* assumes
	* cleaned IHS3 cross sectional data
	* processed wave 1 weather data
	* customsave.ado

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		rootw 	= 	"$data/weather_data/malawi/wave_1/refined"
	loc		rooth 	= 	"$data/household_data/malawi/wave_1/refined"
	loc		export 	= 	"$data/merged_data/malawi/wave_1"
	loc		logout 	= 	"$data/merged_data/malawi/logs"

* open log	
	log 	using 		"`logout'/ihs3cx_build", append

	
* **********************************************************************
* 1 - merge rainfall data with household data
* **********************************************************************

* import the .dta houeshold file
	use 		"`rooth'/hhfinal_ihs3cx.dta", clear
	    
* generate variable to record data source
	gen 		data = "cx1"
	lab var 	data "Data Source"	
	
* define local with all sub-folders in it
	loc 		folderList : dir "`rootw'" dirs "IHS3_rf*"

* define local with all files in each sub-folder	
	foreach 	folder of local folderList {

* define each file in the above local
	loc 		fileList : dir "`rootw'/`folder'" files "*.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
	* merge weather data with household data
		merge 	1:1 case_id using "`rootw'/`folder'/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		* drop variables for all years before 2008 and after 2009
			drop 		mean_season_1983- dry_2007 mean_season_2010- dry_2016
			drop 		mean_period_total_season- z_total_season_2007 ///
						dev_total_season_2010- z_total_season_2016
			drop 		mean_period_raindays- dev_raindays_2007 ///
						dev_raindays_2010- dev_raindays_2016
			drop 		mean_period_norain- dev_norain_2007 ///
						dev_norain_2010- dev_norain_2016
			drop 		mean_period_percent_raindays- dev_percent_raindays_2007 ///
						dev_percent_raindays_2010- dev_percent_raindays_2016	
		
		* define file naming criteria
			loc 		sat = substr("`file'", 9, 3)
			loc 		ext = substr("`file'", 6, 2)
			
		* generate variable to record extraction method
			gen 		`sat'_`ext' = "`sat'_`ext'"
			lab var 	`sat'_`ext' "Satellite/Extraction"			
		
		* rename variables by dropping the year suffix
			gen 		v01_`sat'_`ext' = mean_season_2008 if year == 2008
			replace 	v01_`sat'_`ext' = mean_season_2009 if year == 2009
			lab var		v01_`sat'_`ext' "Mean Daily Rainfall"
		
			gen 		v02_`sat'_`ext' = median_season_2008 if year == 2008
			replace 	v02_`sat'_`ext' = median_season_2009 if year == 2009
			lab var		v02_`sat'_`ext' "Median Daily Rainfall"

			gen 		v03_`sat'_`ext' = sd_season_2008 if year == 2008
			replace 	v03_`sat'_`ext' = sd_season_2009 if year == 2009
			lab var		v03_`sat'_`ext' "Variance of Daily Rainfall"

			gen 		v04_`sat'_`ext' = skew_season_2008 if year == 2008
			replace 	v04_`sat'_`ext' = skew_season_2009 if year == 2009
			lab var		v04_`sat'_`ext' "Skew of Daily Rainfall"

			gen 		v05_`sat'_`ext' = total_season_2008 if year == 2008
			replace 	v05_`sat'_`ext' = total_season_2009 if year == 2009
			lab var		v05_`sat'_`ext' "Total Rainfall"

			gen 		v06_`sat'_`ext' = dev_total_season_2008 if year == 2008
			replace 	v06_`sat'_`ext' = dev_total_season_2009 if year == 2009
			lab var		v06_`sat'_`ext' "Deviation in Total Rainfalll"

			gen 		v07_`sat'_`ext' = z_total_season_2008 if year == 2008
			replace 	v07_`sat'_`ext' = z_total_season_2009 if year == 2009
			lab var		v07_`sat'_`ext' "Z-Score of Total Rainfall"	

			gen 		v08_`sat'_`ext' = raindays_2008 if year == 2008
			replace 	v08_`sat'_`ext' = raindays_2009 if year == 2009
			lab var		v08_`sat'_`ext' "Rainy Days"

			gen 		v09_`sat'_`ext' = dev_raindays_2008 if year == 2008
			replace 	v09_`sat'_`ext' = dev_raindays_2009 if year == 2009
			lab var		v09_`sat'_`ext' "Deviation in Rainy Days"

			gen 		v10_`sat'_`ext' = norain_2008 if year == 2008
			replace 	v10_`sat'_`ext' = norain_2009 if year == 2009	
			lab var		v10_`sat'_`ext' "No Rain Days"

			gen 		v11_`sat'_`ext' = dev_norain_2008 if year == 2008
			replace 	v11_`sat'_`ext' = dev_norain_2009 if year == 2009
			lab var		v11_`sat'_`ext' "Deviation in No Rain Days"

			gen 		v12_`sat'_`ext' = percent_raindays_2008 if year == 2008
			replace 	v12_`sat'_`ext' = percent_raindays_2009 if year == 2009
			lab var		v12_`sat'_`ext' "% Rainy Days"

			gen 		v13_`sat'_`ext' = dev_percent_raindays_2008 if year == 2008
			replace 	v13_`sat'_`ext' = dev_percent_raindays_2009 if year == 2009
			lab var		v13_`sat'_`ext' "Deviation in % Rainy Days"

			gen 		v14_`sat'_`ext' = dry_2008 if year == 2008
			replace 	v14_`sat'_`ext' = dry_2009 if year == 2009
			lab var		v14_`sat'_`ext' "Longest Dry Spell"
		
		* drop year variables
			drop 		*2008 *2009
			drop	if 	year == . 								
	}						
}

	
* **********************************************************************
* 2 - merge temperature data with household data
* **********************************************************************
	
* define local with all sub-folders in it
	loc 		folderList : dir "`rootw'" dirs "IHS3_t*"

* define local with all files in each sub-folder	
	foreach 	folder of local folderList {

* define each file in the above local
	loc 		fileList : dir "`rootw'/`folder'" files "*.dta"
	
* loop through each file in the above local
	foreach 	file in `fileList' {	
	
	* merge weather data with household data
		merge 	1:1 case_id using "`rootw'/`folder'/`file'"	
	
		* drop files that did not merge
			drop 	if 	_merge != 3
			drop 		_merge
		
		* drop variables for all years before 2008 and after 2009
			drop 		mean_season_1983- tempbin1002007 ///
						mean_season_2010- tempbin1002016
			drop 		mean_gdd- z_gdd_2007 dev_gdd_2010- z_gdd_2016
		
		* define file naming criteria
			loc 		sat = substr("`file'", 10, 1)
			loc 		ext = substr("`file'", 6, 2)
			
		* generate variable to record extraction method
			gen 		tp`sat'_`ext' = "tp`sat'_`ext'"
			lab var 	tp`sat'_`ext' "Satellite/Extraction"
		
		* rename variables but dropping the year suffix
			gen 		v15_tp`sat'_`ext' = mean_season_2008 if year == 2008
			replace 	v15_tp`sat'_`ext' = mean_season_2009 if year == 2009
			lab var		v15_tp`sat'_`ext' "Mean Daily Temperature"

			gen 		v16_tp`sat'_`ext' = median_season_2008 if year == 2008
			replace 	v16_tp`sat'_`ext' = median_season_2009 if year == 2009
			lab var		v16_tp`sat'_`ext' "Median Daily Temperature"

			gen 		v17_tp`sat'_`ext' = sd_season_2008 if year == 2008
			replace 	v17_tp`sat'_`ext' = sd_season_2009 if year == 2009
			lab var		v17_tp`sat'_`ext' "Variance of Daily Temperature"

			gen 		v18_tp`sat'_`ext' = skew_season_2008 if year == 2008
			replace 	v18_tp`sat'_`ext' = skew_season_2009 if year == 2009
			lab var		v18_tp`sat'_`ext' "Skew of Daily Temperature"	

			gen 		v19_tp`sat'_`ext' = gdd_2008 if year == 2008
			replace 	v19_tp`sat'_`ext' = gdd_2009 if year == 2009	
			lab var		v19_tp`sat'_`ext' "Growing Degree Days (GDD)"	

			gen 		v20_tp`sat'_`ext' = dev_gdd_2008 if year == 2008
			replace 	v20_tp`sat'_`ext' = dev_gdd_2009 if year == 2009
			lab var		v20_tp`sat'_`ext' "Deviation in GDD"	

			gen 		v21_tp`sat'_`ext' = z_gdd_2008 if year == 2008
			replace 	v21_tp`sat'_`ext' = z_gdd_2009 if year == 2009
			lab var		v21_tp`sat'_`ext' "Z-Score of GDD"	

			gen 		v22_tp`sat'_`ext' = max_season_2008 if year == 2008
			replace 	v22_tp`sat'_`ext' = max_season_2009 if year == 2009	
			lab var		v22_tp`sat'_`ext' "Maximum Daily Temperature"

			gen 		v23_tp`sat'_`ext' = tempbin202008 if year == 2008
			replace 	v23_tp`sat'_`ext' = tempbin202009 if year == 2009
			lab var		v23_tp`sat'_`ext' "Temperature Bin 0-20"	

			gen 		v24_tp`sat'_`ext' = tempbin402008 if year == 2008
			replace 	v24_tp`sat'_`ext' = tempbin402009 if year == 2009
			lab var		v24_tp`sat'_`ext' "Temperature Bin 20-40"	

			gen 		v25_tp`sat'_`ext' = tempbin602008 if year == 2008
			replace 	v25_tp`sat'_`ext' = tempbin602009 if year == 2009
			lab var		v25_tp`sat'_`ext' "Temperature Bin 40-60"	

			gen 		v26_tp`sat'_`ext' = tempbin802008 if year == 2008
			replace 	v26_tp`sat'_`ext' = tempbin802009 if year == 2009
			lab var		v26_tp`sat'_`ext' "Temperature Bin 60-80"	

			gen 		v27_tp`sat'_`ext' = tempbin1002008 if year == 2008
			replace 	v27_tp`sat'_`ext' = tempbin1002009 if year == 2009
			lab var		v27_tp`sat'_`ext' "Temperature Bin 80-100"
		
		* drop year variables
			drop 		*2008 *2009
			drop	if 	year == . 								
	}						
}

* save file
	qui: compress
	customsave 	, idvar(case_id) filename("cx1_merged.dta") ///
		path("`export'") dofile(ihs3cx_build) user($user)
		
* close the log
	log	close

/* END */