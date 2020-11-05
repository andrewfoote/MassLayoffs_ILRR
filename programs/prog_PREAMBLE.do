*THIS DOFILE IS A PREAMBLE FOR MOST REGRESSION FILES.;
	*it sets the panel, creates fe's, etc.;
#delimit;
xtset fips year;



******************************* ;
* REGRESSIONS OUTCOME VARIALBES;
******************************* ;

gen total_ext_shareLF_lf = total_ext/L.lau_LF ;
gen new_disabled_share_lf = new_disabled/L.lau_LF ;
gen new_retired_share_lf = new_retired/L.lau_LF ;

gen total_ext_shareLF = total_ext/L.lau_LF ;
gen new_disabled_share = new_disabled/L.total_pop ;
gen new_retired_share = new_retired/L.total_pop ;

gen inmigration_pct=inmigration_rate/10; 
gen outmigration_pct=outmigration_rate/10; 

*measures of LF, participation, and employment change;
*gen net_LF_share=(lau_LF-l.lau_LF)/l.lau_LF;
gen net_LF_share=(lau_LF-l.lau_LF)/l.total_pop;
*gen lf_pop_share=(lau_LF-l.lau_LF)/l.total_pop;
*gen lf_pop_rate=lau_LF/total_pop;
gen pot_LF_share=(total_age_16_65_pop-l.total_age_16_65_pop)/l.total_pop;
gen lf_pot_share=(lau_LF-l.lau_LF)/l.total_age_16_65_pop;
gen net_erate_share=(lau_emp-l.lau_emp)/l.lau_LF;
gen emp_rate=lau_emp/l.lau_LF;
gen net_emp_share=(lau_emp-l.lau_emp)/(l.lau_emp);
gen nilf=total_age_16_65_pop-lau_LF;
gen net_nonpart_share=(nilf-l.nilf)/l.total_pop;


foreach v of varlist oasdi_* medical* transfers*{;
		gen ln_`v'=ln(`v');
		gen sh_`v'=`v'/l.lau_LF;
		gen lsh_`v'=ln(sh_`v');
		};

************************************;
*SHARE VARIABLES WITH 1996 VALUES AS DENOMINATOR;
	*1996 is the first year that has exemption, population, and labor force data;
**************************************;		

gen dropme=lau_LF if year==1996;
	bysort fips: egen lau_LF96=mean(dropme);
	drop dropme;

	
gen total_ext_shareLF96 = total_ext/lau_LF96 ;
	
********************************;
*Special Variables;
*******************************;
gen nolayoff=(total==0);


drop if year>2010;


*************************************** ;
* FLAGGING OBSERVATIONS THAT HAVE ALL OUTCOMES
* AVAILABLE ;

foreach outcome in net_LF_share inmigration_rate outmigration_rate new_disabled_share new_retired_share { ;
	gen `outcome'_flag = `outcome'!= . ;
	tab year `outcome'_flag, m; 
} ;

gen alloutcomes = (net_LF_share_flag == 1 &
					 inmigration_rate_flag == 1 &  
					 outmigration_rate_flag == 1 &
					 new_disabled_share_flag == 1 & 
					 new_retired_share_flag == 1 ) ;
*************************************** ;

/**********************************************
Created cty trends
************************************************/

qui tab fips, gen(cty) ;
qui tab year, gen(yearfe) ;

gen t = year - 1996 ;

foreach county of varlist cty* { ;
     gen trend_`county' = t*(`county' == 1) ;
} ; 

drop cty*  ;
