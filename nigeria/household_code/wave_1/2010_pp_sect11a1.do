* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited by: ek
* Stata v.16

* does
	* reads in Nigeria, WAVE 1 (2010-2011) - POST PLANTING NIGERIA, SECT 11A1 AG
	* cleans plot size (hecatres)
	* outputs clean data file ready for combination with wave 1 plot data

* assumes
	* customsave.ado
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

* close log (in case still open)
	*log close
	
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
	
	count 			if plot_size_hec_GPS !=.
	count			if plot_size_hec_GPS == . 
	*** 5,401 observations have plot_size_hec_GPS
	
	count	 		if plot_size_hec_SR != . & plot_size_hec_GPS != .
	*** 5205 observations have both self reported and GPS plot size in hectares
	count 			if plot_size_hec_SR == . & plot_size_hec_GPS == .
	*** 153 observations lack either the plot_size_hec_GPS or the plot_size_hec_SR

	pwcorr 			plot_size_hec_SR plot_size_hec_GPS
	*** no low correlation (-0.0003) between selfreported plot size and GPS

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
	*** correlation between self reported and GPS for values within +/- 3 sd's of GPS and SR is higher but still low (0.0319)

* examine larger plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 2
	*** 308 GPS which are greater than 2
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 20
	*** 4 are greater than 20
	*** no wholly unreasonably GPS values 

* correlation at higher plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS)
	*** correlation at higher plot sizes is almost 0 (-0.0038)

* examine smaller plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.1
	*** 1,455  below 0.1
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.05
	*** 1052 below 0.5
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.005
	*** only 110 below 0.005
	*** 41 are below 0.002 ha and are unrealistically small

*correlation at lower plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS < 0.01, sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS < 0.01
	*** relationship between GPS and SR plotsize correlation = -0.2827
	
* compare GPS and SR
* examine GPS 
	sum 			plot_size_hec_GPS
	sum 			plot_size_hec_SR
	*** GPS tending to be smaller than self-reported - and more realistic
	*** as in Y1, will not include SR in imputation - only will include GPS 
	
	*hist	 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.3
	*hist	 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.2
	***appears that GPS becomes less accurate around 0.05

*make GPS values missing if below 0.05 for impute
	replace plot_size_hec_GPS = . if plot_size_hec_GPS <0.05
	*** 1052 changed to missing
	
* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plot_size_hec_GPS // identify plotsize_GPS as the variable being imputed
	sort			hhid plotid, stable // sort to ensure reproducability of results
	mi impute 		pmm plot_size_hec_GPS i.state, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset

* look at the data
	tab				mi_miss
	tabstat 		plot_size_hec_GPS plot_size_hec_SR plot_size_hec_GPS_1_, ///
						by(mi_miss) statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g)
	*** mean of imputed values changed from 0.61 to 0.753 - reasonable changes
	*** good impute

* drop if anything else is still missing
	list			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						missing(plot_size_hec_GPS_1_), sep(0)
	drop 			if missing(plot_size_hec_GPS_1_)
	*** 0 observations deleted

* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************

	rename			plot_size_hec_GPS_1_ plotsize
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
		customsave , idvar(hhid) filename("pp_sect11a1.dta") ///
			path("`export'/`folder'") dofile(pp_sect11a1) user($user)

* close the log
	log	close

/* END */