* Project: WB Weather
* Created on: July 2020
* Created by: mcg
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* merges individual cleaned plot datasets together
	* imputes values for continuous variables
	* collapses wave 2 plot level data to household level for combination with other waves

* assumes
	* previously cleaned household datasets

* TO DO:
	* done


* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc root = "$data/household_data/ethiopia/wave_2/refined"
	loc export = "$data/household_data/ethiopia/wave_2/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/ess2_merge", append
	

* **********************************************************************
* 1 - merging data sets
* **********************************************************************	
	
* **********************************************************************
* 1a - merge crop level data sets together
* **********************************************************************

* start by loading harvest quantity and value, since this is our limiting factor
	use 			"`root'/PH_SEC9", clear

	isid			holder_id parcel field crop_code
	
* merge in crop labor data
	merge 			1:1 holder_id parcel field crop_code using "`root'/PH_SEC10", generate(_10A)
	*** all unmerged obs coming from using data w/ labor values = 0
	
	drop 			if _10A == 2
	
* merge in crop labor data
	merge 			1:1 holder_id parcel field crop_code using "`root'/PP_SEC4", generate(_4A)
	*** 12 obs not matched from master
	
	keep			if _4A == 3
	

* ***********************************************************************
* 1b - pulling in prices fom price datasets
* ***********************************************************************	

* merging in sec 11 price data
* merging in ea level price data	
	merge 		m:1 crop_code region zone woreda ea using "`export'/w2_sect11_pea.dta"

	drop 		if _merge == 2
	drop 		_merge	
	
* merging in woreda level price data	
	merge 		m:1 crop_code region zone woreda using "`export'/w2_sect11_pworeda.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in zone level price data	
	merge 		m:1 crop_code region zone using "`export'/w2_sect11_pzone.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in region level price data	
	merge 		m:1 crop_code region using "`export'/w2_sect11_pregion.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in crop level price data	
	merge 		m:1 crop_code using "`export'/w2_sect11_pcrop.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* generating implied crop values, using sec 11 median price whee we have 10+ obs
	gen			croppricei = .
	
	replace 	croppricei = p_ea if n_ea>=10 & missing(croppricei)
	*** 696 replaced
	
	replace 	croppricei = p_woreda if n_woreda>=10 & missing(croppricei)
	*** 257 replaced
	
	replace 	croppricei = p_zone if n_zone>=10 & missing(croppricei)
	*** 3,506 replaced 
	
	replace 	croppricei = p_region if n_region>=10 & missing(croppricei)
	*** 8,742 replaced
	
	replace 	croppricei = p_crop if missing(croppricei)
	*** 4,998 replaced 

* examine the results
	sum			hvst_qty croppricei
	*** still missing prices for 658 obs
	*** assuming these missing prices all come from the same group of crops
	
	tab crop_code if croppricei != .
	tab crop_code if croppricei == .
	*** cactus, fennel, black pepper, ginger, white lumin, beer root, cabbage, carrot, 
	*** cauliflower, garlic, lettuce, spinach, boye/yam, amboshika, timiz kimem
	*** none of these crops appear when price isn't missing

* merging in sec 12 price data	
	drop 		p_ea- n_crop
	
* merging in ea level price data	
	merge 		m:1 crop_code region zone woreda ea using "`export'/w2_sect12_pea.dta"

	drop 		if _merge == 2
	drop 		_merge	
	
* merging in woreda level price data	
	merge 		m:1 crop_code region zone woreda using "`export'/w2_sect12_pworeda.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in zone level price data	
	merge 		m:1 crop_code region zone using "`export'/w2_sect12_pzone.dta"
	
	drop 		if _merge == 2
	drop 		_merge	
	
* merging in region level price data	
	merge 		m:1 crop_code region using "`export'/w2_sect12_pregion.dta"

	drop 		if _merge == 2
	drop 		_merge	
	
* merging in crop level price data	
	merge 		m:1 crop_code using "`export'/w2_sect12_pcrop.dta"	
	
	drop 		if _merge == 2
	drop 		_merge	
	
* generating implied crop values, using sec 12 median price whee we have 10+ obs	
	replace 	croppricei = p_ea if n_ea>=10 & missing(croppricei)
	*** 0 replaced
	
	replace 	croppricei = p_woreda if n_woreda>=10 & missing(croppricei)
	*** 0 replaced
	
	replace 	croppricei = p_zone if n_zone>=10 & missing(croppricei)
	*** 0 replaced 
	
	replace 	croppricei = p_region if n_region>=10 & missing(croppricei)
	*** 424 replaced
	
	replace 	croppricei = p_crop if missing(croppricei)
	*** 222 replaced 
	
