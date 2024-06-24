* Project: WB Weather
* Created on: November 2020
* Created by: alj
* Edited by: jdm
* Last edit: 20 Jun 2024
* Stata v.18.0

* does
	* reads in lsms data set
	* makes visualziations of summary statistics  

* assumes
	* you have results file 
	* grc1leg2.ado

* TO DO:
	* complete
	
	
* **********************************************************************
* 0 - setup
* **********************************************************************

* define paths
	global	root 	= 	"$data/regression_data"
	global	stab 	= 	"$data/results_data/tables"
	global	xtab 	= 	"$data/output/mismeasure_paper/tables"
	global	sfig	= 	"$data/results_data/figures"	
	global 	xfig    =   "$data/output/mismeasure_paper/figures"
	global	logout 	= 	"$data/results_data/logs"
	* s indicates Stata figures, works in progress
	* x indicates final version for paper 

* open log	
	cap log close
	log 	using 		"$logout/summarytab", append

		
* **********************************************************************
* 1 - load and process data
* **********************************************************************

* load data 
	use 			"$root/lsms_panel", clear

* label variables
	lab var 		tf_hrv	"Total farm production (2015 USD)"
	lab var 		tf_lnd	"Total farmed area (ha)"
	lab var 		tf_yld	"Total farm yield (2015 USD/ha)"
	lab var 		tf_lab	"Total farm labor rate (days/ha)"
	lab var 		tf_frt	"Total farm fertilizer rate (kg/ha)" 
	lab var 		tf_pst	"Total farm pesticide use (\%)"
	lab var 		tf_hrb 	"Total farm herbicide use (\%)"
	lab var 		tf_irr 	"Total farm irrigation use (\%)"
	
	lab var 		cp_hrv	"Primary crop production (kg)"
	lab var 		cp_lnd	"Primary crop farmed area (ha)"
	lab var 		cp_yld	"Primary crop yield (kg/ha)"
	lab var 		cp_lab	"Primary crop labor rate (days/ha)"
	lab var 		cp_frt	"Primary crop fertilizer rate (kg/ha)" 
	lab var 		cp_pst	"Primary crop pesticide use (\%)"
	lab var 		cp_hrb 	"Primary crop herbicide use (\%)"
	lab var 		cp_irr 	"Primary crop irrigation use (\%)"	

* summary stats by country for tf
	eststo 			eth_tf :	estpost ///
						sum tf_hrv tf_lnd tf_yld tf_lab tf_frt tf_pst tf_hrb tf_irr ///
						if country == 1
		
	eststo 			mwi_tf : estpost ///
						sum tf_hrv tf_lnd tf_yld tf_lab tf_frt tf_pst tf_hrb tf_irr ///
						if country == 2
		
	eststo 			ngr_tf : estpost ///
						sum tf_hrv tf_lnd tf_yld tf_lab tf_frt tf_pst tf_hrb tf_irr ///
						if country == 4
		
	eststo 			nga_tf : estpost ///
						sum tf_hrv tf_lnd tf_yld tf_lab tf_frt tf_pst tf_hrb tf_irr ///
						if country == 5
		
	eststo 			tza_tf : estpost ///
						sum tf_hrv tf_lnd tf_yld tf_lab tf_frt tf_pst tf_hrb tf_irr ///
						if country == 6
		
	eststo 			uga_tf : estpost ///
						sum tf_hrv tf_lnd tf_yld tf_lab tf_frt tf_pst tf_hrb tf_irr ///
						if country == 7

