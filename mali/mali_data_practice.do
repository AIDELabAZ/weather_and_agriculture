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

	* done
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=		"$data/household_data/mali/wave_1/raw"
	loc		export	=		"$data/household_data/mali/wave_1/refined"
	loc		logout	= 		"$data/household_data/mali/logs"
	

* open log
	cap 	log 	close
	log 	using	"`logout'/2011_as1p1", append

	
* **********************************************************************
* 1 - describing plot size - self-reported and GPS
* **********************************************************************
	
* import the first relevant data file
	use				"`root'/eaciexploi_p1", clear
		***this line did not work for me. is there something wrong with how i defined paths?^
		
	*use 				"C:\Users\rbrnhm\Documents\GitHub\weather_project\household_data\mali\wave_1\raw\eaciexploi_p1.sav.dta", clear
		***used this instead just to be able to run the code*
	
* determine self reported plotsize
	gen 			plot_size_SR = s1bq10
	lab	var			plot_size_SR "self reported size of plot, in hectares"
	*** SR plot area reported in hectares

	replace			plot_size_SR = . if plot_size_SR > 97
	***972 changed to missing
	
* determine GPS plotsize (area)
	gen 			plot_size_gps_area = s1bq05a
	lab	var			plot_size_gps_area "GPS reported area of plot, in hectares"
	*** GPS plot area reported in hectares

	replace			plot_size_gps_area = . if plot_size_gps_area > 97
	***555 changed to missing
	
/* determine GPS plotsize (perimeter)
	gen 			plot_size_gps_perimeter = s1bq05b
	lab	var			plot_size_gps_area "GPS reported perimeter of plot, in meters"
	*** GPS plot perimeter reported in meters

	replace			plot_size_gps_perimeter = . if plot_size_gps_perimeter > 9997
	
*/

* drop if SR and GPS are both equal to 0
	drop			if plot_size_gps_area == 0 & plot_size_SR == 0
	***0 changes made
	

* assume 0 GPS reading should be . values
	replace 		plot_size_gps_area = . if plot_size_gps_area == 0
	***0 changes made
	
* summarize SR and GPS plot size
	sum 			plot_size_SR
	***mean= 1.55 
	
	sum 			plot_size_gps_area
	***mean= 3.06
	