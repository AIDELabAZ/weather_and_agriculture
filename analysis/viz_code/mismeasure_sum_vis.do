* Project: WB Weather
* Created on: September 2020
* Created by: alj
* Edited by: jdm
* Last edit: 18 June 2024 
* Stata v.18.0 

* does
	* reads in lsms data set
	* makes visualziations of summary statistics  

* assumes
	* you have results file 
	* grc1leg2.ado

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root 	= 	"$data/regression_data"
	global	stab 	= 	"$data/results_data/tables"
	global	xtab 	= 	"$data/output/mismeasure_paper/tables"
	global	sfig	= 	"$data/results_data/figures"	
	global 	xfig    =   "$data/output/mismeasure_paper/figures"
	global	logout 	= 	"$data/results_data/logs"
	* s indicates Stata figures, works in progress
	* x indicates final version for paper

* open log	
	cap log close
	log 	using 		"$logout/summaryvis", append

		
* **********************************************************************
* 1 - load and process data
* **********************************************************************

* load data 
	use 			"$root/lsms_panel", clear


* **********************************************************************
* 2 - generate total season distribution graphs by country
* **********************************************************************

* total season rainfall - ethiopia
	twoway  (kdensity v05_rf1 if country == 1, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country ==1, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country ==1, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country ==1, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country ==1, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country ==1, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(2000)8000)) title("Ethiopia (n = 10,674)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(6) label(1 "ARC2") label(2 "CHIRPS") ///
			label(3 "CPC") label(4 "ERA5") label(5 "MERRA-2") ///
			label(6 "TAMSAT")) saving("$sfig/eth_density_rf", replace)
			
*	graph export 	"$xfig\eth_density_rf.pdf", as(pdf) replace

* total season rainfall - malawi	
	twoway  (kdensity v05_rf1 if country == 2, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 2, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 2, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 2, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 2, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 2, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(500)2500)) title("Malawi (n = 8,897)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/mwi_density_rf", replace)
			
*	graph export 	"$xfig\mwi_density_rf.pdf", as(pdf) replace

* total season rainfall - niger	
	twoway  (kdensity v05_rf1 if country == 4, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 4, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 4, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 4, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 4, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 4, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(100)800)) title("Niger (n = 3,913)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/ngr_density_rf", replace)
			
*	graph export 	"$xfig\ngr_density_rf.pdf", as(pdf) replace

