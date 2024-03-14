* Project: WB Weather
* Created on: November 2020
* Created by: jdm
* Edited by: jdm
* Last edit: 26 August 2021 
* Stata v.17.0 

* does
	* reads in results data set
	* makes visualziations of results 

* assumes
	* you have results file 
	* customsave.ado
	* grc1leg2.ado

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root 	= 	"$data/results_data"
	global	stab 	= 	"$data/results_data/tables"
	global	xtab 	= 	"$data/output/paper/tables"
	global	sfig	= 	"$data/results_data/figures"	
	global 	xfig    =   "$data/output/paper/figures"
	global	logout 	= 	"$data/results_data/logs"

* open log	
	cap log close
	log 	using 	"$logout/resultsvis_r2", append


* **********************************************************************
* 1 - generate R^2 specification curves by extraction & model
* **********************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear
	
	sort 			regname ext 

	collapse 		(mean) r2_mu = adjustedr ///
						(sd) r2_sd = adjustedr ///
						(count) n = adjustedr, by(regname ext)
	
	gen 			r2_hi = r2_mu + invttail(n-1,0.025) * (r2_sd / sqrt(n))
	gen				r2_lo = r2_mu - invttail(n-1,0.025) * (r2_sd / sqrt(n))
	
* weather only and weather squared only
preserve
	keep			if regname == 1 | regname == 4
	sort 			regname r2_mu 
	gen 			obs = _n	

	global			title =		"Adjusted R-Squared"

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	ext + 6 + 2
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Extraction"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	28
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(10)20) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "HH Bilinear" 10 "HH Simple" 11 "EA Bilinear" ///
						12 "EA Simple" 13 "Modified EA Bilinear" 14 "Modified EA Simple" ///
						15 "Admin Bilinear" 16 "Admin Simple" 17 "EA Zonal Mean" ///
						18 "Admin Zonal Mean" 19 "*{bf:Extraction}*" 28 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if ext == 1 | ext == 3 | ext == 5, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(0.012(0.002)0.024, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg1_reg4_ext", replace)	
restore
	
	
* weather FE and weather squared FE
preserve
	keep			if regname == 2 | regname == 5
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	ext + 6 + 2
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Extraction"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	28
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(10)20) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "HH Bilinear" 10 "HH Simple" 11 "EA Bilinear" ///
						12 "EA Simple" 13 "Modified EA Bilinear" 14 "Modified EA Simple" ///
						15 "Admin Bilinear" 16 "Admin Simple" 17 "EA Zonal Mean" ///
						18 "Admin Zonal Mean" 19 "*{bf:Extraction}*" 28 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if ext == 1 | ext == 3 | ext == 5, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(.082(.003).097, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg2_reg5_ext", replace)	
restore


* weather FE inputs and weather squared FE inputs
preserve
	keep			if regname == 3 | regname == 6
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	ext + 6 + 2
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Extraction"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	28
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(10)20) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "HH Bilinear" 10 "HH Simple" 11 "EA Bilinear" ///
						12 "EA Simple" 13 "Modified EA Bilinear" 14 "Modified EA Simple" ///
						15 "Admin Bilinear" 16 "Admin Simple" 17 "EA Zonal Mean" ///
						18 "Admin Zonal Mean" 19 "*{bf:Extraction}*" 28 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if ext == 1 | ext == 3 | ext == 5, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(.223(.003).238, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg3_reg6_ext", replace)	
restore

* combine R^2 specification curves for extration
	grc1leg2 		"$sfig/r2_reg1_reg4_ext.gph" "$sfig/r2_reg2_reg5_ext.gph"  ///
						"$sfig/r2_reg3_reg6_ext.gph", col(2) iscale(.5) ///
						ring(0) pos(5) holes(4) commonscheme
						
	graph export 	"$xfig\r2_ext.pdf", as(pdf) replace
		

* **********************************************************************
* 2 - generate random number to select extraction method
* **********************************************************************

* prior to the posting of the anonymized paper on arXiv the following random extraction was used

/* choose one extraction method at random
preserve
	clear			all
	set obs			1
	set seed		3317230
	gen double 		u = (10-1) * runiform() + 1
	gen 			i = round(u)
	sum		 		u i 
restore	
*** random number was 3, so we proceed with extraction method 3
*/

* after the data was de-anonymized, we replace the above method of selection
* with the "true" or preferred extraction method household bilinear (ext 1)


* **********************************************************************
* 3 - generate R^2 specification curves by weather metric & model
* **********************************************************************


* **********************************************************************
* 3a - generate R^2 specification curves by rainfall metric & model
* **********************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear

* keep HH Bilinear	
	keep			if ext == 1
	sort 			regname varname 

	collapse 		(mean) r2_mu = adjustedr ///
						(sd) r2_sd = adjustedr ///
						(count) n = adjustedr, by(regname varname)
	
	gen 			r2_hi = r2_mu + invttail(n-1,0.025) * (r2_sd / sqrt(n))
	gen				r2_lo = r2_mu - invttail(n-1,0.025) * (r2_sd / sqrt(n))

* weather only and weather squared only
preserve
	keep			if regname == 1 | regname == 4
	keep			if varname < 15
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	varname + 6 + 2
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Rainfall Metric"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	37
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(4)28) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "Mean Daily Rain" 10 "Median Daily Rain" 11 "Variance of Daily Rain" ///
						12 "Skew of Daily Rain" 13 "Total Seasonal Rain" 14 "Dev. in Total Rain" ///
						15 "z-Score of Total Rain" 16 "Rainy Days" 17 "Dev. in Rainy Days" ///
						18 "No Rain Days" 19 "Dev. in No Rain Days" 20 "% Rainy Days" ///
						21 "Dev. in % Rainy Days" 22 "Longest Dry Spell" ///
						23 "*{bf:Rainfall Metric}*" 37 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if varname == 1 | varname == 5 | varname == 8 | ///
						varname == 10 | varname == 12, msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(0(0.01)0.04, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg1_reg4_rf", replace)	
restore

	graph export 	"$xfig\r2_reg1_reg4_rf.png", width(1400) replace			


* weather FE and weather squared FE
preserve
	keep			if regname == 2 | regname == 5
	keep			if varname < 15
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	varname + 6 + 2
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Rainfall Metric"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	37
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(4)28) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "Mean Daily Rain" 10 "Median Daily Rain" 11 "Variance of Daily Rain" ///
						12 "Skew of Daily Rain" 13 "Total Seasonal Rain" 14 "Dev. in Total Rain" ///
						15 "z-Score of Total Rain" 16 "Rainy Days" 17 "Dev. in Rainy Days" ///
						18 "No Rain Days" 19 "Dev. in No Rain Days" 20 "% Rainy Days" ///
						21 "Dev. in % Rainy Days" 22 "Longest Dry Spell" ///
						23 "*{bf:Rainfall Metric}*" 37 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if varname == 1 | varname == 5 | varname == 8 | ///
						varname == 10 | varname == 12, msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(0.07(0.01)0.12, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg2_reg5_rf", replace)	
restore


* weather FE inputs and weather squared FE inputs
preserve
	keep			if regname == 3 | regname == 6
	keep			if varname < 15
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	varname + 6 + 2
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Rainfall Metric"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	37
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(4)28) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "Mean Daily Rain" 10 "Median Daily Rain" 11 "Variance of Daily Rain" ///
						12 "Skew of Daily Rain" 13 "Total Seasonal Rain" 14 "Dev. in Total Rain" ///
						15 "z-Score of Total Rain" 16 "Rainy Days" 17 "Dev. in Rainy Days" ///
						18 "No Rain Days" 19 "Dev. in No Rain Days" 20 "% Rainy Days" ///
						21 "Dev. in % Rainy Days" 22 "Longest Dry Spell" ///
						23 "*{bf:Rainfall Metric}*" 37 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if varname == 1 | varname == 5 | varname == 8 | ///
						varname == 10 | varname == 12, msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(0.2(0.02)0.26, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg3_reg6_rf", replace)	
restore	
	
* combine R^2 specification curves for satellite
	grc1leg2 		"$sfig/r2_reg1_reg4_rf.gph" "$sfig/r2_reg2_reg5_rf.gph"  ///
						"$sfig/r2_reg3_reg6_rf.gph", col(2) iscale(.5) ///
						ring(0) pos(5) holes(4) commonscheme
						
	graph export 	"$xfig\r2_rf.pdf", as(pdf) replace
		

* **********************************************************************
* 3b - generate R^2 specification curves by temperature metric & model
* **********************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear

* keep EA Bilinear	
	keep			if ext == 1
	sort 			regname varname 

	collapse 		(mean) r2_mu = adjustedr ///
						(sd) r2_sd = adjustedr ///
						(count) n = adjustedr, by(regname varname)
	
	gen 			r2_hi = r2_mu + invttail(n-1,0.025) * (r2_sd / sqrt(n))
	gen				r2_lo = r2_mu - invttail(n-1,0.025) * (r2_sd / sqrt(n))

* weather only and weather squared only
preserve
	keep			if regname == 1 | regname == 4
	keep			if varname > 14
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	varname + 6 + 2 - 14
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Temperature Metric"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(4)18) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "Mean Daily Temp" 10 "Median Daily Temp" ///
						11 "Variance of Daily Temp" 12 "Skew of Daily Temp" ///
						13 "Growing Degree Days" 14 "Dev. in GDD" 15 "z-Score of GDD" ///
						16 "Max Daily Temp" 17 "*{bf:Temperature Metric}*" 31 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if varname == 15 | varname == 16, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(0(0.02)0.08, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg1_reg4_tp", replace)	
restore


* weather FE and weather squared FE
preserve
	keep			if regname == 2 | regname == 5
	keep			if varname > 14
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	varname + 6 + 2 - 14
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Temperature Metric"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	37
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(4)18) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "Mean Daily Temp" 10 "Median Daily Temp" ///
						11 "Variance of Daily Temp" 12 "Skew of Daily Temp" ///
						13 "Growing Degree Days" 14 "Dev. in GDD" 15 "z-Score of GDD" ///
						16 "Max Daily Temp" 17 "*{bf:Temperature Metric}*" 31 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if varname == 15 | varname == 16, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(0.06(0.02)0.14, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg2_reg5_tp", replace)	
restore


* weather FE inputs and weather squared FE inputs
preserve
	keep			if regname == 3 | regname == 6
	keep			if varname > 14
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	varname + 6 + 2 - 14
	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Temperature Metric"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	37
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(4)18) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "Mean Daily Temp" 10 "Median Daily Temp" ///
						11 "Variance of Daily Temp" 12 "Skew of Daily Temp" ///
						13 "Growing Degree Days" 14 "Dev. in GDD" 15 "z-Score of GDD" ///
						16 "Max Daily Temp" 17 "*{bf:Temperature Metric}*" 31 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k2 obs if varname == 15 | varname == 16, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab(0.18(0.02)0.28, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.2) color(edkblue%40) yaxis(2) ), ///
						legend(order(4 5) cols(1) size(small) rowgap(.5) pos(12) ///
						label(4 "mean adjusted R{sup:2}") label(5 "95% C.I.") ) ///
						saving("$sfig/r2_reg3_reg6_tp", replace)	
