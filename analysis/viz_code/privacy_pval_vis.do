* Project: WB Weather - privacy paper
* Created on: 14 December 2019
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
	log 	using 	"$logout/privacy_pval_vis", append

		
************************************************************************
**# 1 - load data
************************************************************************

* load data 
	use 			"$root/lsms_complete_results", clear

* generate p-values
	gen 			p99 = 1 if pval <= 0.01
	replace 		p99 = 0 if pval > 0.01
	gen 			p95 = 1 if pval <= 0.05
	replace 		p95 = 0 if pval > 0.05
	gen 			p90 = 1 if pval <= 0.10
	replace 		p90 = 0 if pval > 0.10

* drop models with covariates
	drop if			regname == 3 | regname == 6
	
************************************************************************
**# 2 - generate p-value graphs by extraction
************************************************************************
						
************************************************************************
**## 2a - generate p-value graphs by extraction across countries
************************************************************************

* p-value graph of rainfall by extraction method
preserve
	drop			if varname > 14
	
	collapse 		(mean) mu99 = p99 mu95 = p95 mu90 = p90 ///
						(sd) sd99 = p99 sd95 = p95 sd90 = p90 ///
						(count) n99 = p99 n95 = p95 n90 = p90, by(ext)
	
	gen 			hi99 = mu99 + invttail(n99-1,0.025)*(sd99 / sqrt(n99))
	gen				lo99 = mu99 - invttail(n99-1,0.025)*(sd99 / sqrt(n99))
	
	gen 			hi95 = mu95 + invttail(n95-1,0.025)*(sd95 / sqrt(n95))
	gen				lo95 = mu95 - invttail(n95-1,0.025)*(sd95 / sqrt(n95))
	
	gen 			hi90 = mu90 + invttail(n90-1,0.025)*(sd90 / sqrt(n90))
	gen				lo90 = mu90 - invttail(n90-1,0.025)*(sd90 / sqrt(n90))
	
	reshape 		long mu sd n hi lo, i(ext) j(p)	
	
	sort 			ext p
	gen 			obs = _n
	replace			obs = 1 + obs if obs > 3
	replace			obs = 1 + obs if obs > 7
	replace			obs = 1 + obs if obs > 11
	replace			obs = 1 + obs if obs > 15
	replace			obs = 1 + obs if obs > 19
	replace			obs = 1 + obs if obs > 23
	replace			obs = 1 + obs if obs > 27
	replace			obs = 1 + obs if obs > 31
	replace			obs = 1 + obs if obs > 35

	sum			 	hi if p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if p == 95 & ext == 1
	global			bmin = r(min)	
	
	bys ext: sum mu if p == 95
	
	twoway			(bar mu obs if p == 90, color(emerald*1.5%60)) || ///
						(bar mu obs if p == 95, color(eltblue*1.5%60)) || ///
						(bar mu obs if p == 99, color(khaki*1.5%60)) || ///
						(rcap hi lo obs, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Rainfall") ///
						ytitle("Share of Significant Point Estimates") ///
						xscale(r(0 40) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 6 "HH simple " 10 "EA bilinear " ///
						14 "EA simple " 18 "EA modified bilinear " 22 "EA modified simple " ///
						26 "Admin bilinear " 30 "Admin simple " 34 "EA zone " ///
						38 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2 3 4) label(1 "p>0.90") ///
						label(2 "p>0.95") label(3 "p>0.99") label(4 "95% C.I."))  ///
						saving("$sfig/pval_ext_rf_x", replace)
						
		graph export 	"$data/output/presentations/PacDev/pval_ext_rf.pdf", as(pdf) replace
restore

