* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited by: ek
* Stata v.16

* does
	* reads in Nigeria, WAVE 3 (2015-2016) POST PLANTING, NIGERIA AG SECTA1
	* determines primary and secondary crops, cleans plot size (hecatres)
	* outputs clean data file ready for combination with wave 2 plot data
	* outputs clean data file ready for combination with wave 3 hh data

* assumes
	* customsave.ado
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

	count if plot_size_hec_GPS != .
	*** these 1125 observations have no value of GPS given so cannot be converted 
	*** will impute missing
	count if plot_size_hec_GPS == .
	*** 4,699 observations for plot size in hectares GPS 
	
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
	list 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS)
	*** correlation at higher plot sizes is higher than correlation among all values - 0.2911 

* examine smaller plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.1
	*** 1,056  below 0.1
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.05
	*** 602 below 0.5
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.005
	*** 46 below 0.005
	*** the smallest plot is 6 square meters, could feasibly be a very small vegetable patch
	*** all small values are reasonable - give GPS sensing abilities 

*correlation at lower plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS < 0.01, sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS < 0.01
	*** higher correlation between GPS and SR plotsize, correlation = -0.3175

	* compare GPS and SR
* examine GPS 
	sum 			plot_size_hec_GPS
	sum 			plot_size_hec_SR
	*** GPS tending to be smaller than self-reported - and more realistic
	*** as in wave 2, will not include SR in imputation - only will include GPS 
	
	*hist	 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.3
	*hist	 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.2
	*** roughly uniform distribution until 0.5 to 0.3 hectares
	*** distribution looks okay! 

	* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plot_size_hec_GPS // identify plotsize_GPS as the variable being imputed
	sort			hhid plotid, stable // sort to ensure reproducability of results
	mi impute 		pmm plot_size_hec_GPS i.state, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset

* look at the data 
* this piece of code gives three values to consider: SR, GPS before conversion, and GPS after conversion (indicated with _1_) 
	tab				mi_miss
	tabstat 		plot_size_hec_GPS plot_size_hec_SR plot_size_hec_GPS_1_, ///
						by(mi_miss) statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g)
						
* drop if anything else is still missing
	list			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						missing(plot_size_hec_GPS_1_), sep(0)
	drop 			if missing(plot_size_hec_GPS_1_)
	*** 0 observations deleted
	
	rename			plot_size_hec_GPS_1_ plotsize
	lab	var			plotsize	"plot size (ha)"
	
* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************

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
		customsave , idvar(hhid) filename("ph_sect11a1.dta") ///
			path("`export'/`folder'") dofile(ph_sect11a1) user($user)

* close the log
	log	close

/* END */
