* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Edited on: 29 May 2024
* Edited by: jdm
* Stata v.18

* does
	* merges individual cleaned plot datasets together
	* adjusts binary variables
	* imputes values for continuous variables
	* collapses to wave 3 plot level data to household level for combination with other waves

* assumes
	* previously cleaned household datasets
	* double counting assumed in labor - only use harvest labor 

* TO DO:
	* done 

	
* **********************************************************************
* 0 - setup
* **********************************************************************
	
* define paths	
	global	root			"$data/household_data/nigeria/wave_4/refined"
	global 	export  		"$data/household_data/nigeria/wave_4/refined"
	global 	logout  		"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log using "$logout/ghsy4_merge", append


	
* **********************************************************************
* 1 - merge plot level data sets together
* **********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"$root/ph_secta3i.dta", clear

	isid			cropplot_id
	
* merge in plot size data
	merge 			m:1 hhid plotid using "$root/pp_sect11a1", generate(_11a1)
	*** 0 are missing in master, 10,414 matched
	*** all unmerged (3953) are from using, meaning we lack production data
	*** per Malawi (rs_plot) we drop all unmerged observations

	drop			if _11a1 != 3
	
* merging in irrigation data
	merge			m:1 hhid plotid using "$root/pp_sect11b1", generate(_11b1)
	*** none are missing in master, 10414 matched
	*** 3953 missing from using
	*** we assume these are plots without irrigation
	
	replace			irr_any = 2 if irr_any == . & _11b1 == 1
	*** 0 changes made

	drop			if _11b1 == 2
	
* merging in planting labor data
	merge		m:1 hhid plotid using "$root/pp_sect11c1", generate(_11c1)
	*** 0 are missing in master, 10414 matched
	*** 1234 missing from using
	
	drop			if _11c1 == 2
	*** not going to actually use planting labor in analysis - will omit

* merging in pesticide, herbicide, fertilizer use
	merge		m:1 hhid plotid using "$root/ph_sect11c2", generate(_11c2)
	*** 0 missing in master, 11566 mathced
	*** 1170 missing from using
	*** we assume these are plots without pest or herb

	replace			pest_any = 2 if pest_any == . & _11c2 == 1
	replace			herb_any = 2 if herb_any == . & _11c2 == 1

	*** 0 changes made for each 
	
	drop			if _11c2 == 2

* merging in harvest labor data
	merge		m:1 hhid plotid using "$root/ph_secta2", generate(_a2)
	*** 207 missing from master 998 from using, 11359 matched
	*** we will impute the missing values later
	*** only going to include harvest labor in analysis - will include this and rename generally
	*** can revisit this later

	drop			if _a2 == 2

* merging in households data
	merge		m:1 hhid using "$root/pp_secta", generate(_a)
	*** 0 missing from master, 2,026 from using, 11,566 matched
	
	drop			if _a == 2
	
* drop observations missing values (not in continuous)
	drop			if plotsize == .
	drop			if irr_any == .
	drop			if pest_any == .
	drop			if herb_any == .
	*** no observations dropped

	drop			_11a1 _11b1 _11c1 _11c2 _a2 _a
	
	
* **********************************************************************
* 1b - create total farm and maize variables
* **********************************************************************

* rename some variables
	rename			hrv_labor labordays
	rename			fert_use fert

* recode binary variables
	replace			fert_any = 0 if fert_any == 2
	replace			pest_any = 0 if pest_any == 2
	replace			herb_any = 0 if herb_any == 2
	replace			irr_any  = 0 if irr_any  == 2
	
* generate mz_variables
	gen				mz_lnd = plotsize	if mz_hrv != .
	gen				mz_lab = labordays	if mz_hrv != .
	gen				mz_frt = fert		if mz_hrv != . 
	gen				mz_pst = pest_any	if mz_hrv != .
	gen				mz_hrb = herb_any	if mz_hrv != .
	gen				mz_irr = irr_any	if mz_hrv != .

* collapse to plot level
	collapse (sum)	vl_hrv plotsize labordays fert ///
						mz_hrv mz_lnd mz_lab mz_frt ///
			 (max)	pest_any herb_any irr_any  ///
						mz_pst mz_hrb mz_irr mz_damaged, ///
						by(hhid plotid plot_id zone state lga sector ///
						ea wgt18 wgt_pnl old_new track)

* replace non-maize harvest values as missing
	tab				mz_damaged, missing
	loc	mz			mz_lnd mz_lab mz_frt mz_pst mz_hrb mz_irr
	foreach v of varlist `mz'{
	    replace		`v' = . if mz_damaged == . & mz_hrv == 0	
	}	
	replace			mz_hrv = . if mz_damaged == . & mz_hrv == 0		
	drop 			mz_damaged
	*** 4458 changes made
	
	
