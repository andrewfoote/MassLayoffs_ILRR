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

global stub "" 
global logdir "$stub" 
global datadir "[data]" 
global resultsdir "$stub/results" 
global prodir "$stub" 

#delimit;
use "${datadir}/msacrosswalk.dta", clear ;
rename receiving_county fips ;

replace metarea = 1 ;
rename metarea urban ;
sort fips ;
tempfile msa ;
save `msa', replace ;


use "${datadir}/FINAL_MASSLAYOFF_DATA.dta", clear  ;
sort fips  ;
merge fips using `msa' ;
tab _merge ;

drop if _merge == 2 ;
replace urban = 0 if _merge == 1 ;
drop _merge ;


#delimit;
do "${prodir}/prog_PREAMBLE";
**********************************************************;

replace outmigration_rate=outmigration_rate/10;
replace inmigration_rate=inmigration_rate/10;

gen residual=net_LF_share-0.65*(outmigration_rate-inmigration_rate)-new_disabled_share_-new_retired_share;


keep if year>1999 & year<2011 & year!=.;
gen prerece=year<=2006 & year~=.;

/*How many times did a county surpass a certain layoff pct?*/
foreach z in 1 2 3 4 5{;
	gen hit_that_`z'=total_ext_shareLF>=(`z'/100) & total_ext_shareLF~=.;
	bysort fips: egen s_hit_that_`z'=total(hit_that_`z');
	replace s_hit_that_`z'=s_hit_that_`z'>0;

	gen phit_that_`z'=total_ext_shareLF>=(`z'/100) & total_ext_shareLF~=. & prerece==1;
	bysort fips: egen spr_hit_that_`z'=total(phit_that_`z');
	replace spr_hit_that_`z'=spr_hit_that_`z'>0;

	gen ahit_that_`z'=total_ext_shareLF>=(`z'/100) & total_ext_shareLF~=. & prerece==0;
	bysort fips: egen sa_hit_that_`z'=total(ahit_that_`z');
	replace sa_hit_that_`z'=sa_hit_that_`z'>0;	
	};
	egen tagflag=tag(fips);

		foreach z in 1 2 3 4 5{;
		estpost summ s_hit_that_`z' if tagflag==1;
		est sto all_hit_that_`z';
		estpost summ spr_hit_that_`z' if tagflag==1;
		est sto pre_hit_that_`z';
		estpost summ sa_hit_that_`z' if tagflag==1;
		est sto pos_hit_that_`z';		
		};
		
		
	foreach var in total_ext_shareLF total_ext net_LF_share pot_LF_share inmigration_rate outmigration_rate new_disabled_share new_retired_share residual{;
		estpost summ `var';
		est sto all_`var';
	
		estpost summ `var' if prerece==1;
		est sto pre_`var';
		
		estpost summ `var' if prerece==0;
		est sto pos_`var';
		};
		
		
	local append replace;
	foreach var of varlist hit_that_* total_ext_shareLF total_ext net_LF_share pot_LF_share inmigration_rate outmigration_rate new_disabled_share new_retired_share  residual{;
		
	esttab all_`var' pre_`var' pos_`var' using "$resultsdir/sumstattable.csv", 
			`append' nodepvars nonumbers plain nomtitles cell(mean sd(par)) noobs;
	local append append;
	};
		
		
	
