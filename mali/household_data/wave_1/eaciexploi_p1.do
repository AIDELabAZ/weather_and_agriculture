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
	
* Project: WB Weather
* Created on: June 2020
* Created by: ek
* Stata v.16

* does
	* reads in Niger, WAVE 1 (2011), POST PLANTING (first passage), ecvmaas1_p1_en
	* cleans plot size (hecatres)
	* creates binaries for pesticide and herbicide use
	* creates binaries and kg for fertilizer use
	* cleans labor post planting - prep labor
	* outputs clean data file ready for combination with wave 1 data

* assumes
	* customsave.ado
	* mdesc.ado

* TO DO:
	* done
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=		"$data/household_data/niger/wave_1/raw"
	loc		export	=		"$data/household_data/niger/wave_1/refined"
	loc		logout	= 		"$data/household_data/niger/logs"

* open log
	cap 	log 	close
	log 	using	"`logout'/2011_as1p1", append

	
* **********************************************************************
* 1 - describing plot size - self-reported and GPS
* **********************************************************************
	
* import the first relevant data file
	use				"$root/ecvmaas1_p1_en", clear
	
	rename 			passage visit
	label 			var visit "number of visit - wave number"
	rename			grappe clusterid
	label 			var clusterid "cluster number"
	rename			menage hh_num
	label 			var hh_num "household number - not unique id"
	rename 			as01qa ord 
	label 			var ord "number of order"
	*** note that ord is the id number
	
	rename 			as01q03 field 
	label 			var field "field number"
	rename 			as01q05 parcel 
	label 			var parcel "parcel number"
	*** cant find "extension" variable like they have in wave 2
	*** extension designates movers in wave 2 - does not exist in wave 1 
	
* need to include hid field parcel to uniquely identify
	sort 			hid field parcel
	isid 			hid field parcel
	
* determine cultivated plot
	rename 			as01q40 cultivated
	label 			var cultivated "plot cultivated"

* drop if not cultivated
	keep 			if cultivated == 1
	*** 220 observations dropped
	*** as01q42 asks about fallow specifically rather than did you cultivate 
	
* determine self reported plotsize
	gen 			plot_size_SR = as01q08
	lab	var			plot_size_SR "self reported size of plot, in square meters"
	*** all plots measured in metre carre - square meters

	replace			plot_size_SR = . if plot_size_SR > 999997
	*** 110 changed to missing 

* determine GPS plotsize
	gen 			plot_size_GPS = as01q09
	lab var			plot_size_GPS 	"GPS plot size in sq. meters"
	*** all plots measured in metre carre - square meters
	*** 999999 seems to be a code used to designate missing values
	
	replace			plot_size_GPS = . if plot_size_GPS > 999997
	***  changed to missing 
	
* drop if SR and GPS both equal to 0
	drop	 		if plot_size_GPS == 0 & plot_size_SR == 0
	*** 31 values dropped  

* assume 0 GPS reading should be . values 
	replace 		plot_size_GPS = . if plot_size_GPS == 0 
	*** will replace 1747 values to missing
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
	*** 110 missing plot_size_SR
	*** 110 missing plot_size_hec_SR
	*** 6303 have plot_size_hec_SR
	
* convert gps report to hectares
	count 			if plot_size_GPS == . 
	*** 3262 have no gps value
	gen 			plot_size_2 = .
	replace 		plot_size_2 = plot_size_GPS*sqmcon
	rename 			plot_size_2 plot_size_hec_GPS
	lab	var			plot_size_hec_GPS "GPS measured area of plot in hectares"

	count 			if plot_size_hec_GPS !=.
	count			if plot_size_hec_GPS == . 
	*** 3151 have GPS
	*** 3262 do not have GPS
	
	count	 		if plot_size_hec_SR != . & plot_size_hec_GPS != .
	*** 3068 observations have both self reported and GPS plot size in hectares

	pwcorr 			plot_size_hec_SR plot_size_hec_GPS
	*** relatively low correlation = 0.2403 between selfreported plot size and GPS

* check correlation within +/- 3sd of mean (GPS)
	sum 			plot_size_hec_GPS, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation of points with +/- 3sd is higher 0.3600

