


       **      **     **     **             **      **      ** **********
       ***    ***    ****    **            ****     **      ** **********
       ****  ****    ****    **            ****     **  **  **     **    
       ** *  * **   **  **   **           **  **    **  **  **     **    
       **  **  **   **  **   **           **  **    **  **  **     **    
       **  **  **  ********  **          ********   **  **  **     **    
       **  **  **  ********  **          ********    ** ** **      **    
       **      ** **      ** **         **      **   ********      **    
       **      ** **      ** ********** **      **    **  **   **********
       **      ** **      ** ********** **      **     *  *    **********

********************************************************************************
********************************************************************************

**	Master do-file for creation of analysis datasets using publicly available
**	LSMS survey data from Malawi. 

**	Country :	Malawi
**	Datasets :	2010 IHS3 cross-section, 2010 IHS3-2013 IHPS short panel, 
**				2010 IHS3-2013 IHPS-2016 IHS4 long panel, 2016 IHS4 cross-section
**	Data source : National Statistical Office of Malawi

**	Program author : Josh Brubaker, LEAD Analytics, Inc
**	Date last modified : 15 August, 2018

**	Syntax were originally created in Stata 14.2, and have been checked for 
**	backwards compatability through Stata 12.2. 
**	No user-written commands are used. 

********************************************************************************
********************************************************************************


clear all					//	clears memory 
set more off, permanently	//	allow syntax to run through without needing to manually advance the code  
set rmsg on					//	specifies that return messages should be displayed 
global version = 15.1		//	defines the version of Stata that will be used for all subsequent do-files
version ${version}			//	sets the version of Stata equal to the version defined above


*	This syntax creates a global for the Malawi_analysis_datasets folder. This
*	must be updated based on where the Malawi_analysis_datasets folder is 
*	located on your computer in order for the syntax to run.  
if c(username)=="annal" { 
global Malawi	"C:/Users/aljosephson/OneDrive - University of Arizona/weather_and_agriculture/household_data/malawi/wb_raw_data"
	}
	
********************************************************************************
**	Settings 
********************************************************************************
*	Select which datasets will be created.
*	 To disable creation of the specified dataset, set the global = 0. 
global ihs3cx_run=1		//	2010 IHS3 Cross-Section

global ihs3spnl_run=1	//	2010 IHS3 round of Short Panel
global ihpsspnl_run=1	//	2013 IHPS round of Short Panel

global ihs3lpnl_run=1	//	2010 IHS3 round of Long Panel
global ihpslpnl_run=1	//	2013 IHPS round of Long Panel
global ihs4lpnl_run=1	//	2016 IHS4 round of Long Panel

global ihs4cx_run=1		//	2016 IHS4 Cross-Section

global cleanup=0		//	Set to one to erase unnecessary temporary datasets


********************************************************************************
**	Data Management 
********************************************************************************

*	Unzip all raw data files and organize for consistent file structure 
do "${Malawi}/do/tools/data_management.do"

*	Clear extant temporary files and re-make data structure 
do "${Malawi}/do/tools/reset_tmp_structure.do"


********************************************************************************
*	2010 IHS3 Cross-Section Dataset Creation
********************************************************************************

if ${ihs3cx_run}==1 {	//	if condition to enable creation of IHS3 Cross-Section analysis datasets 
	*	Household raw data work
		do "${Malawi}/do/ihs3cx/hh/hh_a.do"				//	basic survey design variables, household location
		do "${Malawi}/do/ihs3cx/hh/hh_b.do"				//	basic indivisual demographics (age, sex, relationship to household head), household size and make-up variables 
		do "${Malawi}/do/ihs3cx/hh/hh_c.do"				//	individual education levels, household level education variables
		do "${Malawi}/do/ihs3cx/hh/hh_d.do"				//	individual health measures, household level health measures 
		do "${Malawi}/do/ihs3cx/hh/hh_e.do"				//	individual employment information, household level employment variables 
		do "${Malawi}/do/ihs3cx/hh/hh_f.do"				//	household dwelling characteristics
		do "${Malawi}/do/ihs3cx/hh/hh_g1.do"			//	household daily food consumption information
		do "${Malawi}/do/ihs3cx/hh/hh_g2.do"			//	Food Consumption Score 
		do "${Malawi}/do/ihs3cx/hh/hh_h.do"				//	Coping Strategies Index
		do "${Malawi}/do/ihs3cx/hh/hh_i2.do"			//	household expenditures, one-month recall 
		do "${Malawi}/do/ihs3cx/hh/hh_j.do"				//	household expenditures, three-month recall
		do "${Malawi}/do/ihs3cx/hh/hh_k.do"				//	household expenditures, 12-month recall 
		do "${Malawi}/do/ihs3cx/hh/hh_l.do"				//	household assets
		do "${Malawi}/do/ihs3cx/hh/hh_m.do"				//	agricultural assets
		do "${Malawi}/do/ihs3cx/hh/hh_n1.do"			//	household non-agricultural enterprises 
		do "${Malawi}/do/ihs3cx/hh/hh_n2.do"			//	individual non-agricultural enterprises 
		do "${Malawi}/do/ihs3cx/hh/hh_o.do"				//	biological children of head/spouse living elsewhere 
		do "${Malawi}/do/ihs3cx/hh/hh_p.do"				//	other income types; gifts, investment/rent, asset sales
		do "${Malawi}/do/ihs3cx/hh/hh_q.do"				//	gifts given out
		do "${Malawi}/do/ihs3cx/hh/hh_r.do"				//	social transfers 
		do "${Malawi}/do/ihs3cx/hh/hh_s1.do"			//	household access to credit 
		do "${Malawi}/do/ihs3cx/hh/hh_s2.do"			//	household credit refusal 
		do "${Malawi}/do/ihs3cx/hh/hh_u.do"				//	shocks experienced
		do "${Malawi}/do/ihs3cx/hh/hh_w.do"				//	deaths in last two years 
		do "${Malawi}/do/ihs3cx/hh/hh_x.do"				//	fishery participation 
	*	Household aggregated variable creation 
		do "${Malawi}/do/ihs3cx/merge/fss.do"				//	Food Security Status
		do "${Malawi}/do/ihs3cx/merge/wealthindices.do"		//	Household and agricultural wealth indices 
	*	Agriculture raw data work
		do "${Malawi}/do/ihs3cx/ag/ag_c.do"				//	rainy season plot size
		do "${Malawi}/do/ihs3cx/ag/ag_d.do"				//	rainy season plot details
		do "${Malawi}/do/ihs3cx/ag/ag_e.do"				//	household input coupons
		do "${Malawi}/do/ihs3cx/ag/ag_f.do"				//	household rainy season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs3cx/ag/ag_g.do"				//	rainy season crop x plot harvest 
		do "${Malawi}/do/ihs3cx/ag/ag_h.do"				//	household rainy season purchases of seed 
		do "${Malawi}/do/ihs3cx/ag/ag_i.do"				//	rainy season crop disposition and unit value 
		do "${Malawi}/do/ihs3cx/ag/ag_j.do"				//	dimba season plot size
		do "${Malawi}/do/ihs3cx/ag/ag_k.do"				//	dimba season plot details
		do "${Malawi}/do/ihs3cx/ag/ag_l.do"				//	household dimba season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs3cx/ag/ag_m.do"				//	dimba season crop x plot harvest 
		do "${Malawi}/do/ihs3cx/ag/ag_n.do"				//	household dimba season purchases of seed
		do "${Malawi}/do/ihs3cx/ag/ag_o.do"				//	dimba season crop disposition and unit value 
		do "${Malawi}/do/ihs3cx/ag/ag_p.do"				//	tree/permanent crop production
		do "${Malawi}/do/ihs3cx/ag/ag_q.do"				//	tree/permanent crop disposition and unit value 
		do "${Malawi}/do/ihs3cx/ag/ag_r.do"				//	livestock 
		do "${Malawi}/do/ihs3cx/ag/ag_s.do"				//	livestock by-products
		do "${Malawi}/do/ihs3cx/ag/ag_t.do"				//	extension information
		do "${Malawi}/do/ihs3cx/ag/ag_nr.do"			//	network roster 
	*	Agricultural aggregated variable creation 
		do "${Malawi}/do/ihs3cx/merge/rs_plot.do"		//	rainy season production at plot level
		do "${Malawi}/do/ihs3cx/merge/ds_plot.do"		//	dimba season production at plot level
		do "${Malawi}/do/ihs3cx/merge/tp_plot.do"		//	tree/permanent crop production at plot level
		do "${Malawi}/do/ihs3cx/merge/rs_hh.do"			//	rainy season production at household level
		do "${Malawi}/do/ihs3cx/merge/ds_hh.do"			//	dimba season production at household level
		do "${Malawi}/do/ihs3cx/merge/tp_hh.do"			//	tree/permanent crop production at household level
	*	Community raw data work
		do "${Malawi}/do/ihs3cx/com/com_b.do"			//	community key informant characteristics
		do "${Malawi}/do/ihs3cx/com/com_c.do"			//	community demographics 
		do "${Malawi}/do/ihs3cx/com/com_d.do"			//	community infrastructure
		do "${Malawi}/do/ihs3cx/com/com_e.do"			//	community labor 
		do "${Malawi}/do/ihs3cx/com/com_f.do"			//	community agriculture
		do "${Malawi}/do/ihs3cx/com/com_j.do"			//	community organizations 
	*	Final community dataset merge 
		do "${Malawi}/do/ihs3cx/merge/com_final.do"		//	community level dataset
	*	Final household dataset merge 
		do "${Malawi}/do/ihs3cx/merge/hh_final.do"		//	household level dataset
	*	Final individual dataset merge 
		do "${Malawi}/do/ihs3cx/merge/ind_final.do"		//	individual level dataset
	*	Clean up componenet datasets that are now merged into analysis-ready datasets 
		if ${cleanup}==1 do "${Malawi}/do/ihs3cx/merge/cleanup.do"		//	erases component datasets 
	}	//	end of if condition to enable creation of IHS3 Cross-Section analysis datasets 



	
