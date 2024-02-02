* Project: WB Weather
* Created on: Feb 1, 2024
* Created by: reece
* Stata v.18

* does
	* reads in Mali, WAVE 1 (2014), EACIMAINOUVRE_p1
	* cleans labor (prep and planting) first visit 


* assumes
	* customsave.ado
	* mdesc.ado

* TO DO:
	*
	
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root	=		"$data/household_data/mali/wave_1/raw"
	global	export	=		"$data/household_data/mali/wave_1/refined"
	global	logout	= 		"$data/household_data/mali/logs"
	
* open log
	cap 	log 	close
	log 	using	"$logout/eacimainouvre_p1", append 

	
* **********************************************************************
* 1 - determine labor allocation
* **********************************************************************
	
* import the first relevant data file
	use				"$root/EACIMAINOUVRE_p1", clear

* dropping duplicates
	duplicates 		drop	
	
	rename 			passage visit
	label 			var visit "number of visit - wave number"
	rename			grappe clusterid
	label 			var clusterid "cluster number"
	rename			menage hh_num
	label 			var hh_num "household number - not unique id"
	rename 			s2bq00 ord 
	label 			var ord "number of order"
	rename 			s2bq01 field 
	label 			var field "field number"
	rename 			s2bq02 parcel 
	label 			var parcel "parcel number"
	
* creat household id 	
	egen 			hid = concat(clusterid hh_num)
	label 			var hid "Household indentifier"
	destring		hid, replace
	order			hid
	
* need to include hid field parcel to uniquely identify
	sort 			hid field parcel
	isid 			hid field parcel
	
* determine cultivated plot
	rename 			s2bq03 cultivated
	label 			var cultivated "plot cultivated"
	*** 1 = cultivated, 2 = in fallow, 9 = missing

* drop if not cultivated
	keep 			if cultivated == 1
	*** 68 observations dropped, 9337 kept
	


*** No data on household ID of labor like Niger
*** includes data on family, non-family, mutual aid group labor

*family labor days
	tab 			s2bq04
	*** 9105 hired family labor, 230 did not, 2 missing
	*1= yes 2= no 9=missing
	
	gen				fam_lab_men = .
	replace			fam_lab_men = s2bq05b if s2bq04 == 1
	replace			fam_lab_men = 0 if s2bq04 != 1
	*replace			hired_men = 0 if s2bq05b == 99*
	***why are we doing this here? i don't think 99 indicates missing
	replace			fam_lab_men = 0 if s2bq05b == 999
	replace 		fam_lab_men = 0 if s2bq05b == .  

	gen				fam_lab_wom = .
	replace			fam_lab_wom = s2bq05e if s2bq04 == 1
	replace			fam_lab_wom = 0 if s2bq04 != 1
	*replace			hired_men = 0 if s2bq05b == 99*
	***why are we doing this here? i don't think 99 indicates missing
	replace			fam_lab_wom = 0 if s2bq05e == 999
	replace 		fam_lab_wom = 0 if s2bq05e == .  
	
	*** we do not include child labor days

*non-family labor days
	tab 			s2bq06
	*** 1505 hired non-family labor, 7822 did not, 10 missing
	*1= yes 2= no 9=missing
	
	gen				hired_men = .
	replace			hired_men = s2bq07b if s2bq06 == 1
	replace			hired_men = 0 if s2bq06 != 1
	*replace			hired_men = 0 if s2bq05b == 99*
	***why are we doing this here? i don't think 99 indicates missing
	replace			hired_men = 0 if s2bq07b == 999
	replace 		hired_men = 0 if s2bq07b == .  

	gen				hired_women = .
	replace			hired_women = s2bq07e if s2bq06 == 1
	replace			hired_women = 0 if s2bq06 != 1
	*replace			hired_men = 0 if s2bq05b == 99*
	***why are we doing this here? i don't think 99 indicates missing
	replace			hired_women = 0 if s2bq07e == 999
	replace 		hired_women = 0 if s2bq07e == .  

*mutual aid labor days
	tab 			s2bq08
	*** 695 used mutual aid labor, 8614 did not, 28 missing
	*1= yes 2= no 9=missing
	
	gen				mutual_men = .
	replace			mutual_men = s2bq09b if s2bq08 == 1
	replace			mutual_men = 0 if s2bq08 != 1
	*replace			hired_men = 0 if s2bq05b == 99*
	***why are we doing this here? i don't think 99 indicates missing
	replace			mutual_men = 0 if s2bq09b == 999
	replace 		mutual_men = 0 if s2bq09b == .  
	tab 			mutual_men
	***990 was a pretty large outlier i found, looks like a typo and should be missing?
	
	gen				mutual_women = .
	replace			mutual_women = s2bq09e if s2bq08 == 1
	replace			mutual_women = 0 if s2bq08 != 1
	*replace			hired_men = 0 if s2bq05b == 99*
	***why are we doing this here? i don't think 99 indicates missing
	replace			mutual_women = 0 if s2bq09e == 999
	replace 		mutual_women = 0 if s2bq09e == .  

	
