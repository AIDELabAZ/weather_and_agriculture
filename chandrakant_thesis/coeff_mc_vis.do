* Project: WB Weather
* Created on: November 2019
* Created by: jdm
* Edited by: jdm
* Last edit: 9 November 2020 
* Stata v.16.1 

* does
	* reads in results data set for multiple linear combos
	* makes visualziations of results 

* assumes
	* you have results file 
	* customsave.ado
	* grc1leg2.ado

* TO DO:
	* all of it

	
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
	log 	using 	"$logout/resultsvis_mc", append

* load data 
	use 			"$root/lsms_complete_results_mc", clear

	
* **********************************************************************
* 1 - generate serrbar graphs of 4 weather vars by country
* **********************************************************************

* combine mean and var rainfall and temperature
preserve
	keep			if varrs == .
	
* mean daily rainfall
	sort 			varrm country betarm
	gen 			obs = _n	

	serrbar 		betarm serm obs, lcolor(edkblue%10) ///
						mvopts(recast(scatter) mcolor(edkblue%5) ///
						mfcolor(edkblue%5) mlcolor(edkblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Mean Daily Rainfall") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v01_v03_v15_v17_cty", replace)

* variance daily rainfall
	drop			obs
	sort 			varrv country betarv
	gen 			obs = _n	

	serrbar 		betarv serv obs, lcolor(eltblue%10) ///
						mvopts(recast(scatter) mcolor(eltblue%5) ///
						mfcolor(eltblue%5) mlcolor(eltblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Variance of Daily Rainfall") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v03_v01_v15_v17_cty", replace)						
											
* mean daily temperature	
	drop			obs
	sort 			vartm country betatm
	gen 			obs = _n	

	serrbar 		betatm setm obs, lcolor(edkblue%10) ///
						mvopts(recast(scatter) mcolor(edkblue%5) ///
						mfcolor(edkblue%5) mlcolor(edkblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Mean Daily Temperature") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v15_v17_v01_v03_cty", replace)

* variance daily rainfall
	drop			obs
	sort 			vartv country betatv
	gen 			obs = _n	

	serrbar 		betatv setv obs, lcolor(eltblue%10) ///
						mvopts(recast(scatter) mcolor(eltblue%5) ///
						mfcolor(eltblue%5) mlcolor(eltblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Variance of Daily Temperature") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v17_v15_v01_v03_cty", replace)						
restore

* combine mean graphs
	gr combine 		"$sfig/v01_v03_v15_v17_cty.gph" "$sfig/v03_v01_v15_v17_cty.gph" ///
						"$sfig/v15_v17_v01_v03_cty.gph" "$sfig/v17_v15_v01_v03_cty.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export "$xfig\v01_v03_v15_v17_cty.png", width(1400) replace
	

* **********************************************************************
* 2 - generate serrbar graphs of 6 weather vars by country
* **********************************************************************

* combine mean and var rainfall and temperature
preserve
	drop			if varrs == .
	
* mean daily rainfall
	sort 			varrm country betarm
	gen 			obs = _n	

	serrbar 		betarm serm obs, lcolor(edkblue%10) ///
						mvopts(recast(scatter) mcolor(edkblue%5) ///
						mfcolor(edkblue%5) mlcolor(edkblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Mean Daily Rainfall") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v01_v03_v04_v15_v17_v18_cty", replace)

* variance daily rainfall
	drop			obs
	sort 			varrv country betarv
	gen 			obs = _n	

	serrbar 		betarv serv obs, lcolor(eltblue%10) ///
						mvopts(recast(scatter) mcolor(eltblue%5) ///
						mfcolor(eltblue%5) mlcolor(eltblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Variance of Daily Rainfall") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v03_v04_v01_v15_v17_v18_cty", replace)

* skew daily rainfall
	drop			obs
	sort 			varrs country betars
	gen 			obs = _n	

	serrbar 		betars sers obs, lcolor(emerald%10) ///
						mvopts(recast(scatter) mcolor(emerald%5) ///
						mfcolor(emerald%5) mlcolor(emerald%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Skew of Daily Rainfall") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v04_v01_v03_v15_v17_v18_cty", replace)
											
* mean daily temperature	
	drop			obs
	sort 			vartm country betatm
	gen 			obs = _n	

	serrbar 		betatm setm obs, lcolor(edkblue%10) ///
						mvopts(recast(scatter) mcolor(edkblue%5) ///
						mfcolor(edkblue%5) mlcolor(edkblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Mean Daily Temperature") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v15_v17_v18_v01_v03_v04_cty", replace)

* variance daily temperature
	drop			obs
	sort 			vartv country betatv
	gen 			obs = _n	

	serrbar 		betatv setv obs, lcolor(eltblue%10) ///
						mvopts(recast(scatter) mcolor(eltblue%5) ///
						mfcolor(eltblue%5) mlcolor(eltblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Variance of Daily Temperature") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v17_v18_v15_v01_v03_v04_cty", replace)

* skew daily temperature
	drop			obs
	sort 			varts country betats
	gen 			obs = _n	

	serrbar 		betats sets obs, lcolor(emerald%10) ///
						mvopts(recast(scatter) mcolor(emerald%5) ///
						mfcolor(emerald%5) mlcolor(emerald%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Skew of Daily Temperature") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v18_v15_v17_v01_v03_v04_cty", replace)			
restore

* combine mean graphs
	gr combine 		"$sfig/v01_v03_v04_v15_v17_v18_cty.gph" "$sfig/v03_v04_v01_v15_v17_v18_cty.gph" ///
						"$sfig/v04_v01_v03_v15_v17_v18_cty.gph" "$sfig/v15_v17_v18_v01_v03_v04_cty.gph" ///
						"$sfig/v17_v18_v15_v01_v03_v04_cty.gph" "$sfig/v18_v15_v17_v01_v03_v04_cty.gph", ///
						col(3) iscale(.5) commonscheme
						
	graph export "$xfig\v01_v03_v04_v15_v17_v18_cty.png", width(1400) replace
		
	
* **********************************************************************
* 3 - end matter
* **********************************************************************


* close the log
	log	close

/* END */		