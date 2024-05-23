* Project: WB Weather - mismeasure paper
* Created on: 4 April 2023
* Created by: jdm
* Edited by: alj
* Last edit: 25 Jan 2024
* Stata v.18.0 

* does
	* reads in results data set
	* makes visualziations of results 

* assumes
	* you have results file 
	* grc1leg2.ado

* TO DO:
	* experimenting in section 2
	* tidy, clean, etc. 
	
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
	log 	using 	"$logout/mismeasure_coeff_vis", append


************************************************************************
**# 1 - generate (non)-significant indicators
************************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear
	
* keep HH Bilinear - true hh coordinates 
	keep			if ext == 1
	
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
**# 2 - generate specification chart varying over rainfall measure
************************************************************************

* experimenting with specification chart 
 
levelsof varname, local(varrain)
foreach i of local varrain {

*this is a test

keep if `i' < 15
*** generating blank graphs for temperature - need to fix 

preserve
	keep			if varname == `i' & regname == 3
	sort 			country beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	country
	gen 			k2 		= 	depvar + 7 + 2
	gen 			k3 		= 	sat + 2 + 2 + 7 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Country"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	27

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)72) xsize(10) ysize(6) xtitle("") ytitle("") ///
						ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Ethiopia" 2 "Malawi" 4 "Niger" 5 "Nigeria" 6 "Tanzania" ///
						7 "Uganda " 8 "*{bf: Country}*" 10 "Quantity" 11 "Value" 12 "*{bf:Dep. Var.}*" ///
						14 "CHIRPS" 15 "CPC" 16 "MERRA-2" 17 "ARC2" 18 "ERA5" ///
						19 "TAMSAT" 20 "*{bf:Weather Product}*" 27 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						yline(0, lcolor(maroon) axis(2) lstyle(solid) ) ///
						xline(12.5, lcolor(black) lstyle(solid)) ///
						xline(24.5, lcolor(black) lstyle(solid)) ///
						xline(36.5, lcolor(black) lstyle(solid)) ///
						xline(48.5, lcolor(black) lstyle(solid)) ///
						xline(60.5, lcolor(black) lstyle(solid)) ), ///
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 
						*** need to cut gap between Niger and Malawi 
						*** and why not alphabetical 
				
graph export 	"$xfig\v_`i'_reg3.pdf", as(pdf) replace
restore
}
		
	
************************************************************************
**# 3 - generate specification chart for mean rainfall
************************************************************************		
	
************************************************************************
**## 3a - ethiopia
************************************************************************
	
preserve
	keep			if varname == 1 & country == 1 & regname < 4
	sort 			regname sat beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Ethiopia")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v01_cty1", replace)
				
*graph export 	"$xfig\v01_cty1.pdf", as(pdf) replace
restore


************************************************************************
**## 3b - malawi
************************************************************************
	
preserve
	keep			if varname == 1 & country == 2 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Malawi")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v01_cty2", replace)
				
	graph export 	"$xfig\v01_cty2.pdf", as(pdf) replace
restore


************************************************************************
**## 3c - Niger
************************************************************************
	
preserve
	keep			if varname == 1 & country == 4 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Niger")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v01_cty3", replace)
				
	graph export 	"$xfig\v01_cty4.pdf", as(pdf) replace
restore


************************************************************************
**## 3d - Nigeria
************************************************************************

	
preserve
	keep			if varname == 1 & country == 5 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Nigeria")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v01_cty5", replace)
				
	graph export 	"$xfig\v01_cty5.pdf", as(pdf) replace
restore


************************************************************************
**## 3e - Tanzania
************************************************************************

preserve
	keep			if varname == 1 & country == 6 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Tanzania")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v01_cty6", replace)
				
	graph export 	"$xfig\v01_cty6.pdf", as(pdf) replace
restore


************************************************************************
**## 3f - Uganda
************************************************************************

	
preserve
	keep			if varname == 1 & country == 7 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Uganda")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v01_cty7", replace)
				
	graph export 	"$xfig\v01_cty7.pdf", as(pdf) replace
restore

	
************************************************************************
**# 4 - generate specification chart for z-score total rain
************************************************************************

	
************************************************************************
**## 4a - ethiopia
************************************************************************
	
preserve
	keep			if varname == 7 & country == 1 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Ethiopia")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v07_cty1", replace)
				
	graph export 	"$xfig\v07_cty1.pdf", as(pdf) replace
restore


************************************************************************
**## 4b - malawi
************************************************************************
	
preserve
	keep			if varname == 7 & country == 2 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Malawi")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v07_cty2", replace)
				
	graph export 	"$xfig\v07_cty2.pdf", as(pdf) replace
restore


************************************************************************
**## 4c - Niger
************************************************************************
	
preserve
	keep			if varname == 7 & country == 4 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Niger")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v07_cty3", replace)
				
	graph export 	"$xfig\v07_cty4.pdf", as(pdf) replace
restore


************************************************************************
**## 4d - Nigeria
************************************************************************

	
preserve
	keep			if varname == 7 & country == 5 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Nigeria")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v07_cty5", replace)
				
	graph export 	"$xfig\v07_cty5.pdf", as(pdf) replace
restore


************************************************************************
**## 4e - Tanzania
************************************************************************

preserve
	keep			if varname == 7 & country == 6 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Tanzania")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v07_cty6", replace)
				
	graph export 	"$xfig\v07_cty6.pdf", as(pdf) replace
restore


