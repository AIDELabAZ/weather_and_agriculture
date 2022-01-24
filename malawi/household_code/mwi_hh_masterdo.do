* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Stata v.16

* does
	* moves extracted and "cleaned" World Bank data from World Bank file structure
	* place it into our own file structure for use by .do files
	* executes all wave specific Malawi weather .do files
	* outputs .dta LSMS household data ready to append into panel

* assumes
	* Extracted and "cleaned" World Bank Malawi data (provided by Talip Kilic)
	* customsave.ado
	* subsidiary, wave-specific .do files

* TO DO:
	* complete


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc	source 		= 	"$data/household_data/malawi/wb_raw_data"
	loc	export 		= 	"$data/household_data/malawi"
	loc	dofile		= 	"$code/malawi/household_code"


* **********************************************************************
* 1 - move files from WB file structure to our file structure
* **********************************************************************

* move IHS3 data to wave 1 folder
	use			"`source'/tmp/ihs3cx/hh/hh_final.dta", clear
	customsave	, idvar(case_id) filename(ihs3cx_hh.dta) ///
				path("`export'/wave_1/raw") dofile(mwi_hh_masterdo) user($user)

	use			"`source'/data/ihs3cx/geo/HouseholdGeovariables_IHS3CX.dta", clear
	customsave	, idvar(case_id) filename(ihs3cx_geo.dta) ///
				path("`export'/wave_1/raw") dofile(mwi_hh_masterdo) user($user)

	use			"`source'/tmp/ihs3lpnl/hh/hh_final.dta", clear
	customsave	, idvar(case_id) filename(ihs3lpnl_hh.dta) ///
				path("`export'/wave_1/raw") dofile(mwi_hh_masterdo) user($user)

	use			"`source'/data/ihs3lpnl/geo/householdgeovariables_ihs3_rerelease.dta", clear
	customsave	, idvar(case_id) filename(ihs3lpnl_geo.dta) ///
				path("`export'/wave_1/raw") dofile(mwi_hh_masterdo) user($user)

	use			"`source'/tmp/ihs3spnl/hh/hh_final.dta", clear
	customsave	, idvar(case_id) filename(ihs3spnl_hh.dta) ///
				path("`export'/wave_1/raw") dofile(mwi_hh_masterdo) user($user)

	use			"`source'/data/ihs3spnl/geo/householdgeovariables_ihs3_rerelease.dta", clear
	customsave	, idvar(case_id) filename(ihs3spnl_geo.dta) ///
				path("`export'/wave_1/raw") dofile(mwi_hh_masterdo) user($user)


* move IHPS*pnl data to wave 2 folder

	use			"`source'/tmp/ihpsspnl/hh/hh_final.dta", clear
	customsave	, idvar(y2_hhid) filename(ihpsspnl_hh.dta) ///
				path("`export'/wave_2/raw") dofile(mwi_hh_masterdo) user($user)

	use			"`source'/data/ihpsspnl/geo/householdgeovariables_ihps.dta", clear
	customsave	, idvar(y2_hhid) filename(ihpsspnl_geo.dta) ///
				path("`export'/wave_2/raw") dofile(mwi_hh_masterdo) user($user)

	use			"`source'/tmp/ihpslpnl/hh/hh_final.dta", clear
	customsave	, idvar(y2_hhid) filename(ihpslpnl_hh.dta) ///
				path("`export'/wave_2/raw") dofile(mwi_hh_masterdo) user($user)

	use			"`source'/data/ihpslpnl/geo/householdgeovariables_ihps.dta", clear
	customsave	, idvar(y2_hhid) filename(ihpslpnl_geo.dta) ///
				path("`export'/wave_2/raw") dofile(mwi_hh_masterdo) user($user)

				
* move IHS4 data to wave 3 folder
	use			"`source'/tmp/ihs4cx/hh/hh_final.dta", clear
	customsave	, idvar(case_id) filename(ihs4cx_hh.dta) ///
				path("`export'/wave_3/raw") dofile(mwi_hh_masterdo) user($user)
				
	use			"`source'/data/ihs4cx/geo/HouseholdGeovariables_IHS4CX.dta", clear
	customsave	, idvar(case_id) filename(ihs4cx_geo.dta) ///
				path("`export'/wave_3/raw") dofile(mwi_hh_masterdo) user($user)

				
* move IHS4*pnl data to wave 4folder
	use			"`source'/tmp/ihs4lpnl/hh/hh_final.dta", clear
	customsave	, idvar(y3_hhid) filename(ihs4lpnl_hh.dta) ///
				path("`export'/wave_4/raw") dofile(mwi_hh_masterdo) user($user)
				
	use			"`source'/data/ihs4lpnl/geo/householdgeovariables_ihpsy3.dta", clear
	customsave	, idvar(y3_hhid) filename(ihs4lpnl_geo.dta) ///
				path("`export'/wave_4/raw") dofile(mwi_hh_masterdo) user($user)


* **********************************************************************
* 2 - run wave specific cleaning .do files
* **********************************************************************

* do each IHS3 household cleaning files
	do 			"`dofile'/wave_1/ihs3cx_hh_clean.do"		//	cleans IHS3cx
	do 			"`dofile'/wave_1/ihs3spnl_hh_clean.do"		//	cleans IHS3spnl
	do 			"`dofile'/wave_1/ihs3lpnl_hh_clean.do"		//	cleans IHS3lpnl

* do each IHPS*pnl household cleaning files
	do 			"`dofile'/wave_2/ihpsspnl_hh_clean.do"		//	cleans IHPSspnl
	do 			"`dofile'/wave_2/ihpslpnl_hh_clean.do"		//	cleans IHPSlpnl

* do IHS4 household cleaning filename
	do 			"`dofile'/wave_3/ihs4cx_hh_clean.do"		//	cleans IHS4cx

* do IHS4*pnl household cleaning filefiles
	do 			"`dofile'/wave_4/ihs4lpnl_hh_clean.do"		//	cleans IHS4lpnl


* **********************************************************************
* 3 - run wave specific .do files to merge with weather
* **********************************************************************

* do each IHS3 household cleaning files
	do 			"`dofile'/wave_1/ihs3cx_build.do"			//	merges IHS3cx to weather
	do 			"`dofile'/wave_1/ihs3spnl_build.do"			//	merges IHS3spnl to weather
	do 			"`dofile'/wave_1/ihs3lpnl_build.do"			//	merges IHS3lpnl to weather

* do each IHPS*pnl household cleaning files
	do 			"`dofile'/wave_2/ihpsspnl_build.do"			//	merges IHPSspnl to weather
	do 			"`dofile'/wave_2/ihpslpnl_build.do"			//	merges IHPSlpnl	to weather

* do IHS4 household cleaning filename
	do 			"`dofile'/wave_3/ihs4cx_build.do"			//	merges IHS4cx to weather

* do IHS4*pnl household cleaning filefiles
	do 			"`dofile'/wave_4/ihs4lpnl_build.do"			//	merges IHS4lpnl to weather


* **********************************************************************
* 4 - run .do file to append each wave
* **********************************************************************

	do			"`dofile'/mwi_append_built.do"				// append waves

/* END */
