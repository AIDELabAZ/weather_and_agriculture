* Project: WB Weather
* Created on: June 2020
* Created by: alj
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Niger, WAVE 2 (2014), POST PLANTING (first passage), ECVMA2_AS1P1
	* cleans plot size (hecatres)
	* outputs clean data file ready for combination with wave 2 plot data

* assumes
	* access to all raw data

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=	"$data/household_data/niger/wave_2/raw"
	loc		export	=	"$data/household_data/niger/wave_2/refined"
	loc		logout	= 	"$data/household_data/niger/logs"

* open log
	cap		log 	close
	log 	using	"`logout'/2014_as1p1", append

* **********************************************************************
* 1 - describing plot size - self-reported and GPS
* **********************************************************************

* import the first relevant data file
	use				"`root'/ECVMA2_AS1P1", clear
	
* need to rename for English
	rename 			PASSAGE visit
	label 			var visit "number of visit"
	rename			GRAPPE clusterid
	label 			var clusterid "cluster number"
	rename			MENAGE hh_num
	label 			var hh_num "household number - not unique id"
	rename 			EXTENSION extension 
	label 			var extension "extension of household"
	*** will need to do these in every file
	rename 			AS01Q01 field 
	label 			var field "field number"
	rename 			AS01Q03 parcel 
	label 			var parcel "parcel number"
	
* create new household id for merging with weather 
	tostring		clusterid, replace 
	gen str2 		hh_num1 = string(hh_num,"%02.0f")
	tostring		extension, replace
	egen			hhid_y2 = concat( clusterid hh_num1 extension  )
	destring		hhid_y2, replace
	order			hhid_y2 clusterid hh_num hh_num1 extension 
	
* create new household id for merging with year 1 
	egen			hid = concat( clusterid hh_num1  )
	destring		hid, replace
	order			hhid_y2 hid clusterid hh_num hh_num1 
	
* need to destring variables for later use in imputes 	
	destring 		clusterid, replace
	
* hhid_y2 field parcel should uniquely identify 
	describe
	sort 			hhid_y2 field parcel 
	isid 			hhid_y2 field parcel 

* determine cultivated plot
	rename 			AS01Q38 cultivated
	label 			var cultivated "plot cultivated"
* drop if not cultivated
	keep 			if cultivated == 1
	*** 490 observations dropped
	*** AS01Q43 asks about fallow specifically rather than did you cultivate 
	
* determine self reported plotsize
	gen 			plot_size_SR = AS01Q06
	lab	var			plot_size_SR "self reported size of plot, in square meters"
	*** all plots measured in metre carre - square meters
	
	replace			plot_size_SR = . if plot_size_SR > 999997
	*** 26 changed to missing 

* determine GPS plotsize
	gen 			plot_size_GPS = AS01Q07
	lab var			plot_size_GPS 	"GPS plot size in sq. meters"
	*** all plots measured in metre carre - square meters
	*** 999999 seems to be a code used to designate missing values
	
	replace			plot_size_GPS = . if plot_size_GPS > 999997
	*** 236 changed to missing 
	
* drop if SR and GPS both equal to 0
	drop	 		if plot_size_GPS == 0 & plot_size_SR == 0
	*** drops 57 values 

* assume 0 GPS reading should be . values 
	replace 		plot_size_GPS = . if plot_size_GPS < 5 
	*** will replace 1254 values to missing
	*** in other countries, when plot not measured with GPS coded with . - in Niger seems to be coded as 0

* **********************************************************************
* 2 - conversion to hectares
* **********************************************************************

	gen 			plot_size_hec_SR = . 

* plots measures in square meters 
* create conversion variable 
	gen 			sqmcon = 0.0001

* convert to SR hectares
	replace 		plot_size_hec_SR = plot_size_SR*sqmcon
	lab	var			plot_size_hec_SR "SR area of plot in hectares"

* count missing values
	count			if plot_size_SR == . 
	count 			if plot_size_hec_SR !=.
	count			if plot_size_hec_SR == . 
	*** 26 observations do not have plot_size_SR
	*** 26 observations do not have plot_size_hec_SR
	*** 5,061 observations have plot_size_hec_SR

