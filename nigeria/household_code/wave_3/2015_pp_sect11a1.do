* Project: WB Weather
* Created on: May 2020
* Created by: ek
* Edited on: 30 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 3 (2015-2016) POST PLANTING, NIGERIA AG SECTA1
	* determines primary and secondary crops, cleans plot size (hecatres)
	* outputs clean data file ready for combination with wave 3 hh data

* assumes
	* access to all raw data
	* land-conversion.dta conversion file

* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************
	
* define paths	
	loc		root	=		"$data/household_data/nigeria/wave_3/raw"
	loc		cnvrt   =		"$data/household_data/nigeria/conversion_files"
	loc 	export  = 		"$data/household_data/nigeria/wave_3/refined"
	loc 	logout  = 		"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "`logout'/ph_sect11a1", append

	
* **********************************************************************
* 1 - determine plot size
* **********************************************************************
		
* import the relevant data file
		use "`root'/sect11a1_plantingw3", clear 	

* determine self reported plotsize
		gen plot_size_SR = s11aq4a
		rename s11aq4b plot_unit
		label variable plot_size_SR "self reported size of plot, not standardized"
		label variable plot_unit "self reported unit of measure, 1=heaps, 2=ridges, 3=stands, 4=plots, 5=acres, 6=hectares, 7=sq meters, 8=other"

* determine GPS plotsize
		gen plot_size_GPS = s11aq4c
		label variable plot_size_GPS "GPS plotsize in sq. meters"
		
* **********************************************************************
* 2 - conversions
* **********************************************************************

* merge in conversion file
	merge 			m:1 	zone using 	"`cnvrt'/land-conversion"
	
	***all observations matched

	
	keep 			if 		_merge == 3
	drop 			_merge

	tab 			plot_unit
	
	* convert SR to hectares
	gen 			plot_size_hec = .
	replace 		plot_size_hec = plot_size_SR*ridgecon	if plot_unit == 2
	*heaps
	replace 		plot_size_hec = plot_size_SR*heapcon	if plot_unit == 1
	*stands
	replace 		plot_size_hec = plot_size_SR*standcon	if plot_unit == 3
	*plots
	replace 		plot_size_hec = plot_size_SR*plotcon	if plot_unit == 4
	*acre
	replace 		plot_size_hec = plot_size_SR*acrecon	if plot_unit == 5
	*sqm
	replace 		plot_size_hec = plot_size_SR*sqmcon		if plot_unit == 7
	*hec
	replace 		plot_size_hec = plot_size_SR			if plot_unit == 6

	count			if plot_size_SR == . 
	*** 4 observations have . for plot_size_SR
	*** no observations that include "other" units
	rename 			plot_size_hec plot_size_hec_SR
	lab var			plot_size_hec_SR 	"SR plot size converted to hectares"

	count 			if plot_size_hec_SR !=.
	count			if plot_size_hec_SR == . 
	*** 6 observations do not have plot_size_hec_SR
	*** 5818 observations have plot_size_hec_SR

	* convert GPS  to hectares
	count if plot_size_GPS == .
	*** 1,125 missing GPS
	gen 			plot_size_2 = .
	replace 		plot_size_2 = plot_size_GPS*sqmcon
	rename 			plot_size_2 plot_size_hec_GPS
	lab	var			plot_size_hec_GPS "GPS measured area of plot in hectares"

	count if plot_size_hec_GPS == .
	*** 4,699 observations for plot size in hectares GPS 
	*** will impute missing
	
* replace missing self reported with GPS
	replace			plot_size_hec_SR = plot_size_hec_GPS if plot_size_hec_SR == .
	*** 2 changes made

	count 			if plot_size_hec_GPS !=.
	count			if plot_size_hec_GPS == . 

	count	 		if plot_size_hec_SR != . & plot_size_hec_GPS != .
	*** 4699 observations have both self reported and GPS plot size in hectares
	count 			if plot_size_hec_SR == . & plot_size_hec_GPS == .
	*** 4 observations lack either the plot_size_hec_GPS or the plot_size_hec_SR
	
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS
	*** very low correlation = 0.0198 between selfreported plot size and GPS

* check correlation within +/- 3sd of mean (GPS)
	sum 			plot_size_hec_GPS, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation of points with +/- 3sd is higher 0.0341

* check correlation within +/- 3sd of mean (GPS and SR)
	sum 			plot_size_hec_GPS, detail
	sum 			plot_size_hec_SR, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) & ///
						inrange(plot_size_hec_SR,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation between self reported and GPS for values within +/- 3 sd's of GPS and SR is higher 0.1442

* examine larger plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 2
	*** 164 GPS which are greater than 2
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 20
	*** but none which are greater than 20 

* correlation at higher plot sizes
	*list 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS)
	*** correlation at higher plot sizes is higher than correlation among all values - 0.2911 

* compare GPS and SR
* examine GPS 
	sum 			plot_size_hec_GPS, detail
	sum 			plot_size_hec_SR, detail
	*** GPS tending to be smaller than self-reported - and more realistic

* need to get rid of a couple outliers
	*twoway			(scatter plot_size_hec_GPS plot_size_hec_SR	if plot_size_hec_GPS < 0.009)
	replace			plot_size_hec_SR = plot_size_hec_GPS if plot_size_hec_GPS < 0.009 ///
						& plot_size_hec_SR > .1
	*** 40 changes made
	
* need to get rid of a couple outliers
	*twoway			(scatter plot_size_hec_GPS plot_size_hec_SR	if plot_size_hec_GPS > 5 ///
						& plot_size_hec_SR < 20)
	replace			plot_size_hec_GPS = . if plot_size_hec_GPS > 20 & plot_size_hec_SR < 20
	replace			plot_size_hec_SR = plot_size_hec_GPS if plot_size_hec_SR > 200
	*** 5 changes made
	
* replace bottom 5%  and top 1% as missing
	gen				plotsize = plot_size_hec_GPS if plot_size_hec_GPS > 0.022 ///
						& plot_size_hec_GPS < 3.6
	replace			plotsize = plot_size_hec_GPS if plot_size_hec_SR > 3 ///
						& plot_size_hec_GPS >= 3
	*** 1,419 missing then 20 real changes made	
	
	list 			plot_size_hec_GPS plot_size_hec_SR plotsize 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)

* impute missing plot sizes using predictive mean matching - can't use GPS size
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plotsize // identify plotsize_GPS as the variable being imputed
	sort			hhid plotid, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize i.state, ///
						add(1) rseed(245780) noisily dots force knn(10) bootstrap
	mi unset
	
* look at the data
	tab				mi_miss
	tabstat 		plot_size_hec_GPS plot_size_hec_SR plotsize_1_, ///
						by(mi_miss) statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g)
	*** imputed values change VERY little - mean from 0.52 to 0.483
	*** reasonable changes
						

* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************

	replace			plotsize = plotsize_1_ 
	lab	var			plotsize	"plot size (ha)"
	
	keep 			hhid zone state lga hhid ea plotid plotsize

* create unique household-plot identifier
	isid				hhid plotid
	sort				hhid plotid
	egen				plot_id = group(hhid plotid)
	lab var				plot_id "unique plot identifier"

	compress
	describe
	summarize

* save file
	save 			"`export'/ph_sect11a1.dta", replace

* close the log
	//log	close

/* END */
