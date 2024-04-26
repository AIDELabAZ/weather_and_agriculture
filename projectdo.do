/* BEGIN */

* Project: Translating Mali
* Created on: March 2024
* Created by: alj
* Edited on: 25 March 2024
* Edited by: alj
* Stata v.18.0

* does
	* 
	
* assumes
	* access to french mali data files 

* TO DO:
	* 

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

<<<<<<< Updated upstream
    if `"`c(username)'"' == "rodrigoguerra" {
        global 		code  	"/Users/rodrigoguerra/Library/CloudStorage/OneDrive-UniversityofArizona/Documents/GitHub/weather_and_agriculture"
		global 		data	"/Users/rodrigoguerra/Library/CloudStorage/OneDrive-UniversityofArizona/weather_project"
    }
	 if `"`c(username)'"' == "fvkrysbackpackpc" {
        global 		code  	"/Users/fvkrysbackpackpc/Documents/GitHub/weather_and_agriculture"
		global 		data	"/Users/fvkrysbackpackpc/Library/CloudStorage/OneDrive-UniversityofArizona/weather_project"
		
    }
=======
>>>>>>> Stashed changes
	    if `"`c(username)'"' == "annal" {
        global 		code  	"C:/Users/aljosephson/git/translating-mali"
		global 		data	"C:/Users/aljosephson/Dropbox/Classification"
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

	* install -xfill and dm89_1 - packages
		net install xfill, 	replace from(https://www.sealedenvelope.com/)
		
	* update all ado files
		ado update, update

	* set graph and Stata preferences
		set scheme plotplain, perm
		set more off
}

* **********************************************************************
* 1 - run data cleaning .do file
* **********************************************************************

* **********************************************************************
* 2 - run analysis .do files
* **********************************************************************

/* END */