* convert gps report to hectares
	count 			if plot_size_GPS == .  
	*** 1490 observations have no GPS value 
	gen 			plot_size_2 = .
	replace 		plot_size_2 = plot_size_GPS*sqmcon
	rename 			plot_size_2 plot_size_hec_GPS
	lab	var			plot_size_hec_GPS "GPS measured area of plot in hectares"

	count 			if plot_size_hec_GPS !=.
	count			if plot_size_hec_GPS == . 
	*** 1490 observations do not have plot_size_hec_GPS
	*** 3597 observations have plot_size_hec_GPS

	count	 		if plot_size_hec_SR != . & plot_size_hec_GPS != .
	*** 3583 observations have both self reported and GPS plot size in hectares

	pwcorr 			plot_size_hec_SR plot_size_hec_GPS
	*** relatively low correlation = 0.2658 between selfreported plot size and GPS

* check correlation within +/- 3sd of mean (GPS)
	sum 			plot_size_hec_GPS, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation of points with +/- 3sd is lower 0.2671

* check correlation within +/- 3sd of mean (GPS and SR)
	sum 			plot_size_hec_GPS, detail
	sum 			plot_size_hec_SR, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) & ///
						inrange(plot_size_hec_SR,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation between self reported and GPS for values within +/- 3 sd's of GPS and SR is higher - actually pretty good - 0.4698

* examine larger plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 2
	*** 1147 GPS which are greater than 2
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 20
	*** 32 GPS which are greater than 20
	*** some are fairly large... 
	*** but looking at 2011 - it seems like this is possible, based on distribution between years

* correlation at higher plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS)
	*** correlation at higher plot sizes is middle of the line for these correlations 0.1977

* examine smaller plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.1
	*** 233  below 0.1
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.05
	*** 120 below 0.5
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.005
	*** 13 are below 0.005
	*** none are unrealistically small
	
*correlation at lower plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS < 0.01, sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS < 0.01
	*** large but negative relationship between GPS and SR plotsize, correlation = -0.4776
	
* compare GPS and SR
* examine GPS 
	sum 			plot_size_hec_GPS
	sum 			plot_size_hec_SR
	*** GPS tending to be smaller than self-reported, but only VERY slightly 2.32 v. 2.45
	*** per conversations with WBG will not include SR in imputation - only will include GPS 
	** tested with both including SR and not (findings below)
			*** IMPUTE WITH ONLY GPS - mean 2.2, sd 4.31
			*** IMPUTE WITH GPS AND SR - mean 2.23, sd 4.57
	
* examine with histograms
* * so they don't run every time i run this file 	
	*histogram 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.3
	*histogram 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.2
	*histogram 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.1
	*** GPS seems only okay at all sizes
	
* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plot_size_hec_GPS // identify plotsize_GPS as the variable being imputed
	sort			hhid_y2 field parcel, stable // sort to ensure reproducability of results
	mi impute 		pmm plot_size_hec_GPS plot_size_hec_SR i.clusterid, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset

* look at the data
	tab				mi_miss
	tabstat 		plot_size_hec_GPS plot_size_hec_SR plot_size_hec_GPS_1_, ///
						by(mi_miss) statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g)
	*** imputed values change VERY little - mean from 2.32 to 2.29 -- all very reasonable changes
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

	keep 			hhid_y2 hid clusterid hh_num hh_num1 extension field parcel plotsize

* create unique household-plot identifier
	isid			hhid_y2 field parcel 
	sort			hhid_y2 field parcel, stable 
	egen			plot_id = group(hhid_y2 field parcel)
	lab var			plot_id "unique field and parcel identifier (hhid_y2 field parcel)"
	
	label var 		hhid_y2 "unique id - match w2 with weather"
	label var		hid "unique id - match w2 with w1 (no extension)"
	label var 		hh_num1 "household id - string changed, not unique"

	compress
	describe
	summarize

* save file
	save 			"`export'/2014_as1p1", replace

* close the log
	log	close

/* END */