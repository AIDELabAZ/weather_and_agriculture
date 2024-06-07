* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 4 June 2024
* Edited by: jdm
* Stata v.18

* does
	* merges individual cleaned plot datasets together
	* imputes values for continuous variables
	* collapses to wave 2 plot level data to household level for combination with other waves

* assumes
	* previously cleaned household datasets

* TO DO:
	* done

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=	"$data/household_data/niger/wave_2/refined"
	loc 	export	=	"$data/household_data/niger/wave_2/refined"
	loc 	logout	=	"$data/household_data/niger/logs"

* open log
	cap		log 	close
	log 	using 	"`logout'/2014_niger_merge", append

	
* **********************************************************************
* 1 - combine data sets and merge to parcel level
* **********************************************************************
	
	
* **********************************************************************
* 1a - merge plot level data sets together
* **********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"`root'/2014_as2e1p2.dta", clear

	isid 			hhid_y2 field parcel cropid

* no irrigation, no seed use rate
	gen				irr_any = 0
	lab var			irr_any "=1 if any irrigation was used"
	
* merge in plot size data
	merge 			m:1 hhid_y2 field parcel using "`root'/2014_as1p1", generate(_as1p1)
	*** 270 not matched from master out of 1307 not matched 
	*** most unmerged (1037) are from using, meaning we lack production data
	*** per Malawi (rs_plot) we drop all unmerged observations
	
	drop			if _as1p1 != 3

* merging in fertilizer, pesticide, herbicide use and labor
	merge		m:1 hhid_y2 field parcel using "`root'/2014_as2ap1", generate(_as2ap1)
	*** 43 not matched from master, 1130 not matched from using 
	*** we assume these are plots without inputs
	
	replace			pest_any = 0 if pest_any == .
	replace			herb_any = 0 if herb_any == .
	replace			fert_use = 0 if fert_use == .
	replace			fert_any = 0 if fert_any == . & fert_use == 0
	*** 43 changes made
	
	lab def			yesno 0 "No" 1 "Yes"
	lab val			pest_any yesno
	lab val			herb_any yesno
	lab val			fert_any yesno
	lab val			irr_any yesno
	
* 1130 did not match from using 	
	drop			if _as2ap1 == 2

* drop observations missing values (not in continuous)
	drop			if plotsize == .
	drop			if pest_any == .
	drop			if herb_any == .
	*** no observations dropped
		
* merging in plant labor data
	merge		m:1 hhid_y2 field parcel using "`export'/2014_as2ap2", generate(_as2ap2)
	*** 130 missing in master, 385 not matched from using 
	*** total of 8259 matched 
	
* 1121 did not match from using 	
	drop			if _as2ap2 == 2
	
* set labor in 130 unmatched observations to zero
	replace			plant_labor = 0 if plant_labor == . & _as2ap2 == 1
	replace			plant_labor_all = 0 if plant_labor_all == . & _as2ap2 == 1
	replace			harvest_labor = 0 if harvest_labor == . & _as2ap2 == 1
	replace			harvest_labor_all = 0 if harvest_labor_all == . & _as2ap2 == 1

* merge in regional information 
	merge m:1		hhid_y2 using "`export'/2014_ms00p1", generate(_ms00p1)
	*** 8389 matched, 0 from master not matched, 1876 from using (which is fine)
	
	keep 			if _ms00p1 == 3
	
	rename 			zd enumeration 
	label var 		region "region"
	
	drop			_as2ap1 _as1p1 _as2ap2 _ms00p1

	
* **********************************************************************
* 1b - create total farm and maize variables
* **********************************************************************

* rename some variables
	gen				labordays = prep_labor + plant_labor + harvest_labor
	lab var			labordays "farm labor (days)"
	rename			fert_use fert
	replace			mz_damaged = . if mz_hrv == .

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
						by(hhid_y2 hid clusterid hh_num extension field ///
						parcel region dept canton enumeration pw)

