* Project: WB Weather - privacy paper
* Created on: 13 December 2019
* Created by: jdm
* Edited by: alj
* Last edit: 18 January 2024
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
	global	xtab 	= 	"$data/output/mismeasure_paper/tables"
	global	sfig	= 	"$data/results_data/figures"	
	global 	xfig    =   "$data/output/mismeasure_paper/figures"
	global	logout 	= 	"$data/results_data/logs"
	* s indicates Stata figures, works in progress
	* x indicates final version for paper 
	
* open log	
	cap log close
	log 	using 	"$logout/privacy_coeff_vis", append


************************************************************************
**# 1 - generate (non)-significant indicators
************************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear

*generate different betas based on signficance
	gen 			b_sig = beta
	replace 		b_sig = . if pval > .05
	lab var 		b_sig "p < 0.05"
	
	gen 			b_ns = beta
	replace 		b_ns= . if p <= .05
	lab var 		b_ns "n.s."
	
* generate significance dummy
	gen				sig = 1 if b_sig != .
	replace			sig = 0 if b_ns != .
	lab	def			yesno 0 "Not Significant" 1 "Significant"
	lab val			sig yesno
	lab var			sig "Weather variable is significant"
	
* generate sign dummy
	gen 			b_sign = 1 if b_sig > 0 & b_sig != .
	replace 		b_sign = 0 if b_sig < 0 & b_sig != .
	lab	def			posneg 0 "Negative" 1 "Positive"
	lab val			b_sign posneg
	lab var			b_sign "Sign on weather variable"
	
	
************************************************************************
**# 2 - generate specification chart for mean rainfall
************************************************************************
			
* define loop through levels of the data type variable	
	levelsof 	country, local(cty)
	local 		ctyname: value label country
	foreach 	l of local cty {
		local		ctyl: label `ctyname' `l'

	
************************************************************************
**## 2a - weather only
************************************************************************
	
preserve
	keep			if varname == 1 & country == 1 & regname == 1
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Rainfall: Weather Only")  ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(edkblue%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(edkblue%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v01_reg1_cty1", replace)
restore


************************************************************************
**## 2b - weather squared only
************************************************************************

preserve
	keep			if varname == 1 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Rainfall: Weather + Weather{sup:2}") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(edkblue%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(edkblue%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v01_reg4_cty`l'", replace)
restore


************************************************************************
**## 2c - weather and FEs
************************************************************************

preserve
	keep			if varname == 1 & country == `l' & regname == 2
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Rainfall: Weather + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(edkblue%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(edkblue%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v01_reg2_cty`l'", replace)
						
	*	graph export 	"$sfig/v01_reg2_cty`l'.pdf", as(pdf) replace
restore


************************************************************************
**## 2d - weather squared and FEs
************************************************************************

preserve
	keep			if varname == 1 & country == `l' & regname == 5
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Rainfall: Weather + Weather{sup:2} + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(edkblue%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(edkblue%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v01_reg5_cty`l'", replace)
restore


************************************************************************
**## 2e - weather and FEs and inputs
************************************************************************
/*
preserve
	keep			if varname == 1 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Rainfall: Weather + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(edkblue%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(edkblue%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v01_reg3_cty`l'", replace)
restore			


************************************************************************
**## 2f - weather squared and FEs and inputs
************************************************************************

preserve
	keep			if varname == 1 & country == `l' & regname == 6
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Rainfall: Weather + Weather{sup:2} + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(edkblue%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(edkblue%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v01_reg6_cty`l'", replace)
restore
*/
	}

	
************************************************************************
**# 3 - generate specification chart for no rain days
************************************************************************
			
