* Project: WB Weather
* Created on: Feb 8, 2024
* Created by: reece
* Stata v.18

* does
	* reads in Mali, WAVE 2 (2017), eaci17_s11bp1
	* cleans plot size (hecatres)


* assumes
	* customsave.ado
	* mdesc.ado

* TO DO:
	* create hid variable (clusterid + hh_num)
		***need menage/household number variable
	* impute missing plot values
	
	
	
	
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root	=		"$data/household_data/mali/wave_2/raw"
	global	export	=		"$data/household_data/mali/wave_2/refined"
	global	logout	= 		"$data/household_data/mali/logs"
	
* open log
	cap 	log 	close
	log 	using	"$logout/eaci17_s11bp1", append 

	
* **********************************************************************
* 1 - describing plot size - self-reported and GPS
* **********************************************************************
	
* import the first relevant data file
	use				"$root/eaci17_s11bp1", clear

* dropping duplicates
	duplicates 		drop	
	
	rename 			passage visit
	label 			var visit "number of visit - wave number"
	rename			grappe clusterid
	label 			var clusterid "cluster number"
	*rename			menage hh_num
	*label 			var hh_num "household number - not unique id"
	*rename 			s1bq03 ord 
	*label 			var ord "number of order"
	rename 			s11bq01 field 
	label 			var field "field number"
	rename 			s11bq02 parcel 
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
	rename 			s11bq32 cultivated
	label 			var cultivated "plot cultivated"
	*** 1 = fallow, 2 = rented, 3 = cultivated

* drop if not cultivated
	keep 			if cultivated == 3
	*** 152 dropped, 24098 kept
	
* determine self reported plotsize
	gen 			plot_size_SR = s11bq11a
	lab	var			plot_size_SR "self reported size of plot"
	***respondents reported plot size in hectares and square meters

* determine GPS plotsize
	gen 			plot_size_hec_GPS = s11bq07
	lab var			plot_size_hec_GPS 	"GPS plot size in hectares"
	*** all GPS plots measured in hectares	

* drop if SR and GPS both equal to 0
	drop	 		if plot_size_hec_GPS == 0 & plot_size_SR == 0
	*** 0 values dropped  

* assume 0 GPS reading should be . values 
	replace 		plot_size_hec_GPS = . if plot_size_hec_GPS == 0 
	*** will replace 0 values to missing
	*** 0 real changes made


	
* **********************************************************************
* 2 - Self reported conversion to hectares
* **********************************************************************
*GPS plot sizes already in hectares
	
	gen 			plot_size_hec_SR = . 

* plots measures in square meters 
* create conversion variable 
	gen 			sqmcon = 0.0001

* determine SR plot size units
	rename  		s11bq11b plot_SR_unit
* convert to SR hectares
	replace 		plot_size_hec_SR = plot_size_SR
	replace 		plot_size_hec_SR = plot_size_SR*sqmcon if plot_SR_unit == 2
	lab	var			plot_size_hec_SR "SR area of plot in hectares"
	***1= hectares 2= sq meters
	*** 1291 real changes made
	*** seems to be issues with some unit labels
		***some respondents reported hectares instead of sq meters

* count missing values
	count			if plot_size_SR == . 
	count 			if plot_size_hec_SR !=.
	count			if plot_size_hec_SR == . 
	*** 351 observations do not have plot_size_SR
	*** 351 observations do not have plot_size_hec_SR
	*** 23747 observations have plot_size_hec_SR


	pwcorr			plot_size_hec_GPS plot_size_hec_SR
	***low correlation = 0.0133 between selfreported plot size and GPS
	
	tab 			plot_size_hec_SR
	***a few SR values are extremely high 
	
	
* scatter plot comparing SR and GPS plotsize
	twoway (scatter plot_size_hec_SR plot_size_hec_GPS)

* drop large SR values 
	drop 			if plot_size_hec_SR > 40
	
	pwcorr			plot_size_hec_GPS plot_size_hec_SR
	***much higher correlation after dropping incorrectly reported units
	***correlation = 0.6541
	
oifhreobreak

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
		save "$export/2011_as1p1", replace

* close the log
	log	close

/* END */
