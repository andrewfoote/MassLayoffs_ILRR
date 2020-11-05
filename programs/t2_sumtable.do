
clear all
set more off 
cap log close 
set mem 800m 
set matsize 2000 
set maxvar 10000
set matsize 10000
global stub "" 
global logdir "$stub" 
global datadir "[data]" 
global resultsdir "$stub/results" 
global prodir "$stub" 


log using "${logdir}/weighted_sumtable_${S_DATE}.log", replace

use "${datadir}/FINAL_MASSLAYOFF_DATA_forrep.dta", clear 
#delimit;
do "${prodir}/prog_PREAMBLE.do";
keep if alloutcomes == 1 ; /* to keep Ns constant across regressions */

********************************************************************;
tab year if total_ext_shareLF==0;
tab year if total_ext_shareLF==.;

keep if year>1995 & year!=. ;


local total_sum = 0 ;
local lfpr = 1;
sort fips year ;
local outmigration_ratenm "Outmigration" ;
local new_disabled_sharenm "Disability" ;
local new_retired_sharenm "Retirement" ;
eststo clear ;
local x = 1 ;
foreach outcome in net_LF_share inmigration_rate outmigration_rate new_disabled_share new_retired_share net_nonpart_share{ ;
di "***************************************" ;
di "***** OUTCOME: `outcome' **********" ;
di "***************************************" ;
	eststo spec`x': reg `outcome' total_ext_shareLF L.total_ext_shareLF 
		L2.total_ext_shareLF yearfe* i.fips trend_* if year>2000 /*[weight=l.total_pop]*/,   cluster(stfip);
		lincom (total_ext_shareLF+L.total_ext_shareLF+L2.total_ext_shareLF);
		local total_`outcome' = r(estimate) ;
		estadd	local total_beta = string(r(estimate),"%5.4f"): spec`x'  ;
		estadd	local total_se = string(r(se),"%5.4f"): spec`x'  ;
		sum `outcome' if e(sample) [weight = total_pop] ;
		estadd local Y_mean = string(r(mean),"%4.3f"): spec`x' ;
		estadd local CTYFE = "YES": spec`x' ;
		estadd local YRFE = "YES": spec`x' ;
		estadd local TRENDS = "YES": spec`x' ;
		
local x = `x' + 1 ;
} ;

esttab using "${resultsdir}/weighted_sumtable_${S_DATE}.tex", replace se ar2 star(* .10 ** .05 *** .01)  noconstant compress label  title("Effect of Layoff Events on `outcome'") 
keep(total_ext_shareLF L.total_ext_shareLF L2.total_ext_shareLF )
stat(total_beta total_se Y_mean N, labels("Total Effect" "(se)"  "Y-Mean" "Observations") );

log close ;