************************************************************************
**## 4f - Uganda
************************************************************************

	
preserve
	keep			if varname == 7 & country == 7 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(4)36) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Uganda")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "CHIRPS" 11 "CPC" 12 "MERRA-2" 13 "ARC2" 14 "ERA5" ///
						15 "TAMSAT" 16 "*{bf:Weather Product}*" 23 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v07_cty7", replace)
				
	graph export 	"$xfig\v07_cty7.pdf", as(pdf) replace
restore

	
************************************************************************
**# 5 - generate specification chart for GDD
************************************************************************

	
************************************************************************
**## 5a - ethiopia
************************************************************************
	
preserve
	keep			if varname == 19 & country == 1 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Ethiopia")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v19_cty1", replace)
				
	graph export 	"$xfig\v19_cty1.pdf", as(pdf) replace
restore


************************************************************************
**## 5b - malawi
************************************************************************
	
preserve
	keep			if varname == 19 & country == 2 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Malawi")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v19_cty2", replace)
				
	graph export 	"$xfig\v19_cty2.pdf", as(pdf) replace
restore


************************************************************************
**## 5c - Niger
************************************************************************
	
preserve
	keep			if varname == 19 & country == 4 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Niger")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v19_cty3", replace)
				
	graph export 	"$xfig\v19_cty4.pdf", as(pdf) replace
restore


************************************************************************
**## 5d - Nigeria
************************************************************************

	
preserve
	keep			if varname == 19 & country == 5 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Nigeria")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v19_cty5", replace)
				
	graph export 	"$xfig\v19_cty5.pdf", as(pdf) replace
restore


************************************************************************
**## 5e - Tanzania
************************************************************************

preserve
	keep			if varname == 19 & country == 6 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Tanzania")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v19_cty6", replace)
				
	graph export 	"$xfig\v19_cty6.pdf", as(pdf) replace
restore


************************************************************************
**## 5f - Uganda
************************************************************************

	
preserve
	keep			if varname == 19 & country == 7 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Uganda")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v19_cty7", replace)
				
	graph export 	"$xfig\v19_cty7.pdf", as(pdf) replace
restore
	
************************************************************************
**# 6 - generate specification chart for z-score GDD
************************************************************************

	
************************************************************************
**## 6a - ethiopia
************************************************************************
	
preserve
	keep			if varname == 21 & country == 1 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Ethiopia")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v21_cty1", replace)
				
	graph export 	"$xfig\v21_cty1.pdf", as(pdf) replace
restore


************************************************************************
**## 6b - malawi
************************************************************************
	
preserve
	keep			if varname == 21 & country == 2 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Malawi")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v21_cty2", replace)
				
	graph export 	"$xfig\v21_cty2.pdf", as(pdf) replace
restore


************************************************************************
**## 6c - Niger
************************************************************************
	
preserve
	keep			if varname == 21 & country == 4 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Niger")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v21_cty3", replace)
				
	graph export 	"$xfig\v21_cty4.pdf", as(pdf) replace
restore


************************************************************************
**## 6d - Nigeria
************************************************************************

	
preserve
	keep			if varname == 21 & country == 5 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Nigeria")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v21_cty5", replace)
				
	graph export 	"$xfig\v21_cty5.pdf", as(pdf) replace
restore


************************************************************************
**## 6e - Tanzania
************************************************************************

preserve
	keep			if varname == 21 & country == 6 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Tanzania")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v21_cty6", replace)
				
	graph export 	"$xfig\v21_cty6.pdf", as(pdf) replace
restore


************************************************************************
**## 6f - Uganda
************************************************************************

	
preserve
	keep			if varname == 21 & country == 7 & regname < 4
	sort 			beta
	gen 			obs = _n

* stack values of the specification indicators
	gen 			k1 		= 	regname
	gen 			k2 		= 	depvar + 3 + 2
	gen 			k3 		= 	sat + 2 + 2 + 3 + 2
	
* subtract values of off k2 because of varname numbering
	replace			k3		=	10 if k3 == 16
	replace			k3		=	11 if k3 == 17
	replace			k3		=	12 if k3 == 18
	
* label new variables	
	lab				var obs "Specification # - sorted by effect size"

	lab 			var k1 "Model"
	lab				var k2 "Dep. Var."
	lab 			var k3 "Weather Product"

	qui sum			ci_up
	global			bmax = r(max)
	
	qui sum			ci_lo
	global			bmin = r(min)
	
	global			brange	=	$bmax - $bmin
	global			from_y	=	$bmin - 2.5*$brange
	global			gheight	=	23

	twoway 			scatter k1 k2 k3 obs, xlab(0(2)18) xsize(10) ysize(6) xtitle("") ytitle("") ///
						title("Uganda")  ylab(0(1)$gheight ) ///
						msize(small small small) mcolor(gs10 gs10 gs10) ylabel( ///
						1 "Weather" 2 "Weather + FE" 3 "Weather + FE + Inputs" ///
						4 "*{bf: Model}*" 6 "Quantity" 7 "Value" 8 "*{bf:Dep. Var.}*" ///
						10 "MERRA-2" 11 "ERA5" 12 "CPC" 13 "*{bf:Weather Product}*" 20 " ", ///
						angle(0) labsize(vsmall) tstyle(notick)) || ///
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
						legend(order(4 5) cols(2) size(small) rowgap(.5) pos(12)) 	///
						saving("$sfig/v21_cty7", replace)
				
	graph export 	"$xfig\v21_cty7.pdf", as(pdf) replace
restore
	

************************************************************************
**# 7 - end matter
************************************************************************

* close the log
	log	close

/* END */				
	