* **********************************************************************
* 2 - impute: total farm value, labor, fertilizer use 
* **********************************************************************

* ******************************************************************************
* FOLLOWING WB: we will construct production variables on a per hectare basis,
* and conduct imputation on the per hectare variables. We will then create 
* 'imputed' versions of the non-per hectare variables (e.g. harvest, 
* value) by multiplying the imputed per hectare vars by plotsize. 
* This approach relies on the assumptions that the 1) GPS measurements are 
* reliable, and 2) outlier values are due to errors in the respondent's 
* self-reported production quantities (see rs_plot.do)
* ******************************************************************************


* **********************************************************************
* 2a - impute: total value
* **********************************************************************
	
* construct production value per hectare
	gen				vl_yld = vl_hrv / plotsize
	assert 			!missing(vl_yld)
	lab var			vl_yld "value of yield (2015 USD/ha)"

* impute value per hectare outliers 
	sum				vl_yld
	bysort state :	egen stddev = sd(vl_yld) if !inlist(vl_yld,.,0)
	recode stddev	(.=0)
	bysort state :	egen median = median(vl_yld) if !inlist(vl_yld,.,0)
	bysort state :	egen replacement = median(vl_yld) if  ///
						(vl_yld <= median + (3 * stddev)) & ///
						(vl_yld >= median - (3 * stddev)) & !inlist(vl_yld,.,0)
	bysort state :	egen maxrep = max(replacement)
	bysort state :	egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		vl_yldimp = vl_yld
	replace  		vl_yldimp = maxrep if !((vl_yld < median + (3 * stddev)) ///
						& (vl_yld > median - (3 * stddev))) ///
						& !inlist(vl_yld,.,0) & !mi(maxrep)
	tabstat			vl_yld vl_yldimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 663 to 521
	*** reduces max from 43844 to 20366
	
	drop			stddev median replacement maxrep minrep
	lab var			vl_yldimp	"value of yield (2015 USD/ha), imputed"

* inferring imputed harvest value from imputed harvest value per hectare
	generate		vl_hrvimp = vl_yldimp * plotsize 
	lab var			vl_hrvimp "value of harvest (2015 USD), imputed"
	lab var			vl_hrv "value of harvest (2015 USD)"
	
	
* **********************************************************************
* 2b - impute: labor
* **********************************************************************

* construct labor days per hectare
	gen				labordays_ha = labordays / plotsize, after(labordays)
	lab var			labordays_ha "farm labor use (days/ha)"
	sum				labordays labordays_ha

* impute labor outliers, right side only 
	sum				labordays_ha, detail
	bysort state :	egen stddev = sd(labordays_ha) if !inlist(labordays_ha,.,0)
	recode 			stddev (.=0)
	bysort state :	egen median = median(labordays_ha) if !inlist(labordays_ha,.,0)
	bysort state :	egen replacement = median(labordays_ha) if ///
						(labordays_ha <= median + (3 * stddev)) & ///
						(labordays_ha >= median - (3 * stddev)) & !inlist(labordays_ha,.,0)
	bysort state :	egen maxrep = max(replacement)
	bysort state :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				labordays_haimp = labordays_ha, after(labordays_ha)
	replace 		labordays_haimp = maxrep if !((labordays_ha < median + (3 * stddev)) ///
						& (labordays_ha > median - (3 * stddev))) ///
						& !inlist(labordays_ha,.,0) & !mi(maxrep)
	tabstat 		labordays_ha labordays_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 116 to 96
	*** reduces max from 2475 to 1199

	drop			stddev median replacement maxrep minrep
	lab var			labordays_haimp	"farm labor use (days/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				labordaysimp = labordays_haimp * plotsize, after(labordays)
	lab var			labordaysimp "farm labor (days), imputed"
	
	
* **********************************************************************
* 2c - impute: fertilizer
* **********************************************************************

* construct fertilizer use per hectare
	gen				fert_ha = fert / plotsize, after(fert)
	lab var			fert_ha "fertilizer use (kg/ha)"
	sum				fert fert_ha

