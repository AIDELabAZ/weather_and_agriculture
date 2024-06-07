* Project: WB Weather
* Created on: June 2020
* Created by: ek
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* identifies regional elements for use in price data contruction 
	* merges in household sampling weights
	* merges in geovariables
	* outputs clean data file ready for combination with wave 1 data

* assumes
	* access to all raw data

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc 	root	= 	"$data/household_data/niger/wave_1/raw"
	loc 	export	= 	"$data/household_data/niger/wave_1/refined"
	loc 	logout	= 	"$data/household_data/niger/logs"

* open log
	cap 	log 	close
	log 	using 	"`logout'/2011_ms00p1", append

	
* **********************************************************************
* 1 - rename and identify regional variables
* **********************************************************************

* import the first relevant data file
	use				"`root'/ecvmasection00_p1_en", clear

* need to rename for English
	rename 			passage visit
	label 			var visit "number of visit"
	rename			menage hh_num
	label 			var hh_num "household number - not unique id"
	*** will need to do these in every file
	
* identify and rename region specific variables 
	rename			ms00q10 region
	label 			var region "region"
	rename 			ms00q11 dept
	label 			var dept "department"
	rename 			ms00q12 canton
	label 			var canton "canton/commune"
	*** have used enumeration zone instead of zd number which is not present in wave 1
	rename 		    ms00q14 enumeration
	label 			var enumeration "enumeration zone (instead of zd in wave 2)" 

* **********************************************************************
* 2 - merge in household weights
* **********************************************************************

	merge			m:1 grappe using "`root'/Ponderation_Finale_31_05_2013_en"
	*** all matched
	
	drop			_merge	
	
* rename variables
	rename			grappe clusterid
	label 			var clusterid "cluster number"
	rename			hhweight pw

	
* **********************************************************************
* 3 - merge in household weights
* **********************************************************************

	merge			1:1 hid using "`root'/NER_HouseholdGeovars_Y1"
	*** all matched in master, 83 in using unmatched
	
	keep			if _merge == 3
	drop			_merge	
	
* rename variables
	rename			ssa_aez09 aez
	
	
* **********************************************************************
* 4 - end matter, clean up to save
* **********************************************************************

	keep 			hid clusterid hh_num region dept canton enumeration ///
						aez pw
	isid 			hid
	
	compress
	describe
	summarize

* save file
	save 			"`export'/2011_ms00p1.dta", replace

* close the log
	log		close

/* END */