********************************************************************************
**	2010 IHS3-2013 IHPS Short Panel
********************************************************************************
		
*	IHS3 Short Panel Dataset Creation
if ${ihs3spnl_run}==1 {	//	if condition to enable creation of IHS3 Short Panel analysis datasets 
	*	Household raw data work
		do "${Malawi}/do/ihs3spnl/hh/hh_a.do"			//	basic survey design variables, household location
		do "${Malawi}/do/ihs3spnl/hh/hh_b.do"			//	basic indivisual demographics (age, sex, relationship to household head), household size and make-up variables 
		do "${Malawi}/do/ihs3spnl/hh/hh_c.do"			//	individual education levels, household level education variables
		do "${Malawi}/do/ihs3spnl/hh/hh_d.do"			//	individual health measures, household level health measures 
		do "${Malawi}/do/ihs3spnl/hh/hh_e.do"			//	individual employment information, household level employment variables 
		do "${Malawi}/do/ihs3spnl/hh/hh_f.do"			//	household dwelling characteristics
		do "${Malawi}/do/ihs3spnl/hh/hh_g1.do"			//	household daily food consumption information
		do "${Malawi}/do/ihs3spnl/hh/hh_g2.do"			//	Food Consumption Score 
		do "${Malawi}/do/ihs3spnl/hh/hh_h.do"			//	Coping Strategies Index
		do "${Malawi}/do/ihs3spnl/hh/hh_i2.do"			//	household expenditures, one-month recall 
		do "${Malawi}/do/ihs3spnl/hh/hh_j.do"			//	household expenditures, three-month recall
		do "${Malawi}/do/ihs3spnl/hh/hh_k.do"			//	household expenditures, 12-month recall 
		do "${Malawi}/do/ihs3spnl/hh/hh_l.do"			//	household assets
		do "${Malawi}/do/ihs3spnl/hh/hh_m.do"			//	agricultural assets
		do "${Malawi}/do/ihs3spnl/hh/hh_n1.do"			//	household non-agricultural enterprises 
		do "${Malawi}/do/ihs3spnl/hh/hh_n2.do"			//	individual non-agricultural enterprises 
		do "${Malawi}/do/ihs3spnl/hh/hh_o.do"			//	biological children of head/spouse living elsewhere 
		do "${Malawi}/do/ihs3spnl/hh/hh_p.do"			//	other income types; gifts, investment/rent, asset sales
		do "${Malawi}/do/ihs3spnl/hh/hh_q.do"			//	gifts given out
		do "${Malawi}/do/ihs3spnl/hh/hh_r.do"			//	social transfers 
		do "${Malawi}/do/ihs3spnl/hh/hh_s1.do"			//	household access to credit 
		do "${Malawi}/do/ihs3spnl/hh/hh_s2.do"			//	household credit refusal 
		do "${Malawi}/do/ihs3spnl/hh/hh_u.do"			//	shocks experienced
		do "${Malawi}/do/ihs3spnl/hh/hh_w.do"			//	deaths in last two years 
		do "${Malawi}/do/ihs3spnl/hh/hh_x.do"			//	fishery participation 
	*	Household aggregated variable creation 
		do "${Malawi}/do/ihs3spnl/merge/fss.do"				//	Food Security Status
		do "${Malawi}/do/ihs3spnl/merge/wealthindices.do"	//	Household and agricultural wealth indices 
	*	Agriculture raw data work
		do "${Malawi}/do/ihs3spnl/ag/ag_c.do"			//	rainy season plot size
		do "${Malawi}/do/ihs3spnl/ag/ag_d.do"			//	rainy season plot details
		do "${Malawi}/do/ihs3spnl/ag/ag_e.do"			//	household input coupons
		do "${Malawi}/do/ihs3spnl/ag/ag_f.do"			//	household rainy season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs3spnl/ag/ag_g.do"			//	rainy season crop x plot harvest 
		do "${Malawi}/do/ihs3spnl/ag/ag_h.do"			//	household rainy season purchases of seed 
		do "${Malawi}/do/ihs3spnl/ag/ag_i.do"			//	rainy season crop disposition and unit value 
		do "${Malawi}/do/ihs3spnl/ag/ag_j.do"			//	dimba season plot size
		do "${Malawi}/do/ihs3spnl/ag/ag_k.do"			//	dimba season plot details
		do "${Malawi}/do/ihs3spnl/ag/ag_l.do"			//	household dimba season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs3spnl/ag/ag_m.do"			//	dimba season crop x plot harvest 
		do "${Malawi}/do/ihs3spnl/ag/ag_n.do"			//	household dimba season purchases of seed
		do "${Malawi}/do/ihs3spnl/ag/ag_o.do"			//	dimba season crop disposition and unit value 
		do "${Malawi}/do/ihs3spnl/ag/ag_p.do"			//	tree/permanent crop production
		do "${Malawi}/do/ihs3spnl/ag/ag_q.do"			//	tree/permanent crop disposition and unit value 
		do "${Malawi}/do/ihs3spnl/ag/ag_r.do"			//	livestock 
		do "${Malawi}/do/ihs3spnl/ag/ag_s.do"			//	livestock by-products
		do "${Malawi}/do/ihs3spnl/ag/ag_t.do"			//	extension information
		do "${Malawi}/do/ihs3spnl/ag/ag_nr.do"			//	network roster 
	*	Agricultural aggregated variable creation 
		do "${Malawi}/do/ihs3spnl/merge/rs_plot.do"		//	rainy season production at plot level
		do "${Malawi}/do/ihs3spnl/merge/ds_plot.do"		//	dimba season production at plot level
		do "${Malawi}/do/ihs3spnl/merge/tp_plot.do"		//	tree/permanent crop production at plot level
		do "${Malawi}/do/ihs3spnl/merge/rs_hh.do"		//	rainy season production at household level
		do "${Malawi}/do/ihs3spnl/merge/ds_hh.do"		//	dimba season production at household level
		do "${Malawi}/do/ihs3spnl/merge/tp_hh.do"		//	tree/permanent crop production at household level
	*	Community raw data work
		do "${Malawi}/do/ihs3spnl/com/com_b.do"			//	community key informant characteristics
		do "${Malawi}/do/ihs3spnl/com/com_c.do"			//	community demographics 
		do "${Malawi}/do/ihs3spnl/com/com_d.do"			//	community infrastructure
		do "${Malawi}/do/ihs3spnl/com/com_e.do"			//	community labor 
		do "${Malawi}/do/ihs3spnl/com/com_f.do"			//	community agriculture
		do "${Malawi}/do/ihs3spnl/com/com_j.do"			//	community organizations 
	*	Final community dataset merge 
		do "${Malawi}/do/ihs3spnl/merge/com_final.do"	//	community level dataset
	*	Final household dataset merge 
		do "${Malawi}/do/ihs3spnl/merge/hh_final.do"	//	household level dataset
	*	Final individual dataset merge 
		do "${Malawi}/do/ihs3spnl/merge/ind_final.do"	//	individual level dataset
	*	Clean up componenet datasets that are now merged into analysis-ready datasets 
		if ${cleanup}==1 do "${Malawi}/do/ihs3spnl/merge/cleanup.do"		//	erases component datasets 
	}	//	end of if condition to enable creation of IHS3 Short Panel analysis datasets 


