***************************************************
/*
First created: 5.11.2015 by Andrew Foote
Last Updated: 5.11.2015 by Andrew Foote

Our regressions, at the commuting zone level.
Allowing for different effects before and after great recession.

*/
***************************************************


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

log using "${logdir}/cz_sumtable_prepost_${S_DATE}.log", replace


use "${datadir}/FINAL_MASSLAYOFF_CZONE_forrep.dta", clear 
#delimit;
*************************************** ;
* FLAGGING OBSERVATIONS THAT HAVE ALL OUTCOMES
* AVAILABLE ;
foreach outcome in net_LF_share inmigration_rate outmigration_rate new_disabled_share new_retired_share net_nonpart_share{ ;
	gen `outcome'_flag = `outcome'!= . ;
	tab year `outcome'_flag, m; 
	tabstat `outcome', by(year) ;
} ;

gen alloutcomes = (net_LF_share_flag == 1 &
					 inmigration_rate_flag == 1 &  
					 outmigration_rate_flag == 1 &
					 new_disabled_share_flag == 1 & 
					 new_retired_share_flag == 1 ) ;
*************************************** ;

keep if alloutcomes == 1 ;
tab year, m;  
keep if year >= 2000 ;
********************************************************************;
tab year if total_ext_shareLF==0;
tab year if total_ext_shareLF==.;

qui tab year, gen(yearfe) ;
qui tab czon, gen(czonefe) ;
gen t = year-1996 ; 
foreach czone of varlist czonefe* { ; 
	gen trend_`czone' = t*(`czone'==1) ;
} ;

drop czonefe* ;


gen post_rece=year>=2007;
sort czone year ;
gen layoff_postrece_t0=total_ext_shareLF*post_rece;

gen layoff_postrece_t1=L.total_ext_shareLF*post_rece;

gen layoff_postrece_t2=L2.total_ext_shareLF*post_rece;

local outmigration_ratenm "Outmigration" ;
local new_disabled_sharenm "Disability" ;
local new_retired_sharenm "Retirement" ;

sort czone year ;
eststo clear ;
local x = 1 ;

foreach outcome in net_LF_share inmigration_rate outmigration_rate new_disabled_share new_retired_share net_nonpart_share{ ;
		
	eststo spec`x':reg `outcome' total_ext_shareLF L.total_ext_shareLF L2.total_ext_shareLF 
								 layoff_postrece_t0 layoff_postrece_t1 layoff_postrece_t2
									yearfe* i.czone trend*,  cluster(czone);
		lincom (total_ext_shareLF+L.total_ext_shareLF+L2.total_ext_shareLF);
			local total_`outcome' 	= 	r(estimate) ;
			local var_`outcome' 	=	r(se)^2 ;

		estadd	local total_beta = string(r(estimate),"%5.4f"): spec`x'  ;
		estadd	local total_se = string(r(se),"%5.4f"): spec`x'  ;
		estadd local total_pval = string(tprob(r(df),(r(estimate)/r(se))),"%5.4f"): spec`x' ;
		
		
		sum `outcome' if e(sample) [weight = total_pop] ;
		estadd local Y_mean = string(r(mean),"%4.3f"): spec`x' ;
		
		lincom (layoff_postrece_t0 +layoff_postrece_t1+ layoff_postrece_t2+
				total_ext_shareLF+L.total_ext_shareLF+L2.total_ext_shareLF);
				
			local total_`outcome'P 	= 	r(estimate) ;
			local var_`outcome'P 	=	r(se)^2 ;
			
		estadd	local total_betaP = string(r(estimate), "%5.4f"): spec`x'  ;
		estadd	local total_seP = string(r(se),"%5.4f"): spec`x'  ;
		estadd local total_pvalP = string(tprob(r(df),(r(estimate)/r(se))),"%5.4f"): spec`x' ;

		
local x = `x' + 1 ;
} ;

		local beta_resid = `total_net_LF_share' - `total_inmigration_rate' +  
					`total_outmigration_rate' + `total_new_disabled_share' +
					`total_new_retired_share' ;
					
		local se_resid = sqrt(`var_net_LF_share' + `var_inmigration_rate' +  
					`var_outmigration_rate' + `var_new_disabled_share' +
					`var_new_retired_share') ;
					
		local pval_resid = 2*normal(`beta_resid'/`se_resid') ;
		
		local beta_residP = `total_net_LF_shareP' - `total_inmigration_rateP' +  
					`total_outmigration_rateP' + `total_new_disabled_shareP' +
					`total_new_retired_shareP' ;
					
		local se_residP = sqrt(`var_net_LF_shareP' + `var_inmigration_rateP' +  
					`var_outmigration_rateP' + `var_new_disabled_shareP' +
					`var_new_retired_shareP') ;
					
		local pval_residP = 2*normal(`beta_residP'/`se_residP') ;
		
		********************* ;
		* Making them displayable ;
		********************* ;
		local beta_resid = string(`beta_resid', "%5.4f") ;
		local se_resid = string(`se_resid', "%5.4f") ;
		local pval_resid = string(`pval_resid', "%5.4f") ;
		
		local beta_residP = string(`beta_residP', "%5.4f") ;
		local se_residP = string(`se_residP', "%5.4f") ;
		local pval_residP = string(`pval_residP', "%5.4f") ;
esttab using "${resultsdir}/czoneeffect_sumtable_prepost.tex", replace se ar2 star(* .10 ** .05 *** .01) 
noconstant compress label  title("Effect of Layoff Events on `outcome'") 
keep(total_ext_shareLF L.total_ext_shareLF L2.total_ext_shareLF layoff_postrece_t0 layoff_postrece_t1 layoff_postrece_t2)
stat(total_beta total_se total_pval total_betaP total_seP total_pvalP Y_mean N, 
	labels("Total Effect, Pre" "(se)" "Pval" "Total Effect, Post" "(se)" "Pval" "Y-Mean" "Observations") )
addnotes("Standard Errors Clustered on State. 		
		Residual for Pre-Rec:  `beta_resid'   (`se_resid' ), with pvalue: `pval_resid'
		Residual for Post-Rec: `beta_residP'   (`se_residP'), with pvalue:  `pval_residP'"  );


log close ;
