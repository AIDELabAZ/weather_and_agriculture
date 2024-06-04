* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, ag_conv_w3 (wave 3 conversion file)
	* adds kilograms, grams, litres, and centilitres to conversion units
	* outputs conversion file ready for combination with wave 2 and wave 3 harvest data

* assumes
	* ag_conv_w3 conversion file

* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		cnvrt	=	"$data/household_data/nigeria/conversion_files"
	loc 	export	= 	"$data/household_data/nigeria/conversion_files"
	loc 	logout	= 	"$data/household_data/nigeria/logs"

* open log
	cap log close
	log 	using 	"`logout'/harvconv_master_wave_3", append	
	
	
* **********************************************************************
* 1 - general import and clean up
* **********************************************************************

* import the relevant conversion file
	use 			"`cnvrt'/ag_conv_w3" , clear
	
* rename for matching with harvest files
	rename 			crop_cd cropcode
	rename			unit_cd harv_unit 
	
* drop regional measures
* in alignment with previous two rounds, use only national conversions
	drop conv_NC_1 conv_NE_2 conv_NW_3 conv_SE_4 conv_SS_5 conv_SW_6 note
	rename conv_national conversion  
	
* unlike W1 and W2 do not seem to need to add a bunch of other missing units 

* **********************************************************************
* 3 - end matter, clean up to save
* **********************************************************************
	isid			cropcode harv_unit
	
* create unique household-plot identifier
	sort			cropcode harv_unit
	egen			crop_unit = group(cropcode harv_unit)
	lab var			crop_unit "unique crop and unit identifier"
	
	compress
	describe
	summarize

* save file
	save 			"`export'/harvconv_wave_3.dta", replace

* close the log
	log		close

/* END */