*	IHPS Short Panel Dataset Creation
if ${ihpsspnl_run}==1 {	//	if condition to enable creation of IHPS Short Panel analysis datasets 
	*	Household raw data work
		do "${Malawi}/do/ihpsspnl/hh/hh_a.do"			//	basic survey design variables, household location
		do "${Malawi}/do/ihpsspnl/hh/hh_b.do"			//	basic indivisual demographics (age, sex, relationship to household head), household size and make-up variables 
		do "${Malawi}/do/ihpsspnl/hh/hh_c.do"			//	individual education levels, household level education variables
		do "${Malawi}/do/ihpsspnl/hh/hh_d.do"			//	individual health measures, household level health measures 
		do "${Malawi}/do/ihpsspnl/hh/hh_e.do"			//	individual employment information, household level employment variables 
		do "${Malawi}/do/ihpsspnl/hh/hh_f.do"			//	household dwelling characteristics, financial accounts 
		do "${Malawi}/do/ihpsspnl/hh/hh_g1.do"			//	household daily food consumption information
		do "${Malawi}/do/ihpsspnl/hh/hh_g2.do"			//	Food Consumption Score 
		do "${Malawi}/do/ihpsspnl/hh/hh_h.do"			//	Coping Strategies Index
		do "${Malawi}/do/ihpsspnl/hh/hh_i2.do"			//	household expenditures, one-month recall 
		do "${Malawi}/do/ihpsspnl/hh/hh_j.do"			//	household expenditures, three-month recall
		do "${Malawi}/do/ihpsspnl/hh/hh_k.do"			//	household expenditures, 12-month recall 
		do "${Malawi}/do/ihpsspnl/hh/hh_l.do"			//	household assets
		do "${Malawi}/do/ihpsspnl/hh/hh_m.do"			//	agricultural assets
		do "${Malawi}/do/ihpsspnl/hh/hh_n1.do"			//	household non-agricultural enterprises 
		do "${Malawi}/do/ihpsspnl/hh/hh_n2.do"			//	individual non-agricultural enterprises 
		do "${Malawi}/do/ihpsspnl/hh/hh_o.do"			//	biological children of head/spouse living elsewhere 
		do "${Malawi}/do/ihpsspnl/hh/hh_p.do"			//	other income types; gifts, investment/rent, asset sales
		do "${Malawi}/do/ihpsspnl/hh/hh_q.do"			//	gifts given out
		do "${Malawi}/do/ihpsspnl/hh/hh_r.do"			//	social transfers 
		do "${Malawi}/do/ihpsspnl/hh/hh_s1.do"			//	household access to credit 
		do "${Malawi}/do/ihpsspnl/hh/hh_s2.do"			//	household credit refusal 
		do "${Malawi}/do/ihpsspnl/hh/hh_u.do"			//	shocks experienced
		do "${Malawi}/do/ihpsspnl/hh/hh_x.do"			//	fishery participation 
	*	Household aggregated variable creation 
		do "${Malawi}/do/ihpsspnl/merge/fss.do"				//	Food Security Status
		do "${Malawi}/do/ihpsspnl/merge/wealthindices.do"	//	Household and agricultural wealth indices 
	*	Agriculture raw data work
		do "${Malawi}/do/ihpsspnl/ag/ag_c.do"			//	rainy season plot size
		do "${Malawi}/do/ihpsspnl/ag/ag_d.do"			//	rainy season plot details
		do "${Malawi}/do/ihpsspnl/ag/ag_e.do"			//	household input coupons
		do "${Malawi}/do/ihpsspnl/ag/ag_f.do"			//	household rainy season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihpsspnl/ag/ag_g.do"			//	rainy season crop x plot harvest 
		do "${Malawi}/do/ihpsspnl/ag/ag_h.do"			//	household rainy season purchases of seed 
		do "${Malawi}/do/ihpsspnl/ag/ag_i.do"			//	rainy season crop disposition and unit value 
		do "${Malawi}/do/ihpsspnl/ag/ag_j.do"			//	dimba season plot size
		do "${Malawi}/do/ihpsspnl/ag/ag_k.do"			//	dimba season plot details
		do "${Malawi}/do/ihpsspnl/ag/ag_l.do"			//	household dimba season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihpsspnl/ag/ag_m.do"			//	dimba season crop x plot harvest 
		do "${Malawi}/do/ihpsspnl/ag/ag_n.do"			//	household dimba season purchases of seed
		do "${Malawi}/do/ihpsspnl/ag/ag_o.do"			//	dimba season crop disposition and unit value 
		do "${Malawi}/do/ihpsspnl/ag/ag_p.do"			//	tree/permanent crop production
		do "${Malawi}/do/ihpsspnl/ag/ag_q.do"			//	tree/permanent crop disposition and unit value 
		do "${Malawi}/do/ihpsspnl/ag/ag_r.do"			//	livestock 
		do "${Malawi}/do/ihpsspnl/ag/ag_s.do"			//	livestock by-products
		do "${Malawi}/do/ihpsspnl/ag/ag_t.do"			//	extension information
		do "${Malawi}/do/ihpsspnl/ag/ag_nr.do"			//	network roster 
	*	Agricultural aggregated variable creation 
		do "${Malawi}/do/ihpsspnl/merge/rs_plot.do"		//	rainy season production at plot level
		do "${Malawi}/do/ihpsspnl/merge/ds_plot.do"		//	dimba season production at plot level
		do "${Malawi}/do/ihpsspnl/merge/tp_plot.do"		//	tree/permanent crop production at plot level
		do "${Malawi}/do/ihpsspnl/merge/rs_hh.do"		//	rainy season production at household level
		do "${Malawi}/do/ihpsspnl/merge/ds_hh.do"		//	dimba season production at household level
		do "${Malawi}/do/ihpsspnl/merge/tp_hh.do"		//	tree/permanent crop production at household level
	*	Community raw data work
		do "${Malawi}/do/ihpsspnl/com/com_b.do"			//	community key informant characteristics
		do "${Malawi}/do/ihpsspnl/com/com_c.do"			//	community demographics 
		do "${Malawi}/do/ihpsspnl/com/com_d.do"			//	community infrastructure
		do "${Malawi}/do/ihpsspnl/com/com_e.do"			//	community labor 
		do "${Malawi}/do/ihpsspnl/com/com_f.do"			//	community agriculture
		do "${Malawi}/do/ihpsspnl/com/com_j.do"			//	community organizations 
	*	Final community dataset merge 
		do "${Malawi}/do/ihpsspnl/merge/com_final.do"	//	community level dataset
	*	Final household dataset merge 
		do "${Malawi}/do/ihpsspnl/merge/hh_final.do"	//	household level dataset
	*	Final individual dataset merge 
		do "${Malawi}/do/ihpsspnl/merge/ind_final.do"	//	individual level dataset
	*	Clean up componenet datasets that are now merged into analysis-ready datasets 
		if ${cleanup}==1 do "${Malawi}/do/ihpsspnl/merge/cleanup.do"		//	erases component datasets 
	}	//	end of if condition to enable creation of IHPS Short Panel analysis datasets 



	
