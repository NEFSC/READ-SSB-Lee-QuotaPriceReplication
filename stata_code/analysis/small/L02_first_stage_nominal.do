/* Code to estimate quarterly OLS models for quota prices */

/*
basic: just run OLS on the raw data with sandwich SE's
cooksd: use cooksd to drop outlier rows.
dropout: drop if less than 5 and recompute total_lbs 
jacknife: run OLS on the raw data with jacknife sandwich SE's
bootstrap: run OLS on the raw data with bootstrap sandwich SE's



replication: zeros out RHS vars if there are less than 5 obs, drops high leverage rows (cooksd>2)
model2: zeros out RHS vars if there are less than 5 obs
parsim: zeros out RHS vars if there are less than 5 obs; drops high leverage rows (cooksd>2); drops out RHS vars that are stastically insignificant and recomputes total pounds before estimating again
zero_out1: zeros out RHS vars if there are less than 5 obs, drops high leverage rows (cooksd>2); recomputes total pounds before final estimation.  



model3: same as parsim but with hc3 standard errors. 

*/

/************************************/
/************************************/
#delimit cr
version 15.1
pause off
mat drop _all
est drop _all
local logfile "${my_results}/first_stage_Nominal.smcl" 
cap log close 
log using `logfile', replace

*local quota_available_indices "${data_intermediate}/quota_available_indices_${vintage_string}.dta"
local in_price_data "${data_intermediate}/cleaned_quota_${vintage_string}.dta" 
local save_file "${data_main}/inter_qtr_v2_nom_${vintage_string}.dta"


/* changing the flavor to GDPDEF, water, or seafood will vary up the deflated variable.*/
local flavor GDPDEF 
local flavor nominal 

local estout_relabel "b_SNEMA_winter:_cons SNEMA_winter b_CCGOM_yellowtail:_cons CCGOM_Yellowtail b_GBE_cod:_cons GBE_Cod b_GBW_cod:_cons GBW_Cod b_GBE_haddock:_cons GBE_Haddock b_GBW_haddock:_cons GBW_Haddock b_GB_winter:_cons GB_Winter b_GB_yellowtail:_cons GB_Yellowtail b_GOM_cod:_cons GOM_Cod b_GOM_haddock:_cons GOM_Haddock b_GOM_winter:_cons GOM_Winter b_plaice:_cons Plaice b_pollock:_cons Pollock b_redfish:_cons Redfish b_SNEMA_yellowtail:_cons SNEMA_Yellowtail b_white_hake:_cons White_hake b_witch_flounder:_cons Witch b_q1:_cons Q1 b_q2:_cons Q2 b_q3:_cons Q3 b_q4:_cons Q4 b_interaction:_cons interaction b_cons:_cons Constant"
local estout_opts "replace style(tex) starlevels(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(2))) stats(r2 rmse aic bic) varlabels(`estout_relabel') mlabels(2010 2011 2012 2013 2014 2015 2016 2017 2018 2019)  substitute(_ \_) "

local out_coefficients "${my_results}/ols_quarterly_replicate_`flavor'${vintage_string}.dta" 

use `in_price_data', clear


cap drop qtr
order z1-z17, after(to_sector_name)
drop if fy>=2021
/* there's only a few obs in Q1 of FY2010 and Q2 of FY2010. I'm pooling them into Q3 of 2010. */
replace q_fy=3 if q_fy<=2 & fy==2010
gen fyq=yq(fy,q_fy)
drop q_fy
gen q_fy=quarter(dofq(fyq))

gen cons=1
gen qtr1 = q_fy==1
gen qtr2 = q_fy==2
gen qtr3 = q_fy==3
gen qtr4 = q_fy==4


gen end=mdy(5,1,fy+1)
gen begin=mdy(5,1,fy)
gen season_remain=(end-date1)/(end-begin)

gen season_elapsed=1-season_remain

Zdelabel



gen nstocks=0

foreach var of varlist CCGOM_yellowtail- SNEMA_winter{
	replace nstocks=nstocks+1 if `var'>0
}
/**/


/* define constraints */
constraint define 1 CCGOM_yellowtail=0
constraint define 2 GBE_cod=0
constraint define 3 GBW_cod=0
constraint define 4 GBE_haddock=0
constraint define 5 GBW_haddock=0
constraint define 6 GB_winter=0
constraint define 7 GB_yellowtail=0
constraint define 8 GOM_cod=0
constraint define 9 GOM_haddock=0
constraint define 10 GOM_winter=0
constraint define 11 plaice=0
constraint define 12 pollock=0
constraint define 13 redfish=0
constraint define 14 SNEMA_yellowtail=0
constraint define 15 white_hake=0
constraint define 16 witch_flounder=0
constraint define 17 SNEMA_winter=0




