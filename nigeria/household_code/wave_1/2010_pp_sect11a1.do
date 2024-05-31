* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 30 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 1 (2010-2011) - POST PLANTING NIGERIA, SECT 11A1 AG
	* cleans plot size (hecatres)
	* outputs clean data file ready for combination with wave 1 plot data

* assumes
	* access to all raw data
	* land_conversion.dta conversion file

* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	loc		root	=		"$data/household_data/nigeria/wave_1/raw"
	loc		cnvrt	=		"$data/household_data/nigeria/conversion_files"
	loc		export	=		"$data/household_data/nigeria/wave_1/refined"
	loc		logout	= 		"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "`logout'/pp_sect11a1", append

	
* **********************************************************************
* 1 - general clean up, renaming, etc. 
* **********************************************************************

* import the first relevant data file
	use "`root'/sect11a1_plantingw1", clear 	

* need plot id to uniquely identify
	describe
	sort hhid plotid
	isid hhid plotid

* determine self reported plotsize 
	generate 		plot_size_SR = s11aq4a
	rename 			s11aq4b  plot_unit
	lab	var			plot_size_SR	"self reported size of plot, not standardized"
	lab var			plot_unit	"self reported unit of measure"

*determine GPS plotisize 
	generate plot_size_GPS = s11aq4d
	label variable plot_size_GPS "GPS plot size in sq. meters"
	

* **********************************************************************
* 2 - conversion to ha
* **********************************************************************

* merge in conversion file
	merge 			m:1 	zone using 	"`cnvrt'/land-conversion.dta"
	***all observations matched
	
*convert to hectares 
	gen 		plot_size_hec = .
	*heaps
	replace 	plot_size_hec = plot_size_SR*heapcon 	if plot_unit == 1
	*ridges 
	replace 	plot_size_hec = plot_size_SR*ridgecon 	if plot_unit == 2
	*stands
	replace 	plot_size_hec = plot_size_SR*standcon 	if plot_unit == 3
	*plots
	replace 	plot_size_hec = plot_size_SR*plotcon 	if plot_unit == 4
	*acre
	replace 	plot_size_hec = plot_size_SR*acrecon 	if plot_unit == 5
	*hec
	replace 	plot_size_hec = plot_size_SR 			if plot_unit == 6
	*sqm
	replace 	plot_size_hec = plot_size_SR*sqmcon 	if plot_unit == 7

	count		if plot_size_SR == . 
	*** 163 observations have missing for plot_size_SR
	*** 61 other observatins but they are not units we can convert to hectares
	
	rename 			plot_size_hec plot_size_hec_SR
	lab var			plot_size_hec_SR 	"SR plot size converted to hectares"
	
	count 			if plot_size_hec_SR !=.
	count			if plot_size_hec_SR == . 
	***349 observations on plot_size_hec_SR are missing
	
	* convert gps report to hectares
	count 			if plot_size_GPS == .  
	*** 685 observations have no GPS value 
	
	gen 			plot_size_2 = .
	replace 		plot_size_2 = plot_size_GPS*sqmcon
	rename 			plot_size_2 plot_size_hec_GPS
	lab	var			plot_size_hec_GPS "GPS measured area of plot in hectares"
	*** 685 observations do not have plot_size_hec_GPS
	*** these 685 observations have no value of GPS given so cannot be converted 
	*** will impute missing
	
* replace missing self reported with GPS
	replace			plot_size_hec_SR = plot_size_hec_GPS if plot_size_hec_SR == .
	*** 196 changes made
	
	count 			if plot_size_hec_GPS !=.
	count			if plot_size_hec_GPS == . 
	*** 5,401 observations have plot_size_hec_GPS
	
	count	 		if plot_size_hec_SR != . & plot_size_hec_GPS != .
	*** 5,401 observations have both self reported and GPS plot size in hectares
	count 			if plot_size_hec_SR == . & plot_size_hec_GPS == .
	*** 153 observations lack either the plot_size_hec_GPS or the plot_size_hec_SR

	pwcorr 			plot_size_hec_SR plot_size_hec_GPS
	*** no low correlation (-0.0002) between selfreported plot size and GPS

* check correlation within +/- 3sd of mean (GPS)
	sum 			plot_size_hec_GPS, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** no correlation (0)

* check correlation within +/- 3sd of mean (GPS and SR)
	sum 			plot_size_hec_GPS, detail
	sum 			plot_size_hec_SR, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) & ///
						inrange(plot_size_hec_SR,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation between self reported and GPS for values within +/- 3 sd's of GPS and SR is higher but still low (0.0335)

* examine larger plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 2
	*** 308 GPS which are greater than 2
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 20
	*** 4 are greater than 20
	*** no wholly unreasonably GPS values 

* correlation at higher plot sizes
*	list 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS)
	*** correlation at higher plot sizes is almost 0 (-0.0010)

* compare GPS and SR
* examine GPS 
	sum 			plot_size_hec_GPS, detail
	sum 			plot_size_hec_SR, detail
	*** GPS tending to be smaller than self-reported - and more realistic

* need to get rid of a couple outliers
	*twoway			(scatter plot_size_hec_GPS plot_size_hec_SR	if 	plot_size_hec_GPS < 0.009)
	replace			plot_size_hec_SR = plot_size_hec_GPS if plot_size_hec_GPS < 0.009 ///
						& plot_size_hec_SR > .1
	*** 70 changes made
	
	* need to get rid of a couple outliers
	*twoway			(scatter plot_size_hec_GPS plot_size_hec_SR	if plot_size_hec_GPS > 5 ///
						& plot_size_hec_SR < 20)
	replace			plot_size_hec_GPS = . if plot_size_hec_GPS > 20 & plot_size_hec_SR < 20
	replace			plot_size_hec_SR = plot_size_hec_GPS if plot_size_hec_SR > 200
	*** 19 changes made
	
* replace bottom 5%  and top 1% as missing
	gen				plotsize = plot_size_hec_GPS if plot_size_hec_GPS > 0.012 ///
						& plot_size_hec_GPS < 5
	replace			plotsize = plot_size_hec_GPS if plot_size_hec_SR > 3 ///
						& plot_size_hec_GPS >= 3
	*** 1,020 missing then 24 real changes made
	
	list 			plot_size_hec_GPS plot_size_hec_SR plotsize 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)

* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plotsize // identify plotsize_GPS as the variable being imputed
	sort			hhid plotid, stable // sort to ensure reproducability of results
	mi impute 		pmm plotsize plot_size_hec_GPS i.state, ///
						add(1) rseed(245780) noisily dots force knn(5) bootstrap
	mi unset

* look at the data
	tab				mi_miss
	tabstat 		plot_size_hec_GPS plot_size_hec_SR plotsize_1_, ///
						by(mi_miss) statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g)
	*** imputed values change VERY little - mean from 0.586 to 0.584
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
	save 				"`export'/pp_sect11a1.dta", replace

* close the log
	log	close

/* END */