********************************************************************************
**	2010 IHS3-2013 IHPS-2016 IHS4 Long Panel
********************************************************************************
		
*	IHS3 Long Panel Dataset Creation
if ${ihs3lpnl_run}==1 {	//	if condition to enable creation of IHS3 Long Panel analysis datasets 
	*	Household raw data work
		do "${Malawi}/do/ihs3lpnl/hh/hh_a.do"			//	basic survey design variables, household location
		do "${Malawi}/do/ihs3lpnl/hh/hh_b.do"			//	basic indivisual demographics (age, sex, relationship to household head), household size and make-up variables 
		do "${Malawi}/do/ihs3lpnl/hh/hh_c.do"			//	individual education levels, household level education variables
		do "${Malawi}/do/ihs3lpnl/hh/hh_d.do"			//	individual health measures, household level health measures 
		do "${Malawi}/do/ihs3lpnl/hh/hh_e.do"			//	individual employment information, household level employment variables 
		do "${Malawi}/do/ihs3lpnl/hh/hh_f.do"			//	household dwelling characteristics
		do "${Malawi}/do/ihs3lpnl/hh/hh_g1.do"			//	household daily food consumption information
		do "${Malawi}/do/ihs3lpnl/hh/hh_g2.do"			//	Food Consumption Score 
		do "${Malawi}/do/ihs3lpnl/hh/hh_h.do"			//	Coping Strategies Index
		do "${Malawi}/do/ihs3lpnl/hh/hh_i2.do"			//	household expenditures, one-month recall 
		do "${Malawi}/do/ihs3lpnl/hh/hh_j.do"			//	household expenditures, three-month recall
		do "${Malawi}/do/ihs3lpnl/hh/hh_k.do"			//	household expenditures, 12-month recall 
		do "${Malawi}/do/ihs3lpnl/hh/hh_l.do"			//	household assets
		do "${Malawi}/do/ihs3lpnl/hh/hh_m.do"			//	agricultural assets
		do "${Malawi}/do/ihs3lpnl/hh/hh_n1.do"			//	household non-agricultural enterprises 
		do "${Malawi}/do/ihs3lpnl/hh/hh_n2.do"			//	individual non-agricultural enterprises 
		do "${Malawi}/do/ihs3lpnl/hh/hh_o.do"			//	biological children of head/spouse living elsewhere 
		do "${Malawi}/do/ihs3lpnl/hh/hh_p.do"			//	other income types; gifts, investment/rent, asset sales
		do "${Malawi}/do/ihs3lpnl/hh/hh_q.do"			//	gifts given out
		do "${Malawi}/do/ihs3lpnl/hh/hh_r.do"			//	social transfers 
		do "${Malawi}/do/ihs3lpnl/hh/hh_s1.do"			//	household access to credit 
		do "${Malawi}/do/ihs3lpnl/hh/hh_s2.do"			//	household credit refusal 
		do "${Malawi}/do/ihs3lpnl/hh/hh_u.do"			//	shocks experienced
		do "${Malawi}/do/ihs3lpnl/hh/hh_w.do"			//	deaths in last two years 
		do "${Malawi}/do/ihs3lpnl/hh/hh_x.do"			//	fishery participation 
	*	Household aggregated variable creation 
		do "${Malawi}/do/ihs3lpnl/merge/fss.do"				//	Food Security Status
		do "${Malawi}/do/ihs3lpnl/merge/wealthindices.do"	//	Household and agricultural wealth indices 
	*	Agriculture raw data work
		do "${Malawi}/do/ihs3lpnl/ag/ag_c.do"			//	rainy season plot size
		do "${Malawi}/do/ihs3lpnl/ag/ag_d.do"			//	rainy season plot details
		do "${Malawi}/do/ihs3lpnl/ag/ag_e.do"			//	household input coupons
		do "${Malawi}/do/ihs3lpnl/ag/ag_f.do"			//	household rainy season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs3lpnl/ag/ag_g.do"			//	rainy season crop x plot harvest 
		do "${Malawi}/do/ihs3lpnl/ag/ag_h.do"			//	household rainy season purchases of seed 
		do "${Malawi}/do/ihs3lpnl/ag/ag_i.do"			//	rainy season crop disposition and unit value 
		do "${Malawi}/do/ihs3lpnl/ag/ag_j.do"			//	dimba season plot size
		do "${Malawi}/do/ihs3lpnl/ag/ag_k.do"			//	dimba season plot details
		do "${Malawi}/do/ihs3lpnl/ag/ag_l.do"			//	household dimba season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs3lpnl/ag/ag_m.do"			//	dimba season crop x plot harvest 
		do "${Malawi}/do/ihs3lpnl/ag/ag_n.do"			//	household dimba season purchases of seed
		do "${Malawi}/do/ihs3lpnl/ag/ag_o.do"			//	dimba season crop disposition and unit value 
		do "${Malawi}/do/ihs3lpnl/ag/ag_p.do"			//	tree/permanent crop production
		do "${Malawi}/do/ihs3lpnl/ag/ag_q.do"			//	tree/permanent crop disposition and unit value 
		do "${Malawi}/do/ihs3lpnl/ag/ag_r.do"			//	livestock 
		do "${Malawi}/do/ihs3lpnl/ag/ag_s.do"			//	livestock by-products
		do "${Malawi}/do/ihs3lpnl/ag/ag_t.do"			//	extension information
		do "${Malawi}/do/ihs3lpnl/ag/ag_nr.do"			//	network roster 
	*	Agricultural aggregated variable creation 
		do "${Malawi}/do/ihs3lpnl/merge/rs_plot.do"		//	rainy season production at plot level
		do "${Malawi}/do/ihs3lpnl/merge/ds_plot.do"		//	dimba season production at plot level
		do "${Malawi}/do/ihs3lpnl/merge/tp_plot.do"		//	tree/permanent crop production at plot level
		do "${Malawi}/do/ihs3lpnl/merge/rs_hh.do"		//	rainy season production at household level
		do "${Malawi}/do/ihs3lpnl/merge/ds_hh.do"		//	dimba season production at household level
		do "${Malawi}/do/ihs3lpnl/merge/tp_hh.do"		//	tree/permanent crop production at household level
	*	Community raw data work
		do "${Malawi}/do/ihs3lpnl/com/com_b.do"			//	community key informant characteristics
		do "${Malawi}/do/ihs3lpnl/com/com_c.do"			//	community demographics 
		do "${Malawi}/do/ihs3lpnl/com/com_d.do"			//	community infrastructure
		do "${Malawi}/do/ihs3lpnl/com/com_e.do"			//	community labor 
		do "${Malawi}/do/ihs3lpnl/com/com_f.do"			//	community agriculture
		do "${Malawi}/do/ihs3lpnl/com/com_j.do"			//	community organizations 
	*	Final community dataset merge 
		do "${Malawi}/do/ihs3lpnl/merge/com_final.do"	//	community level dataset
	*	Final household dataset merge 
		do "${Malawi}/do/ihs3lpnl/merge/hh_final.do"	//	household level dataset
	*	Final individual dataset merge 
		do "${Malawi}/do/ihs3lpnl/merge/ind_final.do"	//	individual level dataset
	*	Clean up componenet datasets that are now merged into analysis-ready datasets 
		if ${cleanup}==1 do "${Malawi}/do/ihs3lpnl/merge/cleanup.do"		//	erases component datasets 
	}	//	end of if condition to enable creation of IHS3 Long Panel analysis datasets 