restore	
	
* combine R^2 specification curves for satellite
	grc1leg2 		"$sfig/r2_reg1_reg4_tp.gph" "$sfig/r2_reg2_reg5_tp.gph"  ///
						"$sfig/r2_reg3_reg6_tp.gph", col(2) iscale(.5) ///
						ring(0) pos(5) holes(4) commonscheme
						
	graph export 	"$xfig\r2_tp.pdf", as(pdf) replace


* **********************************************************************
* 4 - select weather metrics to investigate
* **********************************************************************

* based on above analysis we will proceed with following rainfall metrics
	* mean rainfall (varname == 1)
	* total rainfall (varname == 5)
	* rainy days (varname == 8)
	* % rainy days (varname == 12)

* based on above analysis we will proceed with following temperature metrics
	* mean temperature (varname == 15)
	* median temperature (varname == 16)
	* variance temperature  (varname == 17)
	

* **********************************************************************
* 4a - generate R^2 specification curves by rainfall satellite & model
* **********************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear

* keep EA Bilinear	
	keep			if ext == 1
	keep			if varname == 1 | varname == 5 | varname == 8 | ///
						varname == 12
	sort 			regname sat 

	collapse 		(mean) r2_mu = adjustedr ///
						(sd) r2_sd = adjustedr ///
						(count) n = adjustedr, by(regname sat)
	
	gen 			r2_hi = r2_mu + invttail(n-1,0.025) * (r2_sd / sqrt(n))
	gen				r2_lo = r2_mu - invttail(n-1,0.025) * (r2_sd / sqrt(n))


