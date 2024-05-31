* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Edited on: 30 May 2024
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
	loc		root	=	"$data/household_data/nigeria/wave_3/refined"
	loc 	export	=	"$data/household_data/nigeria/wave_3/refined"
	loc 	logout	=	"$data/household_data/nigeria/logs"

* open log
	cap 	log 	close
	log 	using 	"`logout'/ghsy3_merge_wave_3", append

	
* **********************************************************************
* 1 - merge plot level data sets together
* **********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"`root'/ph_secta3i.dta", clear

	isid			cropplot_id
	
* merge in plot size data
	merge 			m:1 hhid plotid using "`root'/ph_sect11a1", generate(_11a1)
	*** 80 are missing in master, 10,414 matched
	*** most unmerged (457) are from using, meaning we lack production data
	*** per Malawi (rs_plot) we drop all unmerged observations

	drop			if _11a1 != 3
	
* merging in irrigation data
	merge			m:1 hhid plotid using "`root'/pp_sect11b1", generate(_11b1)
	*** none are missing in master, 10414 matched 
	*** we assume these are plots without irrigation
	
	replace			irr_any = 2 if irr_any == . & _11b1 == 1
	*** 0 changes made

	drop			if _11b1 == 2
	
* merging in planting labor data
	merge		m:1 hhid plotid using "`root'/pp_sect11c1", generate(_11c1)
	*** 0 are missing in master, 10414 matched
	
	drop			if _11c1 == 2
	*** not going to actually use planting labor in analysis - will omit

* merging in pesticide and herbicide use
	merge		m:1 hhid plotid using "`root'/ph_sect11c2", generate(_11c2)
	*** 1 missing in master, 10413 
	*** we assume these are plots without pest or herb

	replace			pest_any = 2 if pest_any == . & _11c2 == 1
	replace			herb_any = 2 if herb_any == . & _11c2 == 1
	*** 1 change made for each 
	
	drop			if _11c2 == 2

* merging in fertilizer use
	merge		m:1 hhid plotid using "`root'/ph_sect11d", generate(_11d)
	*** 2 missing from master, 10412 matched 
	*** we will impute the missing values later
	
	drop			if _11d == 2

* merging in harvest labor data
	merge		m:1 hhid plotid using "`root'/ph_secta2", generate(_a2)
	*** 1 missing from master, 10413 matched
	*** we will impute the missing values later
	*** only going to include harvest labor in analysis - will include this and rename generally
	*** can revisit this later

	drop			if _a2 == 2

* drop observations missing values (not in continuous)
	drop			if plotsize == .
	drop			if irr_any == .
	drop			if pest_any == .
	drop			if herb_any == .
	*** no observations dropped

	drop			_11a1 _11b1 _11c1 _11c2 _11d _a2
	
	
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
						by(hhid plotid plot_id zone state lga sector ea)

* replace non-maize harvest values as missing
	tab				mz_damaged, missing
	loc	mz			mz_lnd mz_lab mz_frt mz_pst mz_hrb mz_irr
	foreach v of varlist `mz'{
	    replace		`v' = . if mz_damaged == . & mz_hrv == 0	
	}	
	replace			mz_hrv = . if mz_damaged == . & mz_hrv == 0		
	drop 			mz_damaged
	*** 3,637 changes made
	
	
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
	*** reduces mean from 1054 to 825
	*** reduces max from 31981 to 14118
	
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
	*** reduces mean from 221 to 181
	*** reduces max from 7262 to 3687

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
	*** reduces mean from 119 to 99
	*** reduces max from 6646 to 3534
	
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
	*** reduces mean from 3386 to 2711
	*** reduces max from 59169 to 31002
					
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
	*** reduces mean from 258 to 206
	*** reduces max from 7262 to 2505

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
	*** reduces mean from 177 to 144
	*** reduces max from 6646 to 3228

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
	*** the max 174965 USD/ha is a bit high
	
* labor
	bysort 			hhid (plot_id) : egen lab_tot = sum(labordaysimp)
	generate		tf_lab = lab_tot / tf_lnd
	lab var			tf_lab	"labor rate (days/ha)"
	sum				tf_lab, detail
	*** the max 53291 days per hectare is a bit high

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
	*** 5367 obs
	
	collapse (max) tf_* cp_*, by(zone state lga sector ea hhid)

