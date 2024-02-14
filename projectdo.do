* Project: WB Weather
* Created on: May 2020
* Created by: jdm
* Stata v.17.0

* does
	* establishes an identical workspace between users
	* sets globals that define absolute paths
	* serves as the starting point to find any do-file, dataset or output
	* runs all do-files needed for data work
	* loads any user written packages needed for analysis

* assumes
	* access to all data and code

* TO DO:
	* complete


* **********************************************************************
* 0 - setup
* **********************************************************************

* set $pack to 0 to skip package installation
	global 			pack 	0
		
* Specify Stata version in use
    global stataVersion 18.0    // set Stata version
    version $stataVersion

* **********************************************************************
* 0 (a) - Create user specific paths
* **********************************************************************

* Define root folder globals
    if `"`c(username)'"' == "jdmichler" {
        global 		code  	"C:/Users/jdmichler/git/AIDELabAZ/weather_and_agriculture"
		global 		data	"C:/Users/jdmichler/OneDrive - University of Arizona/weather_project"
    }

    if `"`c(username)'"' == "rguerrasu" {
        global 		code  	"/Users/rodrigoguerra/Library/CloudStorage/OneDrive-UniversityofArizona/Documents/GitHub/weather_and_agriculture"
		global 		data	"/Users/rodrigoguerra/Library/CloudStorage/OneDrive-UniversityofArizona/weather_project"
    }
	
* **********************************************************************
* 0 (b) - Check if any required packages are installed:
* **********************************************************************

* install packages if global is set to 1
if $pack == 1 {
	
	* for packages/commands, make a local containing any required packages
    * temporarily set delimiter to ; so can break the line
    #delimit ;		
	loc userpack = "blindschemes mdesc estout distinct winsor2" ;
    #delimit cr
	
	* install packages that are on ssc	
		foreach package in `userpack' {
			capture : which `package', all
			if (_rc) {
				capture window stopbox rusure "You are missing some packages." "Do you want to install `package'?"
				if _rc == 0 {
					capture ssc install `package', replace
					if (_rc) {
						window stopbox rusure `"This package is not on SSC. Do you want to proceed without it?"'
					}
				}
				else {
					exit 199
				}
			}
		}

	* install -xfill- package
		net install xfill, replace from(https://www.sealedenvelope.com/)
		
	* install -customsave package
		net install StataConfig, ///
		from(https://raw.githubusercontent.com/etjernst/Materials/master/stata/) replace

	* install -weather- package
		net install WeatherConfig, ///
		from(https://jdavidm.github.io/) replace
	
	* update all ado files
		ado update, update

	* set graph and Stata preferences
		set scheme plotplain, perm
		set more off
}

* **********************************************************************
* 1 - run weather data cleaning .do file
* **********************************************************************

/*	this code requires access to the weather data sets, which are confidential
	and held by the World Bank. They are not publically available

	do 			"$code/ethiopia/weather_code/eth_ess_masterdo.do"
	do 			"$code/malawi/weather_code/mwi_ihs_masterdo.do"
	do 			"$code/niger/weather_code/ngr_ecvma_masterdo.do"
	do 			"$code/nigeria/weather_code/nga_ghs_masterdo.do"
	do 			"$code/tanzania/weather_code/tza_nps_masterdo.do"
	do 			"$code/uganda/weather_code/uga_unps_masterdo.do"


* **********************************************************************
* 2 - run household data cleaning .do files and merge with weather data
* **********************************************************************

/*	this code requires a user to have downloaded the publically available 
	household data sets and placed them into the folder structure detailed
	in the readme file accompanying this repo.
*/	
	do 			"$code/ethiopia/household_code/eth_hh_masterdo.do"
	do 			"$code/malawi/household_code/mwi_hh_masterdo.do"
	do 			"$code/niger/household_code/ngr_hh_masterdo.do"
	do 			"$code/nigeria/household_code/nga_hh_masterdo.do"
	do 			"$code/tanzania/household_code/tza_hh_masterdo.do"
	do 			"$code/uganda/household_code/uga_hh_masterdo.do"



* **********************************************************************
* 3 - build cross-country household panel data set
* **********************************************************************

	do			"$code/analysis/reg_code/panel_build.do"


* **********************************************************************
* 4 - run regression .do files
* **********************************************************************

	do			"$code/analysis/reg_code/regressions.do"
	do			"$code/analysis/reg_code/regressions-linear-combo.do"
	do			"$code/analysis/reg_code/regressions-multi-combo.do"


* **********************************************************************
* 5 - run analysis .do files
* **********************************************************************

	do			"$code/analysis/viz_code/sum_table.do"
	do			"$code/analysis/viz_code/sum_vis.do"
	do			"$code/analysis/viz_code/r2_vis.do"
	do			"$code/analysis/viz_code/pval_vis.do"
	do			"$code/analysis/viz_code/coeff_vis.do"
	do			"$code/analysis/viz_code/coeff_lc_vis.do"
	do			"$code/analysis/viz_code/coeff_mc_vis.do"
