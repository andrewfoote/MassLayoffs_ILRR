/*******************************************************************************************
Last edited on Monday, October 27th
***********************************************************************************************/


clear all
set more off 
cap log close 
set mem 800m 
set matsize 2000 
set maxvar 10000
set matsize 10000


global stub "[stub]" 
global logdir "$stub" 
global datadir "[data]" 
global resultsdir "$stub/results" 
global prodir "$stub" 


log using "${logdir}/migration_decompositions_${S_DATE}.log", replace

#delimit;
use "${datadir}/FINAL_MASSLAYOFF_DATA_forrep.dta", clear  ;

#delimit;
do "${prodir}/prog_PREAMBLE";
keep if alloutcomes == 1 ; /*to keep Ns constant across regressions*/

**********************************************************;



keep if year>1995 & year!=.;





local inmigration_ratenm "In-Migration" ;
local outmigration_ratenm "Out-Migration" ;
local new_disabled_sharenm "Disability" ;
local  new_retired_sharenm "Retirement" ;

local append replace;
eststo clear ;
local x = 1 ;
foreach outcome in inmigration_rate inmigration_instate_rate 
					inmigration_outstate_rate inmigration_adjacent_rate
					inmigration_nonadj_rate { ;
	
		eststo spec`x': reg `outcome' total_ext_shareLF L.total_ext_shareLF L2.total_ext_shareLF 
		                                                    yearfe* i.fips trend_* , cluster(stfip);
			 
			lincom (total_ext_shareLF+L.total_ext_shareLF+L2.total_ext_shareLF);
			estadd	local total_beta = string(r(estimate), "%5.4f"): spec`x'  ;
			estadd	local total_se = "(" + string(r(se), "%5.4f") + ")": spec`x'  ;
			estadd local total_pval =  string(tprob(r(df),(r(estimate)/r(se))),"%5.4f"): spec`x' ;

			sum `outcome' if e(sample) [weight = total_pop] ;
			estadd local Y_mean = round(r(mean),.001): spec`x' ;
			local x = `x' + 1 ;
			
};	
		esttab using "${resultsdir}/migration_decompositions.tex", `append' se ar2 star(* .10 ** .05 *** .01) 
		noconstant compress label  title("Effect of Layoff Events on `outcome' - for `urban`urban''") 
		keep(total_ext_shareLF L.total_ext_shareLF L2.total_ext_shareLF) 
		stat(total_beta total_se total_pval Y_mean r2_a N, 
			labels("`region'" "(se)" "Pval" "Y-Mean" "Adjusted R-Squared" "Observations"))
		addnotes("Standard Errors Clustered on State.");

local append append;
eststo clear ;
foreach outcome in outmigration_rate outmigration_instate_rate outmigration_outstate_rate 
					outmigration_adjacent_rate outmigration_nonadj_rate { ;
					
	eststo spec`x': reg `outcome' total_ext_shareLF L.total_ext_shareLF L2.total_ext_shareLF yearfe* i.fips trend_*  , cluster(stfip);
			 
			lincom (total_ext_shareLF+L.total_ext_shareLF+L2.total_ext_shareLF);
			estadd	local total_beta = string(r(estimate), "%5.4f"): spec`x'  ;
			estadd	local total_se = "(" + string(r(se), "%5.4f") + ")": spec`x'  ;
			estadd local total_pval =  string(tprob(r(df),(r(estimate)/r(se))),"%5.4f"): spec`x' ;

			sum `outcome' if e(sample) [weight = total_pop] ;
			estadd local Y_mean = string(r(mean),"%4.3f"): spec`x' ;
			local x = `x' + 1 ;	
					
} ;

		esttab using "${resultsdir}/migration_decompositions.tex", `append' se ar2 star(* .10 ** .05 *** .01) 
		noconstant compress label  title("Effect of Layoff Events on `outcome' - for `urban`urban''") 
		keep(total_ext_shareLF L.total_ext_shareLF L2.total_ext_shareLF) 
		stat(total_beta total_se total_pval Y_mean r2_a N, 
			labels("`region'" "(se)" "Pval" "Y-Mean" "Adjusted R-Squared" "Observations"))
		addnotes("Standard Errors Clustered on State.");
	
log close ;
