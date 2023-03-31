
	
/*
Code to do margins and dump to nice tables.

This is for prototyping 


nehurdle margins, dydx(age) predict(ytrun)  <- is equivalent to churdle margins, eyex(age) predict(e(0,.))

nehurdle margins, dydx(age) predict(ycen)  <- is equivalent to churdle margins, eyex(age) 

nehurdle margins, dydx(age) predict(ycen)  <- is equivalent to churdle margins, eyex(age) 

after nehurdle, marginal effects and elasticities are easy for the probit part when we have indepvars in levels.
	Slightly harder when we have indepvars in logs for marginal effects.










*/
cap log close

local mylogfile "${my_results}/N03_churdle_margins.smcl" 
log using `mylogfile', replace

#delimit cr
version 16.1
pause on
clear all
spmatrix clear
est  drop _all

/*bootstrap options */
global common_seed 06240628
global bootreps 500


local stock_concentration ${data_main}/quarterly_stock_concentration_index_${vintage_string}.dta
local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta
local stock_concentration_noex ${data_main}/quarterly_stock_concentration_index_no_ex_${vintage_string}.dta

local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local spset_key2 "${data_main}/truncated_spset_id_keyfile_${vintage_string}.dta"
local spatial_lags ${data_main}/spatial_lags_${vintage_string}.dta
local spatial_lagsT ${data_main}/spatial_lags_${vintage_string}.dta

local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local  constraining ${data_main}/most_constraining_${vintage_string}.dta


local linear_hurdle ${my_results}/linear_hurdle_${vintage_string}.ster
local log_indep_hurdle ${my_results}/log_indep_hurdle_${vintage_string}.ster


local spatial_hurdle ${my_results}/spatial_hurdle_${vintage_string}.ster

local exponential_hurdle ${my_results}/exponential_hurdle_${vintage_string}.ster

local exponential_spatial_hurdle ${my_results}/exponential_spatial_hurdle_${vintage_string}.ster




/* read in the spmatrices previously created */
do "${processing_code}/K_spatial/K09T_readin_trunc_stswm.do"


use `prices'
/* drop the interaction and constant */

merge 1:1 stockcode dateq using `constraining'

drop if inlist(stockcode,1818,9999,101,102,103,104,105)
drop if inlist(fishing_year,2009,2020,2021)
drop if _merge==2
drop _merge

/* drop  2020  and 2021
drop 2009 because we already have lags.
2020, we can't add survey data, so we won't use to estimate 
*/


merge 1:1 stockcode dateq using `spatial_lagsT'
*drop if stockcode==17 & fishing_year<2012
assert _merge==3
*bysort _ID: assert _n==1
drop _merge

/* merge in quarterly "stock available indices" */
/* rename dateq to facilitate merges */
rename dateq quarterly 

merge 1:1 stockcode quarterly using `stock_concentration'
drop if _merge==2
assert _merge==3
drop _merge

merge 1:1 stockcode quarterly using `stock_concentration_noex'
drop if _merge==2
assert _merge==3
drop _merge


/* merge in quarterly "fishery available indices" this is a m:1 merge */

merge m:1 quarterly using `fishery_concentration'
drop if _merge==2
assert _merge==3
drop _merge

/* roll back to dateq */
rename  quarterly dateq



/* for any estimation, you'll probably need to rescale the _PQR_index and _QR index by dividing by 100 again, they are on the range of 30-300. We can also try  taking logs*/

foreach var of varlist stock_PQR_Index stock_QR_Index stock_no_ex_PQR_Index stock_no_ex_QR_Index fishery_QR_Index fishery_PQR_Index {
    replace `var'=`var'/100
	
	gen ln_`var'=ln(`var')
}




foreach var of varlist stock_shannon_Q stock_shannon_PQ stock_HHI_Q stock_HHI_PQ stock_no_ex_shannon_Q stock_no_ex_shannon_PQ stock_no_ex_HHI_Q stock_no_ex_HHI_PQ fishery_shannon_Q fishery_HHI_Q fishery_shannon_PQ fishery_HHI_PQ {
	
	gen ln_`var'=ln(`var')
}






gen badj_GDP=badj/fGDP
gen ihs_badj_GDP=asinh(badj_GDP)

gen del=live_priceGDP-badj_GDP
gen ihs_del=asinh(del)


xi i.q_fy