* p-value graph of temperature by extraction method
preserve
	drop			if varname < 15
	
	collapse 		(mean) mu99 = p99 mu95 = p95 mu90 = p90 ///
						(sd) sd99 = p99 sd95 = p95 sd90 = p90 ///
						(count) n99 = p99 n95 = p95 n90 = p90, by(ext)
	
	gen 			hi99 = mu99 + invttail(n99-1,0.025)*(sd99 / sqrt(n99))
	gen				lo99 = mu99 - invttail(n99-1,0.025)*(sd99 / sqrt(n99))
	
	gen 			hi95 = mu95 + invttail(n95-1,0.025)*(sd95 / sqrt(n95))
	gen				lo95 = mu95 - invttail(n95-1,0.025)*(sd95 / sqrt(n95))
	
	gen 			hi90 = mu90 + invttail(n90-1,0.025)*(sd90 / sqrt(n90))
	gen				lo90 = mu90 - invttail(n90-1,0.025)*(sd90 / sqrt(n90))
	
	reshape 		long mu sd n hi lo, i(ext) j(p)	
	
	sort 			ext p
	gen 			obs = _n
	replace			obs = 1 + obs if obs > 3
	replace			obs = 1 + obs if obs > 7
	replace			obs = 1 + obs if obs > 11
	replace			obs = 1 + obs if obs > 15
	replace			obs = 1 + obs if obs > 19
	replace			obs = 1 + obs if obs > 23
	replace			obs = 1 + obs if obs > 27
	replace			obs = 1 + obs if obs > 31
	replace			obs = 1 + obs if obs > 35

	sum			 	hi if p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if p == 95 & ext == 1
	global			bmin = r(min)	

	bys ext: sum mu if p == 95
	
	twoway			(bar mu obs if p == 90, color(maroon*1.5%60)) || ///
						(bar mu obs if p == 95, color(lavender*1.5%60)) || ///
						(bar mu obs if p == 99, color(brown*1.5%60)) || ///
						(rcap hi lo obs, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Temperature") ///
						ytitle("Share of Significant Point Estimates") ///
						xscale(r(0 40) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 6 "HH simple " 10 "EA bilinear " ///
						14 "EA simple " 18 "EA modified bilinear " 22 "EA modified simple " ///
						26 "Admin bilinear " 30 "Admin simple " 34 "EA zone " ///
						38 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2 3 4) label(1 "p>0.90") ///
						label(2 "p>0.95") label(3 "p>0.99") label(4 "95% C.I."))  ///
						saving("$sfig/pval_ext_tp_x", replace)
						
		graph export 	"$data/output/presentations/PacDev/pval_ext_tp.pdf", as(pdf) replace
restore
					

	grc1leg2 		"$sfig/pval_ext_rf_x.gph" "$sfig/pval_ext_tp_x.gph", ///
						col(1) iscale(.5) pos(12) commonscheme imargin(0 0 0 0)
						
	graph export 	"$xfig/pval_ext.pdf", as(pdf) replace		
			
				
************************************************************************
**## 2b - generate p-value graphs by extraction and country
************************************************************************
	
* p-value graph of rainfall by extraction method
preserve
	drop			if varname > 14
	
	collapse 		(mean) mu99 = p99 mu95 = p95 mu90 = p90 ///
						(sd) sd99 = p99 sd95 = p95 sd90 = p90 ///
						(count) n99 = p99 n95 = p95 n90 = p90, by(ext country)
	
	gen 			hi99 = mu99 + invttail(n99-1,0.025)*(sd99 / sqrt(n99))
	gen				lo99 = mu99 - invttail(n99-1,0.025)*(sd99 / sqrt(n99))
	
	gen 			hi95 = mu95 + invttail(n95-1,0.025)*(sd95 / sqrt(n95))
	gen				lo95 = mu95 - invttail(n95-1,0.025)*(sd95 / sqrt(n95))
	
	gen 			hi90 = mu90 + invttail(n90-1,0.025)*(sd90 / sqrt(n90))
	gen				lo90 = mu90 - invttail(n90-1,0.025)*(sd90 / sqrt(n90))
	
	reshape 		long mu sd n hi lo, i(country ext) j(p)	
	
	sort 			country ext p
					
* generate count variable that repeats by country	
	bys country (ext): gen obs = _n
	
* ethiopia
	sum			 	hi if country == 1 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 1 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 1 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 1, color(eltblue*1.5%60)) || ///
						(rcap hi lo obs if country == 1 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Ethiopia") ///
						ytitle("Share of Significant Point Estimates") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/eth_pval_ext_rf", replace)

* malawi
	sum			 	hi if country == 2 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 2 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 2 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 2, color(eltblue*1.5%60)) || ///
						(rcap hi lo obs if country == 2 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Malawi") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/mwi_pval_ext_rf", replace)

* niger
	sum			 	hi if country == 4 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 4 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 4 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 4, color(eltblue*1.5%60)) || ///
						(rcap hi lo obs if country == 4 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Niger") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/ngr_pval_ext_rf", replace)

* nigeria
	sum			 	hi if country == 5 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 5 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 5 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 5, color(eltblue*1.5%60)) || ///
						(rcap hi lo obs if country == 5 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Nigeria") ///
						ytitle("Share of Significant Point Estimates") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/nga_pval_ext_rf", replace)
						
* tanzania
	sum			 	hi if country == 6 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 6 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 6 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 6, color(eltblue*1.5%60)) || ///
						(rcap hi lo obs if country == 6 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Tanzania") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/tza_pval_ext_rf", replace)
						
* uganda
	sum			 	hi if country == 7 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 7 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 7 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 7, color(eltblue*1.5%60)) || ///
						(rcap hi lo obs if country == 7 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Uganda") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/uga_pval_ext_rf", replace)
restore