* weather only and weather squared only
preserve
	keep			if regname == 1 | regname == 4
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	sat + 6 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Weather Product"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	22
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(1)12) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "CHIRPS" 10 "CPC" 11 "MERRA-2" ///
						12 "ARC2" 13 "ERA5" 14 "TAMSAT" ///
						15 "*{bf:Weather Product}*" 22 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) msize(small) ///
						ylab( 0.00(0.01)0.05, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.1) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(1) size(small) rowgap(.5) pos(12) ///
						label(3 "mean adjusted R{sup:2}") label(4 "95% C.I.") )  ///
						saving("$sfig/r2_reg1_reg4_sat_rf", replace)	
restore

	graph export 	"$xfig\r2_reg1_reg4_sat_rf.png", width(1400) replace		
	
* weather FE and weather squared FE
preserve
	keep			if regname == 2 | regname == 5
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	sat + 6 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Weather Product"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	22
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(1)12) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "CHIRPS" 10 "CPC" 11 "MERRA-2" ///
						12 "ARC2" 13 "ERA5" 14 "TAMSAT" ///
						15 "*{bf:Weather Product}*" 22 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) msize(small) ///
						ylab(0.06(0.02)0.12 , axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.1) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(1) size(small) rowgap(.5) pos(12) ///
						label(3 "mean adjusted R{sup:2}") label(4 "95% C.I.") ) ///
						saving("$sfig/r2_reg2_reg5_sat_rf", replace)	
