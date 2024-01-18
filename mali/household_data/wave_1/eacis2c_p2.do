* Project: WB Weather
* Created on: Nov 20, 2023
* Created by: reece
* Stata v.18

* does
	* reads in Mali, WAVE 1 (2014), eaciexploi_p1
	* cleans plot size (hecatres)


* assumes
	* customsave.ado
	* mdesc.ado

* TO DO:
	* done
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root	=		"$data/household_data/mali/wave_1/raw"
	global	export	=		"$data/household_data/mali/wave_1/refined"
	global	logout	= 		"$data/household_data/mali/logs"
	
* open log
	cap 	log 	close
	log 	using	"$logout/eaciexploi_p1", append

	
* **********************************************************************
* 1 - describing plot size - self-reported and GPS
* **********************************************************************
	
* import the first relevant data file
	use				"$root/eaciexploi_p1.sav.dta", clear