/* bring in deflators and construct real compensation */

preserve
use  "$data_external/deflatorsQ_${vintage_string}.dta", clear
keep dateq  fGDPDEF_2010Q1 fPCU483483 fPCU31173117_2010Q1

rename fGDPDEF_2010Q1 fGDP
rename fPCU483483 fwater_transport
rename fPCU31173117_2010Q1 fseafoodproductpreparation

notes fGDP: Implicit price deflator
notes fwater: Industry PPI for water transport services
notes fseafood: Industry PPI for seafood product prep and packaging
tempfile deflators
save `deflators'
restore

gen dateq=qofd(date1)
format dateq %tq
merge m:1 dateq using `deflators', keep(1 3)
assert _merge==3
drop _merge


gen compensationR_GDPDEF=compensation/fGDP

gen compensationR_water=compensation/fwater_transport
gen compensationR_seafood=compensation/fseafoodproductpreparation


gen compensationR_nominal=compensation






/* RHS variables */
local rhs CCGOM_yellowtail GBE_cod GBW_cod GBE_haddock GBW_haddock GB_winter GB_yellowtail GOM_cod GOM_haddock GOM_winter plaice pollock redfish  SNEMA_yellowtail  white_hake witch_flounder SNEMA_winter

/* absolute values */
foreach var of local rhs{
    gen ABS_`var'=abs(`var')
}
local ABS_rhs ABS_CCGOM_yellowtail ABS_GBE_cod ABS_GBW_cod ABS_GBE_haddock ABS_GBW_haddock ABS_GB_winter ABS_GB_yellowtail ABS_GOM_cod ABS_GOM_haddock ABS_GOM_winter ABS_plaice ABS_pollock ABS_redfish  ABS_SNEMA_yellowtail  ABS_white_hake ABS_witch_flounder ABS_SNEMA_winter


/* set up interaction variable */
 
cap drop total_lbs
egen total_lbs=rowtotal(`ABS_rhs')
clonevar totalpounds2=total_lbs
levelsof fyq, local(myquarters)
 
tempfile estimation_dataset
save `estimation_dataset', replace
 
/*******************************************************************/ 
/* REPLICATE MODEL 
 -- this should replicate chad's model in R.
 set the variable to zero if there are less than 5 obs in that quarter of positive prices.
This is okay, because that var will have no variation and will not be included in the RHS.  It makes compute the total_lbs variable easier too*/

use `estimation_dataset', clear

/* back up the rhs variables
count up how many i have that are non-zero
Set those rhs variables=0 when I have less than 5
update the absolute values also */
foreach var of local rhs {
	clonevar `var'_bak=`var'
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
	replace ABS_`var'=0 if `tc'<=4

}

/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs


/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
}
gen flag_in=1





/*regress and compute cooks D and flag high leverage rows*/
qui foreach fy of local myquarters{
	
	di "estimating unconstrained OLS for period `fy'"
	regress compensationR_`flavor' `rhs' interaction if fyq==`fy'

	predict cooksd`fy' if e(sample), cooksd
	replace flag_in=0 if cooksd`fy'>=2 & fyq==`fy'
}
drop if flag_in==0
/* set the sparse variables to zero again*/
foreach var of local rhs {
	tempvar count tc
	gen `count'=`var'~=0 
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
	replace ABS_`var'=0 if `tc'<=4

}


/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs


/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
}

assert flag_in==1
statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction, robust 
pause
/* I'm using the "total option of statsby" to hopefully force the full set of regression coefs to pop out 
Then I have to drop it here.*/
drop if fyq==.

format fyq %tq
cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock

cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string
 
gen modeltype="replic"

notes modeltype: replication should match stats from R.


tempfile replication
save `replication', replace
/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 







/*******************************************************************/ 
/* Replicate4 
 -- Replicate chad's model in R.
 set the variable to zero if there are less than 4 obs in that quarter of positive prices.
This is okay, because that var will have no variation and will not be included in the RHS.  It makes compute the total_lbs variable easier too*/

use `estimation_dataset', clear

/* back up the rhs variables
count up how many i have that are non-zero
Set those rhs variables=0 when I have less than 5
update the absolute values also */
foreach var of local rhs {
	clonevar `var'_bak=`var'
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=3
	replace ABS_`var'=0 if `tc'<=3

}

