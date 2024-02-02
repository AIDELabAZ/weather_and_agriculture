* Project: WB Weather
* Created on: Feb 1, 2024
* Created by: reece
* Stata v.18

* does
	* reads in Mali, WAVE 1 (2014), eaciexploi_p1
	* cleans plot size (hecatres)


* assumes
	* customsave.ado
	* mdesc.ado

* TO DO:
	* go back to pwcorr between plot_size_hec_SR and plot_size_hec_GPS
	
	
	
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
	use				"$root/EACIEXPLOI_p1", clear

* dropping duplicates
	duplicates 		drop	
	
	rename 			passage visit
	label 			var visit "number of visit - wave number"
	rename			grappe clusterid
	label 			var clusterid "cluster number"
	rename			menage hh_num
	label 			var hh_num "household number - not unique id"
	rename 			s1bq03 ord 
	label 			var ord "number of order"
	rename 			s1bq01 field 
	label 			var field "field number"
	rename 			s1bq02 parcel 
	label 			var parcel "parcel number"
	
* creat household id 	
	egen 			hid = concat(clusterid hh_num)
	label 			var hid "Household indentifier"
	destring		hid, replace
	order			hid
	
* need to include hid field parcel to uniquely identify
	sort 			hid field parcel
	isid 			hid field parcel
	
* determine cultivated plot
	rename 			s1bq32 cultivated
	label 			var cultivated "plot cultivated"
	*** 1 = fallow, 2 = cultivated, 9 = missing

* drop if not cultivated
	keep 			if cultivated == 2
	*** 446 dropped, 9,212 kept
	