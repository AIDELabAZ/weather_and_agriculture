* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Stata v.16

* does
	* cleans WB data set for IHS4 long panel
	* outputs .dta L  SMS household data ready to merge with weather data

* assumes
	* Extracted and "cleaned" World Bank Malawi data (provided by Talip Kilic)
	* customsave.ado

* TO DO:
	* complete


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root 	= 	"$data/household_data/malawi/wave_4/raw"
	loc		export 	= 	"$data/household_data/malawi/wave_4/refined"
	loc		logout 	= 	"$data/household_data/malawi/logs"

* open log
	cap 	log			close
	log 	using 		"`logout'/ihs4lpnl_hh_clean", append


* **********************************************************************
* 1 - clean household data
* **********************************************************************