* impute labor outliers, right side only 
	sum				fert_ha, detail
	bysort state :	egen stddev = sd(fert_ha) if !inlist(fert_ha,.,0)
	recode 			stddev (.=0)
	bysort state :	egen median = median(fert_ha) if !inlist(fert_ha,.,0)
	bysort state :	egen replacement = median(fert_ha) if ///
						(fert_ha <= median + (3 * stddev)) & ///
						(fert_ha >= median - (3 * stddev)) & !inlist(fert_ha,.,0)
	bysort state :	egen maxrep = max(replacement)
	bysort state :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				fert_haimp = fert_ha, after(fert_ha)
	replace 		fert_haimp = maxrep if !((fert_ha < median + (3 * stddev)) ///
						& (fert_ha > median - (3 * stddev))) ///
						& !inlist(fert_ha,.,0) & !mi(maxrep)
	tabstat 		fert_ha fert_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 177 to 145
	*** reduces max from 12039 to 6087
	
	drop			stddev median replacement maxrep minrep
	lab var			fert_haimp	"fertilizer use (kg/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				fertimp = fert_haimp * plotsize, after(fert)
	lab var			fertimp "fertilizer (kg), imputed"
	lab var			fert "fertilizer (kg)"


* **********************************************************************
* 3 - impute: maize yield, labor, fertilizer use 
* **********************************************************************


* **********************************************************************
* 3a - impute: maize yield
* **********************************************************************

* construct maize yield
	gen				mz_yld = mz_hrv / mz_lnd, after(mz_hrv)
	lab var			mz_yld	"maize yield (kg/ha)"

*maybe imputing zero values	
	
* impute yield outliers
	sum				mz_yld
	bysort state : egen stddev = sd(mz_yld) if !inlist(mz_yld,.,0)
	recode 			stddev (.=0)
	bysort state : egen median = median(mz_yld) if !inlist(mz_yld,.,0)
	bysort state : egen replacement = median(mz_yld) if /// 
						(mz_yld <= median + (3 * stddev)) & ///
						(mz_yld >= median - (3 * stddev)) & !inlist(mz_yld,.,0)
	bysort state : egen maxrep = max(replacement)
	bysort state : egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		mz_yldimp = mz_yld, after(mz_yld)
	replace  		mz_yldimp = maxrep if !((mz_yld < median + (3 * stddev)) ///
					& (mz_yld > median - (3 * stddev))) ///
					& !inlist(mz_yld,.,0) & !mi(maxrep)
	tabstat 		mz_yld mz_yldimp, ///
					f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 1496 to 1255
	*** reduces max from 34728 to 14632
					
	drop 			stddev median replacement maxrep minrep
	lab var 		mz_yldimp "maize yield (kg/ha), imputed"

* inferring imputed harvest quantity from imputed yield value 
	generate 		mz_hrvimp = mz_yldimp * mz_lnd, after(mz_hrv)
	lab var 		mz_hrvimp "maize harvest quantity (kg), imputed"
	lab var 		mz_hrv "maize harvest quantity (kg)"

	
* **********************************************************************
* 3b - impute: maize labor
* **********************************************************************

* construct labor days per hectare
	gen				mz_lab_ha = mz_lab / mz_lnd, after(labordays)
	lab var			mz_lab_ha "maize labor use (days/ha)"
	sum				mz_lab mz_lab_ha

* impute labor outliers, right side only 
	sum				mz_lab_ha, detail
	bysort state :	egen stddev = sd(mz_lab_ha) if !inlist(mz_lab_ha,.,0)
	recode 			stddev (.=0)
	bysort state :	egen median = median(mz_lab_ha) if !inlist(mz_lab_ha,.,0)
	bysort state :	egen replacement = median(mz_lab_ha) if ///
						(mz_lab_ha <= median + (3 * stddev)) & ///
						(mz_lab_ha >= median - (3 * stddev)) & !inlist(mz_lab_ha,.,0)
	bysort state :	egen maxrep = max(replacement)
	bysort state :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				mz_lab_haimp = mz_lab_ha, after(mz_lab_ha)
	replace 		mz_lab_haimp = maxrep if !((mz_lab_ha < median + (3 * stddev)) ///
						& (mz_lab_ha > median - (3 * stddev))) ///
						& !inlist(mz_lab_ha,.,0) & !mi(maxrep)
	tabstat 		mz_lab_ha mz_lab_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 123 to 100
	*** reduces max from 2463 to 1156

	drop			stddev median replacement maxrep minrep
	lab var			mz_lab_haimp	"maize labor use (days/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				mz_labimp = mz_lab_haimp * mz_lnd, after(mz_lab)
	lab var			mz_labimp "maize labor (days), imputed"

	
* **********************************************************************
* 3c - impute: maize fertilizer
* **********************************************************************

* construct fertilizer use per hectare
	gen				mz_frt_ha = mz_frt / mz_lnd, after(mz_frt)
	lab var			mz_frt_ha "fertilizer use (kg/ha)"
	sum				mz_frt mz_frt_ha