*	IHPS Long Panel Dataset Creation
if ${ihpslpnl_run}==1 {	//	if condition to enable creation of IHPS Long Panel analysis datasets 
	*	Household raw data work
		do "${Malawi}/do/ihpslpnl/hh/hh_a.do"			//	basic survey design variables, household location
		do "${Malawi}/do/ihpslpnl/hh/hh_b.do"			//	basic indivisual demographics (age, sex, relationship to household head), household size and make-up variables 
		do "${Malawi}/do/ihpslpnl/hh/hh_c.do"			//	individual education levels, household level education variables
		do "${Malawi}/do/ihpslpnl/hh/hh_d.do"			//	individual health measures, household level health measures 
		do "${Malawi}/do/ihpslpnl/hh/hh_e.do"			//	individual employment information, household level employment variables 
		do "${Malawi}/do/ihpslpnl/hh/hh_f.do"			//	household dwelling characteristics, financial accounts 
		do "${Malawi}/do/ihpslpnl/hh/hh_g1.do"			//	household daily food consumption information
		do "${Malawi}/do/ihpslpnl/hh/hh_g2.do"			//	Food Consumption Score 
		do "${Malawi}/do/ihpslpnl/hh/hh_h.do"			//	Coping Strategies Index
		do "${Malawi}/do/ihpslpnl/hh/hh_i2.do"			//	household expenditures, one-month recall 
		do "${Malawi}/do/ihpslpnl/hh/hh_j.do"			//	household expenditures, three-month recall
		do "${Malawi}/do/ihpslpnl/hh/hh_k.do"			//	household expenditures, 12-month recall 
		do "${Malawi}/do/ihpslpnl/hh/hh_l.do"			//	household assets
		do "${Malawi}/do/ihpslpnl/hh/hh_m.do"			//	agricultural assets
		do "${Malawi}/do/ihpslpnl/hh/hh_n1.do"			//	household non-agricultural enterprises 
		do "${Malawi}/do/ihpslpnl/hh/hh_n2.do"			//	individual non-agricultural enterprises 
		do "${Malawi}/do/ihpslpnl/hh/hh_o.do"			//	biological children of head/spouse living elsewhere 
		do "${Malawi}/do/ihpslpnl/hh/hh_p.do"			//	other income types; gifts, investment/rent, asset sales
		do "${Malawi}/do/ihpslpnl/hh/hh_q.do"			//	gifts given out
		do "${Malawi}/do/ihpslpnl/hh/hh_r.do"			//	social transfers 
		do "${Malawi}/do/ihpslpnl/hh/hh_s1.do"			//	household access to credit 
		do "${Malawi}/do/ihpslpnl/hh/hh_s2.do"			//	household credit refusal 
		do "${Malawi}/do/ihpslpnl/hh/hh_u.do"			//	shocks experienced
		do "${Malawi}/do/ihpslpnl/hh/hh_x.do"			//	fishery participation 
	*	Household aggregated variable creation 
		do "${Malawi}/do/ihpslpnl/merge/fss.do"				//	Food Security Status
		do "${Malawi}/do/ihpslpnl/merge/wealthindices.do"	//	Household and agricultural wealth indices 
	*	Agriculture raw data work
		do "${Malawi}/do/ihpslpnl/ag/ag_c.do"			//	rainy season plot size
		do "${Malawi}/do/ihpslpnl/ag/ag_d.do"			//	rainy season plot details
		do "${Malawi}/do/ihpslpnl/ag/ag_e.do"			//	household input coupons
		do "${Malawi}/do/ihpslpnl/ag/ag_f.do"			//	household rainy season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihpslpnl/ag/ag_g.do"			//	rainy season crop x plot harvest 
		do "${Malawi}/do/ihpslpnl/ag/ag_h.do"			//	household rainy season purchases of seed 
		do "${Malawi}/do/ihpslpnl/ag/ag_i.do"			//	rainy season crop disposition and unit value 
		do "${Malawi}/do/ihpslpnl/ag/ag_j.do"			//	dimba season plot size
		do "${Malawi}/do/ihpslpnl/ag/ag_k.do"			//	dimba season plot details
		do "${Malawi}/do/ihpslpnl/ag/ag_l.do"			//	household dimba season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihpslpnl/ag/ag_m.do"			//	dimba season crop x plot harvest 
		do "${Malawi}/do/ihpslpnl/ag/ag_n.do"			//	household dimba season purchases of seed
		do "${Malawi}/do/ihpslpnl/ag/ag_o.do"			//	dimba season crop disposition and unit value 
		do "${Malawi}/do/ihpslpnl/ag/ag_p.do"			//	tree/permanent crop production
		do "${Malawi}/do/ihpslpnl/ag/ag_q.do"			//	tree/permanent crop disposition and unit value 
		do "${Malawi}/do/ihpslpnl/ag/ag_r.do"			//	livestock 
		do "${Malawi}/do/ihpslpnl/ag/ag_s.do"			//	livestock by-products
		do "${Malawi}/do/ihpslpnl/ag/ag_t.do"			//	extension information
		do "${Malawi}/do/ihpslpnl/ag/ag_nr.do"			//	network roster 
	*	Agricultural aggregated variable creation 
		do "${Malawi}/do/ihpslpnl/merge/rs_plot.do"		//	rainy season production at plot level
		do "${Malawi}/do/ihpslpnl/merge/ds_plot.do"		//	dimba season production at plot level
		do "${Malawi}/do/ihpslpnl/merge/tp_plot.do"		//	tree/permanent crop production at plot level
		do "${Malawi}/do/ihpslpnl/merge/rs_hh.do"		//	rainy season production at household level
		do "${Malawi}/do/ihpslpnl/merge/ds_hh.do"		//	dimba season production at household level
		do "${Malawi}/do/ihpslpnl/merge/tp_hh.do"		//	tree/permanent crop production at household level
	*	Community raw data work
		do "${Malawi}/do/ihpslpnl/com/com_b.do"			//	community key informant characteristics
		do "${Malawi}/do/ihpslpnl/com/com_c.do"			//	community demographics 
		do "${Malawi}/do/ihpslpnl/com/com_d.do"			//	community infrastructure
		do "${Malawi}/do/ihpslpnl/com/com_e.do"			//	community labor 
		do "${Malawi}/do/ihpslpnl/com/com_f.do"			//	community agriculture
		do "${Malawi}/do/ihpslpnl/com/com_j.do"			//	community organizations 
	*	Final community dataset merge 
		do "${Malawi}/do/ihpslpnl/merge/com_final.do"	//	community level dataset
	*	Final household dataset merge 
		do "${Malawi}/do/ihpslpnl/merge/hh_final.do"	//	household level dataset
	*	Final individual dataset merge 
		do "${Malawi}/do/ihpslpnl/merge/ind_final.do"	//	individual level dataset
	*	Clean up componenet datasets that are now merged into analysis-ready datasets 
		if ${cleanup}==1 do "${Malawi}/do/ihpslpnl/merge/cleanup.do"		//	erases component datasets 
	}	//	end of if condition to enable creation of IHPS Long Panel analysis datasets 


