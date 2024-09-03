* Project: WB Weather - Privacy Paper
* Created on: September 2020
* Created by: alj
* Edited by: jdm
* Last edit: 16 May 2022
* Stata v.17.0 

* does
	* reads in lsms data set
	* makes visualziations of summary statistics  

* assumes
	* you have results file 
	* customsave.ado
	* grc1leg2.ado
	* palettes
	* colrspace

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root 	= 	"$data/regression_data"
	global	stab 	= 	"$data/results_data/tables"
	global	xtab 	= 	"$data/output/privacy_paper/tables"
	global	sfig	= 	"$data/results_data/figures"	
	global 	xfig    =   "$data/output/privacy_paper/figures"
	global	logout 	= 	"$data/results_data/logs"

* open log	
	cap log close
	log 	using 		"$logout/privacy_sum_vis", append

		
* **********************************************************************
* 1 - load and process data
* **********************************************************************

* load data 
	use 			"$root/lsms_panel", clear

* replace missing values as zeros for rainfall variables 1-9
	forval j = 1/9 {
	    forval i = 1/6 {
		    forval k = 0/9 {
				qui: replace		v0`j'_rf`i'_x`k' = 0 if v0`j'_rf`i'_x`k' == .    
			}
		}
	}

* replace missing values as zeros for rainfall variables 10-14
	forval j = 10/14 {
	    forval i = 1/6 {
		    forval k = 0/9 {
				qui: replace		v`j'_rf`i'_x`k' = 0 if v`j'_rf`i'_x`k' == .    
			}
		}
	}

* replace missing values as zeros for temperature variables 15-22
	forval j = 15/22 {
	    forval i = 1/3 {
		    forval k = 0/9 {
				qui: replace		v`j'_tp`i'_x`k' = 0 if v`j'_tp`i'_x`k' == .    
			}
		}
	}


* **********************************************************************
* 2 - generate mean daily rainfall distribution graphs by extraction
* **********************************************************************

	colorpalette	economist