/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs


/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=3
}
gen flag_in=1





/*regress and compute cooks D and flag high leverage rows*/
qui foreach fy of local myquarters{
	
	di "estimating unconstrained OLS for period `fy'"
	regress compensationR_`flavor' `rhs' interaction if fyq==`fy'

	predict cooksd`fy' if e(sample), cooksd
	replace flag_in=0 if cooksd`fy'>=2 & fyq==`fy'
}
drop if flag_in==0
/* set the sparse variables to zero again*/
foreach var of local rhs {
	tempvar count tc
	gen `count'=`var'~=0 
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=3
	replace ABS_`var'=0 if `tc'<=3

}


/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs


/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=3
}

assert flag_in==1
statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction, robust 
pause
/* I'm using the "total option of statsby" to hopefully force the full set of regression coefs to pop out 
Then I have to drop it here.*/
drop if fyq==.

format fyq %tq
cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock

cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string
 
gen modeltype="Replic4"

notes modeltype: Replication, but we keep stocks in if there are at least 4 trades in a quarter.



append using `replication' 
save `replication', replace
/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 











































/*******************************************************************/ 
/* CooksD model; drop outliers only*/
use `estimation_dataset', clear
gen flag_in=1



/*regress and compute cooks D and flag high leverage rows*/
qui foreach fy of local myquarters{
	
	di "estimating unconstrained OLS for period `fy'"
	regress compensationR_`flavor' `rhs' interaction if fyq==`fy'

	predict cooksd`fy' if e(sample), cooksd
	replace flag_in=0 if cooksd`fy'>=2 & fyq==`fy'
}
drop if flag_in==0


/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs

assert flag_in==1
statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction, robust 
pause
drop if fyq==.

format fyq %tq
cap rename _stat_4 _b_GBE_haddock
cap rename _stat_5 _b_GBW_haddock

cap rename _stat_23 _se_GBE_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string
 
gen modeltype="cooksd"

notes modeltype: cooksd drops outlier rows.


append using `replication' 
save `replication', replace
/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 






/*******************************************************************/ 
/* dropout model: drop if less than 5 and recompute total_lbs */
use `estimation_dataset', clear


foreach var of local rhs {
	clonevar `var'_bak=`var'
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
	replace ABS_`var'=0 if `tc'<=4
}

gen flag_in=1
/* recompute total lbs */
cap drop total_lbs
egen total_lbs=rowtotal(`ABS_rhs')

cap drop interaction
gen interaction=lease_only*total_lbs


/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
}






assert flag_in==1
statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction, robust 
pause
drop if fyq==.

cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string
 
gen modeltype="dropout"

notes modeltype: dropout drops RHS variables if there are less than 5 obs.


append using `replication' 
save `replication', replace
/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 






















/*******************************************************************/ 
/*******************************************************************/ 
/* Model 2:  
1. Lets not bother with dropping the high leverage points
*/

use `estimation_dataset', clear

foreach var of local rhs {
clonevar `var'_bak=`var'
tempvar count tc
gen `count'=`var'~=0
bysort fyq: egen `tc'=total(`count')
replace `var'=0 if `tc'<=4
	replace ABS_`var'=0 if `tc'<=4

}
/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs

gen flag_in=1

/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
}

assert flag_in==1
statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction, robust 
pause
drop if fyq==.

cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n


reshape long _b_ _se_, i(fyq) j(var) string
 
gen modeltype="model2"
notes modeltype: model2 does not drop out high leverage obs


append using `replication' 
save `replication', replace




/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 


/*******************************************************************/ 
/*******************************************************************/ 
/* parsim:  
1.Based on the "Replication" model, but we also estimate a model where we 
	zero out pounds that are not statistically significant and re-estimate.
*/

use `estimation_dataset', clear

foreach var of local rhs {
clonevar `var'_bak=`var'
tempvar count tc
gen `count'=`var'~=0
bysort fyq: egen `tc'=total(`count')
replace `var'=0 if `tc'<=4
replace ABS_`var'=0 if `tc'<=4

}

gen flag_in=1


/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs


/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
}


/*regress and compute cooks D and flag high leverage rows*/
qui foreach fy of local myquarters{
	
	di "estimating unconstrained OLS for period `fy'"
	regress compensationR_`flavor' `rhs' interaction if fyq==`fy'

	predict cooksd`fy' if e(sample), cooksd
	replace flag_in=0 if cooksd`fy'>=2 & fyq==`fy'
}
drop if flag_in==0

