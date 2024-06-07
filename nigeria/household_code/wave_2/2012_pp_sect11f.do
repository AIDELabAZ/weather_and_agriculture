* Project: WB Weather
* Created on: May 2020
* Created by: alj
* Edited on: 23 May 2024
* Edited by: jdm
* Stata v.18

* does
	* reads in Nigeria, WAVE 2 (2012-2013), POST PLANTING,AG SECT11F
	* determines planting month and year
	* planting dates look ok, so we don't need anything from this file

* assumes
	* access to all raw data
	* mdesc.ado
	
* TO DO:
	* complete

	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	loc		root	=	"$data/household_data/nigeria/wave_2/raw"
	loc		export	=	"$data/household_data/nigeria/wave_2/refined"
	loc		logout	=	"$data/household_data/nigeria/logs"

* open log	
	cap log close
	log 	using 	"`logout'/wave_2_pp_sect11f", append
	
	
* **********************************************************************
* 1 - determine planting area
* **********************************************************************
		
* import the first relevant data file
		use "`root'/sect11f_plantingw2", clear 	
		
	describe
	sort			hhid plotid cropid
	isid			hhid plotid cropid

* rename month and year
	rename			s11fq3a month
	lab var			month "planting month"
	
	rename			s11fq3b year
	lab var			year "planting year"
	
* check that month and year make sense
	tab				month
	*** monthly planting pattern makes sense
	*** vast majority are in March-June
	*** this aligns with FAO planting season

	tab				year
	*** most report 2012 but some strange results
	*** clearly 1994 is an error, but check 2011 and 2013
	
* month of 2011 and 2013 planting
	tab				month if year == 2011
	tab				month if year == 2013
	*** some of the months are not feasible given the survey timing but some are
	*** since we are dealing with only 67 (0.6%) of all obs, we will assume all are from 2012

* close the log
	log	close

/* END */