* count after collapse 
	count 
	*** 5367 to 2783 observations 
	
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
	*** max is determined by comparing the right end tail distribution to wave maxes using a kdensity peak.
	sum 			tf_yld tf_lab tf_hrv, detail			
	
	*kdensity 		tf_hrv if tf_hrv > 5000
	*** peak is at 5,250
	*kdensity		tf_yld if tf_yld > 9000
	*** peak is at 10,000
	*kdensity 		tf_lab if tf_lab > 1400
	*** peak is around 1,900
	*kdensity		tf_lnd if tf_yld > 10000
	
	*kdensity tf_yld if tf_lnd < 0.1 & tf_yld < 10000
	*** max tf_yld when lnd is 0.1
	
	*kdensity tf_lab if tf_lnd < 0.1 & tf_lab > 400
	*kdensity tf_lab if tf_lnd < 0.1 & tf_lab < 10000

	replace 		tf_lab = . if tf_lab > 500 & tf_lnd < 0.1
	*** 40 changes
	replace 		tf_lab = . if tf_lab > 1900
	*** 6 changes
	replace 		tf_hrv = . if tf_yld > 1000 & tf_lnd < 0.1
	*** 84 changes

	*scatter 		tf_yld tf_lnd 
	
* impute missing labor
	sum 			tf_lab
	
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed tf_lab // identify tf_lab as the variable being imputed
	sort			hhid state zone, stable // sort to ensure reproducability of results
	mi impute 		pmm tf_lab i.state tf_lnd, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 	unset	
	
	*** review imputation
	sum				tf_lab_1_
	replace 		tf_lab = tf_lab_1_
	sum 			tf_lab, detail
	*** mean 155, max 1883
	drop			mi_miss tf_lab_1_
	mdesc			tf_lab
	*** none missing

* impute tf_hrv outliers
	*kdensity 		tf_yld if tf_yld > 7300
	*** max is 11000
	sum 			tf_yld, detail
	*** mean 768, max 10768
	
	sum				tf_lnd tf_hrv  if tf_yld > 4595
	
	replace 		tf_hrv =. if tf_yld > 4595
	
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed tf_hrv // identify tf_hrv as the variable being imputed
	sort			hhid state zone, stable // sort to ensure reproducability of results
	mi impute 		pmm tf_hrv i.state tf_lnd tf_lab tf_frt, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi unset
	
	sort 			tf_hrv
	replace    		tf_hrv = tf_hrv_1_	if 	tf_hrv == .
	replace 		tf_yld = tf_hrv / tf_lnd
	sum 			tf_yld, detail
	*** mean 835, max 28727
	
	replace			tf_hrv = 1700 if tf_yld > 25000
	replace			tf_hrv = 1300 if tf_yld > 20500 & tf_yld < 25000
	replace			tf_hrv = 480 if tf_yld > 20000 & tf_yld < 20500
	*** 3 changes made
	
	replace 		tf_yld = tf_hrv / tf_lnd
	sum 			tf_yld, detail
	*** mean 820, max 18830
	
	mdesc 			tf_yld
	*** 0 missing
	drop 			mi_miss tf_hrv_1_ 
	
* impute cp_lab
	sum 			cp_lab, detail
	*scatter			cp_lnd cp_lab
	*kdensity 		cp_lab if cp_lnd < 1 & cp_lab < 500
	*** max is 50
	
	replace 		cp_lab = . if cp_lab > 1390
	*** 15 changes
	
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed cp_lab // identify cp_lab as the variable being imputed
	sort			hhid state zone, stable // sort to ensure reproducability of results
	mi impute 		pmm cp_lab i.state cp_lnd, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
	mi 	unset	
	
	*** review imputation
	sum				cp_lab_1_
	replace 		cp_lab = cp_lab_1_
	sum 			cp_lab, detail
	*** mean 180, max 1385
	drop			mi_miss cp_lab_1_
	mdesc			cp_lab if cp_lnd !=.
	*** none missing
	
* cp yield outliers
	sum 			cp_yld, detail
	*** mean 2705, max is 31021
	sum 			cp_hrv, detail
	*** mean 897, max 10466
	*kdensity cp_yld if cp_yld > 20000
	
	sum cp_hrv if cp_lnd < 0.5 & cp_yld > 12000, detail
	
	* change outliers to missing
	replace 		cp_hrv = . if cp_yld > 12000 & cp_lnd < 0.5
	*** 54 changes made
	replace 		cp_hrv = . if cp_lnd < .03
	*** 23 changes