* checking results
	sum			hvst_qty croppricei
	*** only missing prices for 12 obs
	*** assuming these missing prices all come from the same group of crops
	
	tab 		crop_code if croppricei != .
	tab 		crop_code if croppricei == .
	*** still missing prices for fennel, black pepper, cauliflower
	*** 8 obs total - no prices in either sec 11 or 12
	*** will drop
	
	drop		if croppricei == .
	*** 12 obs dropped
	
	drop		p_ea- n_crop
	
* investigate mean prices by crop	
	tab crop_code, summarize(croppricei) mean freq
		
	
* ***********************************************************************
* 1c - finding harvest values
* ***********************************************************************	
	
	summarize
	
* creating harvest values
	generate			hvst_value = hvst_qty*croppricei 

* currency conversion
	replace				hvst_value = hvst_value/22.672
	lab var				hvst_value "Value of Harvest (2015 USD)"
	

* **********************************************************************
* 1d - merging in plot level input data
* **********************************************************************

* merge in crop labor data
	merge 			m:1 holder_id parcel field using "`root'/PP_SEC3", generate(_3A)
	*** 543 obs not matched from master
	
	keep			if _3A == 3
	
	
* **********************************************************************
* 1e - create total farm and maize variables
* **********************************************************************

* rename some variables
	rename 			hvst_value vl_hrv
	gen				labordays = labordays_plant + labordays_harv
	rename			kilo_fert fert
	rename			pesticide_any pest_any
	rename 			herbicide_any herb_any
	rename			irrigated irr_any

* recode binary variables
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
						mz_pst mz_hrb mz_irr, ///
						by(holder_id parcel field pw2 hhid hhid2 ///
						region zone woreda ea rural field_id)