* check correlation within +/- 3sd of mean (GPS and SR)
	sum 			plot_size_hec_GPS, detail
	sum 			plot_size_hec_SR, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) & ///
						inrange(plot_size_hec_SR,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation between self reported and GPS for values within +/- 3 sd's of GPS and SR is higher and good: 0.5505

* examine larger plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 2
	*** 944 GPS which are greater than 2
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 20
	*** 29 GPS which are greater than 20
	*** 3 GPS measures are in the 90's 

* correlation at higher plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS)
	*** very low correlation at higher plot sizes: 0.0725

* examine smaller plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.1
	*** 222  below 0.1
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.05
	*** 126 below 0.5
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.005
	*** 20 are below 0.005
	*** none are unrealistically small, 0.005 hectares is 50 square meters which is a very small vegetable patch.
	
*correlation at lower plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS < 0.01, sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS < 0.01
	*** small relationship between GPS and SR plotsize, correlation = 0.1455
	
* compare GPS and SR
* examine GPS 
	sum 			plot_size_hec_GPS
	sum 			plot_size_hec_SR
	*** GPS tending to be larger than self-reported, mean gps 2.318 and sr 1.906
	*** per conversations with WBG will not include SR in imputation - only will include GPS 
	
* compare the self reported and GPS plot size measures for large plots
	tab plot_size_hec_SR plot_size_hec_GPS if plot_size_hec_GPS > 70
	tab plot_size_hec_SR plot_size_hec_GPS if plot_size_hec_SR > 60
	*** huge discrepencies between self reported and gps plot sizes at higher plot sizes.
	*** the same obs that are over 80 hectares GPS are less than 10 hectares self reported
	*** the same obs that is 70 hectares self reported is 3.1 hectares GPS
	
* replace large GPS values that do not have large SR values
	sum plot_size_hec_GPS, detail // standard deviation is 5.5, 4 std. above mean is 24.31
	tab plot_size_hec_GPS plot_size_hec_SR if plot_size_hec_GPS> 24.31 // there are 3 obs with a high GPS, 33 hec, and a high SR plot, 20 hec, suggests they are correct readings. 
	replace plot_size_hec_GPS = . if plot_size_hec_GPS> 40 // above 40 hectares SR totally contridicts GPS and makes appears unreliable
	*** 14 changed to missing

* examine with histograms
	*histogram 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.3
	*histogram 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.2
	*histogram 		plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.1
	*** GPS seems okay at all sizes
	
* sum plot_size_hec_GPS
	sum plot_size_hec_GPS, detail
	*** mean 2.02
	
* impute missing plot sizes using predictive mean matching
	mi set 			wide // declare the data to be wide.
	mi xtset		, clear // this is a precautinary step to clear any existing xtset
	mi register 	imputed plot_size_hec_GPS // identify plotsize_GPS as the variable being imputed
	sort			hid field parcel, stable // sort to ensure reproducability of results
	mi impute 		pmm plot_size_hec_GPS plot_size_hec_SR i.clusterid, add(1) rseed(245780) noisily dots ///
						force knn(5) bootstrap
	mi unset

* look at the data
	tab				mi_miss
	tabstat 		plot_size_hec_GPS plot_size_hec_SR plot_size_hec_GPS_1_, ///
						by(mi_miss) statistics(n mean min max) columns(statistics) ///
						longstub format(%9.3g)
	*** mean changes little after impute - mean 2.02
	*** imputed 3237 obs

* drop if anything else is still missing
	list			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						missing(plot_size_hec_GPS_1_), sep(0)
	drop 			if missing(plot_size_hec_GPS_1_)
	*** 0 observations deleted

	rename			plot_size_hec_GPS_1_ plotsize
	lab	var			plotsize	"plot size (ha)"



* **********************************************************************
* 7 - end matter, clean up to save
* **********************************************************************

	keep 			hid clusterid hh_num field parcel plotsize

* create unique household-plot identifier
	isid				hid field parcel
	sort				hid field parcel
	egen				plot_id = group(hid field parcel)
	lab var				plot_id "unique field and parcel identifier"

	compress
	describe
	summarize

* save file
		save "$export/2011_as1p1", replace

* close the log
	log	close

/* END */