/* if you want to adjust the spatial lags, here is where you do it 
something like


gen t=live_priceGDP
replace t=0 if stockcode==17 & fishing_year<=2012
spgenerate Wrev_livep=Wi2S_rev*t
drop t


*/
/* construct a variable representing the revenue from the other */
gen otherR=live_priceGDP*quota_remaining_BOQ
gen ihs_otherR=asinh(otherR)
gen ln_otherR=ln(otherR)



/* classify as nearshore 25nm, intermediate 25-75nm, and far over 75nm from land. This gives us 4 stocks in the nearshore, 8 in the intermediate, and 4 that are offshore).  
This is intended to help me capture cost differences - fuel is related to cost, but so is distance*/
gen stock_distance_type=0
replace stock_distance_type=1 if inlist(stockcode,5,9,11,12,13,15,16,17)
replace stock_distance_type=2 if inlist(stockcode,2,4,6,7)
label define stock_dist 0 "nearshore" 1 "intermediate" 2 "far" 
label values stock_distance_type stock_dist


gen stocktype2=0
replace stocktype2=1 if inlist(stockcode, 1,8,9,10)
replace stocktype2=2 if inlist(stockcode, 2,3,4,5,6,7)
replace stocktype2=3 if inlist(stockcode,14,17 )

label define st2 1 "GOM" 2 "GB" 3 "SNEMA" 0 "Unit"
label values stocktype2 st2





/* create a "yearly quota variable from the quota_remaining_BOQ in q_fy=1*/
sort stockcode fishing_year q_fy
gen sectorACL=quota_remaining_BOQ if q_fy==1
bysort stockcode fishing_year (q_fy): replace sectorACL=sectorACL[1] if sectorACL==.
gen recip_ACL=1/sectorACL
gen lnACL=ln(sectorACL)
gen lnrecip=ln(recip_ACL)
/* need to add controls for quarter of the FY */

/* live price is endog, use 4th lag as IV */



gen bpos=badj_GDP>0 
replace bpos=. if badj_GDP==.
gen lnfp=ln(DDFUEL_R)

egen clustvar=group(stockcode fishing_year)







/* load in linear hurdle */
qui est describe using `linear_hurdle'




/* read in 6 */
local numest=r(nestresults)
forvalues est=6(1)6{
	est use `linear_hurdle', number(`est')
	est store linear`est'
}


/* load in logged RHS hurdle */
qui est describe using `log_indep_hurdle'
local numest=r(nestresults)