* impute fertilizer outliers, right side only 
	sum				mz_frt_ha, detail
	bysort state :	egen stddev = sd(mz_frt_ha) if !inlist(mz_frt_ha,.,0)
	recode 			stddev (.=0)
	bysort state :	egen median = median(mz_frt_ha) if !inlist(mz_frt_ha,.,0)
	bysort state :	egen replacement = median(mz_frt_ha) if ///
						(mz_frt_ha <= median + (3 * stddev)) & ///
						(mz_frt_ha >= median - (3 * stddev)) & !inlist(mz_frt_ha,.,0)
	bysort state :	egen maxrep = max(replacement)
	bysort state :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				mz_frt_haimp = mz_frt_ha, after(mz_frt_ha)
	replace 		mz_frt_haimp = maxrep if !((mz_frt_ha < median + (3 * stddev)) ///
						& (mz_frt_ha > median - (3 * stddev))) ///
						& !inlist(mz_frt_ha,.,0) & !mi(maxrep)
	tabstat 		mz_frt_ha mz_frt_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 230 to 191
	*** reduces max from 12039 to 4360

	drop			stddev median replacement maxrep minrep
	lab var			mz_frt_haimp	"fertilizer use (kg/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				mz_frtimp = mz_frt_haimp * mz_lnd, after(mz_frt)
	lab var			mz_frtimp "fertilizer (kg), imputed"
	lab var			mz_frt "fertilizer (kg)"

	
* **********************************************************************
* 4 - collapse to household level
* **********************************************************************


* **********************************************************************
* 4a - generate total farm variables
* **********************************************************************

* generate plot area
	bysort			hhid (plot_id) : egen tf_lnd = sum(plotsize)
	lab var			tf_lnd	"Total farmed area (ha)"
	assert			tf_lnd > 0 
	sum				tf_lnd, detail

* value of harvest
	bysort			hhid (plot_id) : egen tf_hrv = sum(vl_hrvimp)
	lab var			tf_hrv	"Total value of harvest (2015 USD)"
	sum				tf_hrv, detail
	
* value of yield
	generate		tf_yld = tf_hrv / tf_lnd
	lab var			tf_yld	"value of yield (2015 USD/ha)"
	sum				tf_yld, detail
	*** the max 4631.99 USD/ha, seems low
	
* labor
	bysort 			hhid (plot_id) : egen lab_tot = sum(labordaysimp)
	generate		tf_lab = lab_tot / tf_lnd
	lab var			tf_lab	"labor rate (days/ha)"
	sum				tf_lab, detail
	*** the max 2702.43 days per hectare

* fertilizer
	bysort 			hhid (plot_id) : egen fert_tot = sum(fertimp)
	generate		tf_frt = fert_tot / tf_lnd
	lab var			tf_frt	"fertilizer rate (kg/ha)"
	sum				tf_frt, detail

* pesticide
	bysort 			hhid (plot_id) : egen tf_pst = max(pest_any)
	lab var			tf_pst	"Any plot has pesticide"
	tab				tf_pst
	
* herbicide
	bysort 			hhid (plot_id) : egen tf_hrb = max(herb_any)
	lab var			tf_hrb	"Any plot has herbicide"
	tab				tf_hrb
	
* irrigation
	bysort 			hhid (plot_id) : egen tf_irr = max(irr_any)
	lab var			tf_irr	"Any plot has irrigation"
	tab				tf_irr

* **********************************************************************
* 4b - generate maize variables 
* **********************************************************************	
	
* generate plot area
	bysort			hhid (plot_id) :	egen cp_lnd = sum(mz_lnd) ///
						if mz_hrvimp != .
	lab var			cp_lnd	"Total maize area (ha)"
	assert			cp_lnd > 0 
	sum				cp_lnd, detail

* value of harvest
	bysort			hhid (plot_id) :	egen cp_hrv = sum(mz_hrvimp) ///
						if mz_hrvimp != .
	lab var			cp_hrv	"Total quantity of maize harvest (kg)"
	sum				cp_hrv, detail
	
* value of yield
	generate		cp_yld = cp_hrv / cp_lnd if mz_hrvimp != .
	lab var			cp_yld	"Maize yield (kg/ha)"
	sum				cp_yld, detail
	
* labor
	bysort 			hhid (plot_id) : egen lab_mz = sum(mz_labimp) ///
						if mz_hrvimp != .
	generate		cp_lab = lab_mz / cp_lnd
	lab var			cp_lab	"labor rate for maize (days/ha)"
	sum				cp_lab, detail