/* set the sparse variables to zero again*/
foreach var of local rhs {
	tempvar count tc
	gen `count'=`var'~=0 & flag_in==1
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
	replace ABS_`var'=0 if `tc'<=4

}


/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs


/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
}
preserve
assert flag_in==1


statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction, robust 
drop if fyq==.

cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n

/* mark RHS vars that are not statistically significant, I'm using 1.645 as the critical t statistic */

foreach var of local rhs{
gen t_`var'=_b_`var'/_se_`var'
gen keep_`var'=abs(t_`var')>1.645
replace keep_`var'=0 if _se_`var'==0
}
keep fyq keep_*
tempfile zero_out
save `zero_out', replace
restore



merge m:1 fyq using `zero_out'

/* set the variable to zero if it's not statistically significant. Then recompute the total_lbs variable. */

foreach var of local rhs {
replace `var'=0 if keep_`var'==0
replace ABS_`var'=0 if keep_`var'==0

}


/* recompute total lbs and interaction */
cap drop total_lbs
cap drop interaction

egen total_lbs=rowtotal(`ABS_rhs')
gen interaction=lease_only*total_lbs


/* check that there's enough for interaction */
foreach var of varlist interaction {
	tempvar count tc
	gen `count'=`var'~=0
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
}

statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction if flag_in==1, robust 
pause
drop if fyq==.
cap rename _stat_4 _b_GBE_haddock
cap rename _stat_23 _se_GBE_haddock

cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string

gen modeltype="parsim"
notes modeltype: parsim estimates another step where we've zeroed out some values.

append using `replication' 
save `replication', replace



/*
/*******************************************************************/ 
/*******************************************************************/ 
/* Model 3:  
1.Based on the "Parsim " model,but using vce(hc3) standard errors
I think this might not be posting the hc3 standard errors properly*/

use `estimation_dataset', clear

foreach var of local rhs {
clonevar `var'_bak=`var'
tempvar count tc
gen `count'=`var'~=0
bysort fyq: egen `tc'=total(`count')
replace `var'=0 if `tc'<=4
}

gen flag_in=1



/*regress and compute cooks D and flag high leverage rows*/
qui foreach fy of local myquarters{
	
	di "estimating unconstrained OLS for period `fy'"
	regress compensationR_`flavor' `rhs' interaction if fyq==`fy'

	predict cooksd`fy' if e(sample), cooksd
	replace flag_in=0 if cooksd`fy'>=2 & fyq==`fy'
}

/* set the sparse variables to zero again*/
foreach var of local rhs {
	tempvar count tc
	gen `count'=`var'~=0 & flag_in==1
	bysort fyq: egen `tc'=total(`count')
	replace `var'=0 if `tc'<=4
}


preserve

statsby _b _se, by(fyq) clear: regress compensationR_`flavor' `rhs' interaction if flag_in==1, vce(hc3)
format fyq %tq
cap rename _stat_4 _b_GBE_haddock
cap rename _stat_5 _b_GBW_haddock

cap rename _stat_23 _se_GBE_haddock
cap rename _stat_24 _se_GBW_haddock
/* mark RHS vars that are not statistically significant, I'm using 1.645 as the critical t statistic */

foreach var of local rhs{
gen t_`var'=_b_`var'/_se_`var'
gen keep_`var'=abs(t_`var')>1.645
replace keep_`var'=0 if _se_`var'==0
}
keep fyq keep_*
tempfile zero_out
save `zero_out', replace
restore



merge m:1 fyq using `zero_out'

/* set the variable to zero if it's not statistically significant. Then recompute the total_lbs variable. */