forvalues est=4(1)4{
	est use `log_indep_hurdle', number(`est')
	est store log_indep`est'
}


/* load in spatial_hurdle hurdle */
qui est describe using `spatial_hurdle'
local numest=r(nestresults)

forvalues est=13(2)15{
	est use `spatial_hurdle', number(`est')
	est store spatial_`est'
}



/* load in exp hurdle hurdle */
qui est describe using `exponential_hurdle'
local numest=r(nestresults)

forvalues est=11(1)16{
	est use `exponential_hurdle', number(`est')
	est store exp_`est'
}



/* load in exp hurdle hurdle */
qui est describe using `exponential_spatial_hurdle'
local numest=r(nestresults)

foreach est of numlist 8 12{
	est use `exponential_spatial_hurdle', number(`est')
	est store exp_spatial_`est'
}


/*HERE ARE My preferred models */




/* set e(sample) quickly by estimating a non-bootstrapped version. It is not quite the whole dataset, I'm not using the 2010Q1 and 2010Q2 observations -- the market is too thin.*/


/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev  stock_QR_Index stock_shannon_Q i.stock_distance_type#c.DDFUEL_R  _Iq*

/* Full list of exogenous variables that are included in the participation equation */
global exog_part _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

/* Full list of exogenous variables that are excluded from both the participation and levels equations (excluded instruments)
note that c.recip_ACL isn't really an instrument in the way we usually think of it. But it's not in the main equations -- it enters as an interaction but not alone.  
*/

global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

global selection_controls  qrresid4
global level_controls  pres4 qrresid4
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select(c.$endog2 $exog_part  $interaction)

/*gen a dummy variable for the e(sample) */
gen hand_esample=e(sample)

/*************************************************************************************/
/* 
Margins overview
1. , atmeans computes at the means of the RHS vars. You don't want this, you want, "asobserved"
2. Can use r.q_fy to compute contrasts relative to a base period

If you estimate the exponential hurdle (log on the LHS), margins is aware of this.

	Log-Log: use margins, eydx() to compute the elasticity.
	Log-level: use margins, eyex() to compute the elasticity.  
			use margins, eydx() to compute a semi-elasticity (dlny, dx) -- idk what this means.
	level-level: use margins, eyex() to compute the elasticity
	level-log: use margins, eydx() to compute the elasticity.
	
	
	For equations with a log on the RHS, it's tricky to compute the Average marginal effect.
	
3. The elasticity of a categorical/dummy does not make sense

*/



label var quota_remaining_BOQ "Quota Remaining 000mt"

label var live_priceGDP "Live Price"
label var ln_live_priceGDP "Log Live Price"
label var ln_quota_remaining_BOQ "Log Quota Remaining 000mt"
label var ln_fraction_remaining_BOQ "Log Fraction Quota Remaining"
label var stock_QR_Index "Quota Remaining Index"
label var lnfp "Log Fuel Price"
label var ln_stock_QR_Index "Log Quota Remaining Index"


local working_model linear6

local T_pr_D "Marginal Effect on Positive Prices"
local T_pr_E "Elasticities of Probability of Positive"

local T_ycenD "Marginal Effect on  Prices"
local T_ycenE "Elasticites of Prices"

local T_ytrunE "Elasticites of Positive Prices"
local T_ytrunD "Marginal Effect on Positive Prices"

est restore `working_model'
estimates esample: if hand_esample

est replay

/**************************************/
/* PARTICIPATION Equation */
/* the marginal effects and elasticities on the probability of being positive.*/ 
margins, dydx(*) predict(psel) asobserved post

estimates store pr_D_`working_model', title("`T_pr_D'")

est restore `working_model'
estimates esample: if hand_esample

margins, eyex(quota_remaining_BOQ recip_ACL) predict(psel) asobserved post

estimates store pr_E_`working_model',title("`T_pr_E'")

/**************************************/



/**************************************/
/*LEVEL Equation */
/*Average Marginal effects */

est restore `working_model'
estimates esample: if hand_esample

/* the marginal effects on the Truncated (conditional) mean E[y|y>0,x] */
margins, dydx(*) predict(ytrun) post 

estimates store ytrun_D_`working_model',title(`T_ytrunD')














est restore `working_model'
estimates esample: if hand_esample

/* the marginal effects on the censored (unconditional) mean E[y]*/
margins, dydx(*) predict(ycen) post


estimates store ycen_D_`working_model', title(`T_ycenD')


/**************************************/
est restore `working_model'
estimates esample: if hand_esample

/**************************************/
/*Elasticities*/
/*  Elasticity on the censored (unconditional) mean E[y] */ 
margins, eyex(quota_remaining_BOQ live_priceGDP stock_QR_Index) predict(ycen) asobserved post



estimates store ycen_E_`working_model', title(`T_ycenE'')


est restore `working_model'
estimates esample: if hand_esample
/* Elasticity on the Truncated (conditional) mean E[y|y>0,x] */
margins, eyex(quota_remaining_BOQ live_priceGDP stock_QR_Index) predict(ytrun) asobserved post


estimates store ytrun_E_`working_model', title(`T_ytrunE')

/**************************************/
/**************************************/

local estout_opts nobaselevels cells(b (star fmt(3)) se(par fmt(2)))  starlevels(* 0.10 ** 0.05 *** 0.01) wrap drop(recip_ACL)
local label_opts label varlabels(_Iq_fy_2 "Quarter 2" _Iq_fy_3 "Quarter 3" _Iq_fy_4 "Quarter 4") collabels(none)
estout  pr_D_`working_model' pr_E_`working_model' ytrun_D_`working_model' ytrun_E_`working_model' ycen_D_`working_model' ycen_E_`working_model', `estout_opts' `label_opts'


*estout  pr_D_`working_model' pr_E_`working_model' ytrun_D_`working_model' ytrun_E_`working_model' ycen_D_`working_model' ycen_E_`working_model' style(tex) replace `estout_opts' `label_opts'


esttab  pr_D_`working_model' pr_E_`working_model' ytrun_D_`working_model' ytrun_E_`working_model' ycen_D_`working_model' ycen_E_`working_model' using ${my_tables}\elasticity_`working_model'.tex, replace `estout_opts' `label_opts' noobs nonumbers mtitle("`T_pr_D'" "`T_pr_E'" "`T_ytrunD'"  "`T_ytrunE'"  "`T_ycenD'"  "`T_ycenE'")   alignment(r)

/* 
ycen is E[y|x]
ytrun is E[y|x,y>=0]



This is pretty good, I just need to fiddle with the stars and signif levels and give the columns good titles

Participation   
Marginal Effect  - Elasticity     | Marginal Effect | Elasticity |Marginal Effect | Elasticity 
*/ 
 
 
log close