restore


* weather FE inputs and weather squared FE inputs
preserve
	keep			if regname == 3 | regname == 6
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	sat + 6 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Weather Product"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	22
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(1)12) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "CHIRPS" 10 "CPC" 11 "MERRA-2" ///
						12 "ARC2" 13 "ERA5" 14 "TAMSAT" ///
						15 "*{bf:Weather Product}*" 22 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) msize(small) ///
						ylab(0.20(0.01)0.27 , axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.1) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(1) size(small) rowgap(.5) pos(12) ///
						label(3 "mean adjusted R{sup:2}") label(4 "95% C.I.") ) ///
						saving("$sfig/r2_reg3_reg6_sat_rf", replace)	
restore	
	
* combine R^2 specification curves for satellite
	grc1leg2 		"$sfig/r2_reg1_reg4_sat_rf.gph" "$sfig/r2_reg2_reg5_sat_rf.gph"  ///
						"$sfig/r2_reg3_reg6_sat_rf.gph", col(2) iscale(.5) ///
						ring(0) pos(5) holes(4) commonscheme
						
	graph export 	"$xfig\r2_sat_rf.pdf", as(pdf) replace
		
	
* **********************************************************************
* 4a - generate R^2 specification curves by temperature satellite & model
* **********************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear

* keep EA Bilinear	
	keep			if ext == 1
	keep			if varname == 15 | varname == 16 | ///
						varname == 17
	sort 			regname sat 

	collapse 		(mean) r2_mu = adjustedr ///
						(sd) r2_sd = adjustedr ///
						(count) n = adjustedr, by(regname sat)
	
	gen 			r2_hi = r2_mu + invttail(n-1,0.025) * (r2_sd / sqrt(n))
	gen				r2_lo = r2_mu - invttail(n-1,0.025) * (r2_sd / sqrt(n))