* p-value graph of temperature by extraction method
preserve
	drop			if varname < 15
	
	collapse 		(mean) mu99 = p99 mu95 = p95 mu90 = p90 ///
						(sd) sd99 = p99 sd95 = p95 sd90 = p90 ///
						(count) n99 = p99 n95 = p95 n90 = p90, by(ext country)
	
	gen 			hi99 = mu99 + invttail(n99-1,0.025)*(sd99 / sqrt(n99))
	gen				lo99 = mu99 - invttail(n99-1,0.025)*(sd99 / sqrt(n99))
	
	gen 			hi95 = mu95 + invttail(n95-1,0.025)*(sd95 / sqrt(n95))
	gen				lo95 = mu95 - invttail(n95-1,0.025)*(sd95 / sqrt(n95))
	
	gen 			hi90 = mu90 + invttail(n90-1,0.025)*(sd90 / sqrt(n90))
	gen				lo90 = mu90 - invttail(n90-1,0.025)*(sd90 / sqrt(n90))
	
	reshape 		long mu sd n hi lo, i(country ext) j(p)	
	
	sort 			country ext p
					
* generate count variable that repeats by country	
	bys country (ext): gen obs = _n
	
* ethiopia
	sum			 	hi if country == 1 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 1 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 1 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 1, color(lavender*1.5%60)) || ///
						(rcap hi lo obs if country == 1 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Ethiopia") ///
						ytitle("Share of Significant Point Estimates") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/eth_pval_ext_tp", replace)

* malawi
	sum			 	hi if country == 2 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 2 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 2 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 2, color(lavender*1.5%60)) || ///
						(rcap hi lo obs if country == 2 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Malawi") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/mwi_pval_ext_tp", replace)

* niger
	sum			 	hi if country == 4 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 4 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 4 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 4, color(lavender*1.5%60)) || ///
						(rcap hi lo obs if country == 4 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Niger") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/ngr_pval_ext_tp", replace)

* nigeria
	sum			 	hi if country == 5 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 5 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 5 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 5, color(lavender*1.5%60)) || ///
						(rcap hi lo obs if country == 5 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Nigeria") ///
						ytitle("Share of Significant Point Estimates") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/nga_pval_ext_tp", replace)
						
* tanzania
	sum			 	hi if country == 6 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 6 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 6 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 6, color(lavender*1.5%60)) || ///
						(rcap hi lo obs if country == 6 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Tanzania") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/tza_pval_ext_tp", replace)
						
* uganda
	sum			 	hi if country == 7 & p == 95 & ext == 1
	global			bmax = r(max)
	
	sum			 	lo if country == 7 & p == 95 & ext == 1
	global			bmin = r(min)

	bys ext: sum mu if country == 7 & p == 95
	
	twoway			(bar mu obs if p == 95 & country == 7, color(lavender*1.5%60)) || ///
						(rcap hi lo obs if country == 7 & p == 95, yscale(r(0 1)) ///
						ylab(0(.1)1, labsize(small)) title("Uganda") ///
						lcolor(black) xscale(r(0 30) ex) ///
						yline($bmax, lcolor(maroon) lstyle(solid) ) ///
						yline($bmin, lcolor(maroon)  lstyle(solid) ) ///
						xlabel(2 "{bf:HH bilinear} " 5 "HH simple " 8 "EA bilinear " ///
						11 "EA simple " 14 "EA modified bilinear " 17 "EA modified simple " ///
						20 "Admin bilinear " 23 "Admin simple " 26 "EA zone " ///
						29 "Admin area ", angle(45) notick) xtitle("")), ///
						legend(pos(12) col(5) order(1 2) label(1 "p>0.95") ///
						label(2 "95% C.I.")) ///
						saving("$sfig/uga_pval_ext_tp", replace)
restore
						
* p-value extraction method for rainfall
	grc1leg2 		"$sfig/eth_pval_ext_rf.gph" "$sfig/mwi_pval_ext_rf.gph" ///
						"$sfig/ngr_pval_ext_rf.gph" "$sfig/nga_pval_ext_rf.gph" ///
						"$sfig/tza_pval_ext_rf.gph" "$sfig/uga_pval_ext_rf.gph", ///
						col(3) iscale(.5) pos(12) commonscheme imargin(0 0 0 0)
						
	graph export 	"$xfig\pval_ext_rf.pdf", as(pdf) replace
	
* p-value extraction method for temperature
	grc1leg2 		"$sfig/eth_pval_ext_tp.gph" "$sfig/mwi_pval_ext_tp.gph" ///
						"$sfig/ngr_pval_ext_tp.gph" "$sfig/nga_pval_ext_tp.gph" ///
						"$sfig/tza_pval_ext_tp.gph" "$sfig/uga_pval_ext_tp.gph", ///
						col(3) iscale(.5) pos(12) commonscheme imargin(0 0 0 0)
						
	graph export 	"$xfig\pval_ext_tp.pdf", as(pdf) replace					

************************************************************************
**# 3 - end matter
************************************************************************


* close the log
	log	close

/* END */		