* define loop through levels of countries	
levelsof 	country		, local(lc)
	foreach c of local lc {
		distinct		hhid if country == `c'
		local 			temp`c'a = r(N) 
			local 			`c'n : display %4.0f `temp`c'a'
		local 			temp`c'b = r(ndistinct) 
			local 			`c'hh : display %4.0f `temp`c'b'
	}

						
	esttab 			eth_tf mwi_tf ngr_tf nga_tf tza_tf uga_tf ///
						using "$xtab/summary_stats.tex", replace ///
						prehead("\begin{tabular}{l*{6}{c}} \\ [-1.8ex]\hline \hline \\[-1.8ex] " ///
						"& \multicolumn{1}{c}{Ethiopia} & \multicolumn{1}{c}{Malawi} &  " ///
						"\multicolumn{1}{c}{Niger} & \multicolumn{1}{c}{Nigeria} & " ///
						"\multicolumn{1}{c}{Tanzania} & \multicolumn{1}{c}{Uganda} \\ " ///
						"\midrule &&&&&& \\ \multicolumn{7}{l}{\emph{\textbf{Panel A}: " ///
						"Total Farm Production}} \\ ") ///
						main(mean) aux(sd) nostar unstack label booktabs nonum ///
						collabels(none) fragment noobs nomtitle nogaps ///
						cells(mean(fmt(1 3 2 2 3 3 3 3)) sd(fmt(1 3 1 1 2 3 3 3)par )  ) ///
						prefoot(" \midrule Observations & `1n' & `2n' & `4n' & `5n' & `6n' & `7n' \\ " ///
						"Households & `1hh' & `2hh' & `4hh' & `5hh' & `6hh' & `7hh' \\ ") 

* summary stats by country for cp
	drop if			cp_hrv == .

	eststo 			eth_cp :	estpost ///
						sum cp_hrv cp_lnd cp_yld cp_lab cp_frt cp_pst cp_hrb cp_irr ///
						if country == 1
		
	eststo 			mwi_cp : estpost ///
						sum cp_hrv cp_lnd cp_yld cp_lab cp_frt cp_pst cp_hrb cp_irr ///
						if country == 2
		
	eststo 			ngr_cp : estpost ///
						sum cp_hrv cp_lnd cp_yld cp_lab cp_frt cp_pst cp_hrb cp_irr ///
						if country == 4
		
	eststo 			nga_cp : estpost ///
						sum cp_hrv cp_lnd cp_yld cp_lab cp_frt cp_pst cp_hrb cp_irr ///
						if country == 5
		
	eststo 			tza_cp : estpost ///
						sum cp_hrv cp_lnd cp_yld cp_lab cp_frt cp_pst cp_hrb cp_irr ///
						if country == 6
		
	eststo 			uga_cp : estpost ///
						sum cp_hrv cp_lnd cp_yld cp_lab cp_frt cp_pst cp_hrb cp_irr ///
						if country == 7

* define loop through levels of countries	
levelsof 	country		, local(lc)
	foreach c of local lc {
		distinct		hhid if country == `c'
		local 			temp`c'a = r(N) 
			local 			`c'n : display %4.0f `temp`c'a'
		local 			temp`c'b = r(ndistinct) 
			local 			`c'hh : display %4.0f `temp`c'b'
	}					
	
	esttab 			eth_cp mwi_cp ngr_cp nga_cp tza_cp uga_cp ///
						using "$xtab/summary_stats.tex", append ///
						posthead("\midrule &&&&&& \\ \multicolumn{7}{l}{\emph{\textbf{Panel B}: " ///
						"Primary Crop Production}} \\  ") ///
						main(mean) aux(sd) nostar unstack label booktabs nonum ///
						collabels(none) fragment noobs nomtitle nogaps  ///
						cells("mean(fmt(2 3 2 2 3 3 3 3))" sd(fmt(2 3 1 1 3 3 3 3)par )  ) ///
						postfoot(" \midrule Observations & `1n' & `2n' & `4n' & `5n' & `6n' & `7n' \\ " ///
						"Households & `1hh' & `2hh' & `4hh' & `5hh' & `6hh' & `7hh' \\ " ///
						"\hline \hline \\[-1.8ex] \multicolumn{7}{p{\linewidth}}{\small " ///
						"\noindent \textit{Note}: The table presents the mean  and " ///
						"(standard deviation) of total farm production and primary crop " ///
						"production. Statistics are calculated for each country, " ///
						"aggregated across all waves used.}  \end{tabular}") 
	
		
* **********************************************************************
* 2 - end matter
* **********************************************************************

* close the log
	log	close

/* END */