* weather only and weather squared only
preserve
	keep			if regname == 1 | regname == 4
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	sat + 6 + 2
	
* subtract values of off k3 because of varname numbering
		replace			k2		=	9 if k2 == 15
		replace			k2		=	10 if k2 == 16
		replace			k2		=	11 if k2 == 17

* label new variables	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Weather Product"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	18
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(1)6) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "MERRA-2" 10 "ERA5" 11 "CPC" ///
						12 "*{bf:Weather Product}*" 18 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) msize(small) ///
						ylab( 0.02(0.01)0.06, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.05) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(1) size(small) rowgap(.5) pos(12) ///
						label(3 "mean adjusted R{sup:2}") label(4 "95% C.I.") ) ///
						saving("$sfig/r2_reg1_reg4_sat_tp", replace)	
restore

	graph export 	"$xfig\r2_reg1_reg4_sat_tp.png", width(1400) replace		
	


* weather FE and weather squared FE
preserve
	keep			if regname == 2 | regname == 5
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	sat + 6 + 2
	
* subtract values of off k3 because of varname numbering
		replace			k2		=	9 if k2 == 15
		replace			k2		=	10 if k2 == 16
		replace			k2		=	11 if k2 == 17

* label new variables	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Weather Product"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	18
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(1)6) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "MERRA-2" 10 "ERA5" 11 "CPC" ///
						12 "*{bf:Weather Product}*" 18 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) msize(small) ///
						ylab( 0.06(0.02)0.14, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.05) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(1) size(small) rowgap(.5) pos(12) ///
						label(3 "mean adjusted R{sup:2}") label(4 "95% C.I.") ) ///
						saving("$sfig/r2_reg2_reg5_sat_tp", replace)	
restore


* weather FE inputs and weather squared FE inputs
preserve
	keep			if regname == 3 | regname == 6
	sort 			regname r2_mu 
	gen 			obs = _n	

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	sat + 6 + 2
	
* subtract values of off k3 because of varname numbering
		replace			k2		=	9 if k2 == 15
		replace			k2		=	10 if k2 == 16
		replace			k2		=	11 if k2 == 17

* label new variables	
	lab				var obs "Specification # - sorted by model & effect size"

	lab 			var k1 "Model"
	lab 			var k2 "Weather Product"

	sum			 	r2_hi
	global			bmax = r(max)
	
	sum			 	r2_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	18
	  
	di $bmin
	di $brange
	di $from_y
	di $gheight
		
	twoway 			scatter k1 k2 obs, xlab(0(1)6) xsize(10) ysize(6) msize(small small small) title("")	  ///
						ylab(0(1)$gheight ) ylabel(1 "Weather" ///
						2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "Weather + Weather{sup:2}" 5 "Weather + Weather{sup:2} + FE" /// 
						6 "Weather + Weather{sup:2} + FE + Inputs" 7 "*{bf:Model}*" ///
						9 "MERRA-2" 10 "ERA5" 11 "CPC" ///
						12 "*{bf:Weather Product}*" 18 " ", angle(0) ///
						labsize(vsmall) tstyle(notick)) || ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) msize(small) ///
						ylab( 0.18(0.02)0.28, axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.05) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(1) size(small) rowgap(.5) pos(12) ///
						label(3 "mean adjusted R{sup:2}") label(4 "95% C.I.") ) ///
						saving("$sfig/r2_reg3_reg6_sat_tp", replace)	
restore	
	
* combine R^2 specification curves for satellite
	grc1leg2 		"$sfig/r2_reg1_reg4_sat_tp.gph" "$sfig/r2_reg2_reg5_sat_tp.gph"  ///
						"$sfig/r2_reg3_reg6_sat_tp.gph", col(2) iscale(.5) ///
						ring(0) pos(5) holes(4) commonscheme
						
	graph export 	"$xfig\r2_sat_tp.pdf", as(pdf) replace
	
	
* **********************************************************************
* 4 - end matter
* **********************************************************************


* close the log
	log	close

/* END */		