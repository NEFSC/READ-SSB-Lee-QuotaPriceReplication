/*Code to tes the differences between GBE and GBW cod prices */

/************************************/
/************************************/
#delimit cr
version 15.1
mat drop _all
est drop _all
local logfile "${my_results}/first_stage_tests.smcl" 
cap log close 
log using `logfile', replace
set scheme s2mono
*local quota_available_indices "${data_intermediate}/quota_available_indices_${vintage_string}.dta"
local in_price_data "${data_intermediate}/cleaned_quota_${vintage_string}.dta" 
local save_file "${data_main}/first_stage_tests_${vintage_string}.dta"




tempname sim
postfile `sim' str16 model double( fyq EW_cod EW_cod_se EW_cod_t EW_cod_lb EW_cod_ub EW_haddock EW_haddock_se EW_haddock_t EW_haddock_lb EW_haddock_ub confidence_interval) using `save_file', replace












/* changing the flavor to GDPDEF, water, or seafood will vary up the deflated variable.*/
local flavor GDPDEF 

local estout_relabel "b_SNEMA_winter:_cons SNEMA_winter b_CCGOM_yellowtail:_cons CCGOM_Yellowtail b_GBE_cod:_cons GBE_Cod b_GBW_cod:_cons GBW_Cod b_GBE_haddock:_cons GBE_Haddock b_GBW_haddock:_cons GBW_Haddock b_GB_winter:_cons GB_Winter b_GB_yellowtail:_cons GB_Yellowtail b_GOM_cod:_cons GOM_Cod b_GOM_haddock:_cons GOM_Haddock b_GOM_winter:_cons GOM_Winter b_plaice:_cons Plaice b_pollock:_cons Pollock b_redfish:_cons Redfish b_SNEMA_yellowtail:_cons SNEMA_Yellowtail b_white_hake:_cons White_hake b_witch_flounder:_cons Witch b_q1:_cons Q1 b_q2:_cons Q2 b_q3:_cons Q3 b_q4:_cons Q4 b_interaction:_cons interaction b_cons:_cons Constant"
local estout_opts "replace style(tex) starlevels(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(2))) stats(r2 rmse aic bic) varlabels(`estout_relabel') mlabels(2010 2011 2012 2013 2014 2015 2016 2017 2018 2019)  substitute(_ \_) "

/*local out_coefficients "${my_results}/ols_quarterly_replicate_`flavor'${vintage_string}.dta"  */

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

pause
local my_confid_interval 90
foreach fy of local myquarters{
regress compensationR_`flavor' `rhs' interaction if fyq==`fy', robust
lincom GBE_cod-GBW_cod, level(`my_confid_interval')
local EW_cod=`r(estimate)'
local EW_cod_se=`r(se)'
local EW_cod_t=`r(t)'
local EW_cod_lb=`r(lb)'
local EW_cod_ub=`r(ub)'

lincom GBE_haddock-GBW_haddock, level(`my_confid_interval')
local EW_haddock=`r(estimate)'
local EW_haddock_se=`r(se)'
local EW_haddock_t=`r(t)'
local EW_haddock_lb=`r(lb)'
local EW_haddock_ub=`r(ub)'

/*postfile `sim' str10 model double( fyq EW_cod EW_cod_se EW_cod_t EW_cod_lb EW_cod_ub EW_haddock EW_haddock_se EW_haddock_t EW_haddock_lb EW_haddock_ub) using `save_file', replace */

post `sim' ("replication") (`fy') (`EW_cod') (`EW_cod_se') (`EW_cod_t') (`EW_cod_lb') (`EW_cod_ub') (`EW_haddock') (`EW_haddock_se') (`EW_haddock_t') (`EW_haddock_lb') (`EW_haddock_ub') (`my_confid_interval')
 }


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
foreach fy of local myquarters{
regress compensationR_`flavor' `rhs' interaction if fyq==`fy', robust
lincom GBE_cod-GBW_cod, level(`my_confid_interval')

local EW_cod=`r(estimate)'
local EW_cod_se=`r(se)'
local EW_cod_t=`r(t)'
local EW_cod_lb=`r(lb)'
local EW_cod_ub=`r(ub)'

lincom GBE_haddock-GBW_haddock, level(`my_confid_interval')
local EW_haddock=`r(estimate)'
local EW_haddock_se=`r(se)'
local EW_haddock_t=`r(t)'
local EW_haddock_lb=`r(lb)'
local EW_haddock_ub=`r(ub)'

/*postfile `sim' str10 model double( fyq EW_cod EW_cod_se EW_cod_t EW_cod_lb EW_cod_ub EW_haddock EW_haddock_se EW_haddock_t EW_haddock_lb EW_haddock_ub) using `save_file', replace */

post `sim' ("cooksd") (`fy') (`EW_cod') (`EW_cod_se') (`EW_cod_t') (`EW_cod_lb') (`EW_cod_ub') (`EW_haddock') (`EW_haddock_se') (`EW_haddock_t') (`EW_haddock_lb') (`EW_haddock_ub') (`my_confid_interval')
 }

/*******************************************************************/ 
/*******************************************************************/ 
/*******************************************************************/ 



 
postclose `sim' 

use `save_file', clear



/*swap in the cooksd prices for FY2012, Q4 */
drop if model=="cooksd" & fyq~=tq(2012q4)
drop if model=="replication" & fyq==tq(2012q4)
drop model
format fyq %tq`'
tsset fyq

rename fyq dateq
save `save_file', replace


/* pick up the confidence inverval */
local my_confid_interval=confidence_interval[1]

cap drop u2
cap drop l2

twoway (rcap EW_cod_lb EW_cod_ub dateq, color(gs14) fcolor(none) cmissing(n))

gen u2=EW_cod_ub
replace u2=5 if u2>=5 & u2~=.

gen l2=EW_cod_lb

replace l2=-2 if l2<=-2

label def myu2 5 ">5" -2 "<-2", replace
label values u2 myu2
label values l2 myu2


local axis_options xlabel(200(4)240, format(%tqCCYY) angle(45) grid)  xmtick(##4)  ylabel(-2(1)5, valuelabel grid gstyle(dot)) xtitle("") ytitle("GBE Cod price minus GBW cod price")

/*gen mark2=u2<0*/


twoway (rcap l2 u2 dateq ) (scatter  EW_cod dateq, sort msymbol(oh)), legend(order( 2 "Point Estimate" 1 "`my_confid_interval'% Confidence Interval")) `axis_options' yline(0)


	graph export "${my_images}/quarterly/GBEminusGBWcod.png", replace as(png) width(2000)


/* GBE GBW haddock only has 2 points*/
replace EW_haddock=. if EW_haddock==0

drop u2 l2

gen u2=EW_haddock_ub
replace u2=10 if u2>=10 & u2~=.

gen l2=EW_haddock_lb

replace l2=-10 if l2<=-10

label def myu2 10 ">10" -10 "<-10", replace
label values u2 myu2
label values l2 myu2

local axis_options xlabel(#11, format(%tqCCYY) angle(45) grid gstyle(dot)) xmtick(##4)  ylabel(, grid gstyle(dot)) xtitle("") ytitle("GBE Haddock price minus GBW Haddock price")
twoway (rcap EW_haddock_lb EW_haddock_ub  dateq ) (scatter EW_haddock dateq, sort msymbol(oh)), legend(order( 2 "Point Estimate" 1 "`my_confid_interval'% Confidence Interval")) `axis_options' yline(0)

	graph export "${my_images}/quarterly/GBEminusGBWhaddock.png", replace as(png) width(2000)















cap log close
 
 
 
 
 
 