* impute missing values (impute in stages to get imputation near similar land values)
	sum 			cp_hrv
	
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed cp_hrv // identify cp_hrv as the variable being imputed
	sort			hhid state zone, stable // sort to ensure reproducability of results
	mi impute 		pmm cp_hrv i.state cp_lnd cp_lab, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
									
	mi 				unset	

	sort 			cp_hrv
	replace 		cp_hrv = cp_hrv_1_ if cp_hrv == . 
	replace 		cp_yld = cp_hrv / cp_lnd
	sum 			cp_yld, detail
	*** mean 2442, max 75710

	drop mi_miss cp_hrv_1_	

	replace			cp_hrv = . if cp_yld > 12834
	*** 15 changes made
	
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed cp_hrv // identify cp_hrv as the variable being imputed
	sort			hhid state zone, stable // sort to ensure reproducability of results
	mi impute 		pmm cp_hrv i.state cp_lnd cp_lab, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
									
	mi 				unset	

	sort 			cp_hrv
	replace 		cp_hrv = cp_hrv_1_ if cp_hrv == . 
	replace 		cp_yld = cp_hrv / cp_lnd
	sum 			cp_yld, detail
	*** mean 2588, max 241736
	
	drop mi_miss cp_hrv_1_	
	
	replace 		cp_hrv = . if cp_yld > 11620
	*** 15 changes

* impute missing values (impute in stages to get imputation near similar land values)
	sum 			cp_hrv
	
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed cp_hrv // identify cp_hrv as the variable being imputed
	sort			hhid state zone, stable // sort to ensure reproducability of results
	mi impute 		pmm cp_hrv i.state cp_lnd cp_lab, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
						
	mi 				unset	

	sort 			cp_hrv
	replace 		cp_hrv = cp_hrv_1_
	replace 		cp_yld = cp_hrv / cp_lnd
	sum 			cp_yld, detail
	*** mean 2337, max is 115936
	
	drop mi_miss cp_hrv_1_

	replace 		cp_hrv = . if cp_yld > 11620
	*** 5 changes

* impute missing values (impute in stages to get imputation near similar land values)
	sum 			cp_hrv
	
	mi set 			wide 	// declare the data to be wide.
	mi xtset		, clear 	// clear any xtset that may have had in place previously
	mi register		imputed cp_hrv // identify cp_hrv as the variable being imputed
	sort			hhid state zone, stable // sort to ensure reproducability of results
	mi impute 		pmm cp_hrv i.state cp_lnd cp_lab, add(1) rseed(245780) ///
						noisily dots force knn(5) bootstrap
						
	mi 				unset	

	sort 			cp_hrv
	replace 		cp_hrv = cp_hrv_1_
	replace 		cp_yld = cp_hrv / cp_lnd
	sum 			cp_yld, detail
	*** mean 2210, max is 20680
	
	drop mi_miss cp_hrv_1_

	replace 		cp_hrv = 110 if cp_yld > 11620
	*** 2 changes
	replace 		cp_yld = cp_hrv / cp_lnd
	sum 			cp_yld, detail
	*** mean 2202, max is 11503
	
	mdesc			cp_yld cp_hrv if cp_lnd != .
	*** none missing

* **********************************************************************
* 5 - end matter, clean up to save
* **********************************************************************

* verify unique household id
	isid			hhid

* merge in geovars
	merge			m:1 hhid using "`root'/NGA_geovars", force
	keep			if _merge == 3
	drop			_merge
	
* generate year identifier
	gen				year = 2015
	lab var			year "Year"
		
	order 			zone state lga sector ea hhid aez year /// 	
					tf_hrv tf_lnd tf_yld tf_lab tf_frt ///
					tf_pst tf_hrb tf_irr cp_hrv cp_lnd cp_yld cp_lab ///
					cp_frt cp_pst cp_hrb cp_irr
	compress
	describe
	summarize 
	
* saving production dataset
	save 			"`export'/hhfinal_ghsy3.dta", replace

* close the log
	log	close

/* END */
