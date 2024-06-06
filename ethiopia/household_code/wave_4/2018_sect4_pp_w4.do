* Project: WB Weather
* Created on: June 2020
* Created by: McG
* Edited on 6 June 2024
* Edited by: jdm
* Stata v.18

* does
	* cleans Ethiopia household variables, wave 3 PP sec4
	* looks like a crop level field roster, includes pesticide and herbicide use
	* pct_field, damage, field proportion (of crop planted)
	* hierarchy: holder > parcel > field > crop
	* some information on inputs

* assumes
	* access to raw data

* TO DO:
	* done
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths	
	global		root 		 	"$data/household_data/ethiopia/wave_4/raw"  
	global		export 		 	"$data/household_data/ethiopia/wave_4/refined"
	global		logout 		 	"$data/household_data/ethiopia/logs"
	
* open log	
	cap log 	close
	log 		using			"$logout/wv4_PPSEC4", append


* **********************************************************************
* 1 - preparing ESS (Wave 3) - Post Planting Section 4
* **********************************************************************

* load data
	use 		"$root/sect4_pp_w4.dta", clear

* dropping duplicates
	duplicates drop
	format 		%4.0g crop_id
	rename		s4q01b crop_code

* unique identifier can only be generated including crop code as some fields are mixed (s4q03d)
	describe
	sort 		holder_id household_id parcel_id field_id crop_id
	isid 		holder_id household_id parcel_id field_id crop_id
	
* creating district identifier
	egen 		district_id = group( saq01 saq02)
	lab var 	district_id "Unique district identifier"
	distinct	saq01 saq02, joint
	*** 72 distinct district
	*** 3 less than pp sect3
	
* creating parcel identifier
	rename		parcel_id parcel
	tostring	parcel, replace
	generate 	parcel_id = holder_id + " " + parcel
	
* creating field identifier
	rename		field_id field
	tostring	field, replace
	generate 	field_id = holder_id + " " + parcel + " " + field
	
* creating unique crop identifier
	rename		crop_id crop
	tostring	crop, generate(crop_idS)
	generate 	crop_id = holder_id + " " + ea_id + " " + parcel + " " ///
					+ field + " " + crop_idS
	isid		crop_id
	drop		crop_idS

* drop observations with a missing field_id/crop_id
	summarize 	if missing(parcel_id,field_id,crop_id)
	drop 		if missing(parcel_id,field_id,crop_id)
	isid holder_id parcel_id field_id crop_id
	*** 0 observtions dropped
	

* ***********************************************************************
* 2 - variables of interest
* ***********************************************************************

* ***********************************************************************
* 2a - percent field use
* ***********************************************************************

* accounting for mixed use fields - creates a multiplier
	generate 	field_prop = 1 if s4q02 == 1
	replace 	field_prop = s4q03 * .01 if s4q02 ==2
	label var	field_prop "Percent field planted with crop"
	
	
* ***********************************************************************
* 2b - damage and damage preventation
* ***********************************************************************

* looking at crop damage
	rename		s4q08 damaged
	sum 		damaged
	*** info for all observations
	
* percent crop damaged
	rename		s4q10 damaged_pct
	replace		damaged_pct = 0 if damaged == 2
	replace		damaged_pct = damaged_pct * .01
	sum			damaged_pct
	*** info for all obs

* looking at crop damage prevention measures
	generate 	pesticide_any = s4q05 if s4q05 >= 1
	generate 	herbicide_any = s4q06 if s4q06 >= 1
	replace 	herbicide_any = s4q07 if s4q06 != 1 & s4q07 >= 1
	*** the same obs have both pesticde or herbicide information
	*** all other obs are blank

	replace		pesticide_any = 2 if pesticide_any == .
	replace		herbicide_any = 2 if herbicide_any == .

* pp_s4q12_a and pp_s4q12_b give month and year seeds were planted
* the years are from 2010 and 2011, so in ethiopian calendar 


* ***********************************************************************
* 3 - cleaning and keeping
* ***********************************************************************

* renaming some variables of interest
	rename 		household_id hhid
	rename 		saq01 region
	rename 		saq02 zone
	rename 		saq03 woreda
	rename 		saq05 ea
	
* restrict to variables of interest
	keep  		holder_id- crop_code pesticide_any herbicide_any field_prop ///
					damaged damaged_pct parcel_id field_id crop_id
	order 		holder_id- ea

* Final preparations to export
	isid 		holder_id parcel field crop_id
	isid		crop_id
	compress
	describe
	summarize 
	sort 		holder_id parcel field crop_id
	save 		"$export/PP_SEC4.dta", replace

* close the log
	log	close