* total season rainfall - nigeria
	twoway  (kdensity v05_rf1 if country == 5, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 5, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 5, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 5, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 5, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 5, color(ananas%30) recast(area) ///
			xtitle("") xscale(r(0(500)3000)) title("Nigeria (n = 9,145)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/nga_density_rf", replace)
			
*	graph export 	"$xfig\nga_density_rf.pdf", as(pdf) replace

* total season rainfall - tanzania	
	twoway  (kdensity v05_rf1 if country == 6, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 6, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 6, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 6, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 6, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 6, color(ananas%30) recast(area) ///
			xtitle("Total Season Rainfall (mm)") xscale(r(0(2000)6000)) title("Tanzania (n = 9,916)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/tza_density_rf", replace)
			
*	graph export 	"$xfig\tza_density_rf.pdf", as(pdf) replace

* total season rainfall - uganda	
	twoway  (kdensity v05_rf1 if country == 7, color(gray%30) recast(area)) ///
			(kdensity v05_rf2 if country == 7, color(vermillion%30) recast(area)) ///
			(kdensity v05_rf3 if country == 7, color(sea%30) recast(area)) ///
			(kdensity v05_rf4 if country == 7, color(turquoise%30) recast(area)) ///
			(kdensity v05_rf5 if country == 7, color(reddish%30) recast(area)) ///
			(kdensity v05_rf6 if country == 7, color(ananas%30) recast(area) ///
			xtitle("Total Season Rainfall (mm)") xscale(r(0(5000)3500)) ///
			title("Uganda (n = 11,692)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/uga_density_rf", replace)	
			
*	graph export 	"$xfig\uga_density_rf.pdf", as(pdf) replace

	grc1leg2 		"$sfig/eth_density_rf.gph" "$sfig/mwi_density_rf.gph" ///
						"$sfig/ngr_density_rf.gph" "$sfig/nga_density_rf.gph"   ///
						"$sfig/tza_density_rf.gph" "$sfig/uga_density_rf.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\density_rf.pdf", replace			
	
* **********************************************************************
* 4 - generate mean temperature distribution graphs
* **********************************************************************

* mean temp - ethiopia
	twoway	(kdensity v15_tp7 if country ==1, color(gray%30) recast(area)) ///
			(kdensity v15_tp8 if country ==1, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp9 if country ==1, color(sea%30) recast(area) ///
			xtitle("") title("Ethiopia (n = 10,674)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CPC") label(2 "ERA5") ///
			label(3 "MERRA-2")) saving("$sfig/eth_density_tp", replace)
			
*	graph export 	"$xfig\eth_density_tp.pdf", as(pdf) replace		

* mean temp - malawi
	twoway	(kdensity v15_tp7 if country == 2, color(gray%30) recast(area)) ///
			(kdensity v15_tp8 if country == 2, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp9 if country == 2, color(sea%30) recast(area) ///
			xtitle("") title("Malawi (n = 8,897)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/mwi_density_tp", replace)
			
*	graph export 	"$xfig\mwi_density_tp.pdf", as(pdf) replace		

	replace			v15_tp9 = 29.91119 if v15_tp9 == 0
	
* mean temp - Niger
	twoway	(kdensity v15_tp7 if country == 4, color(gray%30) recast(area)) ///
			(kdensity v15_tp8 if country == 4, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp9 if country == 4, color(sea%30) recast(area) ///
			xtitle("") title("Niger (n = 3,913)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/ngr_density_tp", replace)	
			
*	graph export 	"$xfig\ngr_density_tp.pdf", as(pdf) replace			

* mean temp - Nigeria
	twoway	(kdensity v15_tp7 if country == 5, color(gray%30) recast(area)) ///
			(kdensity v15_tp8 if country == 5, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp9 if country == 5, color(sea%30) recast(area) ///
			xtitle("") title("Nigeria (n = 9,145)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/nga_density_tp", replace)
			
*	graph export 	"$xfig\nga_density_tp.pdf", as(pdf) replace		

	replace			v15_tp7 = 24.07102 if v15_tp7 == 0
	
* mean temp - Tanzania
	twoway	(kdensity v15_tp7 if country == 6, color(gray%30) recast(area)) ///
			(kdensity v15_tp8 if country == 6, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp9 if country == 6, color(sea%30) recast(area) ///
			xtitle("Mean Seasonal Temperature (C)") title("Tanzania (n = 9,916)") ///
			ytitle("Density") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/tza_density_tp", replace)
			
*	graph export 	"$xfig\tza_density_tp.pdf", as(pdf) replace		

* mean temp - Uganda
	twoway	(kdensity v15_tp7 if country == 7, color(gray%30) recast(area)) ///
			(kdensity v15_tp8 if country == 7, color(vermillion%30) recast(area)) ///
			(kdensity v15_tp9 if country == 7, color(sea%30) recast(area) ///
			xtitle("Mean Seasonal Temperature (C)") title("Uganda (n = 11,692)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/uga_density_tp", replace)	
			
*	graph export 	"$xfig\uga_density_tp.pdf", as(pdf) replace					

	grc1leg2 		"$sfig/eth_density_tp.gph" "$sfig/mwi_density_tp.gph" ///
						"$sfig/ngr_density_tp.gph" "$sfig/nga_density_tp.gph"   ///
						"$sfig/tza_density_tp.gph" "$sfig/uga_density_tp.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\density_tp.pdf", replace				

* **********************************************************************
* 5 - generate days without rain line graphs by country
* **********************************************************************

* days without rain - ethiopia	
	twoway  (fpfitci v10_rf1 year if country ==1, color(gray%30) ) ///
			(fpfitci v10_rf2 year if country ==1, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if country ==1, color(sea%30) ) ///
			(fpfitci v10_rf4 year if country ==1, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if country ==1, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if country ==1, color(ananas%30)  ///
			xtitle("") title("Ethiopia (n = 10,674)") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(6) label(1 "ARC2") label(3 "CHIRPS") ///
			label(5 "CPC") label(7 "ERA5") label(9 "MERRA-2") ///
			label(11 "TAMSAT") order(1 3 5 7 9 11)) saving("$sfig/eth_norain_rf", replace)

* days without rain - malawi	
	twoway  (fpfitci v10_rf1 year if country == 2, color(gray%30) ) ///
			(fpfitci v10_rf2 year if country == 2, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if country == 2, color(sea%30) ) ///
			(fpfitci v10_rf4 year if country == 2, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if country == 2, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if country == 2, color(ananas%30)  ///
			xtitle("") title("Malawi (n = 8,897)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/mwi_norain_rf", replace)
			
* days without rain - Niger	
	twoway  (fpfitci v10_rf1 year if country == 4, color(gray%30) ) ///
			(fpfitci v10_rf2 year if country == 4, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if country == 4, color(sea%30) ) ///
			(fpfitci v10_rf4 year if country == 4, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if country == 4, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if country == 4, color(ananas%30)  ///
			xtitle("") title("Niger (n = 3,913)") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/ngr_norain_rf", replace)

* days without rain - Nigeria	
	twoway  (fpfitci v10_rf1 year if country == 5, color(gray%30) ) ///
			(fpfitci v10_rf2 year if country == 5, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if country == 5, color(sea%30) ) ///
			(fpfitci v10_rf4 year if country == 5, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if country == 5, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if country == 5, color(ananas%30)  ///
			xtitle("") title("Nigeria (n = 9,145)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/nga_norain_rf", replace)

* days without rain - Tanzania	
	twoway  (fpfitci v10_rf1 year if country == 6, color(gray%30) ) ///
			(fpfitci v10_rf2 year if country == 6, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if country == 6, color(sea%30) ) ///
			(fpfitci v10_rf4 year if country == 6, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if country == 6, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if country == 6, color(ananas%30)  ///
			xtitle("Year") title("Tanzania (n = 9,916)") ///
			ytitle("Days without Rain") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/tza_norain_rf", replace)
			
* days without rain - Uganda	
	twoway  (fpfitci v10_rf1 year if country == 7, color(gray%30) ) ///
			(fpfitci v10_rf2 year if country == 7, color(vermillion%30) ) ///
			(fpfitci v10_rf3 year if country == 7, color(sea%30) ) ///
			(fpfitci v10_rf4 year if country == 7, color(turquoise%30) ) ///
			(fpfitci v10_rf5 year if country == 7, color(reddish%30) ) ///
			(fpfitci v10_rf6 year if country == 7, color(ananas%30)  ///
			xtitle("Year") title("Uganda (n = 11,692)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/uga_norain_rf", replace)				

	grc1leg2 		"$sfig/eth_norain_rf.gph" "$sfig/mwi_norain_rf.gph" ///
						"$sfig/ngr_norain_rf.gph" "$sfig/nga_norain_rf.gph"   ///
						"$sfig/tza_norain_rf.gph" "$sfig/uga_norain_rf.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\norain_rf.pdf", replace				
		
* **********************************************************************
* 6 - generate GDD line graphs by country
* **********************************************************************

* growing degree days - ethiopia
	twoway	(fpfitci v19_tp7 year if country ==1, color(gray%30) ) ///
			(fpfitci v19_tp8 year if country ==1, color(vermillion%30) ) ///
			(fpfitci v19_tp9 year if country ==1, color(sea%30)  ///
			xtitle("") title("Ethiopia (n = 10,674)") ///
			ytitle("Growing Degree Days") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(pos(6) col(3) label(1 "CPC") label(3 "ERA5") ///
			label(5 "MERRA-2") order(1 3 5)) saving("$sfig/eth_gdd_tp", replace)

* growing degree days - malawi
	twoway	(fpfitci v19_tp7 year if country == 2, color(gray%30) ) ///
			(fpfitci v19_tp8 year if country == 2, color(vermillion%30) ) ///
			(fpfitci v19_tp9 year if country == 2, color(sea%30)  ///
			xtitle("") title("Malawi (n = 8,897)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/mwi_gdd_tp", replace)

* growing degree days - Niger
	twoway	(fpfitci v19_tp7 year if country == 4, color(gray%30) ) ///
			(fpfitci v19_tp8 year if country == 4, color(vermillion%30) ) ///
			(fpfitci v19_tp9 year if country == 4, color(sea%30) ///
			xtitle("") title("Niger (n = 3,913)") ///
			ytitle("Growing Degree Days") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/ngr_gdd_tp", replace)		

* growing degree days - Nigeria
	twoway	(fpfitci v19_tp7 year if country == 5, color(gray%30) ) ///
			(fpfitci v19_tp8 year if country == 5, color(vermillion%30) ) ///
			(fpfitci v19_tp9 year if country == 5, color(sea%30)  ///
			xtitle("") title("Nigeria (n = 9,145)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/nga_gdd_tp", replace)

* growing degree days - Tanzania
	twoway	(fpfitci v19_tp7 year if country == 6, color(gray%30) ) ///
			(fpfitci v19_tp8 year if country == 6, color(vermillion%30) ) ///
			(fpfitci v19_tp9 year if country == 6, color(sea%30)  ///
			xtitle("Year") title("Tanzania (n = 9,916)") ///
			ytitle("Growing Degree Days") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/tza_gdd_tp", replace)

* growing degree days - Uganda
	twoway	(fpfitci v19_tp7 year if country == 7, color(gray%30) ) ///
			(fpfitci v19_tp8 year if country == 7, color(vermillion%30) ) ///
			(fpfitci v19_tp9 year if country == 7, color(sea%30)  ///
			xtitle("Year") title("Uganda (n = 11,692)") ///
			ytitle("") ylabel(, nogrid labsize(small)) xlabel(, nogrid labsize(small))), ///
			legend(off) saving("$sfig/uga_gdd_tp", replace)				
	
	grc1leg2 		"$sfig/eth_gdd_tp.gph" "$sfig/mwi_gdd_tp.gph" ///
						"$sfig/ngr_gdd_tp.gph" "$sfig/nga_gdd_tp.gph"   ///
						"$sfig/tza_gdd_tp.gph" "$sfig/uga_gdd_tp.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\gdd_tp.pdf", replace					
			
			
* **********************************************************************
* 7 - end matter
* **********************************************************************

* close the log
	log	close

/* END */