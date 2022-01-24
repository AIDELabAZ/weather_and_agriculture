* Project: WB Weather
* Created on: September 2020
* Created by: alj
* Edited by: jdm
* Last edit: 28 September 2021 
* Stata v.17.0 

* does
	* reads in lsms data set
	* makes visualziations of summary statistics  

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
	global	root 	= 	"$data/regression_data"
	global	stab 	= 	"$data/results_data/tables"
	global	xtab 	= 	"$data/output/paper/tables"
	global	sfig	= 	"$data/results_data/figures"	
	global 	xfig    =   "$data/output/paper/figures"
	global	logout 	= 	"$data/results_data/logs"

* open log	
	cap log close
	log 	using 		"$logout/summaryvis", append

		
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
* 2 - generate summary variables
* **********************************************************************

* generate averages across extractions for rainfall variables 1-9
	forval j = 1/9 {
	    forval i = 1/6 {
				egen 		v0`j'_rf`i' = rowmean(v0`j'_rf`i'_x0 ///
								v0`j'_rf`i'_x1 v0`j'_rf`i'_x2 v0`j'_rf`i'_x3 ///
								v0`j'_rf`i'_x4 v0`j'_rf`i'_x5 v0`j'_rf`i'_x6 ///
								v0`j'_rf`i'_x7 v0`j'_rf`i'_x8 v0`j'_rf`i'_x9)  
		}
	}
	
* generate averages across extractions for rainfall variables 10-14
	forval j = 10/14 {
	    forval i = 1/6 {
				egen 		v`j'_rf`i' = rowmean(v`j'_rf`i'_x0 ///
								v`j'_rf`i'_x1 v`j'_rf`i'_x2 v`j'_rf`i'_x3 ///
								v`j'_rf`i'_x4 v`j'_rf`i'_x5 v`j'_rf`i'_x6 ///
								v`j'_rf`i'_x7 v`j'_rf`i'_x8 v`j'_rf`i'_x9)  
		}
	}