*	IHS4 Long Panel Dataset Creation
if ${ihs4lpnl_run}==1 {	//	if condition to enable creation of IHS4 Long Panel analysis datasets 
	*	Household raw data work
		do "${Malawi}/do/ihs4lpnl/hh/hh_a.do"			//	basic survey design variables, household location
		do "${Malawi}/do/ihs4lpnl/hh/hh_b.do"			//	basic indivisual demographics (age, sex, relationship to household head), household size and make-up variables 
		do "${Malawi}/do/ihs4lpnl/hh/hh_c.do"			//	individual education levels, household level education variables
		do "${Malawi}/do/ihs4lpnl/hh/hh_d.do"			//	individual health measures, household level health measures 
		do "${Malawi}/do/ihs4lpnl/hh/hh_e.do"			//	individual employment information, household level employment variables 
		do "${Malawi}/do/ihs4lpnl/hh/hh_f.do"			//	household dwelling characteristics, financial accounts 
		do "${Malawi}/do/ihs4lpnl/hh/hh_g1.do"			//	household daily food consumption information
		do "${Malawi}/do/ihs4lpnl/hh/hh_g2.do"			//	Food Consumption Score 
		do "${Malawi}/do/ihs4lpnl/hh/hh_h.do"			//	Coping Strategies Index
		do "${Malawi}/do/ihs4lpnl/hh/hh_i2.do"			//	household expenditures, one-month recall 
		do "${Malawi}/do/ihs4lpnl/hh/hh_j.do"			//	household expenditures, three-month recall
		do "${Malawi}/do/ihs4lpnl/hh/hh_k.do"			//	household expenditures, 12-month recall 
		do "${Malawi}/do/ihs4lpnl/hh/hh_l.do"			//	household assets
		do "${Malawi}/do/ihs4lpnl/hh/hh_m.do"			//	agricultural assets
		do "${Malawi}/do/ihs4lpnl/hh/hh_n1.do"			//	household non-agricultural enterprises 
		do "${Malawi}/do/ihs4lpnl/hh/hh_n2.do"			//	individual non-agricultural enterprises 
		do "${Malawi}/do/ihs4lpnl/hh/hh_o.do"			//	biological children of head/spouse living elsewhere 
		do "${Malawi}/do/ihs4lpnl/hh/hh_p.do"			//	other income types; gifts, investment/rent, asset sales
		do "${Malawi}/do/ihs4lpnl/hh/hh_q.do"			//	gifts given out
		do "${Malawi}/do/ihs4lpnl/hh/hh_r.do"			//	social transfers 
		do "${Malawi}/do/ihs4lpnl/hh/hh_s1.do"			//	household access to credit 
		do "${Malawi}/do/ihs4lpnl/hh/hh_s2.do"			//	household credit refusal 
		do "${Malawi}/do/ihs4lpnl/hh/hh_u.do"			//	shocks experienced
		do "${Malawi}/do/ihs4lpnl/hh/hh_w.do"			//	deaths in last two years 
		do "${Malawi}/do/ihs4lpnl/hh/hh_x.do"			//	fishery participation 
	*	Household aggregated variable creation 
		do "${Malawi}/do/ihs4lpnl/merge/fss.do"				//	Food Security Status
		do "${Malawi}/do/ihs4lpnl/merge/wealthindices.do"	//	Household and agricultural wealth indices 
	*	Agriculture raw data work
		do "${Malawi}/do/ihs4lpnl/ag/ag_c.do"			//	rainy season plot size
		do "${Malawi}/do/ihs4lpnl/ag/ag_d.do"			//	rainy season plot details
		do "${Malawi}/do/ihs4lpnl/ag/ag_e.do"			//	household input coupons
		do "${Malawi}/do/ihs4lpnl/ag/ag_f.do"			//	household rainy season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs4lpnl/ag/ag_g.do"			//	rainy season crop x plot harvest 
		do "${Malawi}/do/ihs4lpnl/ag/ag_h.do"			//	household rainy season purchases of seed 
		do "${Malawi}/do/ihs4lpnl/ag/ag_i.do"			//	rainy season crop disposition and unit value 
		do "${Malawi}/do/ihs4lpnl/ag/ag_j.do"			//	dimba season plot size
		do "${Malawi}/do/ihs4lpnl/ag/ag_k.do"			//	dimba season plot details
		do "${Malawi}/do/ihs4lpnl/ag/ag_l.do"			//	household dimba season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs4lpnl/ag/ag_m.do"			//	dimba season crop x plot harvest 
		do "${Malawi}/do/ihs4lpnl/ag/ag_n.do"			//	household dimba season purchases of seed
		do "${Malawi}/do/ihs4lpnl/ag/ag_o.do"			//	dimba season crop disposition and unit value 
		do "${Malawi}/do/ihs4lpnl/ag/ag_p.do"			//	tree/permanent crop production
		do "${Malawi}/do/ihs4lpnl/ag/ag_q.do"			//	tree/permanent crop disposition and unit value 
		do "${Malawi}/do/ihs4lpnl/ag/ag_r.do"			//	livestock 
		do "${Malawi}/do/ihs4lpnl/ag/ag_s.do"			//	livestock by-products
		do "${Malawi}/do/ihs4lpnl/ag/ag_t.do"			//	extension information
		do "${Malawi}/do/ihs4lpnl/ag/ag_nr.do"			//	network roster 
	*	Agricultural aggregated variable creation 
		do "${Malawi}/do/ihs4lpnl/merge/rs_plot.do"		//	rainy season production at plot level
		do "${Malawi}/do/ihs4lpnl/merge/ds_plot.do"		//	dimba season production at plot level
		do "${Malawi}/do/ihs4lpnl/merge/tp_plot.do"		//	tree/permanent crop production at plot level
		do "${Malawi}/do/ihs4lpnl/merge/rs_hh.do"		//	rainy season production at household level
		do "${Malawi}/do/ihs4lpnl/merge/ds_hh.do"		//	dimba season production at household level
		do "${Malawi}/do/ihs4lpnl/merge/tp_hh.do"		//	tree/permanent crop production at household level
	*	Community raw data work
		do "${Malawi}/do/ihs4lpnl/com/com_b.do"			//	community key informant characteristics
		do "${Malawi}/do/ihs4lpnl/com/com_c.do"			//	community demographics 
		do "${Malawi}/do/ihs4lpnl/com/com_d.do"			//	community infrastructure
		do "${Malawi}/do/ihs4lpnl/com/com_e.do"			//	community labor 
		do "${Malawi}/do/ihs4lpnl/com/com_f.do"			//	community agriculture
		do "${Malawi}/do/ihs4lpnl/com/com_j.do"			//	community organizations 
	*	Final community dataset merge 
		do "${Malawi}/do/ihs4lpnl/merge/com_final.do"	//	community level dataset
	*	Final household dataset merge 
		do "${Malawi}/do/ihs4lpnl/merge/hh_final.do"	//	household level dataset
	*	Final individual dataset merge 
		do "${Malawi}/do/ihs4lpnl/merge/ind_final.do"	//	individal level dataset
	*	Clean up componenet datasets that are now merged into analysis-ready datasets 
		if ${cleanup}==1 do "${Malawi}/do/ihs4lpnl/merge/cleanup.do"		//	erases component datasets 
	}	//	end of if condition to enable creation of IHS4 Long Panel analysis datasets 



	