* replace non-maize harvest values as missing
	tab				mz_damaged, missing
	loc	mz			mz_lnd mz_lab mz_frt mz_pst mz_hrb mz_irr
	foreach v of varlist `mz'{
	    replace		`v' = . if mz_damaged == . & mz_hrv == 0	
	}	
	replace			mz_hrv = . if mz_damaged == . & mz_hrv == 0		
	drop 			mz_damaged
	*** 814 changes made	

	
* **********************************************************************
* 2 - impute: yield, value per hectare, labor (both), fertilizer use 
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
* 2a - impute: value
* **********************************************************************
	
* construct production value per hectare
	gen				vl_yld = vl_hrv / plotsize
	assert 			!missing(vl_yld)
	lab var			vl_yld "value of yield (2010USD/ha)"

* impute value per hectare outliers 
	sum				vl_yld
	bysort dept :	egen stddev = sd(vl_yld) if !inlist(vl_yld,.,0)
	recode stddev	(.=0)
	bysort dept :	egen median = median(vl_yld) if !inlist(vl_yld,.,0)
	bysort dept :	egen replacement = median(vl_yld) if  ///
						(vl_yld <= median + (3 * stddev)) & ///
						(vl_yld >= median - (3 * stddev)) & !inlist(vl_yld,.,0)
	bysort dept :	egen maxrep = max(replacement)
	bysort dept :	egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		vl_yldimp = vl_yld
	replace  		vl_yldimp = maxrep if !((vl_yld < median + (3 * stddev)) ///
						& (vl_yld > median - (3 * stddev))) ///
						& !inlist(vl_yld,.,0) & !mi(maxrep)
	tabstat			vl_yld vl_yldimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 864 to 131
	*** max is high - 165,049

						
	drop			stddev median replacement maxrep minrep
	lab var			vl_yldimp	"value of yield (2010USD/ha), imputed"

* inferring imputed harvest value from imputed harvest value per hectare
	generate		vl_hrvimp = vl_yldimp * plotsize 
	lab var			vl_hrvimp "value of harvest (2010USD), imputed"
	lab var			vl_hrv "value of harvest (2010USD)"
	
	sum				vl_hrv vl_hrvimp 
	*** reduces mean from 55 to 54
	*** no change in max 
	
	
* **********************************************************************
* 2b - impute: labor
* **********************************************************************

* construct labor days per hectare
	gen				labordays_ha = labordays / plotsize, after(labordays)
	lab var			labordays_ha "farm labor use (days/ha)"
	sum				labordays labordays_ha

* impute labor outliers, right side only 
	sum				labordays_ha, detail
	bysort dept :	egen stddev = sd(labordays_ha) if !inlist(labordays_ha,.,0)
	recode 			stddev (.=0)
	bysort dept :	egen median = median(labordays_ha) if !inlist(labordays_ha,.,0)
	bysort dept :	egen replacement = median(labordays_ha) if ///
						(labordays_ha <= median + (3 * stddev)) & ///
						(labordays_ha >= median - (3 * stddev)) & !inlist(labordays_ha,.,0)
	bysort dept :	egen maxrep = max(replacement)
	bysort dept :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				labordays_haimp = labordays_ha, after(labordays_ha)
	replace 		labordays_haimp = maxrep if !((labordays_ha < median + (3 * stddev)) ///
						& (labordays_ha > median - (3 * stddev))) ///
						& labordays_ha != 0 & !mi(maxrep)
	tabstat 		labordays_ha labordays_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 1882 to 328
	*** max is 340,000 relatively high
	
	drop			stddev median replacement maxrep minrep
	lab var			labordays_haimp	"farm labor use (days/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				labordaysimp = labordays_haimp * plotsize, after(labordays)
	lab var			labordaysimp "farm labor (days), imputed"

	sum				labordays labordaysimp 
	*** reduces mean from 122 to 119
	*** no change in max
	

