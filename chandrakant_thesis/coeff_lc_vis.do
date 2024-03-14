* Project: WB Weather
* Created on: November 2019
* Created by: jdm
* Edited by: jdm
* Last edit: 2 November 2020 
* Stata v.16.1 

* does
	* reads in results data set for linear combos
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
	log 	using 	"$logout/resultsvis_lc", append

* load data 
	use 			"$root/lsms_complete_results_lc", clear

	
* **********************************************************************
* 1 - generate serrbar graphs of 2 weather vars by country
* **********************************************************************

* combine mean rainfall and temperature
preserve
	keep			if var_rain == 1
	sort 			var_rain country beta_rain
	gen 			obs = _n	

* mean daily rainfall
	serrbar 		beta_rain se_rain obs, lcolor(edkblue%10) ///
						mvopts(recast(scatter) mcolor(edkblue%5) ///
						mfcolor(edkblue%5) mlcolor(edkblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Mean Daily Rainfall") ///
						xline(2160 4320 6480 8640 10800) xmtick(1080(2160)11880)  ///
						xlabel(0 "0" 1080 "Ethiopia" 2160 "2,160" 3240 "Malawi" ///
						4320 "4,320" 5400 "Niger" 6480 "6,480" 7560 "Nigeria" ///
						8640 "8,640" 9720 "Tanzania" 10800 "10,800" 11880 "Uganda" ///
						12960 "12,960", alt) xtitle("") saving("$sfig/v01_v15_cty", replace)

	drop			obs
	sort 			var_rain country beta_temp
	gen 			obs = _n	

* mean daily temperature	
	serrbar 		beta_temp se_temp obs, lcolor(edkblue%10) ///
						mvopts(recast(scatter) mcolor(edkblue%5) ///
						mfcolor(edkblue%5) mlcolor(edkblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Mean Daily Temperature") ///
						xline(2160 4320 6480 8640 10800) xmtick(1080(2160)11880)  ///
						xlabel(0 "0" 1080 "Ethiopia" 2160 "2,160" 3240 "Malawi" ///
						4320 "4,320" 5400 "Niger" 6480 "6,480" 7560 "Nigeria" ///
						8640 "8,640" 9720 "Tanzania" 10800 "10,800" 11880 "Uganda" ///
						12960 "12,960", alt) xtitle("") saving("$sfig/v15_v01_cty", replace)
restore

* combine mean graphs
	gr combine 		"$sfig/v01_v15_cty.gph" "$sfig/v15_v01_cty.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\v01_v15_cty.png", width(1400) replace
	

* combine median rainfall and temperature
preserve
	keep			if var_rain == 2
	sort 			var_rain country beta_rain
	gen 			obs = _n	

* median daily rainfall	
	serrbar 		beta_rain se_rain obs, lcolor(emidblue%10) ///
						mvopts(recast(scatter) mcolor(emidblue%5) ///
						mfcolor(emidblue%5) mlcolor(emidblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) ) ///
						ytitle("Coefficient") title("Median Daily Rainfall") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v02_v16_cty", replace)

	drop			obs
	sort 			var_rain country beta_temp
	gen 			obs = _n		

* median daily temperature	
	serrbar 		beta_temp se_temp obs, lcolor(edkblue%10) ///
						mvopts(recast(scatter) mcolor(edkblue%5) ///
						mfcolor(edkblue%5) mlcolor(edkblue%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Median Daily Temperature") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v16_v02_cty", replace)		
restore	

* combine median graphs
	gr combine 		"$sfig/v02_v16_cty.gph" "$sfig/v16_v02_cty.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\v02_v16_cty.png", width(1400) replace
	
	
* combine total rainfall  and GDD
preserve
	keep			if var_rain == 5
	sort 			var_rain country beta_rain
	gen 			obs = _n	

* total seasonal rainfall
	serrbar 		beta_rain se_rain obs, lcolor(erose%10) ///
						mvopts(recast(scatter) mcolor(erose%5) ///
						mfcolor(erose%5) mlcolor(erose%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) ) ///
						ytitle("Coefficient") title("Total Seasonal Rainfall") ///
						xline(2160 4320 6480 8640 10800) xmtick(1080(2160)11880)  ///
						xlabel(0 "0" 1080 "Ethiopia" 2160 "2,160" 3240 "Malawi" ///
						4320 "4,320" 5400 "Niger" 6480 "6,480" 7560 "Nigeria" ///
						8640 "8,640" 9720 "Tanzania" 10800 "10,800" 11880 "Uganda" ///
						12960 "12,960", alt) xtitle("") saving("$sfig/v05_v19_cty", replace)

	drop			obs
	sort 			var_rain country beta_temp
	gen 			obs = _n		

* growing degree days
	serrbar 		beta_temp se_temp obs, lcolor(erose%10) ///
						mvopts(recast(scatter) mcolor(erose%5) ///
						mfcolor(erose%5) mlcolor(erose%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("Growing Degree Days (GDD)") ///
						xline(2160 4320 6480 8640 10800) xmtick(1080(2160)11880)  ///
						xlabel(0 "0" 1080 "Ethiopia" 2160 "2,160" 3240 "Malawi" ///
						4320 "4,320" 5400 "Niger" 6480 "6,480" 7560 "Nigeria" ///
						8640 "8,640" 9720 "Tanzania" 10800 "10,800" 11880 "Uganda" ///
						12960 "12,960", alt) xtitle("") saving("$sfig/v19_v05_cty", replace)		
restore	

* combine totals graphs
	gr combine 		"$sfig/v05_v19_cty.gph" "$sfig/v19_v05_cty.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\v05_v19_cty.png", width(1400) replace
	

* combine z-score rainfall and temperature
preserve
	keep			if var_rain == 7
	sort 			var_rain country beta_rain
	gen 			obs = _n	

* z-score seasonal rainfall
	serrbar 		beta_rain se_rain obs, lcolor(eltgreen%10) ///
						mvopts(recast(scatter) mcolor(eltgreen%5) ///
						mfcolor(eltgreen%5) mlcolor(eltgreen%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) ) ///
						ytitle("Coefficient") title("z-Score of Total Seasonal Rainfall") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v07_v21_cty", replace)

	drop			obs
	sort 			var_rain country beta_temp
	gen 			obs = _n		

* z-score gdd
	serrbar 		beta_temp se_temp obs, lcolor(eltgreen%10) ///
						mvopts(recast(scatter) mcolor(eltgreen%5) ///
						mfcolor(eltgreen%5) mlcolor(eltgreen%5)) ///
						scale (1.96) yline(0, lcolor(maroon) lstyle(solid) )  ///
						ytitle("Coefficient") title("z-Score of Growing Degree Days (GDD)") ///
						xline(1080 2160 3240 4320 5400) xmtick(540(1080)5940)  ///
						xlabel(0 "0" 540 "Ethiopia" 1080 "1,080" 1620 "Malawi" ///
						2160 "2,160" 2700 "Niger" 3240 "3,240" 3780 "Nigeria" ///
						4320 "4,320" 4860 "Tanzania" 5400 "5,400" 5940 "Uganda" ///
						6480 "6,480", alt) xtitle("") saving("$sfig/v21_v07_cty", replace)		
restore	

* combine z-score graphs
	gr combine 		"$sfig/v07_v21_cty.gph" "$sfig/v21_v07_cty.gph", ///
						col(2) iscale(.5) commonscheme
						
	graph export 	"$xfig\v07_v21_cty.png", width(1400) replace
	
		
* **********************************************************************
* 2 - end matter
* **********************************************************************


* close the log
	log	close

/* END */		