********************************************************************************
*	2016 IHS4 Cross-Section Dataset Creation
********************************************************************************

if ${ihs4cx_run}==1 {	//	if condition to enable creation of IHS4 Cross-Section analysis datasets 
	*	Household raw data work
		do "${Malawi}/do/ihs4cx/hh/hh_a.do"				//	basic survey design variables, household location
		do "${Malawi}/do/ihs4cx/hh/hh_b.do"				//	basic indivisual demographics (age, sex, relationship to household head), household size and make-up variables 
		do "${Malawi}/do/ihs4cx/hh/hh_c.do"				//	individual education levels, household level education variables
		do "${Malawi}/do/ihs4cx/hh/hh_d.do"				//	individual health measures, household level health measures 
		do "${Malawi}/do/ihs4cx/hh/hh_e.do"				//	individual employment information, household level employment variables 
		do "${Malawi}/do/ihs4cx/hh/hh_f.do"				//	household dwelling characteristics, financial accounts 
		do "${Malawi}/do/ihs4cx/hh/hh_g1.do"			//	household daily food consumption information
		do "${Malawi}/do/ihs4cx/hh/hh_g2.do"			//	Food Consumption Score 
		do "${Malawi}/do/ihs4cx/hh/hh_h.do"				//	Coping Strategies Index
		do "${Malawi}/do/ihs4cx/hh/hh_i2.do"			//	household expenditures, one-month recall 
		do "${Malawi}/do/ihs4cx/hh/hh_j.do"				//	household expenditures, three-month recall
		do "${Malawi}/do/ihs4cx/hh/hh_k.do"				//	household expenditures, 12-month recall 
		do "${Malawi}/do/ihs4cx/hh/hh_l.do"				//	household assets
		do "${Malawi}/do/ihs4cx/hh/hh_m.do"				//	agricultural assets
		do "${Malawi}/do/ihs4cx/hh/hh_n1.do"			//	household non-agricultural enterprises 
		do "${Malawi}/do/ihs4cx/hh/hh_n2.do"			//	individual non-agricultural enterprises 
		do "${Malawi}/do/ihs4cx/hh/hh_o.do"				//	biological children of head/spouse living elsewhere 
		do "${Malawi}/do/ihs4cx/hh/hh_p.do"				//	other income types; gifts, investment/rent, asset sales
		do "${Malawi}/do/ihs4cx/hh/hh_q.do"				//	gifts given out
		do "${Malawi}/do/ihs4cx/hh/hh_r.do"				//	social transfers 
		do "${Malawi}/do/ihs4cx/hh/hh_s1.do"			//	household access to credit 
		do "${Malawi}/do/ihs4cx/hh/hh_s2.do"			//	household credit refusal 
		do "${Malawi}/do/ihs4cx/hh/hh_u.do"				//	shocks experienced
		do "${Malawi}/do/ihs4cx/hh/hh_w.do"				//	deaths in last two years 
		do "${Malawi}/do/ihs4cx/hh/hh_x.do"				//	fishery participation 
	*	Household aggregated variable creation 
		do "${Malawi}/do/ihs4cx/merge/fss.do"				//	Food Security Status
		do "${Malawi}/do/ihs4cx/merge/wealthindices.do"		//	Household and agricultural wealth indices 
	*	Agriculture raw data work
		do "${Malawi}/do/ihs4cx/ag/ag_c.do"				//	rainy season plot size
		do "${Malawi}/do/ihs4cx/ag/ag_d.do"				//	rainy season plot details
		do "${Malawi}/do/ihs4cx/ag/ag_e.do"				//	household input coupons
		do "${Malawi}/do/ihs4cx/ag/ag_f.do"				//	household rainy season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs4cx/ag/ag_g.do"				//	rainy season crop x plot harvest 
		do "${Malawi}/do/ihs4cx/ag/ag_h.do"				//	household rainy season purchases of seed 
		do "${Malawi}/do/ihs4cx/ag/ag_i.do"				//	rainy season crop disposition and unit value 
		do "${Malawi}/do/ihs4cx/ag/ag_j.do"				//	dimba season plot size
		do "${Malawi}/do/ihs4cx/ag/ag_k.do"				//	dimba season plot details
		do "${Malawi}/do/ihs4cx/ag/ag_l.do"				//	household dimba season purchases of fertilizer / pesticide
		do "${Malawi}/do/ihs4cx/ag/ag_m.do"				//	dimba season crop x plot harvest 
		do "${Malawi}/do/ihs4cx/ag/ag_n.do"				//	household dimba season purchases of seed
		do "${Malawi}/do/ihs4cx/ag/ag_o.do"				//	dimba season crop disposition and unit value 
		do "${Malawi}/do/ihs4cx/ag/ag_p.do"				//	tree/permanent crop production
		do "${Malawi}/do/ihs4cx/ag/ag_q.do"				//	tree/permanent crop disposition and unit value 
		do "${Malawi}/do/ihs4cx/ag/ag_r.do"				//	livestock 
		do "${Malawi}/do/ihs4cx/ag/ag_s.do"				//	livestock by-products
		do "${Malawi}/do/ihs4cx/ag/ag_t.do"				//	extension information
		do "${Malawi}/do/ihs4cx/ag/ag_nr.do"			//	network roster 
	*	Agricultural aggregated variable creation 
		do "${Malawi}/do/ihs4cx/merge/rs_plot.do"		//	rainy season production at plot level
		do "${Malawi}/do/ihs4cx/merge/ds_plot.do"		//	dimba season production at plot level
		do "${Malawi}/do/ihs4cx/merge/tp_plot.do"		//	tree/permanent crop production at plot level
		do "${Malawi}/do/ihs4cx/merge/rs_hh.do"			//	rainy season production at household level
		do "${Malawi}/do/ihs4cx/merge/ds_hh.do"			//	dimba season production at household level
		do "${Malawi}/do/ihs4cx/merge/tp_hh.do"			//	tree/permanent crop production at household level
	*	Community raw data work
		do "${Malawi}/do/ihs4cx/com/com_b.do"			//	community key informant characteristics
		do "${Malawi}/do/ihs4cx/com/com_c.do"			//	community demographics 
		do "${Malawi}/do/ihs4cx/com/com_d.do"			//	community infrastructure
		do "${Malawi}/do/ihs4cx/com/com_e.do"			//	community labor 
		do "${Malawi}/do/ihs4cx/com/com_f.do"			//	community agriculture
		do "${Malawi}/do/ihs4cx/com/com_j.do"			//	community organizations 
	*	Final community dataset merge 
		do "${Malawi}/do/ihs4cx/merge/com_final.do"		//	community level dataset
	*	Final household dataset merge 
		do "${Malawi}/do/ihs4cx/merge/hh_final.do"		//	household level dataset
	*	Final individual dataset merge 
		do "${Malawi}/do/ihs4cx/merge/ind_final.do"		//	household level dataset
	*	Clean up componenet datasets that are now merged into analysis-ready datasets 
		if ${cleanup}==1 do "${Malawi}/do/ihs4cx/merge/cleanup.do"		//	erases component datasets 
	}	//	end of if condition to enable creation of IHS4 Cross-Section analysis datasets 


