/* replace non-maize harvest values as missing
	tab				mz_damaged, missing
	loc	mz			mz_lnd mz_lab mz_frt mz_pst mz_hrb mz_irr
	foreach v of varlist `mz'{
	    replace		`v' = . if mz_damaged == . & mz_hrv == 0	
	}	
	replace			mz_hrv = . if mz_damaged == . & mz_hrv == 0		
	drop 			mz_damaged
	*** 1,834 changes made
	*/
	*** no mz_damaged in this data, should we look for it?	
	
	

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
	bysort region :	egen stddev = sd(vl_yld) if !inlist(vl_yld,.,0)
	recode stddev	(.=0)
	bysort region :	egen median = median(vl_yld) if !inlist(vl_yld,.,0)
	bysort region :	egen replacement = median(vl_yld) if  ///
						(vl_yld <= median + (3 * stddev)) & ///
						(vl_yld >= median - (3 * stddev)) & !inlist(vl_yld,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		vl_yldimp = vl_yld
	replace  		vl_yldimp = maxrep if !((vl_yld < median + (3 * stddev)) ///
						& (vl_yld > median - (3 * stddev))) ///
						& !inlist(vl_yld,.,0) & !mi(maxrep)
	tabstat			vl_yld vl_yldimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
						
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
	bysort region :	egen stddev = sd(labordays_ha) if !inlist(labordays_ha,.,0)
	recode 			stddev (.=0)
	bysort region :	egen median = median(labordays_ha) if !inlist(labordays_ha,.,0)
	bysort region :	egen replacement = median(labordays_ha) if ///
						(labordays_ha <= median + (3 * stddev)) & ///
						(labordays_ha >= median - (3 * stddev)) & !inlist(labordays_ha,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				labordays_haimp = labordays_ha, after(labordays_ha)
	replace 		labordays_haimp = maxrep if !((labordays_ha < median + (3 * stddev)) ///
						& (labordays_ha > median - (3 * stddev))) ///
						& !inlist(labordays_ha,.,0) & !mi(maxrep)
	tabstat 		labordays_ha labordays_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	
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
	bysort region :	egen stddev = sd(fert_ha) if !inlist(fert_ha,.,0)
	recode 			stddev (.=0)
	bysort region :	egen median = median(fert_ha) if !inlist(fert_ha,.,0)
	bysort region :	egen replacement = median(fert_ha) if ///
						(fert_ha <= median + (3 * stddev)) & ///
						(fert_ha >= median - (3 * stddev)) & !inlist(fert_ha,.,0)
	bysort region :	egen maxrep = max(replacement)
	bysort region :	egen minrep = min(replacement)
	assert			minrep==maxrep
	gen				fert_haimp = fert_ha, after(fert_ha)
	replace 		fert_haimp = maxrep if !((fert_ha < median + (3 * stddev)) ///
						& (fert_ha > median - (3 * stddev))) ///
						& !inlist(fert_ha,.,0) & !mi(maxrep)
	tabstat 		fert_ha fert_haimp, ///
						f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
	
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
	bysort region : egen stddev = sd(mz_yld) if !inlist(mz_yld,.,0)
	recode 			stddev (.=0)
	bysort region : egen median = median(mz_yld) if !inlist(mz_yld,.,0)
	bysort region : egen replacement = median(mz_yld) if /// 
						(mz_yld <= median + (3 * stddev)) & ///
						(mz_yld >= median - (3 * stddev)) & !inlist(mz_yld,.,0)
	bysort region : egen maxrep = max(replacement)
	bysort region : egen minrep = min(replacement)
	assert 			minrep==maxrep
	generate 		mz_yldimp = mz_yld, after(mz_yld)
	replace  		mz_yldimp = maxrep if !((mz_yld < median + (3 * stddev)) ///
					& (mz_yld > median - (3 * stddev))) ///
					& !inlist(mz_yld,.,0) & !mi(maxrep)
	tabstat 		mz_yld mz_yldimp, ///
					f(%9.0f) s(n me min p1 p50 p95 p99 max) c(s) longstub
					
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
	bysort			hhid2 (field_id) : egen tf_lnd = sum(plotsize)
	assert			tf_lnd > 0 
	sum				tf_lnd, detail

* value of harvest
	bysort			hhid2 (field_id) : egen tf_hrv = sum(vl_hrvimp)
	sum				tf_hrv, detail
	
* value of yield
	generate		tf_yld = tf_hrv / tf_lnd
	sum				tf_yld, detail
	
* labor
	bysort 			hhid2 (field_id) : egen lab_tot = sum(labordaysimp)
	generate		tf_lab = lab_tot / tf_lnd
	sum				tf_lab, detail

* fertilizer
	bysort 			hhid2 (field_id) : egen fert_tot = sum(fertimp)
	generate		tf_frt = fert_tot / tf_lnd
	sum				tf_frt, detail

* pesticide
	bysort 			hhid2 (field_id) : egen tf_pst = max(pest_any)
	tab				tf_pst
	
* herbicide
	bysort 			hhid2 (field_id) : egen tf_hrb = max(herb_any)
	tab				tf_hrb
	
* irrigation
	bysort 			hhid2 (field_id) : egen tf_irr = max(irr_any)
	tab				tf_irr
	
	
* **********************************************************************
* 4b - generate maize variables 
* **********************************************************************	
	
* generate plot area
	bysort			hhid2 (field_id) :	egen cp_lnd = sum(mz_lnd) ///
						if mz_hrvimp != .
	assert			cp_lnd > 0 
	sum				cp_lnd, detail

* value of harvest
	bysort			hhid2 (field_id) :	egen cp_hrv = sum(mz_hrvimp) ///
						if mz_hrvimp != .
	sum				cp_hrv, detail
	
* value of yield
	generate		cp_yld = cp_hrv / cp_lnd if mz_hrvimp != .
	sum				cp_yld, detail
	
* labor
	bysort 			hhid2 (field_id) : egen lab_mz = sum(mz_labimp) ///
						if mz_hrvimp != .
	generate		cp_lab = lab_mz / cp_lnd
	sum				cp_lab, detail

* fertilizer
	bysort 			hhid2(field_id) : egen fert_mz = sum(mz_frtimp) ///
						if mz_hrvimp != .
	generate		cp_frt = fert_mz / cp_lnd
	sum				cp_frt, detail

* pesticide
	bysort 			hhid2 (field_id) : egen cp_pst = max(mz_pst) /// 
						if mz_hrvimp != .
	tab				cp_pst
	
* herbicide
	bysort 			hhid2 (field_id) : egen cp_hrb = max(mz_hrb) ///
						if mz_hrvimp != .
	tab				cp_hrb
	
* irrigation
	bysort 			hhid2 (field_id) : egen cp_irr = max(mz_irr) ///
						if mz_hrvimp != .
	tab				cp_irr

* verify values are accurate
	sum				tf_* cp_*
	
* collapse to the household level
	loc	cp			cp_*
	foreach v of varlist `cp'{
	    replace		`v' = 0 if `v' == .
	}		
	
	collapse (max)	tf_* cp_*, by(pw2 region zone woreda ea rural ///
						hhid hhid2)
	*** we went from 4,697 to 2,661 observations 
	
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

* verify unique household id
	isid			hhid2

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

* rename and hhid2
	rename			hhid2 household_id2
	
* merge in geovars
	merge			m:1 household_id2 using "`root'/ess2_geovars", force
	keep			if _merge == 3
	drop			_merge	

* generate year identifier
	gen				year = 2013
	lab var			year "Year"
	
	order 			household_id2 hhid region zone woreda ea rural aez ///
						pw2 year tf_hrv tf_lnd tf_yld tf_lab tf_frt tf_pst ///
						tf_hrb tf_irr cp_hrv cp_lnd cp_yld cp_lab cp_frt ///
						cp_pst cp_hrb cp_irr
	compress
	describe
	summarize 
	
* saving production dataset
	save 			"`export'.hhfinal_ess2.dta", replace
* close the log
	log	close

/* END */