* **********************************************************************
* 2c - impute: fertilizer
* **********************************************************************

* construct fertilizer use per hectare
	gen				fert_ha = fert / plotsize, after(fert)
	lab var			fert_ha "fertilizer use (kg/ha)"
	sum				fert fert_ha

* impute fert outliers, right side only 
	sum				fert_ha, detail
	bysort dept :	egen stddev = sd(fert_ha) if !inlist(fert_ha,.,0)
	recode 			stddev (.=0)
	bysort dept :	egen median = median(fert_ha) if !inlist(fert_ha,.,0)
	bysort dept :	egen replacement = median(fert_ha) if ///
						(fert_ha <= median + (3 * stddev)) & ///
						(fert_ha >= median - (3 * stddev)) & !inlist(fert_ha,.,0)
	bysort dept :	egen maxrep = max(replacement)
	bysort dept :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				fert_haimp = fert_ha, after(fert_ha)
	replace 		fert_haimp = maxrep if !((fert_ha < median + (3 * stddev)) ///
						& (fert_ha > median - (3 * stddev))) ///
						& fert_ha != 0 & !mi(maxrep)
	tabstat 		fert_ha fert_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 62 to 6
	*** max is at 1706
	
	drop			stddev median replacement maxrep minrep
	lab var			fert_haimp	"fertilizer use (kg/ha), imputed"

* make fertilizer based on imputed fertilizer per hectare
	gen				fertimp = fert_haimp * plotsize, after(fert)
	lab var			fertimp "fertilizer (kg), imputed"
	lab var			fert "fertilizer (kg)"

	sum				fert_ha fert_haimp
	*** mean reduces from 62 to 5
	*** max is now 1706
	

* **********************************************************************
* 3 - impute: millet yield, labor, fertilizer use 
* **********************************************************************

* **********************************************************************
* 3a - impute: millet yield
* **********************************************************************

* construct maize yield
	gen				mz_yld = mz_hrv / plotsize, after(mz_hrv)
	lab var			mz_yld	"millet yield (kg/ha)"

* impute zero values	
	
* impute yield outliers
	sum				mz_yld mz_hrv
	bysort dept :	egen stddev = sd(mz_yld) if !inlist(mz_yld,.,0)
	recode 			stddev (.=0)
	bysort dept :	egen median = median(mz_yld) if !inlist(mz_yld,.,0)
	bysort dept :	egen replacement = median(mz_yld) if /// 
						(mz_yld <= median + (3 * stddev)) & ///
						(mz_yld >= median - (3 * stddev)) & !inlist(mz_yld,.,0)
	bysort dept :	egen maxrep = max(replacement)
	bysort dept :	egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		mz_yldimp = mz_yld, after(mz_yld)
	replace  		mz_yldimp = maxrep if !((mz_yld < median + (3 * stddev)) ///
						& (mz_yld > median - (3 * stddev))) ///
						& !inlist(mz_yld,.,0) & !mi(maxrep)
	tabstat 		mz_yld mz_yldimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 2516 to 183
	*** the outliers are now 112,000 from 1,500,000

					
	drop 			stddev median replacement maxrep minrep
	lab var 		mz_yldimp "millet yield (kg/ha), imputed"

* inferring imputed harvest quantity from imputed yield value 
	generate 		mz_hrvimp = mz_yldimp * plotsize, after(mz_hrv)
	lab var 		mz_hrvimp "millet harvest quantity (kg), imputed"
	lab var 		mz_hrv "millet harvest quantity (kg)"

	sum				mz_hrv mz_hrvimp
	*** reduces mean from 144 to 142
	*** max at 710 - no change 


* **********************************************************************
* 3b - impute: millet labor
* **********************************************************************

* construct labor days per hectare
	gen				mz_lab_ha = mz_lab / mz_lnd, after(labordays)
	lab var			mz_lab_ha "maize labor use (days/ha)"
	sum				mz_lab mz_lab_ha