* total seasonal rainfall - CHIRPS
	twoway	(kdensity v01_rf1_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v01_rf1_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v01_rf1_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v01_rf1_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v01_rf1_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v01_rf1_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v01_rf1_x7, color(maroon) lpattern(._) ) ///
			(kdensity v01_rf1_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v01_rf1_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v01_rf1_x0, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(0(5)15)) title("CHIRPS") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(0(5)15, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(1 "{bf:{bf:HH bilinear}}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v01_rf1_density", replace)

* total seasonal rainfall - CPC
	twoway	(kdensity v01_rf2_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v01_rf2_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v01_rf2_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v01_rf2_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v01_rf2_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v01_rf2_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v01_rf2_x7, color(maroon) lpattern(._) ) ///
			(kdensity v01_rf2_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v01_rf2_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v01_rf2_x0, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(0(5)15)) title("CPC") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(0(5)15, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(1 "{bf:HH bilinear}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v01_rf2_density", replace)

* total seasonal rainfall - MERRA-2
	twoway	(kdensity v01_rf3_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v01_rf3_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v01_rf3_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v01_rf3_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v01_rf3_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v01_rf3_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v01_rf3_x7, color(maroon) lpattern(._) ) ///
			(kdensity v01_rf3_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v01_rf3_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v01_rf3_x0, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(0(5)15)) title("MERRA-2") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(0(5)15, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(1 "{bf:HH bilinear}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v01_rf3_density", replace)
			
* total seasonal rainfall - ARC2
	twoway	(kdensity v01_rf4_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v01_rf4_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v01_rf4_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v01_rf4_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v01_rf4_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v01_rf4_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v01_rf4_x7, color(maroon) lpattern(._) ) ///
			(kdensity v01_rf4_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v01_rf4_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v01_rf4_x0, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(0(5)15)) title("ARC2") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(0(5)15, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(1 "{bf:HH bilinear}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v01_rf4_density", replace)
			
* total seasonal rainfall - ERA5
	twoway	(kdensity v01_rf5_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v01_rf5_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v01_rf5_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v01_rf5_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v01_rf5_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v01_rf5_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v01_rf5_x7, color(maroon) lpattern(._) ) ///
			(kdensity v01_rf5_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v01_rf5_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v01_rf5_x0, color(cranberry) lpattern(solid) ///
			xtitle("Total Season Rainfall (mm)") title("ERA5") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(1 "{bf:HH bilinear}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v01_rf5_density", replace)
			
* total seasonal rainfall - TAMSAT
	twoway	(kdensity v01_rf6_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v01_rf6_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v01_rf6_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v01_rf6_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v01_rf6_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v01_rf6_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v01_rf6_x7, color(maroon) lpattern(._) ) ///
			(kdensity v01_rf6_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v01_rf6_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v01_rf6_x0, color(cranberry) lpattern(solid) ///
			xtitle("Total Season Rainfall (mm)") xscale(r(0(5)15)) title("TAMSAT") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(0(5)15, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(1 "{bf:HH bilinear}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v01_rf6_density", replace)
			
	grc1leg2 		"$sfig/v01_rf1_density.gph" "$sfig/v01_rf2_density.gph" ///
						"$sfig/v01_rf3_density.gph" "$sfig/v01_rf4_density.gph"   ///
						"$sfig/v01_rf5_density.gph" "$sfig/v01_rf6_density.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\v01_density_x.pdf", replace

	
* **********************************************************************
* 3 - generate mean temperature distribution graphs by extraction
* **********************************************************************

* mean temp - MERRA-2
	twoway	(kdensity v15_tp1_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v15_tp1_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v15_tp1_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v15_tp1_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v15_tp1_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v15_tp1_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v15_tp1_x7, color(maroon) lpattern(._) ) ///
			(kdensity v15_tp1_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v15_tp1_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v15_tp1_x0, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(0(5)35)) title("MERRA-2") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(0(5)35, nogrid labsize(small))), ///
			legend(pos(4) col(1) size(vsmall) label(1 "{bf:HH bilinear}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v15_tp1_density", replace)
			
* mean temp - ERA5
	twoway	(kdensity v15_tp2_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v15_tp2_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v15_tp2_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v15_tp2_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v15_tp2_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v15_tp2_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v15_tp2_x7, color(maroon) lpattern(._) ) ///
			(kdensity v15_tp2_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v15_tp2_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v15_tp2_x0, color(cranberry) lpattern(solid) ///
			xtitle("Mean Seasonal Temperature (C)") xscale(r(0(5)35)) title("ERA5") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(0(5)35, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(1 "{bf:HH bilinear}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v15_tp2_density", replace)

* mean temp - CPC
	twoway	(kdensity v15_tp3_x1, color(edkblue) lpattern(dash) ) ///
			(kdensity v15_tp3_x2, color(eltblue) lpattern(dot) ) ///
			(kdensity v15_tp3_x3, color(emerald) lpattern(dash_dot) ) ///
			(kdensity v15_tp3_x4, color(erose) lpattern(shortdash) ) ///
			(kdensity v15_tp3_x5, color(eltgreen) lpattern(shortdash_dot) ) ///
			(kdensity v15_tp3_x6, color(stone) lpattern(longdash) ) ///
			(kdensity v15_tp3_x7, color(maroon) lpattern(._) ) ///
			(kdensity v15_tp3_x8, color(brown) lpattern(..--_#) ) ///
			(kdensity v15_tp3_x9, color(lavender) lpattern(---...) ) ///
			(kdensity v15_tp3_x0, color(cranberry) lpattern(solid) ///
			xtitle("Mean Seasonal Temperature (C)") xscale(r(0(5)35)) title("CPC") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(0(5)35, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(1 "{bf:HH bilinear}") label(2 "HH simple") ///
			label(3 "EA bilinear") label(4 "EA simple") label(5 "EA modified bilinear") ///
			label(6 "EA modified simple") label(7 "Admin bilinear") ///
			label(8 "Admin simple") label(9 "EA zone") ///
			label(10 "Admin area")) saving("$sfig/v15_tp3_density", replace)
			
	grc1leg2 		"$sfig/v15_tp1_density.gph" "$sfig/v15_tp2_density.gph" ///
						"$sfig/v15_tp3_density.gph" , ring(0) pos(4) holes(4) ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\v15_density_x.pdf", replace
	

* **********************************************************************
* 4 - generate days without rain line graphs by extraction
* **********************************************************************

* days without rain - CHIRPS
	twoway	(fpfitci v10_rf1_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v10_rf1_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v10_rf1_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v10_rf1_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v10_rf1_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v10_rf1_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v10_rf1_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v10_rf1_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v10_rf1_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v10_rf1_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(2008(1)2015)) title("CHIRPS") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v10_rf1_density", replace)
			
* days without rain - CPC
	twoway	(fpfitci v10_rf2_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v10_rf2_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v10_rf2_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v10_rf2_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v10_rf2_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v10_rf2_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v10_rf2_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v10_rf2_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v10_rf2_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v10_rf2_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(2008(1)2015)) title("CPC") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v10_rf2_density", replace)	
			
* days without rain - MERRA-2
	twoway	(fpfitci v10_rf3_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v10_rf3_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v10_rf3_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v10_rf3_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v10_rf3_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v10_rf3_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v10_rf3_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v10_rf3_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v10_rf3_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v10_rf3_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(2008(1)2015)) title("MERRA-2") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v10_rf3_density", replace)
			
* days without rain - ARC2
	twoway	(fpfitci v10_rf4_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v10_rf4_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v10_rf4_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v10_rf4_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v10_rf4_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v10_rf4_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v10_rf4_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v10_rf4_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v10_rf4_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v10_rf4_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(2008(1)2015)) title("ARC2") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v10_rf4_density", replace)	
			
* days without rain - ERA5
	twoway	(fpfitci v10_rf5_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v10_rf5_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v10_rf5_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v10_rf5_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v10_rf5_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v10_rf5_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v10_rf5_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v10_rf5_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v10_rf5_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v10_rf5_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("Year") xscale(r(2008(1)2015)) title("ERA5") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v10_rf5_density", replace)
			
* days without rain - TAMSAT
	twoway	(fpfitci v10_rf6_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v10_rf6_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v10_rf6_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v10_rf6_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v10_rf6_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v10_rf6_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v10_rf6_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v10_rf6_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v10_rf6_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v10_rf6_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("Year") xscale(r(2008(1)2015)) title("TAMSAT") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v10_rf6_density", replace)			
		
	grc1leg2 		"$sfig/v10_rf1_density.gph" "$sfig/v10_rf2_density.gph" ///
						"$sfig/v10_rf3_density.gph" "$sfig/v10_rf4_density.gph"   ///
						"$sfig/v10_rf5_density.gph" "$sfig/v10_rf6_density.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\v10_density_x.pdf", replace
			

* **********************************************************************
* 5 - generate GDD line graphs by extraction
* **********************************************************************

* growing degree days - MERRA-2
	twoway	(fpfitci v19_tp1_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v19_tp1_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v19_tp1_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v19_tp1_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v19_tp1_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v19_tp1_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v19_tp1_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v19_tp1_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v19_tp1_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v19_tp1_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("") xscale(r(2008(1)2015)) title("MERRA-2") ///
			ytitle("Growing Degree Days") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(4) col(1) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v19_tp1_density", replace)
			
* growing degree days - ERA5
	twoway	(fpfitci v19_tp2_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v19_tp2_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v19_tp2_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v19_tp2_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v19_tp2_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v19_tp2_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v19_tp2_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v19_tp2_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v19_tp2_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v19_tp2_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("Year") xscale(r(2008(1)2015)) title("ERA5") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v19_tp2_density", replace)

* growing degree days - CPC
	twoway	(fpfitci v19_tp3_x1 year, color(edkblue) lpattern(dash) ) ///
			(fpfitci v19_tp3_x2 year, color(eltblue) lpattern(dot) ) ///
			(fpfitci v19_tp3_x3 year, color(emerald) lpattern(dash_dot) ) ///
			(fpfitci v19_tp3_x4 year, color(erose) lpattern(shortdash) ) ///
			(fpfitci v19_tp3_x5 year, color(eltgreen) lpattern(shortdash_dot) ) ///
			(fpfitci v19_tp3_x6 year, color(stone) lpattern(longdash) ) ///
			(fpfitci v19_tp3_x7 year, color(maroon) lpattern(._) ) ///
			(fpfitci v19_tp3_x8 year, color(brown) lpattern(..--_#) ) ///
			(fpfitci v19_tp3_x9 year, color(lavender) lpattern(---...) ) ///
			(fpfitci v19_tp3_x0 year, color(cranberry) lpattern(solid) ///
			xtitle("Year") xscale(r(2008(1)2015)) title("CPC") ///
			ytitle("Growing Degree Days") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(5) size(vsmall) label(2 "{bf:HH bilinear}") label(4 "HH simple") ///
			label(6 "EA bilinear") label(8 "EA simple") label(10 "EA modified bilinear") ///
			label(12 "EA modified simple") label(14 "Admin bilinear") ///
			label(16 "Admin simple") label(18 "EA zone") ///
			label(20 "Admin area") order(2 4 6 8 10 12 14 16 18 20)) ///
			saving("$sfig/v19_tp3_density", replace)
			
	grc1leg2 		"$sfig/v19_tp1_density.gph" "$sfig/v19_tp2_density.gph" ///
						"$sfig/v19_tp3_density.gph" , ring(0) pos(4) holes(4) ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\v19_density_x.pdf", replace
	
			
* **********************************************************************
* 7 - end matter
* **********************************************************************

* close the log
	log	close

/* END */