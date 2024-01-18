* Project: WB Weather - Privacy Paper
* Created on: 13 December 2021
* Created by: jdm
* Edited by: jdm
* Last edit: 16 May 2022 
* Stata v.17.0 

* does
	* reads in results data set
	* makes visualziations of results 

* assumes
	* you have results file 
	* grc1leg2.ado

* TO DO:
	* complete

	
************************************************************************
**# 0 - setup
************************************************************************

* define paths
	global	root 	= 	"$data/results_data"
	global	stab 	= 	"$data/results_data/tables"
	global	xtab 	= 	"$data/output/privacy_paper/tables"
	global	sfig	= 	"$data/results_data/figures"	
	global 	xfig    =   "$data/output/privacy_paper/figures"
	global	logout 	= 	"$data/results_data/logs"

* open log	
	cap log close
	log 	using 	"$logout/privacy_r2_vis", append


************************************************************************
**# 1 - generate R^2 specification curves by extraction & model	
************************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear
	
	sort 			regname ext 
/*
	collapse 		(mean) r2_mu = adjustedr ///
						(sd) r2_sd = adjustedr ///
						(count) n = adjustedr, by(regname ext)
	
	gen 			r2_hi = r2_mu + invttail(n-1,0.025) * (r2_sd / sqrt(n))
	gen				r2_lo = r2_mu - invttail(n-1,0.025) * (r2_sd / sqrt(n))
*/
	collapse 		(mean) r2_mu = loglike ///
						(sd) r2_sd = loglike ///
						(count) n = loglike, by(regname ext)
	
	gen 			r2_hi = r2_mu + invttail(n-1,0.025) * (r2_sd / sqrt(n))
	gen				r2_lo = r2_mu - invttail(n-1,0.025) * (r2_sd / sqrt(n))

	
************************************************************************
**## 1a - weather only
************************************************************************
	
preserve
	keep			if regname == 1
	sort 			r2_mu 
	gen 			obs = _n	

	global			title =		"Adjusted R-Squared"

* stack values of the specification indicators
	gen 			k1 		= 	ext
	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Extraction"

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
		
	twoway 			scatter k1 obs, xlab(0(1)10) xsize(10) ysize(6) ///
						title("Weather") xtitle("") ///
						msize(small small small) ylab(0(1)$gheight ) ///
						ytitle("") ylabel(1 "{bf:HH bilinear}" 2 "HH simple" ///
						3 "EA bilinear" 4 "EA simple" 5 "EA modified bilinear" ///
						6 "EA modified simple" 7 "Admin bilinear" ///
						8 "Admin simple" 9 "EA zone" ///
						10 "Admin area" 11 "*{bf:Anon. Method}*" 18 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k1 obs if ext == 1, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab( , axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.08) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(2) size(small) rowgap(.5) pos(12) ///
						label(3 "mean log likelihood") label(4 "95% C.I. on mean") ) ///
						saving("$sfig/r2_reg1_ext", replace)	
						
		graph export 	"$data/output/presentations/PacDev/r2_reg1_ext.pdf", as(pdf) replace
restore
		

************************************************************************
**## 1b - weather squared only
************************************************************************

preserve
	keep			if regname == 4
	sort 			r2_mu 
	gen 			obs = _n	

	global			title =		"Adjusted R-Squared"

* stack values of the specification indicators
	gen 			k1 		= 	ext
	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Extraction"

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
		
	twoway 			scatter k1 obs, xlab(0(1)10) xsize(10) ysize(6) ///
						title("Weather + Weather{sup:2}") xtitle("") ///
						msize(small small small) ylab(0(1)$gheight ) ///
						ytitle("") ylabel(1 "{bf:HH bilinear}" 2 "HH simple" ///
						3 "EA bilinear" 4 "EA simple" 5 "EA modified bilinear" ///
						6 "EA modified simple" 7 "Admin bilinear" ///
						8 "Admin simple" 9 "EA zone" ///
						10 "Admin area" 11 "*{bf:Anon. Method}*" 18 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k1 obs if ext == 1, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab( , axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.08) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(2) size(small) rowgap(.5) pos(12) ///
						label(3 "mean log likelihood") label(4 "95% C.I. on mean") ) ///
						saving("$sfig/r2_reg4_ext", replace)		
						
		graph export 	"$data/output/presentations/PacDev/r2_reg4_ext.pdf", as(pdf) replace
restore


************************************************************************
**## 1c - weather and FEs
************************************************************************

preserve
	keep			if regname == 2
	sort 			r2_mu 
	gen 			obs = _n	

	global			title =		"Adjusted R-Squared"