* impute labor outliers, right side only 
	sum				mz_lab_ha, detail
	bysort region :	egen stddev = sd(mz_lab_ha) if !inlist(mz_lab_ha,.,0)
	recode 			stddev (.=0)
	bysort region :	egen median = median(mz_lab_ha) if !inlist(mz_lab_ha,.,0)
	bysort region :	egen replacement = median(mz_lab_ha) if ///
						(mz_lab_ha <= median + (3 * stddev)) & ///
						(mz_lab_ha >= median - (3 * stddev)) & !inlist(mz_lab_ha,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				mz_lab_haimp = mz_lab_ha, after(mz_lab_ha)
	replace 		mz_lab_haimp = maxrep if !((mz_lab_ha < median + (3 * stddev)) ///
						& (mz_lab_ha > median - (3 * stddev))) ///
						& !inlist(mz_lab_ha,.,0) & !mi(maxrep)
	tabstat 		mz_lab_ha mz_lab_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 1751 to 367
	
	drop			stddev median replacement maxrep minrep
	lab var			mz_lab_haimp	"maize labor use (days/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				mz_labimp = mz_lab_haimp * mz_lnd, after(mz_lab)
	lab var			mz_labimp "maize labor (days), imputed"

	sum				mz_lab mz_labimp
	*** reduces mean from 60 to 59
	*** no change in max


* **********************************************************************
* 3c - impute: millet fertilizer
* **********************************************************************

* construct fertilizer use per hectare
	gen				mz_frt_ha = mz_frt / mz_lnd, after(mz_frt)
	lab var			mz_frt_ha "fertilizer use (kg/ha)"
	sum				mz_frt mz_frt_ha

* impute labor outliers, right side only 
	sum				mz_frt_ha, detail
	bysort region :	egen stddev = sd(mz_frt_ha) if !inlist(mz_frt_ha,.,0)
	recode 			stddev (.=0)
	bysort region :	egen median = median(mz_frt_ha) if !inlist(mz_frt_ha,.,0)
	bysort region :	egen replacement = median(mz_frt_ha) if ///
						(mz_frt_ha <= median + (3 * stddev)) & ///
						(mz_frt_ha >= median - (3 * stddev)) & !inlist(mz_frt_ha,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				mz_frt_haimp = mz_frt_ha, after(mz_frt_ha)
	replace 		mz_frt_haimp = maxrep if !((mz_frt_ha < median + (3 * stddev)) ///
						& (mz_frt_ha > median - (3 * stddev))) ///
						& !inlist(mz_frt_ha,.,0) & !mi(maxrep)
	tabstat 		mz_frt_ha mz_frt_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	*** reduces mean from 74 to 4
	
	drop			stddev median replacement maxrep minrep
	lab var			mz_frt_haimp	"fertilizer use (kg/ha), imputed"

* make labor days based on imputed labor days per hectare
	gen				mz_frtimp = mz_frt_haimp * mz_lnd, after(mz_frt)
	lab var			mz_frtimp "fertilizer (kg), imputed"
	lab var			mz_frt "fertilizer (kg)"

	sum				mz_frt mz_frtimp
	*** reduces mean from 1.9 to 1.8
	*** no change in max
	

* **********************************************************************
* 4 - collapse to household level
* **********************************************************************

* **********************************************************************
* 4a - generate total farm variables
* **********************************************************************

* generate plot id for generating plot level aggregates
	sort			hhid_y2 field parcel
	egen			plot_id = group(hhid_y2 field parcel)

* generate plot area
	bysort			hhid_y2 (plot_id) : egen tf_lnd = sum(plotsize)
	assert			tf_lnd > 0 
	sum				tf_lnd, detail

* value of harvest
	bysort			hhid_y2 (plot_id) : egen tf_hrv = sum(vl_hrvimp)
	sum				tf_hrv, detail
	
* value of yield
	generate		tf_yld = tf_hrv / tf_lnd
	sum				tf_yld, detail
	
* labor
	bysort 			hhid_y2 (plot_id) : egen lab_tot = sum(labordaysimp)
	generate		tf_lab = lab_tot / tf_lnd
	sum				tf_lab, detail

* fertilizer
	bysort 			hhid_y2 (plot_id) : egen fert_tot = sum(fertimp)
	generate		tf_frt = fert_tot / tf_lnd
	sum				tf_frt, detail

* pesticide
	bysort 			hhid_y2 (plot_id) : egen tf_pst = max(pest_any)
	tab				tf_pst
	
* herbicide
	bysort 			hhid_y2 (plot_id) : egen tf_hrb = max(herb_any)
	tab				tf_hrb
	
* irrigation
	bysort 			hhid_y2 (plot_id) : egen tf_irr = max(irr_any)
	tab				tf_irr
	
	
* **********************************************************************
* 4b - generate maize variables 
* **********************************************************************	
	
* generate plot area
	bysort			hhid_y2 (plot_id) :	egen cp_lnd = sum(mz_lnd) ///
						if mz_hrvimp != .
	assert			cp_lnd > 0 
	sum				cp_lnd, detail

* value of harvest
	bysort			hhid_y2 (plot_id) :	egen cp_hrv = sum(mz_hrvimp) ///
						if mz_hrvimp != .
	sum				cp_hrv, detail
	
* value of yield
	generate		cp_yld = cp_hrv / cp_lnd if mz_hrvimp != .
	sum				cp_yld, detail
	
* labor
	bysort 			hhid_y2 (plot_id) : egen lab_mz = sum(mz_labimp) ///
						if mz_hrvimp != .
	generate		cp_lab = lab_mz / cp_lnd
	sum				cp_lab, detail

* fertilizer
	bysort 			hhid_y2 (plot_id) : egen fert_mz = sum(mz_frtimp) ///
						if mz_hrvimp != .
	generate		cp_frt = fert_mz / cp_lnd
	sum				cp_frt, detail

* pesticide
	bysort 			hhid_y2 (plot_id) : egen cp_pst = max(mz_pst) /// 
						if mz_hrvimp != .
	tab				cp_pst
	
* herbicide
	bysort 			hhid_y2 (plot_id) : egen cp_hrb = max(mz_hrb) ///
						if mz_hrvimp != .
	tab				cp_hrb
	
* irrigation
	bysort 			hhid_y2 (plot_id) : egen cp_irr = max(mz_irr) ///
						if mz_hrvimp != .
	tab				cp_irr

* verify values are accurate
	sum				tf_* cp_*
	
* collapse to the household level
	loc	cp			cp_*
	foreach v of varlist `cp'{
	    replace		`v' = 0 if `v' == .
	}		
	
	collapse (max)	tf_* cp_*, by(region dept canton enumeration ///
						clusterid hhid_y2 hid extension pw)
	*** we went from 5,805 to 2,223 observations 
	
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
	
	
* **********************************************************************
* 5 - end matter, clean up to save
* **********************************************************************

* generate year identifier
	gen				year = 2014
	lab var			year "Year"
	
* label variables
	lab var			tf_lnd	"Total farmed area (ha)"
	lab var			tf_hrv	"Total value of harvest (2010 USD)"
	lab var			tf_yld	"value of yield (2010 USD/ha)"
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
	lab var			cp_irr	"Any plot has irrigation"
	
	isid			hhid_y2
		
	order 			region dept canton enumeration clusterid pw ///
						hhid_y2 extension hid year tf_hrv tf_lnd tf_yld tf_lab tf_frt ///
						tf_pst tf_hrb tf_irr cp_hrv cp_lnd cp_yld ///
						cp_lab cp_frt cp_pst cp_hrb cp_irr
	compress
	describe
	summarize 
	
* saving production dataset
	save 			"`export'/hhfinal_ecvma2.dta", replace
	
* close the log
	log	close

/* END */