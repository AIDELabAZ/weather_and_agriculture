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
	* address issues with self reported and GPS plot size discrepencies
	* impute missing data
	
	
	
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
	
* create household id 	
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
	
* determine self reported plotsize
	gen 			plot_size_hec_SR = s1bq10
	lab	var			plot_size_hec_SR "self reported size of plot, in hectares"
	*** all plots measured in hectares

* determine GPS plotsize
	gen 			plot_size_hec_GPS = s1bq05a
	lab var			plot_size_hec_GPS 	"GPS plot size in hectares"
	*** all plots measured in hectares
	*** 99 seems to be a code used to designate missing values

	order 			plot_size_hec_GPS s1bq10 plot_size_hec_SR, after(s1bq05a)		
	
	replace			plot_size_hec_SR = . if plot_size_hec_SR >= 99
	*** 806 changed to missing 
	
	replace			plot_size_hec_GPS = . if plot_size_hec_GPS >= 99
	*** 707 changed to missing 

* drop if SR and GPS both equal to 0
	drop	 		if plot_size_hec_GPS == 0 & plot_size_hec_SR == 0
	*** 0 values dropped  

* assume 0 GPS reading should be . values 
	replace 		plot_size_hec_GPS = . if plot_size_hec_GPS == 0 
	*** will replace 0 values to missing


	
* **********************************************************************
* 2 - conversion to hectares
* **********************************************************************
	***Mali plot sizes already in hectares

* count missing values
	count 			if plot_size_hec_SR !=.
	count			if plot_size_hec_SR == . 
	*** 8406 have plot_size_hec_SR
	*** 806 do not have plot_size_hec_SR

	count 			if plot_size_hec_GPS !=.
	count			if plot_size_hec_GPS == . 
	*** 8719 have GPS
	*** 493 do not have GPS
	
	count	 		if plot_size_hec_SR != . & plot_size_hec_GPS != .
	*** 7968 observations have both self reported and GPS plot size in hectares

	pwcorr 			plot_size_hec_SR plot_size_hec_GPS
	*** relatively low correlation = 0.2704 between selfreported plot size and GPS
	
* scatter plot comparing SR and GPS plotsize
	 twoway (scatter plot_size_hec_SR s1bq05a) ///
	 (scatter plot_size_hec_SR plot_size_hec_GPS) 
	
* scatter plot comparing SR and GPS plot size by crop type
* scatter plot comparing SR and GPS by millet, sorghum, rice, corn, and groundnut
 
	*all crops types
	twoway(scatter plot_size_hec_GPS plot_size_hec_SR), by(s1bq08b)
	
	*millet
	twoway (scatter plot_size_hec_GPS plot_size_hec_SR if s1bq08b == 101), by(s1bq08b) ///
	title("Millet")
	*graph export "$export/plot_corr_millet.png", replace as(png)
	
	*sorghum
	twoway (scatter plot_size_hec_GPS plot_size_hec_SR if s1bq08b == 102), by(s1bq08b) ///
	title("Sorghum")
	*graph export "$export/plot_corr_sorghum.png", replace as(png)
	
	*rice
	twoway (scatter plot_size_hec_GPS plot_size_hec_SR if s1bq08b == 103), by(s1bq08b) ///
	title("Rice")
	*graph export "$export/plot_corr_rice.png", replace as(png)
	
	*corn
	twoway (scatter plot_size_hec_GPS plot_size_hec_SR if s1bq08b == 104), by(s1bq08b) ///
	title("Corn")
	*graph export "$export/plot_corr_corn.png", replace as(png)
	
	*groundnut
	twoway (scatter plot_size_hec_GPS plot_size_hec_SR if s1bq08b == 121), by(s1bq08b) ///
	title("Groundnut")
	*graph export "$export/plot_corr_groundnut.png", replace as(png)
	
	
uwiqheuwqbreak

* check correlation within +/- 3sd of mean (GPS)
	sum 			plot_size_hec_GPS, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation of points with +/- 3sd is higher 0.2465

* check correlation within +/- 3sd of mean (GPS and SR)
	sum 			plot_size_hec_GPS, detail
	sum 			plot_size_hec_SR, detail
	pwcorr 			plot_size_hec_SR plot_size_hec_GPS if ///
						inrange(plot_size_hec_GPS,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)')) & ///
						inrange(plot_size_hec_SR,`r(p50)'-(3*`r(sd)'),`r(p50)'+(3*`r(sd)'))
	*** correlation between self reported and GPS for values within +/- 3 sd's of GPS and SR is higher and good: 0.5919

* examine larger plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 2
	*** 2154 GPS which are greater than 2
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 20
	*** 295 GPS which are greater than 20
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS > 90
	*** 16 GPS measures are in the 90's 

* correlation at higher plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS), sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS > 3 & !missing(plot_size_hec_GPS)
	*** very low correlation at higher plot sizes: 0.1857

* examine smaller plot sizes
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.1
	*** 680  below 0.1
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.05
	*** 326 below 0.5
	tab				plot_size_hec_GPS 	if 	plot_size_hec_GPS < 0.005
	*** 16 are below 0.005
	*** none are unrealistically small, 0.005 hectares is 50 square meters which is a very small vegetable patch.
	
*correlation at lower plot sizes
	list 			plot_size_hec_GPS plot_size_hec_SR 	if 	///
						plot_size_hec_GPS < 0.01, sep(0)
	pwcorr 			plot_size_hec_GPS plot_size_hec_SR 	if ///
						plot_size_hec_GPS < 0.01
	*** small relationship between GPS and SR plotsize, correlation = -0.1617
	
* compare GPS and SR
* examine GPS 
	sum 			plot_size_hec_GPS
	sum 			plot_size_hec_SR
	*** GPS tending to be larger than self-reported, mean gps 3.128 and sr 1.534
	*** per conversations with WBG will not include SR in imputation - only will include GPS 
	
* compare the self reported and GPS plot size measures for large plots
	tab plot_size_hec_SR plot_size_hec_GPS if plot_size_hec_GPS > 70
	tab plot_size_hec_SR plot_size_hec_GPS if plot_size_hec_SR > 60
	*** many discrepencies between self reported and gps plot sizes at higher plot sizes.
	*** 
	*** 
	
* replace large GPS values that do not have large SR values
	sum plot_size_hec_GPS, detail // standard deviation is 9.2, 4 std. above mean is 39.92
	tab plot_size_hec_GPS plot_size_hec_SR if plot_size_hec_GPS> 39.92 // there are 3 obs with a high GPS, 33 hec, and a high SR plot, 20 hec, suggests they are correct readings. 
	replace plot_size_hec_GPS = . if plot_size_hec_GPS> 40 // above 40 hectares SR totally contridicts GPS and makes appears unreliable
	***  changed to missing

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
		save "$export/eaciexploi_p1", replace

* close the log
	log	close

/* END */