* stack values of the specification indicators
	gen 			k1 		= 	ext
	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Extraction"

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
		
	twoway 			scatter k1 obs, xlab(0(1)10) xsize(10) ysize(6) ///
						title("Weather + FE")  ///
						msize(small small small) ylab(0(1)$gheight ) ///
						ytitle("") ylabel(1 "{bf:HH bilinear}" 2 "HH simple" ///
						3 "EA bilinear" 4 "EA simple" 5 "EA modified bilinear" ///
						6 "EA modified simple" 7 "Admin bilinear" ///
						8 "Admin simple" 9 "EA zone" ///
						10 "Admin area" 11 "*{bf:Anon. Method}*" 18 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k1 obs if ext == 1, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab( , axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.08) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(2) size(small) rowgap(.5) pos(12) ///
						label(3 "mean log likelihood") label(4 "95% C.I. on mean") ) ///
						saving("$sfig/r2_reg2_ext", replace)	
restore		


************************************************************************
**## 1d - weather squared and FEs
************************************************************************

preserve
	keep			if regname == 5
	sort 			r2_mu 
	gen 			obs = _n	

	global			title =		"Adjusted R-Squared"

* stack values of the specification indicators
	gen 			k1 		= 	ext
	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Extraction"

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
		
	twoway 			scatter k1 obs, xlab(0(1)10) xsize(10) ysize(6) ///
						title("Weather + Weather{sup:2} + FE") ///
						msize(small small small) ylab(0(1)$gheight ) ///
						ytitle("") ylabel(1 "{bf:HH bilinear}" 2 "HH simple" ///
						3 "EA bilinear" 4 "EA simple" 5 "EA modified bilinear" ///
						6 "EA modified simple" 7 "Admin bilinear" ///
						8 "Admin simple" 9 "EA zone" ///
						10 "Admin area" 11 "*{bf:Anon. Method}*" 18 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k1 obs if ext == 1, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab( , axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.08) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(2) size(small) rowgap(.5) pos(12) ///
						label(3 "mean log likelihood") label(4 "95% C.I. on mean") ) ///
						saving("$sfig/r2_reg5_ext", replace)	
restore			


************************************************************************
**## 1e - weather and FEs and inputs
************************************************************************

preserve
	keep			if regname == 3
	sort 			r2_mu 
	gen 			obs = _n	

	global			title =		"Adjusted R-Squared"

* stack values of the specification indicators
	gen 			k1 		= 	ext
	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Extraction"

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
		
	twoway 			scatter k1 obs, xlab(0(1)10) xsize(10) ysize(6) ///
						title("Weather + FE + Inputs") ///
						msize(small small small) ylab(0(1)$gheight ) ///
						ytitle("") ylabel(1 "{bf:HH bilinear}" 2 "HH simple" ///
						3 "EA bilinear" 4 "EA simple" 5 "EA modified bilinear" ///
						6 "EA modified simple" 7 "Admin bilinear" ///
						8 "Admin simple" 9 "EA zone" ///
						10 "Admin area" 11 "*{bf:Anon. Method}*" 18 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k1 obs if ext == 1, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab( , axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.08) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(2) size(small) rowgap(.5) pos(12) ///
						label(3 "mean log likelihood") label(4 "95% C.I. on mean") ) ///
						saving("$sfig/r2_reg3_ext", replace)	
restore			


************************************************************************
**## 1f - weather squared and FEs and inputs
************************************************************************

preserve
	keep			if regname == 6
	sort 			r2_mu 
	gen 			obs = _n	

	global			title =		"Adjusted R-Squared"

* stack values of the specification indicators
	gen 			k1 		= 	ext
	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Extraction"

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
		
	twoway 			scatter k1 obs, xlab(0(1)10) xsize(10) ysize(6) ///
						title("Weather + Weather{sup:2} + FE + Inputs") ///
						msize(small small small) ylab(0(1)$gheight ) ///
						ytitle("") ylabel(1 "{bf:HH bilinear}" 2 "HH simple" ///
						3 "EA bilinear" 4 "EA simple" 5 "EA modified bilinear" ///
						6 "EA modified simple" 7 "Admin bilinear" ///
						8 "Admin simple" 9 "EA zone" ///
						10 "Admin area" 11 "*{bf:Anon. Method}*" 18 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
						(scatter k1 obs if ext == 1, ///
						msize(small small) mcolor(orange)) ///
						(scatter r2_mu obs, yaxis(2) mcolor(maroon) ///
						ylab( , axis(2) labsize(tiny) angle(0) ) ///
						yscale(range($from_y $bmax ) axis(2))) || ///
						(rbar r2_lo r2_hi obs, barwidth(.08) color(edkblue%40) yaxis(2) ), ///
						legend(order(3 4) cols(2) size(small) rowgap(.5) pos(12) ///
						label(3 "mean log likelihood") label(4 "95% C.I. on mean") ) ///
						saving("$sfig/r2_reg6_ext", replace)	
restore	
	

* combine R^2 specification curves for extration
	grc1leg2 		"$sfig/r2_reg1_ext.gph" "$sfig/r2_reg4_ext.gph" ///
						"$sfig/r2_reg2_ext.gph" "$sfig/r2_reg5_ext.gph", ///
						col(2) iscale(.5) pos(12) commonscheme
						
	graph export 	"$xfig\r2_ext.pdf", as(pdf) replace
	
************************************************************************
**# 2 - end matter
************************************************************************


* close the log
	log	close

/* END */		