* define loop through levels of the data type variable	
	levelsof 	country, local(cty)
	local 		ctyname: value label country
	foreach 	l of local cty {
		local		ctyl: label `ctyname' `l'


************************************************************************
**## 3a - weather only
************************************************************************
	
preserve
	keep			if varname == 10 & country == `l' & regname == 1
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("No Rain Days: Weather Only")  ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(brown%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(brown%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v10_reg1_cty`l'", replace)
restore


************************************************************************
**## 3b - weather squared only
************************************************************************

preserve
	keep			if varname == 10 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("No Rain Days: Weather + Weather{sup:2}") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(brown%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(brown%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v10_reg4_cty`l'", replace)
restore


************************************************************************
**## 3c - weather and FEs
************************************************************************

preserve
	keep			if varname == 10 & country == `l' & regname == 2
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("No Rain Days: Weather + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(brown%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(brown%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v10_reg2_cty`l'", replace)
restore


************************************************************************
**## 3d - weather squared and FEs
************************************************************************

preserve
	keep			if varname == 10 & country == `l' & regname == 5
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("No Rain Days: Weather + Weather{sup:2} + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(brown%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(brown%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v10_reg5_cty`l'", replace)
restore

/*
************************************************************************
**## 3e - weather and FEs and inputs
************************************************************************

preserve
	keep			if varname == 10 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("No Rain Days: Weather + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(brown%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(brown%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v10_reg3_cty`l'", replace)
restore			


************************************************************************
**## 3f - weather squared and FEs and inputs
************************************************************************

preserve
	keep			if varname == 10 & country == `l' & regname == 6
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("No Rain Days: Weather + Weather{sup:2} + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(brown%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(brown%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v10_reg6_cty`l'", replace)
restore
*/
	}
	
	
************************************************************************
**# 4 - generate specification chart for z-score total season
************************************************************************
			
* define loop through levels of the data type variable	
	levelsof 	country, local(cty)
	local 		ctyname: value label country
	foreach 	l of local cty {
		local		ctyl: label `ctyname' `l'


************************************************************************
**## 4a - weather only
************************************************************************
	
preserve
	keep			if varname == 7 & country == `l' & regname == 1
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("z-Score of Seasonal Rain: Weather Only")  ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(eltgreen%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(eltgreen%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v07_reg1_cty`l'", replace)
restore


************************************************************************
**## 4b - weather squared only
************************************************************************

preserve
	keep			if varname == 7 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("z-Score of Seasonal Rain: Weather + Weather{sup:2}") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(eltgreen%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(eltgreen%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v07_reg4_cty`l'", replace)
restore


************************************************************************
**## 4c - weather and FEs
************************************************************************

preserve
	keep			if varname == 7 & country == `l' & regname == 2
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("z-Score of Seasonal Rain: Weather + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(eltgreen%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(eltgreen%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v07_reg2_cty`l'", replace)
restore


************************************************************************
**## 4d - weather squared and FEs
************************************************************************

preserve
	keep			if varname == 7 & country == `l' & regname == 5
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("z-Score of Seasonal Rain: Weather + Weather{sup:2} + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 13, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(eltgreen%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(eltgreen%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v07_reg5_cty`l'", replace)
restore

/*
************************************************************************
**## 4e - weather and FEs and inputs
************************************************************************

preserve
	keep			if varname == 7 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("z-Score of Seasonal Rain: Weather + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(eltgreen%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(eltgreen%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v07_reg3_cty`l'", replace)
restore			


************************************************************************
**## 4f - weather squared and FEs and inputs
************************************************************************

preserve
	keep			if varname == 7 & country == `l' & regname == 6
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 6 + 2 + 2 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	34

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)120) xsize(10) ysize(6) ytitle("") ///
						title("z-Score of Seasonal Rain: Weather + Weather{sup:2} + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "CHIRPS" ///
						6 "CPC" 7 "MERRA-2" 8 "ARC2" 9 "ERA5" 10 "TAMSAT" ///
						11 "*{bf:Weather Product}*" 13 "{bf:HH bilinear}" ///
						14 "HH simple" 15 "EA bilinear" 16 "EA simple" ///
						17 "EA modified bilinear" 18 "EA modified simple" ///
						19 "Admin bilinear" 20 "Admin simple" 21 "EA zone" ///
						22 "Admin area" 23 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(eltgreen%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(eltgreen%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v07_reg6_cty`l'", replace)
restore
*/
	}
			
	
************************************************************************
**# 5 - combine rainfall graphs
************************************************************************
	
* define loop through levels of the data type variable	
	levelsof 	country, local(cty)
	foreach 	l of local cty {
		
* combine country graphs for linear models
	grc1leg2 		"$sfig/v01_reg1_cty`l'.gph" "$sfig/v01_reg2_cty`l'.gph" ///
						"$sfig/v10_reg1_cty`l'.gph" "$sfig/v10_reg2_cty`l'.gph", ///
						col(2) iscale(.5) pos(12) commonscheme
						
	graph export 	"$xfig\line_cty`l'_rf.pdf", as(pdf) replace
	
* combine country graphs for quadtratic models
	grc1leg2 		"$sfig/v01_reg4_cty`l'.gph" "$sfig/v01_reg5_cty`l'.gph" ///
						"$sfig/v10_reg4_cty`l'.gph" "$sfig/v10_reg5_cty`l'.gph", ///
						col(2) iscale(.5) pos(12) commonscheme
						
	graph export 	"$xfig\quad_cty`l'_rf.pdf", as(pdf) replace
	
* combine country graphs for z-score
	grc1leg2 		"$sfig/v07_reg1_cty`l'.gph" "$sfig/v07_reg2_cty`l'.gph" ///
						"$sfig/v07_reg4_cty`l'.gph" "$sfig/v07_reg5_cty`l'.gph", ///
						col(2) iscale(.5) pos(12) commonscheme
						
	graph export 	"$xfig\ztot_cty`l'_rf.pdf", as(pdf) replace
	}
	
	
************************************************************************
**# 6 - generate specification chart for mean temperature
************************************************************************
	
* define loop through levels of the data type variable	
	levelsof 	country, local(cty)
	foreach 	l of local cty {

	
************************************************************************
**## 6a - weather only
************************************************************************
	
preserve
	keep			if varname == 15 & country ==`l' & regname == 1
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Temperature: Weather")  ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(emerald%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(emerald%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v15_reg1_cty`l'", replace)
restore


************************************************************************
**## 6b - weather squared only
************************************************************************

preserve
	keep			if varname == 15 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Temperature: Weather + Weather{sup:2}") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(emerald%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(emerald%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v15_reg4_cty`l'", replace)
restore


************************************************************************
**## 6c - weather and FEs
************************************************************************

preserve
	keep			if varname == 15 & country == `l' & regname == 2
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Temperature: Weather + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(emerald%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(emerald%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v15_reg2_cty`l'", replace)
restore


************************************************************************
**## 6d - weather squared and FEs
************************************************************************

preserve
	keep			if varname == 15 & country == `l' & regname == 5
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Mean Daily Temperature: Weather + Weather{sup:2} + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(emerald%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(emerald%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v15_reg5_cty`l'", replace)
restore

/*
************************************************************************
**## 6e - weather and FEs and inputs
************************************************************************

preserve
	keep			if varname == 15 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("Mean Daily Temperature: Weather + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(emerald%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(emerald%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v15_reg3_cty`l'", replace)
restore			


************************************************************************
**## 6f - weather squared and FEs and inputs
************************************************************************

preserve
	keep			if varname == 15 & country == `l' & regname == 6
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("Mean Daily Temperature: Weather + Weather{sup:2} + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(emerald%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(emerald%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v15_reg6_cty`l'", replace)
restore
*/
	}
	
************************************************************************
**# 7 - generate specification chart for GDD
************************************************************************
	
* define loop through levels of the data type variable	
	levelsof 	country, local(cty)
	foreach 	l of local cty {

	
************************************************************************
**## 7a - weather only
************************************************************************
	
preserve
	keep			if varname == 19 & country == `l' & regname == 1
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("Growing Degree Days: Weather")  ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(erose%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(erose%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v19_reg1_cty`l'", replace)
restore


************************************************************************
**## 7b - weather squared only
************************************************************************

preserve
	keep			if varname == 19 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("Growing Degree Days: Weather + Weather{sup:2}") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(erose%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(erose%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v19_reg4_cty`l'", replace)
restore


************************************************************************
**## 7c - weather and FEs
************************************************************************

preserve
	keep			if varname == 19 & country == `l' & regname == 2
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("Growing Degree Days: Weather + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(erose%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(erose%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v19_reg2_cty`l'", replace)

	*	graph export 	"$sfig/v19_reg2_cty`l'.pdf", as(pdf) replace
restore


************************************************************************
**## 7d - weather squared and FEs
************************************************************************

preserve
	keep			if varname == 19 & country == `l' & regname == 5
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("Growing Degree Days: Weather + Weather{sup:2} + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(erose%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(erose%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v19_reg5_cty`l'", replace)
restore

/*
************************************************************************
**## 7e - weather and FEs and inputs
************************************************************************

preserve
	keep			if varname == 19 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("Growing Degree Days: Weather + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(erose%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(erose%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v19_reg3_cty`l'", replace)
restore			


************************************************************************
**## 7f - weather squared and FEs and inputs
************************************************************************

preserve
	keep			if varname == 19 & country == `l' & regname == 6
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("Growing Degree Days: Weather + Weather{sup:2} + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(erose%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(erose%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v19_reg6_cty`l'", replace)
restore
*/
	}

	
************************************************************************
**# 8 - generate specification chart for z-GDD
************************************************************************
	
* define loop through levels of the data type variable	
	levelsof 	country, local(cty)
	foreach 	l of local cty {

	
************************************************************************
**## 8a - weather only
************************************************************************
	
preserve
	keep			if varname == 21 & country == `l' & regname == 1
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("z-Score of GDD: Weather")  ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(cranberry%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(cranberry%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v21_reg1_cty`l'", replace)
restore


************************************************************************
**## 8b - weather squared only
************************************************************************

preserve
	keep			if varname == 21 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("z-Score of GDD: Weather + Weather{sup:2}") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(cranberry%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(cranberry%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v21_reg4_cty`l'", replace)
restore


************************************************************************
**## 8c - weather and FEs
************************************************************************

preserve
	keep			if varname == 21 & country == `l' & regname == 2
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("z-Score of GDD: Weather + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(cranberry%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(cranberry%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v21_reg2_cty`l'", replace)
restore


************************************************************************
**## 8d - weather squared and FEs
************************************************************************

preserve
	keep			if varname == 21 & country == `l' & regname == 5
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("z-Score of GDD: Weather + Weather{sup:2} + FE") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(cranberry%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(cranberry%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v21_reg5_cty`l'", replace)
restore

/*
************************************************************************
**## 8e - weather and FEs and inputs
************************************************************************

preserve
	keep			if varname == 21 & country == `l' & regname == 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("z-Score of GDD: Weather + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(cranberry%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(cranberry%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v21_reg3_cty`l'", replace)
restore			


************************************************************************
**## 8f - weather squared and FEs and inputs
************************************************************************

preserve
	keep			if varname == 21 & country == `l' & regname == 6
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	depvar
	gen 			k2 		= 	sat + 2 + 2
	gen 			k3 		= 	ext + 3 + 2 + 2 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k2		=	5 if k2 == 11
	replace			k2		=	6 if k2 == 12
	replace			k2		=	7 if k2 == 13
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Dep. Var."
	lab				var k2 "Weather Product"
	lab 			var k3 "Anon. Method"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	31

	twoway 			scatter k1 k2 k3 obs, xlab(0(6)60) xsize(10) ysize(6) ytitle("") ///
						title("z-Score of GDD: Weather + Weather{sup:2} + FE + Inputs") ylab(0(1)$gheight ) ///
						msize(vsmall vsmall vsmall) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Quantity" 2 "Value" 3 "*{bf:Dep. Var.}*" 5 "MERRA-2" ///
						6 "ERA5" 7 "CPC" 8 "*{bf:Weather Product}*" 10 "{bf:HH bilinear}" ///
						11 "HH simple" 12 "EA bilinear" 13 "EA simple" ///
						14 "EA modified bilinear" 15 "EA modified simple" ///
						16 "Admin bilinear" 17 "Admin simple" 18 "EA zone" ///
						19 "Admin area" 20 "*{bf:Anon. Method}*" 34 " ", ///
						angle(0) labsize(tiny) tstyle(notick)) || ///
						(scatter k3 obs if k3 == 10, ///
						msize(vsmall vsmall) mcolor(orange)) || ///
						(scatter b_ns obs, yaxis(2) mcolor(black%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(scatter b_sig obs, yaxis(2) mcolor(cranberry%75) ylab(, ///
						axis(2) labsize(vsmall) angle(0) ) yscale( ///
						range($from_y $bmax ) axis(2)) ) || ///
						(rbar ci_lo ci_up obs if b_sig == ., ///
						barwidth(.2) color(black%50) yaxis(2) ) || ///
						(rbar ci_lo ci_up obs if b_sig != ., ///
						barwidth(.2) color(cranberry%50) yaxis(2)  ///
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ), ///
						legend(order(5 6) cols(2) size(small) rowgap(.5) pos(12)) ///
						saving("$sfig/v21_reg6_cty`l'", replace)
restore
*/
	}
	
	
************************************************************************
**# 9 - combine graphs
************************************************************************
	
* define loop through levels of the data type variable	
	levelsof 	country, local(cty)
	foreach 	l of local cty {
		
* combine country graphs for linear models
	grc1leg2 		"$sfig/v15_reg1_cty`l'.gph" "$sfig/v15_reg2_cty`l'.gph" ///
						"$sfig/v19_reg1_cty`l'.gph" "$sfig/v19_reg2_cty`l'.gph", ///
						col(2) iscale(.5) pos(12) commonscheme
						
	graph export 	"$xfig\line_cty`l'_tp.pdf", as(pdf) replace
	
* combine country graphs for quadtratic models
	grc1leg2 		"$sfig/v15_reg4_cty`l'.gph" "$sfig/v15_reg5_cty`l'.gph" ///
						"$sfig/v19_reg4_cty`l'.gph" "$sfig/v19_reg5_cty`l'.gph", ///
						col(2) iscale(.5) pos(12) commonscheme
						
	graph export 	"$xfig\quad_cty`l'_tp.pdf", as(pdf) replace
	
* combine country graphs for z-score
	grc1leg2 		"$sfig/v21_reg1_cty`l'.gph" "$sfig/v21_reg2_cty`l'.gph" ///
						"$sfig/v21_reg4_cty`l'.gph" "$sfig/v21_reg5_cty`l'.gph", ///
						col(2) iscale(.5) pos(12) commonscheme
						
	graph export 	"$xfig\zgdd_cty`l'_tp.pdf", as(pdf) replace
	}

************************************************************************
**# 10 - end matter
************************************************************************

* close the log
	log	close

/* END */				
	