* fertilizer
	bysort 			hhid (plot_id) : egen fert_mz = sum(mz_frtimp) ///
						if mz_hrvimp != .
	generate		cp_frt = fert_mz / cp_lnd
	lab var			cp_frt	"fertilizer rate for maize (kg/ha)"
	sum				cp_frt, detail

* pesticide
	bysort 			hhid (plot_id) : egen cp_pst = max(mz_pst) /// 
						if mz_hrvimp != .
	lab var			cp_pst	"Any maize plot has pesticide"
	tab				cp_pst
	
* herbicide
	bysort 			hhid (plot_id) : egen cp_hrb = max(mz_hrb) ///
						if mz_hrvimp != .
	lab var			cp_hrb	"Any maize plot has herbicide"
	tab				cp_hrb
	
* irrigation
	bysort 			hhid (plot_id) : egen cp_irr = max(mz_irr) ///
						if mz_hrvimp != .
	lab var			cp_irr	"Any maize plot has irrigation"
	tab				cp_irr

* verify values are accurate
	sum				tf_* cp_*
	
* collapse to the household level
	loc	cp			cp_*
	foreach v of varlist `cp'{
	    replace		`v' = 0 if `v' == .
	}		
	
* count before collapse
	count
	*** 7124 obs
	
	collapse (max) 	tf_* cp_*, by(zone state lga sector ea hhid ///
						wgt18 wgt_pnl old_new track)

* count after collapse 
	count 
	*** drops to 3238 observations 
	
* return non-maize production to missing
	replace			cp_yld = . if cp_yld == 0
	replace			cp_irr = 1 if cp_irr > 0	
	replace			cp_irr = . if cp_yld == . 
	replace			cp_hrb = 1 if cp_hrb > 0
	replace			cp_hrb = . if cp_yld == .
	replace			cp_pst = 1 if cp_pst > 0
	replace			cp_pst = . if cp_yld == .
	replace			cp_frt = . if cp_yld == .
	replace			cp_lnd = . if cp_yld == .
	replace			cp_hrv = . if cp_yld == .
	replace			cp_lab = . if cp_yld == .

* verify values are accurate
	sum				tf_* cp_*
	
* label variables
	lab var			tf_lnd	"Total farmed area (ha)"
	lab var			tf_hrv	"Total value of harvest (2015 USD)"
	lab var			tf_yld	"value of yield (2015 USD/ha)"
	lab var			tf_lab	"labor rate (days/ha)"
	lab var			tf_frt	"fertilizer rate (kg/ha)"
	lab var			tf_pst	"Any plot has pesticide"
	lab var			tf_hrb	"Any plot has herbicide"
	lab var			tf_irr	"Any plot has irrigation"
	lab var			cp_lnd	"Total maize area (ha)"
	lab var			cp_hrv	"Total quantity of maize harvest (kg)"
	lab var			cp_yld	"Maize yield (kg/ha)"
	lab var			cp_lab	"labor rate for maize (days/ha)"
	lab var			cp_frt	"fertilizer rate for maize (kg/ha)"
	lab var			cp_pst	"Any maize plot has pesticide"
	lab var			cp_hrb	"Any maize plot has herbicide"
	lab var			cp_irr	"Any maize plot has irrigation"
	
* impute missing labor
	sum 			tf_lab , detail			
	*** max is 1128, reasonable
	*** no imputation
	
* impute tf_hrv outliers
	sum 			tf_yld, detail
	*** max is 6275, also reasonable
	*** no imputation
					
* impute cp_lab
	sum 			cp_lab, detail
	*** max is 1128, also reasonable
	*** no imputation
	
* cp yield outliers
	sum 			cp_yld, detail
	*** max is 11,032, also reasonable
	*** no imputation
	
* unlike in other waves, at this stage variables look reasonable
* max of each is less than max of variable in other wave - EVEN AFTER - imputation
* so we do not impute anything at this stage
	
* **********************************************************************
* 5 - end matter, clean up to save
* **********************************************************************

* verify unique household id
	isid			hhid

* merge in geovars
	merge			m:1 hhid using "$root/NGA_geovars", force
	keep			if _merge == 3
	drop			_merge
	
* generate year identifier
	gen				year = 2018
	lab var			year "Year"
		
	order 			zone state lga sector ea hhid aez year /// 	
					wgt18 wgt_pnl old_new track ///
					tf_hrv tf_lnd tf_yld tf_lab tf_frt ///
					tf_pst tf_hrb tf_irr cp_hrv cp_lnd cp_yld cp_lab ///
					cp_frt cp_pst cp_hrb cp_irr
	compress
	describe
	summarize 
	
* saving production dataset
	save 			"$export/hhfinal_ghsy4.dta", replace

* close the log
	log	close

/* END */
