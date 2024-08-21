*** START ***
* graphs for mismeasure 
* created by: alj
* created on: 19 august 2024
* edited by: alj
* edited on: 20 august 2024

* this code is not currently replicable 

*** TOTAL SEASONAL RAINFALL ***


clear

import excel "C:\Users\aljosephson\OneDrive - University of Arizona\weather_and_agriculture\output\mismeasure_paper\bumpline.xlsx", sheet("total_seasonal") firstrow
rename F ord6
rename G ord5
rename H ord4
rename I ord3
rename J ord2
rename K ord1

egen rg_vg = concat(country reg_type value1quantity2)

reshape long ord, i(rg_vg) j(count)

rename ord source
replace source = "ARC2" if source == "ARC"
replace source = "ERA5" if source == "ERA"
replace source = "ERA5" if source == "ERA5 "
replace source = "MERRA2" if source == "MERRA "
replace source = "MERRA2" if source == "MERRA"
replace source = "TAMSAT" if source == "TAMSAT "
tab source

destring rg_vg, generate(reg_vg)

bumpline count reg_vg , by(source)

*** NO RAIN DAYS ***

clear

import excel "C:\Users\aljosephson\OneDrive - University of Arizona\weather_and_agriculture\output\mismeasure_paper\bumpline.xlsx", sheet("no_rain_days") firstrow
rename F ord6
rename G ord5
rename H ord4
rename I ord3
rename J ord2
rename K ord1

egen rg_vg = concat(country reg_type value1quantity2)

reshape long ord, i(rg_vg) j(count)

rename ord source
replace source = "ARC2" if source == "ARC"
replace source = "MERRA2" if source == "MERRA"
tab source

destring rg_vg, generate(reg_vg)

bumpline count reg_vg , by(source)


*** MEAN TEMPERATURE ***

clear

import excel "C:\Users\aljosephson\OneDrive - University of Arizona\weather_and_agriculture\output\mismeasure_paper\bumpline.xlsx", sheet("mean_temp") firstrow
rename F ord3
rename G ord2
rename H ord1


egen rg_vg = concat(country reg_type value1quantity2)

reshape long ord, i(rg_vg) j(count)

rename ord source

destring rg_vg, generate(reg_vg)

bumpline count reg_vg , by(source)


*** GDD ***

clear

import excel "C:\Users\aljosephson\OneDrive - University of Arizona\weather_and_agriculture\output\mismeasure_paper\bumpline.xlsx", sheet("GDD") firstrow
rename F ord3
rename G ord2
rename H ord1


egen rg_vg = concat(country reg_type value1quantity2)

reshape long ord, i(rg_vg) j(count)

rename ord source
replace source = "ERA5" if source == "ERA5 "
replace source = "MERRA2" if source == "MER"
replace source = "MERRA2" if source == "MERA"

destring rg_vg, generate(reg_vg)

bumpline count reg_vg , by(source)

*** END *** 