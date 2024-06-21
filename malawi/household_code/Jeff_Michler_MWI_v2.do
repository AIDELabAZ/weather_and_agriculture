
/*********************************************************************************
* Tracking rules for MWI IHPS									          *
* Date: June 2024                                                            *
* Creator: Thomas Bentze                                                            *
* -------------------------------------------------------------------------------*
*/

global		Input "$data/household_data/malawi/wb_ihsp"
global		Output "$data/household_data/malawi"

**************** 1) Program to identify parents and split offs 

capture program drop define_MWI_track
program define_MWI_track
args hhid_n1 hhid_n0 wave_n1 wave_n0 year1 year0 dist_var
	
	duplicates report `hhid_n1' // = unique identifier
	gen parent_w`wave_n1' = 1
	duplicates tag `hhid_n0', gen(split_w`wave_n0')
	replace parent_w`wave_n1' = 0 if split_w`wave_n0'>0
		// 1) parent_w`wave_n1' if stayed put (less than 200m)
		replace parent_w`wave_n1' = 1 if `dist_var'<=0.2 & split_w`wave_n0'>0
		bys `hhid_n0': egen check_parent_w`wave_n1's = total(parent_w`wave_n1')
		fre check_parent_w`wave_n1's // about 70 with multiple parent_w`wave_n1's
		replace parent_w`wave_n1' = 0 if check_parent_w`wave_n1's>1 | check_parent_w`wave_n1's==0
			// 2) if not, parent_w`wave_n1' if hh head tracked
			preserve
				// generate datasets of heads
				foreach option in same different  { // sometimes household heads swtich, but are still in the same hh
				use "${Input}\\Malawi\\IHPS `year1'\\hh_mod_b_`year1'", clear 
				merge m:1 `hhid_n1' using "${Input}\\Malawi\\IHPS `year1'\hh_mod_a_filt_`year1'.dta", keep(master match) nogen
				if "`option'" == "same" {
					keep if hh_b04==1 // keep heads
					duplicates report `hhid_n1' // now unique identifier (= one head per hh)
				}	
				keep  `hhid_n1'  `hhid_n0' PID
				tempfile heads_w`wave_n1'
				save `heads_w`wave_n1'', replace
				
				use "${Input}\\Malawi\\IHPS `year0'\hh_mod_b_`year0'.dta", clear 
				merge m:1 `hhid_n0' using "${Input}\\Malawi\\IHPS `year0'\hh_mod_a_filt_`year0'.dta", keep(master match) nogen
				keep if hh_b04==1 // keep heads
				duplicates report PID // now unique identifier (= one head per hh)				
				keep `hhid_n0' PID
				merge 1:1 PID using `heads_w`wave_n1'', keep(match) nogen
				keep `hhid_n1' 
				duplicates drop // multiple heads can originate from a single hh
				tempfile matched_heads_`option'
				save `matched_heads_`option'', replace
				}
			restore
			
			merge 1:1 `hhid_n1' using  `matched_heads_same'
			replace parent_w`wave_n1' = 1 if _merge==3 & check_parent_w`wave_n1's>1 | _merge==3 &  check_parent_w`wave_n1's==0
			drop  _merge
			merge 1:1 `hhid_n1' using  `matched_heads_different'
			replace parent_w`wave_n1' = 1 if _merge==3 & check_parent_w`wave_n1's>1 | _merge==3 &  check_parent_w`wave_n1's==0
			drop check_parent_w`wave_n1's _merge
			bys `hhid_n0': egen check_parent_w`wave_n1's = total(parent_w`wave_n1')
			fre check_parent_w`wave_n1's // some still with no parent_w`wave_n1'
			replace parent_w`wave_n1' = 0 if check_parent_w`wave_n1's>1 | check_parent_w`wave_n1's==0
				// 3) if not, parent_w`wave_n1' if household more populated
				preserve
					use "${Input}\\Malawi\\IHPS `year1'\\hh_mod_a_filt_`year1'.dta", clear 
					merge 1:m `hhid_n1' using "${Input}\\Malawi\\IHPS `year1'\hh_mod_b_`year1'.dta", keep(master match) nogen
					keep `hhid_n1' `hhid_n0' PID
					duplicates drop
					tempfile PID`wave_n1'
					save `PID`wave_n1'', replace
					
					use "${Input}\\Malawi\\IHPS `year0'\\hh_mod_a_filt_`year0'.dta", clear 
					merge 1:m `hhid_n0' using "${Input}\\Malawi\\IHPS `year0'\hh_mod_b_`year0'.dta", keep(master match) nogen
					keep `hhid_n0' PID
					merge 1:1 `hhid_n0' PID using `PID`wave_n1'', keep(match) nogen
					bys `hhid_n0': egen nb_tracked = count(PID)
					bys `hhid_n1': egen max_tracked = max(nb_tracked)
					gen hh_max_nb_tracked = nb_tracked==max_tracked
					keep hh_max_nb_tracked `hhid_n1'
					duplicates drop 
					tempfile tracked`wave_n1'
					save `tracked`wave_n1'', replace
				restore
				merge 1:1 `hhid_n1' using  `tracked`wave_n1'', nogen
				replace parent_w`wave_n1' = 1 if hh_max_nb_tracked==1 & check_parent_w`wave_n1's>1 | hh_max_nb_tracked==1 &  check_parent_w`wave_n1's==0
				drop check_parent_w`wave_n1's 
				bys `hhid_n0': egen check_parent_w`wave_n1's = total(parent_w`wave_n1')
				fre check_parent_w`wave_n1's // some still with no parent_w`wave_n1'
				replace parent_w`wave_n1' = 0 if check_parent_w`wave_n1's>1 | check_parent_w`wave_n1's==0 // these are all split offs

end


**************** 2) Create household frames and identify split offs

	use "${Input}\\Malawi\\IHPS 10\\hh_mod_a_filt_10.dta", clear 
	
	gen hh_id_obs = case_id
	keep case_id  hh_id_obs 
	merge 1:m case_id using "${Input}\\Malawi\\IHPS 13\\\hh_mod_a_filt_13.dta", keepusing(y2_hhid dist_to_IHS3location) keep(match) nogen
	
	define_MWI_track y2_hhid case_id 2 1 13 10 dist_to_IHS3location	
	replace hh_id_obs = y2_hhid if 	parent_w2==0
	gen wave = 2

	keep case_id y2_hhid hh_id_obs parent_w2 wave
	tempfile HH_frame_w2
	save `HH_frame_w2', replace
	merge 1:m y2_hhid using  "${Input}\\Malawi\\IHPS 16\\\hh_mod_a_filt_16.dta", keepusing(y3_hhid dist_to_IHPSlocation)  keep(match) nogen
	
	define_MWI_track y3_hhid y2_hhid 3 2 16 13 dist_to_IHPSlocation	
	replace hh_id_obs = y3_hhid + "-w3" if 	parent_w3==0
	replace wave = 3
	
	keep case_id y2_hhid y3_hhid  hh_id_obs parent_w2 parent_w3 wave
	tempfile HH_frame_w3
	save `HH_frame_w3', replace
	merge 1:m y3_hhid using  "${Input}\\Malawi\\IHPS 19\\\hh_mod_a_filt_19.dta", keepusing(y4_hhid dist_to_IHPS2016location)  keep(match) nogen

	define_MWI_track y4_hhid y3_hhid 4 3 19 16 dist_to_IHPS2016location	
	replace hh_id_obs = y4_hhid + "-w4" if 	parent_w4==0
	replace wave = 4
	
	keep case_id y2_hhid y3_hhid y4_hhid  hh_id_obs parent_w2 parent_w3 parent_w4 wave
	tempfile HH_frame_w4
	save `HH_frame_w4', replace
	
**************** 3) Append
	
	use "${Input}\\Malawi\\IHPS 10\\HH_MOD_A_FILT_10.dta", clear
	keep case_id
	gen wave = 1 
	gen hh_id_obs = case_id
	append using "${Input}\\Malawi\\IHPS 13\\HH_MOD_A_FILT_13.dta"
	keep  hh_id_obs wave case_id y2_hhid
	replace wave = 2 if wave==.
	append using "${Input}\\Malawi\\IHPS 16\\HH_MOD_A_FILT_16.dta"
	keep  hh_id_obs wave case_id y2_hhid y3_hhid
	replace wave = 3 if wave==.
	append using "${Input}\\Malawi\\IHPS 19\\HH_MOD_A_FILT_19.dta"
	keep  hh_id_obs wave case_id y2_hhid y3_hhid y4_hhid
	replace wave = 4 if wave==.
	
	merge m:1 y2_hhid wave using `HH_frame_w2', nogen update
	merge m:1 y3_hhid wave using `HH_frame_w3', nogen update
	merge m:1 y4_hhid wave using `HH_frame_w4', nogen update
	
	rename hh_id_obs hh_id_obs_temp // tracked unit will be a numeric ID 
	egen hh_id_obs = group(hh_id_obs_temp)
	replace hh_id_obs = hh_id_obs + 2000000 
	
	lab var hh_id_obs "Household ID (Tracked unit)"

keep hh_id_obs wave case_id y2_hhid y3_hhid y4_hhid
save "${Output}\\trackingfiles\\Frame_hhIDs_v2.dta", replace




