* Project: WB Weather
* Created on: July 2020
* Created by: McG
* Edited on: 20 May 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 3 PP sec4
	* looks like a crop level field roster, includes pesticide and herbicide use
	* pct_field, damage, field proportion (of crop planted)
	* hierarchy: holder > parcel > field > crop
	
* assumes
	* raw lsms-isa data

* TO DO:
	* done
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc root = "$data/household_data/ethiopia/wave_2/raw"
	loc export = "$data/household_data/ethiopia/wave_2/refined"
	loc logout = "$data/household_data/ethiopia/logs"

* open log
	cap log close
	log using "`logout'/wv2_PPSEC4", append


* **********************************************************************
* 1 - preparing ESS 2013/14 (Wave 3) - Post Planting Section 4
* **********************************************************************

* load data
	use 		"`root'/sect4_pp_w2.dta", clear

* dropping duplicates
	duplicates drop

* unique identifier can only be generated including crop code as some fields are mixed (pp_s4q02)
	describe
	sort 		holder_id parcel_id field_id crop_code
	isid 		holder_id parcel_id field_id crop_code
	
* creating district identifier
	egen 		district_id = group( saq01 saq02)
	lab var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 74 distinct district
	*** same as pp sect3, good
	
* creating parcel identifier
	rename		parcel_id parcel
	tostring	parcel, replace
	generate 	parcel_id = holder_id + " " + parcel
	
* creating field identifier
	rename		field_id field
	tostring	field, replace
	generate 	field_id = holder_id + " " + parcel + " " + field
	
* creating unique crop identifier
	tostring	crop_code, generate(crop_codeS)
	generate 	crop_id = holder_id + " " + parcel + " " + field + " " + ///
					crop_codeS
	isid		crop_id
	drop		crop_codeS

* drop observations with a missing field_id/crop_code
	summarize 	if missing(parcel_id,field_id,crop_code)
	drop 		if missing(parcel_id,field_id,crop_code)
	isid holder_id parcel_id field_id crop_code
	*** 0 observtions dropped
	

* ***********************************************************************
* 2 - variables of interest
* ***********************************************************************

* ***********************************************************************
* 2a - percent field use
* ***********************************************************************

* accounting for mixed use fields - creates a multiplier
	generate 	field_prop = 1 if pp_s4q02 == 1
	replace 	field_prop = pp_s4q03*.01 if pp_s4q02 ==2
	label var	field_prop "Percent field planted with crop"
	*** missing 135 obs, i don't think this is used anyway?
	
	
* ***********************************************************************
* 2b - damage and damage preventation
* ***********************************************************************

* looking at crop damage
	rename		pp_s4q08 damaged
	sum 		damaged
	*** missing info for 88 obs
	
* percent crop damaged
	rename		pp_s4q10 damaged_pct
	replace		damaged_pct = 0 if damaged == 2
	sum			damaged_pct
	*** missing info for 126 obs

* looking at crop damage prevention measures
	generate 	pesticide_any = pp_s4q05 if pp_s4q05 >= 1
	generate 	herbicide_any = pp_s4q06 if pp_s4q06 >= 1
	replace 	herbicide_any = pp_s4q07 if pp_s4q06 != 1 & pp_s4q07 >= 1
	*** the same 3,740 obs have both pesticde & herbicide information
	*** all other obs are blank
	*** should these be considered as 'no's? seems like a big assumption
	
* should (can) we impute a binary variable? - NO!
* jeff sez "if it's missing, call it a no"
	replace		pesticide_any = 2 if pesticide_any == .
	replace		herbicide_any = 2 if herbicide_any == .
	*** in both these cases we're making ~26,000 obs from missing into no


* ***********************************************************************
* 3 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid
	rename 		household_id2 hhid2
	rename 		saq01 region
	rename 		saq02 zone
	rename 		saq03 woreda
	rename 		saq05 ea
	
* restrict to variables of interest
	keep  		holder_id- pp_s4q01_b pesticide_any herbicide_any field_prop ///
					damaged damaged_pct parcel_id field_id crop_id
	order 		holder_id- ea

* Final preparations to export
	isid 		holder_id parcel field crop_code
	isid		crop_id
	compress
	describe
	summarize 
	sort 		holder_id parcel field crop_code
	save		"`export'.PP_SEC4.dta", replace
* close the log
	log	close