* generate averages across extractions for temperature variables 15-22
	forval j = 15/22 {
	    forval i = 1/3 {
				egen 		v`j'_tp`i' = rowmean(v`j'_tp`i'_x0 ///
								v`j'_tp`i'_x1 v`j'_tp`i'_x2 v`j'_tp`i'_x3 ///
								v`j'_tp`i'_x4 v`j'_tp`i'_x5 v`j'_tp`i'_x6 ///
								v`j'_tp`i'_x7 v`j'_tp`i'_x8 v`j'_tp`i'_x9)  
		}
	}		

* **********************************************************************
* 3 - generate total season distribution graphs by aez
* **********************************************************************

* total season rainfall - Tropic-warm/semi-arid	
	twoway  (kdensity v05_rf1 if aez == 312, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if aez == 312, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if aez == 312, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if aez == 312, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if aez == 312, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if aez == 312, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(500)2000)) title("Tropic-warm/semi-arid (n = 9,095)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(2 "CPC") ///
			label(3 "MERRA-2") label(4 "ARC2") label(5 "ERA5") ///
			label(6 "TAMSAT")) saving("$sfig/twsa_density_rf", replace)
			
	graph export 	"$sfig\twsa_density_rf.png", width(1400) replace

* total season rainfall - Tropic-warm/sub-humid		
	twoway  (kdensity v05_rf1 if aez == 313, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if aez == 313, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if aez == 313, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if aez == 313, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if aez == 313, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if aez == 313, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(1000)4000)) title("Tropic-warm/sub-humid (n = 9,009)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(2 "CPC") ///
			label(3 "MERRA-2") label(4 "ARC2") label(5 "ERA5") ///
			label(6 "TAMSAT")) saving("$sfig/twsh_density_rf", replace)
			
	graph export 	"$sfig\twsh_density_rf.png", width(1400) replace

* total season rainfall - Tropic-warm/humid		
	twoway  (kdensity v05_rf1 if aez == 314, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if aez == 314, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if aez == 314, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if aez == 314, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if aez == 314, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if aez == 314, color(ananas%30) recast(area) ///
			xtitle("Total Season Rainfall (mm)") xscale(r(0(1000)4000)) ///
			title("Tropic-warm/humid (n = 3,280)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(2 "CPC") ///
			label(3 "MERRA-2") label(4 "ARC2") label(5 "ERA5") ///
			label(6 "TAMSAT")) saving("$sfig/twh_density_rf", replace)
			
	graph export 	"$sfig\twh_density_rf.png", width(1400) replace

* total season rainfall - Tropic-cool/semi-arid	
	twoway  (kdensity v05_rf1 if aez == 322, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if aez == 322, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if aez == 322, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if aez == 322, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if aez == 322, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if aez == 322, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(500)2500)) title("Tropic-cool/semi-arid (n = 2,840)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(2 "CPC") ///
			label(3 "MERRA-2") label(4 "ARC2") label(5 "ERA5") ///
			label(6 "TAMSAT")) saving("$sfig/tcsa_density_rf", replace)
			
	graph export 	"$sfig\tcsa_density_rf.png", width(1400) replace

* total season rainfall - Tropic-cool/sub-humid		
	twoway  (kdensity v05_rf1 if aez == 323, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if aez == 323, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if aez == 323, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if aez == 323, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if aez == 323, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if aez == 323, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(1000)7000)) title("Tropic-cool/sub-humid (n = 5,886)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(2 "CPC") ///
			label(3 "MERRA-2") label(4 "ARC2") label(5 "ERA5") ///
			label(6 "TAMSAT")) saving("$sfig/tcsh_density_rf", replace)
			
	graph export 	"$sfig\tcsh_density_rf.png", width(1400) replace

* total season rainfall - Tropic-cool/humid		
	twoway  (kdensity v05_rf1 if aez == 324, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if aez == 324, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if aez == 324, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if aez == 324, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if aez == 324, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if aez == 324, color(ananas%30) recast(area) ///
			xtitle("Total Season Rainfall (mm)") xscale(r(0(1000)4000)) ///
			title("Tropic-cool/humid (n = 2,960)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(2 "CPC") ///
			label(3 "MERRA-2") label(4 "ARC2") label(5 "ERA5") ///
			label(6 "TAMSAT")) saving("$sfig/tch_density_rf", replace)	
			
	graph export 	"$sfig\tch_density_rf.png", width(1400) replace		
			
	grc1leg2 		"$sfig/twsa_density_rf.gph" "$sfig/tcsa_density_rf.gph" ///
						"$sfig/twsh_density_rf.gph" "$sfig/tcsh_density_rf.gph"   ///
						"$sfig/twh_density_rf.gph" "$sfig/tch_density_rf.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\density_aez_rf.pdf", replace

	
* **********************************************************************
* 4 - generate mean temperature distribution graphs
* **********************************************************************

* mean temp - Tropic-warm/semi-arid
	twoway	(kdensity v15_tp1 if aez == 312, color(gray%30) recast(area)) ///
			(kdensity v15_tp2 if aez == 312, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp3 if aez == 312, color(sea%30) recast(area) ///
			xtitle("") xscale(r(20(5)32)) title("Tropic-warm/semi-arid (n = 9,095)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(2 "ERA5") ///
			label(3 "CPC")) saving("$sfig/twsa_density_tp", replace)
			
	graph export 	"$sfig\twsa_density_tp.png", width(1400) replace		

* mean temp - Tropic-warm/sub-humid
	twoway	(kdensity v15_tp1 if aez == 313, color(gray%30) recast(area)) ///
			(kdensity v15_tp2 if aez == 313, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp3 if aez == 313, color(sea%30) recast(area) ///
			xtitle("") xscale(r(15(5)30)) title("Tropic-warm/sub-humid (n = 9,009)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(2 "ERA5") ///
			label(3 "CPC")) saving("$sfig/twsh_density_tp", replace)
			
	graph export 	"$sfig\twsh_density_tp.png", width(1400) replace		

* mean temp - Tropic-warm/humid
	twoway	(kdensity v15_tp1 if aez == 314, color(gray%30) recast(area)) ///
			(kdensity v15_tp2 if aez == 314, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp3 if aez == 314, color(sea%30) recast(area) ///
			xtitle("Mean Seasonal Temperature (C)") xscale(r(20(5)30)) ///
			title("Tropic-warm/humid (n = 3,280)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(2 "ERA5") ///
			label(3 "CPC")) saving("$sfig/twh_density_tp", replace)	
			
	graph export 	"$sfig\twh_density_tp.png", width(1400) replace			

* mean temp - Tropic-cool/semi-arid
	twoway	(kdensity v15_tp1 if aez == 322, color(gray%30) recast(area)) ///
			(kdensity v15_tp2 if aez == 322, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp3 if aez == 322, color(sea%30) recast(area) ///
			xtitle("") xscale(r(15(5)30)) title("Tropic-cool/semi-arid (n = 2,840)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(2 "ERA5") ///
			label(3 "CPC")) saving("$sfig/tcsa_density_tp", replace)
			
	graph export 	"$sfig\tcsa_density_tp.png", width(1400) replace		

* mean temp - Tropic-cool/sub-humid
	twoway	(kdensity v15_tp1 if aez == 323, color(gray%30) recast(area)) ///
			(kdensity v15_tp2 if aez == 323, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp3 if aez == 323, color(sea%30) recast(area) ///
			xtitle("") xscale(r(10(5)30)) title("Tropic-cool/sub-humid (n = 5,886)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(2 "ERA5") ///
			label(3 "CPC")) saving("$sfig/tcsh_density_tp", replace)
			
	graph export 	"$sfig\tcsh_density_tp.png", width(1400) replace		

* mean temp - Tropic-cool/humid
	twoway	(kdensity v15_tp1 if aez == 324, color(gray%30) recast(area)) ///
			(kdensity v15_tp2 if aez == 324, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp3 if aez == 324, color(sea%30) recast(area) ///
			xtitle("Mean Seasonal Temperature (C)") xscale(r(16(2)26)) ///
			title("Tropic-cool/humid (n = 2,960)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(2 "ERA5") ///
			label(3 "CPC")) saving("$sfig/tch_density_tp", replace)	
			
	graph export 	"$sfig\tch_density_tp.png", width(1400) replace					
		
		
	grc1leg2 		"$sfig/twsa_density_tp.gph" "$sfig/tcsa_density_tp.gph" ///
						"$sfig/twsh_density_tp.gph" "$sfig/tcsh_density_tp.gph" ///
						"$sfig/twh_density_tp.gph" "$sfig/tch_density_tp.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\density_aez_tp.pdf", replace
	

* **********************************************************************
* 5 - generate days without rain line graphs by aez
* **********************************************************************

* days without rain - Tropic-warm/semi-arid	
	twoway  (fpfitci v10_rf1 year if aez == 312, color(gray%30) ) ///
			(fpfitci v10_rf2 year if aez == 312, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if aez == 312, color(sea%30) ) ///
			(fpfitci v10_rf4 year if aez == 312, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if aez == 312, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if aez == 312, color(ananas%30)  ///
			xtitle("") xscale(r(2008(1)2015)) title("Tropic-warm/semi-arid (n = 9,095)") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(3 "CPC") ///
			label(5 "MERRA-2") label(7 "ARC2") label(9 "ERA5") ///
			label(11 "TAMSAT") order(1 3 5 7 9 11)) saving("$sfig/twsa_norain_rf", replace)

* days without rain - Tropic-warm/sub-humid	
	twoway  (fpfitci v10_rf1 year if aez == 313, color(gray%30) ) ///
			(fpfitci v10_rf2 year if aez == 313, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if aez == 313, color(sea%30) ) ///
			(fpfitci v10_rf4 year if aez == 313, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if aez == 313, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if aez == 313, color(ananas%30)  ///
			xtitle("") xscale(r(2008(1)2015)) title("Tropic-warm/sub-humid (n = 9,009)") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(3 "CPC") ///
			label(5 "MERRA-2") label(7 "ARC2") label(9 "ERA5") ///
			label(11 "TAMSAT") order(1 3 5 7 9 11)) saving("$sfig/twsh_norain_rf", replace)
			
* days without rain - Tropic-warm/humid	
	twoway  (fpfitci v10_rf1 year if aez == 314, color(gray%30) ) ///
			(fpfitci v10_rf2 year if aez == 314, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if aez == 314, color(sea%30) ) ///
			(fpfitci v10_rf4 year if aez == 314, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if aez == 314, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if aez == 314, color(ananas%30)  ///
			xtitle("Year") xscale(r(2008(1)2015)) title("Tropic-warm/humid (n = 3,280)") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(3 "CPC") ///
			label(5 "MERRA-2") label(7 "ARC2") label(9 "ERA5") ///
			label(11 "TAMSAT") order(1 3 5 7 9 11)) saving("$sfig/twh_norain_rf", replace)

* days without rain - Tropic-cool/semi-arid	
	twoway  (fpfitci v10_rf1 year if aez == 322, color(gray%30) ) ///
			(fpfitci v10_rf2 year if aez == 322, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if aez == 322, color(sea%30) ) ///
			(fpfitci v10_rf4 year if aez == 322, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if aez == 322, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if aez == 322, color(ananas%30)  ///
			xtitle("") xscale(r(2008(1)2015)) title("Tropic-cool/semi-arid (n = 2,840)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(3 "CPC") ///
			label(5 "MERRA-2") label(7 "ARC2") label(9 "ERA5") ///
			label(11 "TAMSAT") order(1 3 5 7 9 11)) saving("$sfig/tcsa_norain_rf", replace)

* days without rain - Tropic-cool/sub-humid	
	twoway  (fpfitci v10_rf1 year if aez == 323, color(gray%30) ) ///
			(fpfitci v10_rf2 year if aez == 323, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if aez == 323, color(sea%30) ) ///
			(fpfitci v10_rf4 year if aez == 323, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if aez == 323, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if aez == 323, color(ananas%30)  ///
			xtitle("") xscale(r(2008(1)2015)) title("Tropic-cool/sub-humid (n = 5,886)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(3 "CPC") ///
			label(5 "MERRA-2") label(7 "ARC2") label(9 "ERA5") ///
			label(11 "TAMSAT") order(1 3 5 7 9 11)) saving("$sfig/tcsh_norain_rf", replace)
			
* days without rain - Tropic-cool/humid	
	twoway  (fpfitci v10_rf1 year if aez == 324, color(gray%30) ) ///
			(fpfitci v10_rf2 year if aez == 324, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if aez == 324, color(sea%30) ) ///
			(fpfitci v10_rf4 year if aez == 324, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if aez == 324, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if aez == 324, color(ananas%30)  ///
			xtitle("Year") xscale(r(2008(1)2015)) title("Tropic-cool/humid (n = 2,960)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CHIRPS") label(3 "CPC") ///
			label(5 "MERRA-2") label(7 "ARC2") label(9 "ERA5") ///
			label(11 "TAMSAT") order(1 3 5 7 9 11)) saving("$sfig/tch_norain_rf", replace)				
		
		
	grc1leg2 		"$sfig/twsa_norain_rf.gph" "$sfig/tcsa_norain_rf.gph" ///
						"$sfig/twsh_norain_rf.gph" "$sfig/tcsh_norain_rf.gph" ///
						"$sfig/twh_norain_rf.gph"  "$sfig/tch_norain_rf.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\norain_aez_rf.pdf", replace	
			

* **********************************************************************
* 6 - generate GDD line graphs by aez
* **********************************************************************

* growing degree days - Tropic-warm/semi-arid
	twoway	(fpfitci v19_tp1 year if aez == 312, color(gray%30) ) ///
			(fpfitci v19_tp2 year if aez == 312, color(vermillion%30) ) ///
			(fpfitci v19_tp3 year if aez == 312, color(sea%30)  ///
			xtitle("") xscale(r(2008(1)2015)) title("Tropic-warm/semi-arid (n = 9,095)") ///
			ytitle("Growing Degree Days") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(3 "ERA5") ///
			label(5 "CPC") order(1 3 5)) saving("$sfig/twsa_gdd_tp", replace)

* growing degree days - Tropic-warm/sub-humid
	twoway	(fpfitci v19_tp1 year if aez == 313, color(gray%30) ) ///
			(fpfitci v19_tp2 year if aez == 313, color(vermillion%30) ) ///
			(fpfitci v19_tp3 year if aez == 313, color(sea%30)  ///
			xtitle("") xscale(r(2008(1)2015)) title("Tropic-warm/sub-humid (n = 9,009)") ///
			ytitle("Gorwing Degree Days") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(3 "ERA5") ///
			label(5 "CPC") order(1 3 5)) saving("$sfig/twsh_gdd_tp", replace)

* growing degree days - Tropic-warm/humid
	twoway	(fpfitci v19_tp1 year if aez == 314, color(gray%30) ) ///
			(fpfitci v19_tp2 year if aez == 314, color(vermillion%30) ) ///
			(fpfitci v19_tp3 year if aez == 314, color(sea%30) ///
			xtitle("Year") xscale(r(2008(1)2015)) title("Tropic-warm/humid (n = 3,280)") ///
			ytitle("Growing Degree Days") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(3 "ERA5") ///
			label(5 "CPC") order(1 3 5)) saving("$sfig/twh_gdd_tp", replace)		

* growing degree days - Tropic-cool/semi-arid
	twoway	(fpfitci v19_tp1 year if aez == 322, color(gray%30) ) ///
			(fpfitci v19_tp2 year if aez == 322, color(vermillion%30) ) ///
			(fpfitci v19_tp3 year if aez == 322, color(sea%30)  ///
			xtitle("") xscale(r(2008(1)2015)) title("Tropic-cool/semi-arid (n = 2,840)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(3 "ERA5") ///
			label(5 "CPC") order(1 3 5)) saving("$sfig/tcsa_gdd_tp", replace)

* growing degree days - Tropic-cool/sub-humid
	twoway	(fpfitci v19_tp1 year if aez == 323, color(gray%30) ) ///
			(fpfitci v19_tp2 year if aez == 323, color(vermillion%30) ) ///
			(fpfitci v19_tp3 year if aez == 323, color(sea%30)  ///
			xtitle("") xscale(r(2008(1)2015)) title("Tropic-cool/sub-humid (n = 5,886)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(3 "ERA5") ///
			label(5 "CPC") order(1 3 5)) saving("$sfig/tcsh_gdd_tp", replace)

* growing degree days - Tropic-cool/humid
	twoway	(fpfitci v19_tp1 year if aez == 324, color(gray%30) ) ///
			(fpfitci v19_tp2 year if aez == 324, color(vermillion%30) ) ///
			(fpfitci v19_tp3 year if aez == 324, color(sea%30)  ///
			xtitle("Year") xscale(r(2008(1)2015)) title("Tropic-cool/humid (n = 2,960)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "MERRA-2") label(3 "ERA5") ///
			label(5 "CPC") order(1 3 5)) saving("$sfig/tch_gdd_tp", replace)				
			
	grc1leg2 		"$sfig/twsa_gdd_tp.gph" "$sfig/tcsa_gdd_tp.gph" ///
						"$sfig/twsh_gdd_tp.gph" "$sfig/tcsh_gdd_tp.gph" ///
						"$sfig/twh_gdd_tp.gph" "$sfig/tch_gdd_tp.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\gdd_aez_tp.pdf", replace			
			
			
* **********************************************************************
* 7 - end matter
* **********************************************************************

* close the log
	log	close

/* END */