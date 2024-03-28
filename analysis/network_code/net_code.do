* Project: WB Weather
* Created on: March 2024
* Created by: jdm
* Edited by: jdm
* Last edit: 28 March 2024
* Stata v.18.0 

* does
	* reads in excel file with papers
	* makes network visualziation 

* assumes
	* paper data file
	* nwcommands

* TO DO:
	* everything

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global	root 	= 	"$data/output/iv_lit"
	global	stab 	= 	"$data/results_data/tables"
	global	xtab 	= 	"$data/output/metric_paper/tables"
	global	sfig	= 	"$data/results_data/figures"	
	global 	xfig    =   "$data/output/metric_paper/figures"
	global	logout 	= 	"$data/results_data/logs"

* open log	
	cap log close
	log 	using 	"$logout/network_viz", append

	
************************************************************************
**# 1 - load and transform data
************************************************************************

* load data
	import excel		"$root/220 Papers_Outcome-rainfall.xlsx", sheet("Sheet1") ///
							firstrow case(lower) allstring clear

* clean data
	drop				if outcomecategory == ""
	drop				if rainfallvariable == ""

* rename
	rename				outcomecategory outcome
	rename				rainfallvariable rain
	
************************************************************************
**# 2 - create network data
************************************************************************
	
* declare data a network
	nwset				rain outcome, name(rainnet)
	nwset,				detail

	nwset 				rain outcome, name(rainnet) edgelist
	

	
************************************************************************
**# 7 - end matter
************************************************************************


* close the log
	log	close

/* END */		