foreach var of local rhs {
replace `var'=0 if keep_`var'==0
}
cap drop total_lbs
egen total_lbs=rowtotal(`rhs')





statsby _b _se, by(fyq) clear: regress compensationR_`flavor' `rhs' interaction if flag_in==1, vce(hc3)
format fyq %tq
rename _stat_4 _b_GBE_haddock
rename _stat_5 _b_GBW_haddock

rename _stat_23 _se_GBE_haddock
rename _stat_24 _se_GBW_haddock

rename _stat_18 _b_interaction
rename _stat_37 _se_interaction

rename _eq2_r2 r2
rename _eq2_n n
reshape long _b_ _se_, i(fyq) j(var) string

gen modeltype="model3"

notes modeltype: modeltype 3 is model2 with hc3 standard errors.
append using `replication' 
save `replication', replace

*/



/*******************************************************************/ 
/* BASIC 
This model does no data cleaning; just estimates the hedonic model.*/
use `estimation_dataset', clear

gen flag_in=1

cap drop interaction

gen interaction=lease_only*total_lbs

assert flag_in==1
statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction, robust 
pause
drop if fyq==.

cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string
 
gen modeltype="basic"

notes modeltype: basic does not data cleaning


append using `replication' 
save `replication', replace
/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 




/*******************************************************************/ 
/* groupSE 
This model does no data cleaning; just estimates the hedonic model with dyad clustered SE's.*/
use `estimation_dataset', clear

gen flag_in=1

generate first = cond(from_sector_name < to_sector_name, from_sector_name, to_sector_name)
generate second = cond(from_sector_name < to_sector_name, to_sector_name, from_sector_name)
egen g=group(first second) 
 
cap drop interaction

gen interaction=lease_only*total_lbs


statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction if flag_in==1, vce(cluster g)
pause
drop if fyq==.

cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string
 

gen modeltype="groupSE"

notes modeltype: groupSE clusters the SEs on the to-from pair


append using `replication' 
save `replication', replace
/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 



/*


/*******************************************************************/ 
/* BASIC jacknife
This model does no data cleaning; just estimates the hedonic model using hc3 standard errors.*/
use `estimation_dataset', clear

gen flag_in=1



cap drop interaction

gen interaction=lease_only*total_lbs


statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction if flag_in==1,  vce(jacknife)  
pause
drop if fyq==.

cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string
 

gen modeltype="jacknife"

notes modeltype: jacknife is the same as basic, but with jacknife  standard errors


append using `replication' 
save `replication', replace
/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 




/*******************************************************************/ 
/* BASIC bootstrap
This model does no data cleaning; just estimates the hedonic model bootstrapped standard errors.*/
use `estimation_dataset', clear

gen flag_in=1

cap drop interaction

gen interaction=lease_only*total_lbs


statsby _b _se r2=e(r2) n=e(N), by(fyq) clear total: regress compensationR_`flavor' `rhs' interaction if flag_in==1, vce(bootstrap, rep(500)) 
pause
drop if fyq==.

cap rename _stat_5 _b_GBW_haddock
cap rename _stat_24 _se_GBW_haddock
cap rename _eq2_r2 r2
cap rename _eq2_n n

reshape long _b_ _se_, i(fyq) j(var) string
 

gen modeltype="bootstrap"

notes modeltype: bootstrap is the same as basic, but with bootstrap  standard errors


append using `replication' 
save `replication', replace
/*******************************************************************/ 


*/




 
 
 
 
use `replication', replace
 /*save these in a nice format */
rename _b Estimate
rename _se standard_error

gen t_value=Estimate/standard_error

gen fy=yofd(dofq(fyq))
gen q_fy=quarter(dofq(fyq))


gen stockcode=0
replace stockcode=1 if var=="CCGOM_yellowtail"
replace stockcode=2 if var=="GBE_cod"
replace stockcode=3 if var=="GBW_cod"
replace stockcode=4 if var=="GBE_haddock"
replace stockcode=5 if var=="GBW_haddock"
replace stockcode=6 if var=="GB_winter"
replace stockcode=7 if var=="GB_yellowtail"
replace stockcode=8 if var=="GOM_cod"
replace stockcode=9 if var=="GOM_haddock"
replace stockcode=10 if var=="GOM_winter"


 
replace stockcode=11 if var=="plaice"
replace stockcode=12 if var=="pollock"
replace stockcode=13 if var=="redfish"
replace stockcode=14 if var=="SNEMA_yellowtail"
replace stockcode=15 if var=="white_hake"

 
replace stockcode=16 if var=="witch_flounder"
replace stockcode=17 if var=="SNEMA_winter"

 
 
 
 replace stockcode=1818 if var=="interaction"

replace stockcode=9999 if var=="cons"
merge m:1 stockcode using "${data_main}/stock_codes_${vintage_string}.dta", keep(1 3)

sort fyq var modeltype
encode modeltype, gen(model)
replace stock="Interaction" if stockcode==1818
replace stock="Constant" if stockcode==9999
rename Estimate EstimateN
labmask stockcode, values(stock)
format fyq %tq
save `save_file', replace 
 
 
 log close
 
 
 
 
 
 