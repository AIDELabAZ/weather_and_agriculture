* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Edited on: 20 June 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans WB data set for IHS3 short panel
	* outputs .dta LSMS household data ready to merge with weather data

* assumes
	* Extracted and "cleaned" World Bank Malawi data (provided by Talip Kilic)

* TO DO:
	* complete


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_1/raw"
	loc		export 	= 	"$data/household_data/malawi/wave_1/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"`logout'/ihs3spnl_hh_clean", append


* **********************************************************************
* 1 - clean household data
* **********************************************************************

* load data
	use 		"`root'/ihs3spnl_hh_new.dta", clear

* keep only the variables we need
	keep 		case_id region district urban ta ea_id strata cluster ///
				hhweightR1 intmonth intyear qx_type rs_harvest_value* ///
				rsmz_harvest* ds_harvest_value* dsmz_harvest* ///
				rs_cultivatedarea rsmz_cultivatedarea ds_cultivatedarea ///
				dsmz_cultivatedarea rs_labordays* rsmz_labordays* ///
				ds_labordays* dsmz_labordays* rs_fert* rs_insecticide* ///
				rs_herbicide* rs_fungicide* rs_pesticide* rsmz_fert* ///
				rsmz_insecticide* rsmz_herbicide* rsmz_fungicide* ///
				rsmz_pesticide* ds_fert* ds_insecticide* ds_herbicide* ///
				ds_fungicide* ds_pesticide* dsmz_fert* dsmz_insecticide* ///
				dsmz_herbicide* dsmz_fungicide* dsmz_pesticide* ///
				rs_irrigation* rsmz_irrigation* ds_irrigation* dsmz_irrigation* /// 
				rs_fert_inorgkg rsmz_fert_kg

* generate indicator variables for herbicide and fungicide
	gen 		rs_herb = 1 if rs_herbicideany == 1 | rs_fungicideany == 1
	replace 	rs_herb = 0 if rs_herb != 1

	gen 		ds_herb = 1 if ds_herbicideany == 1 | ds_fungicideany == 1
	replace 	ds_herb = 0 if ds_herb != 1

	gen 		rsmz_herb = 1 if rsmz_herbicideany == 1 | rsmz_fungicideany == 1
	replace 	rsmz_herb = 0 if rsmz_herb != 1

	gen 		dsmz_herb = 1 if dsmz_herbicideany == 1 | dsmz_fungicideany == 1
	replace 	dsmz_herb = 0 if dsmz_herb != 1

* drop old herbicide and fungicide variables
	drop 		rs_herbicideany rs_fungicideany ds_herbicideany ///
				ds_fungicideany rsmz_herbicideany rsmz_fungicideany ///
				dsmz_herbicideany dsmz_fungicideany

* generate indicator variables for pesticide and insecticide
	gen 		rs_pest = 1 if rs_pesticideany == 1 | rs_insecticideany == 1
	replace 	rs_pest = 0 if rs_pest != 1

	gen 		ds_pest = 1 if ds_pesticideany == 1 | ds_insecticideany == 1
	replace 	ds_pest = 0 if ds_pest != 1

	gen 		rsmz_pest = 1 if rsmz_pesticideany == 1 | rsmz_insecticideany == 1
	replace 	rsmz_pest = 0 if rsmz_pest != 1

	gen 		dsmz_pest = 1 if dsmz_pesticideany == 1 | dsmz_insecticideany == 1
	replace 	dsmz_pest = 0 if dsmz_pest != 1

* drop old variables for pesticide and insecticide
	drop 		rs_pesticideany rs_insecticideany ds_pesticideany ///
				ds_insecticideany rsmz_pesticideany rsmz_insecticideany ///
				dsmz_pesticideany dsmz_insecticideany

* merge in geovariables
	merge 		1:1 case_id using "`root'/ihs3spnl_geo.dta", generate(_geo)				
	keep		if _geo == 3
	
	rename		ssa_aez09 aez
	
	drop		lat_modified - fsrad3_lcmaj afmnslp_pct - _geo

* destring unique household indicator
	gen			hh_id_merge = case_id
	destring 	case_id, replace	

	
* **********************************************************************
* 2 - end matter, clean up to save
* **********************************************************************
	
	compress
	describe
	summarize 
	
* save data
	save		"`export'/hhfinal_ihs3spnl.dta", replace

* close the log
	log			close

/* END */
