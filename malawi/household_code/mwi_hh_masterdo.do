* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* moves extracted and "cleaned" World Bank data from World Bank file structure
	* place it into our own file structure for use by .do files
	* executes all wave specific Malawi weather .do files
	* outputs .dta LSMS household data ready to append into panel

* assumes
	* Extracted and "cleaned" World Bank Malawi data (provided by Talip Kilic)
	* subsidiary, wave-specific .do files

* TO DO:
	* complete


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global		source 		"$data/household_data/malawi/wb_raw_data"
	global		export 		"$data/household_data/malawi"
	global		dofile		"$code/malawi/household_code"


* **********************************************************************
* 1 - move files from WB file structure to our file structure
* **********************************************************************

* move IHS3 data to wave 1 folder
	use			"$source/tmp/ihs3cx/hh/hh_final.dta", clear
	save		"$export/wave_1/raw/ihs3cx_hh.dta", replace

	use			"$source/data/ihs3cx/geo/HouseholdGeovariables_IHS3CX.dta", clear
	save		"$export/wave_1/ihs3cx_geo.dta", replace

	use			"$source/tmp/ihs3lpnl/hh/hh_final.dta", clear
	save		"$export/wave_1/raw/ihs3lpnl_hh.dta", replace

	use			"$source/data/ihs3lpnl/geo/householdgeovariables_ihs3_rerelease.dta", clear
	save		"$export/wave_1/raw/ihs3lpnl_geo.dta", replace

	use			"$source/tmp/ihs3spnl/hh/hh_final.dta", clear
	save		"$export/wave_1/raw/ihs3spnl_hh.dta", replace

	use			"$source/data/ihs3spnl/geo/householdgeovariables_ihs3_rerelease.dta", clear
	save		"$export/wave_1/raw/ihs3spnl_geo.dta", replace


* move IHPS*pnl data to wave 2 folder
	use			"$source/tmp/ihpsspnl/hh/hh_final.dta", clear
	save		"$export/wave_2/raw/ihpsspnl_hh.dta", replace

	use			"$source/data/ihpsspnl/geo/householdgeovariables_ihps.dta", clear
	save		"$export/wave_2/raw/ihpsspnl_geo.dta", replace

	use			"$source/tmp/ihpslpnl/hh/hh_final.dta", clear
	save		"$export/wave_2/raw/ihpslpnl_hh.dta", replace

	use			"$source/data/ihpslpnl/geo/householdgeovariables_ihps.dta", clear
	save		"$export/wave_2/raw/ihpslpnl_geo.dta", replace

				
* move IHS4 data to wave 3 folder
	use			"$source/tmp/ihs4cx/hh/hh_final.dta", clear
	save		"$export/wave_3/raw/ihs4cx_hh.dta", replace
				
	use			"$source/data/ihs4cx/geo/HouseholdGeovariables_IHS4CX.dta", clear
	save		"$export/wave_3/raw/ihs4cx_geo.dta", replace

				
* move IHS4*pnl data to wave 4folder
	use			"$source/tmp/ihs4lpnl/hh/hh_final.dta", clear
	save		"$export/wave_4/raw/ihs4lpnl_hh.dta", replace
				
	use			"$source/data/ihs4lpnl/geo/householdgeovariables_ihpsy3.dta", clear
	save		"$export/wave_4/raw/ihs4lpnl_geo.dta", replace


* **********************************************************************
* 2 - run wave specific cleaning .do files
* **********************************************************************

* do each IHS3 household cleaning files
	do 			"$dofile/wave_1/ihs3cx_hh_clean.do"			//	cleans IHS3cx
	do 			"$dofile/wave_1/ihs3spnl_hh_clean.do"		//	cleans IHS3spnl
	do 			"$dofile/wave_1/ihs3lpnl_hh_clean.do"		//	cleans IHS3lpnl

* do each IHPS*pnl household cleaning files
	do 			"$dofile/wave_2/ihpsspnl_hh_clean.do"		//	cleans IHPSspnl
	do 			"$dofile/wave_2/ihpslpnl_hh_clean.do"		//	cleans IHPSlpnl

* do IHS4 household cleaning filename
	do 			"$dofile/wave_3/ihs4cx_hh_clean.do"			//	cleans IHS4cx

* do IHS4*pnl household cleaning filefiles
	do 			"$dofile/wave_4/ihs4lpnl_hh_clean.do"		//	cleans IHS4lpnl

* do IHS5*pnl household cleaning filefiles
	loc HHfile : dir "$dofile/wave_6" files "*hh*.do"
	
	* loop through each file in the above local
		foreach file in `HHfile' {
	    
		* run each individual file
			do "$dofile/wave_6/`file'"	
	}
	loc HHfile : dir "$dofile/wave_6" files "*ag*.do"
	
	* loop through each file in the above local
		foreach file in `HHfile' {
	    
		* run each individual file
			do "$dofile/wave_6/`file'"	
	}
	do 			"$dofile/wave_6/ihs5p_rs_plot.do"		

* **********************************************************************
* 3 - run wave specific .do files to merge with weather
* **********************************************************************

* do each IHS3 household cleaning files
	do 			"$dofile/wave_1/ihs3cx_build.do"			//	merges IHS3cx to weather
	do 			"$dofile/wave_1/ihs3spnl_build.do"			//	merges IHS3spnl to weather
	do 			"$dofile/wave_1/ihs3lpnl_build.do"			//	merges IHS3lpnl to weather

* do each IHPS*pnl household cleaning files
	do 			"$dofile/wave_2/ihpsspnl_build.do"			//	merges IHPSspnl to weather
	do 			"$dofile/wave_2/ihpslpnl_build.do"			//	merges IHPSlpnl	to weather

* do IHS4 household cleaning filename
	do 			"$dofile/wave_3/ihs4cx_build.do"			//	merges IHS4cx to weather

* do IHS4*pnl household cleaning filefiles
	do 			"$dofile/wave_4/ihs4lpnl_build.do"			//	merges IHS4lpnl to weather

* do IHS4*pnl household cleaning filefiles
	do 			"$dofile/wave_6/ihs5p_merge.do"				//	merges IHS5lpnl together
	do 			"$dofile/wave_6/ihs5p_build.do"				//	merges IHS5lpnl to weather


* **********************************************************************
* 4 - run .do file to append each wave
* **********************************************************************

	do			"$dofile/mwi_append_built.do"				// append waves

/* END */
