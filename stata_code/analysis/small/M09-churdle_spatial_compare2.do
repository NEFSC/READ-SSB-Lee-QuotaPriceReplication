
	
/*
This is just about identical to M03B-explanatory_churdle.do. 

M03-explanatory_churdle estimates these models
(1): Y = a ln(quota_remaining_BOQ) + bln(fraction_remaining)

M03B-explanatory_churdle estimates these models
(2): Y = c ln(quota_remaining_BOQ) - b ln(ACL)



1. The market price for quota fits perfectly into the "corner solution" setup described by Wooldridge. This is just Walras law of zero valued excess demand. 

	If all the individual demand functions x(p,w) are continuous, then we have the excess demand function:
	
	z(p)=sum x_i(p,w)-\omega_i
for any price vector p, we must have p*z(p) \equiv 0.

We therefore have --- if prices are non-zero, then we have Q_s=Q_d
If there is excess supply, then the price must be zero.  


Even if stock $i$ is often caught along with stock $j$ and catching $j$ is highly profitable, the fact that there there is no excess demand implies that only the amount of quota available matters.

We might have many ways to 

	
On one hand, I have a big enough n (16/17) and t(44ish). But perhaps I don't because it's 16 x 11.
	The "invidvidual-ness", resets itself every year, because it isn't an actual individual, but a market outcome.
	so, perhaps I have 
		t=4
		and n~stock*year (17*17)
	
	Note that the x(p,w) is an input demand equation, so it also depends on costs of fishing

	
	
stata's churdle exponential is broken.
I can do what I need with 
nehurdle, exponential


nehurdle margins, dydx(age) predict(ytrun)  <- is equivalent to churdle margins, eyex(age) predict(e(0,.))

nehurdle margins, dydx(age) predict(ycen)  <- is equivalent to churdle margins, eyex(age) 

*/
cap log close

local mylogfile "${my_results}/churdle_spatial_compare2.smcl" 
log using `mylogfile', replace

#delimit cr
version 15.1
clear all
spmatrix clear
est  drop _all

/*bootstrap options */
global common_seed 06240628
global bootreps 1000

local stock_concentration ${data_main}/quarterly_stock_concentration_index_${vintage_string}.dta
local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta
local stock_concentration_noex ${data_main}/quarterly_stock_concentration_index_no_ex_${vintage_string}.dta
local stock_disjoint ${data_main}/quarterly_stock_disjoint_index_${vintage_string}.dta

local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local spset_key2 "${data_main}/truncated_spset_id_keyfile_${vintage_string}.dta"
local spatial_lags ${data_main}/spatial_lags_${vintage_string}.dta
local spatial_lagsT ${data_main}/Tspatial_lags_${vintage_string}.dta

local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local constraining ${data_main}/most_constraining_${vintage_string}.dta


/* results files */

local churdle_compare ${my_results}/churdle_compare2_${vintage_string}.ster


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
/* drop snema winter from 2010 and 2011*/
drop if stockcode==17 & fishing_year<2012
merge 1:1 stockcode dateq using `spatial_lagsT'
*drop if stockcode==17 & fishing_year<2012
assert _merge==3 | (stockcode==17 & fishing_year<2012)
*bysort _ID: assert _n==1
drop _merge

drop if stockcode==17 & fishing_year<2012


merge 1:1 stockcode dateq using `spset_key2'
assert _merge==3
bysort _ID: assert _n==1
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

merge 1:1 stockcode quarterly using `stock_disjoint'
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

foreach var of varlist stock_PQR_Index stock_QR_Index stock_no_ex_PQR_Index stock_no_ex_QR_Index fishery_QR_Index fishery_PQR_Index stockD_PQR_Index stockD_QR_Index {
    replace `var'=`var'/100
	
	gen ln_`var'=ln(`var')
}




foreach var of varlist stock_shannon_Q stock_shannon_PQ  stock_Nshannon_Q stock_Nshannon_PQ stock_HHI_Q stock_HHI_PQ stock_no_ex_shannon_Q stock_no_ex_shannon_PQ stock_no_ex_HHI_Q stock_no_ex_HHI_PQ fishery_shannon_Q fishery_HHI_Q fishery_shannon_PQ fishery_HHI_PQ avg_hourly_wage_R  {
	
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




/* create a "yearly quota variable from the quota_remaining_BOQ in _Iq*=1*/
sort stockcode fishing_year _Iq*
gen sectorACL=quota_remaining_BOQ if q_fy==1
bysort stockcode fishing_year (_Iq*): replace sectorACL=sectorACL[1] if sectorACL==.
gen recip_ACL=1/sectorACL
/* need to add controls for quarter of the FY */

/* live price is endog, use 4th lag as IV */



gen bpos=badj_GDP>0 
replace bpos=. if badj_GDP==.
gen lnfp=ln(DDFUEL_R)

egen clustvar=group(stockcode fishing_year)




/*********************************************************/
/*********************************************************/
/* Program  a softcoded version of the NEHURDLE with a control function */
/**If you want one of the endogenous variables to be exogenous, all you need to do is omit it's residual from the $level_controls or $selection_controls macro.  
	You still end up running the 1st stage OLS models, but don't plug them into the 2nd stage.
	You need to be careful about the list of IVs though.  
*******************************************************/
/*********************************************************/
/* this is probably bad coding to use globals and a program without an arg, but whatever */

cap drop pres4
cap drop qrresid4

cap program drop boot_nehurdle_generic
program boot_nehurdle_generic, rclass
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)

drop pres4 qrresid4
end program






cap program drop boot_nehurdle_generic_exp
program boot_nehurdle_generic_exp, rclass
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc exponential select(c.$endog2 $exog_part  $interaction $selection_controls)

drop pres4 qrresid4
end program


/*Setup */
/* Need to clear the panel structure in order to cluster bootstrap.*/
tsset, clear





/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/* Linear Hurdle. 1st and 4th lags as price instruments 4th only for Q */
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/




/*Setup */



tsset, clear

/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev  WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ c.DDFUEL_R  c.avg_hourly_wage_R _Iq*

/* Full list of exogenous variables that are included in the participation equation */
global exog_part _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

/* Full list of exogenous variables that are excluded from both the participation and levels equations (excluded instruments)
note that c.recip_ACL isn't really an instrument in the way we usually think of it. But it's not in the main equations -- it enters as an interaction but not alone.  
*/

global IVs lag1Q_live_priceGDP lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL 
global selection_controls  qrresid4
global level_controls  pres4 qrresid4
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 

bssize initial, tau(0.05) pdb(5)

/*
bssize initial, tau(0.05) pdb(5)
global bootreps 768

/* estimate the hurdle by boostrap*/
bootstrap, reps($bootreps) seed($common_seed) cluster(clustvar)  saving($my_results\linear1.dta, replace): boot_nehurdle_generic
estimates title: Linear Endog Spatial Hurdle. 1st and 4th lags as IVs for Price, 4th for Q
local replacer  replace
est store EndogB_linear_sp
est save `churdle_compare', `replacer'
local replacer append

preserve
use $my_results\linear1.dta, clear


renvars, subst("_b_" "")
renvars, pref("_b_")

save $my_results\linear1.dta, replace
restore

      bssize display using $my_results\linear1.dta
      bssize analyze using $my_results\linear1.dta, pdb(5)

      bssize refine using $my_results\linear1.dta
/* says we need more reps -- like 2600! The exponential one says we need 2800 reps. I'll just round both to 3000 reps */
*/


bootstrap, reps($bootreps) seed($common_seed) cluster(clustvar)  saving($my_results\linear1.dta, replace): boot_nehurdle_generic
estimates title: Linear Endog Spatial Hurdle. 1st and 4th lags as IVs for Price, 4th for Q
local replacer  replace
est store EndogB_linear_sp
est save `churdle_compare', `replacer'
local replacer append

test [selection]_b[qrresid4] [badj_GDP]_b[pres4] [badj_GDP]_b[qrresid4]
test [badj_GDP]_b[pres4] [badj_GDP]_b[qrresid4]
test [selection]_b[qrresid4][badj_GDP]_b[qrresid4]


preserve
use $my_results\linear1.dta, clear


renvars, subst("_b_" "")
renvars, pref("_b_")

save $my_results\linear1.dta, replace
restore

      bssize display using $my_results\linear1.dta
      bssize analyze using $my_results\linear1.dta, pdb(5)

      bssize refine using $my_results\linear1.dta

/* NOTE: This model strongly suggests that the RHS vars are exogenous. Therefore, we can just reestimate with NEHURDLE and test down */


 
 
 
 
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/* LOG_linear Hurdle. 1st and 4th lags as price instruments 4th only for Q */
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/



	 bssize initial, tau(0.05) pdb(5)
 
/***************************************************************************************************/
/* Exponential Hurdle. 1st and 4th lags as price instruments 4th only for Q */

/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev  WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ c.DDFUEL_R  c.avg_hourly_wage_R _Iq*

/* Full list of exogenous variables that are included in the participation equation */
global exog_part _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

/* Full list of exogenous variables that are excluded from both the participation and levels equations (excluded instruments)
note that c.recip_ACL isn't really an instrument in the way we usually think of it. But it's not in the main equations -- it enters as an interaction but not alone.  
*/

global IVs lag1Q_live_priceGDP lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL 
global selection_controls  qrresid4
global level_controls  pres4 qrresid4
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 



bootstrap, reps($bootreps) seed($common_seed) cluster(clustvar)  saving($my_results\exponential1.dta, replace): boot_nehurdle_generic_exp
estimates title: Exponential Endog Spatial Hurdle 1. 1st and 4th lags as for prices. 4th lags for Quantities
est store Endog_exponentialB_sp1
est save `churdle_compare', `replacer'

test [selection]_b[qrresid4] [lnbadj_GDP]_b[pres4] [lnbadj_GDP]_b[qrresid4]
test [lnbadj_GDP]_b[pres4] [lnbadj_GDP]_b[qrresid4]
test [selection]_b[qrresid4][lnbadj_GDP]_b[qrresid4]


preserve
use $my_results\exponential1.dta, clear
renvars, subst("_b_" "")
renvars, pref("_b_")
save $my_results\exponential1.dta, replace

restore


bssize refine using $my_results\exponential1.dta
bssize display using $my_results\exponential1.dta
bssize analyze using $my_results\exponential1.dta, pdb(5)
/* says we need 2800 reps */
/* this model says that q might be endogenous in the level equation, but not the participation equation. And that prices are exog */








/***************************************************************************************************/
/* Exponential Hurdle.  4th lags only as IVS for Q . P found to be exog*/
bssize initial, tau(0.05) pdb(5)

/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev  WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ c.DDFUEL_R  c.avg_hourly_wage_R _Iq*

/* Full list of exogenous variables that are included in the participation equation */
global exog_part _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

/* Full list of exogenous variables that are excluded from both the participation and levels equations (excluded instruments)
note that c.recip_ACL isn't really an instrument in the way we usually think of it. But it's not in the main equations -- it enters as an interaction but not alone.  
*/

global IVs  lag4Q_quota_remaining_BOQ c.recip_ACL 
global level_controls  qrresid4
global selection_controls 
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 



bootstrap, reps($bootreps) seed($common_seed) cluster(clustvar)  saving($my_results\exponential2.dta, replace): boot_nehurdle_generic_exp
estimates title: Exponential Endog Spatial Hurdle 1. 4th lags for Quantities. P is exog

local replacer append

est store Endog_exponentialB_sp2
est save `churdle_compare', `replacer'

test WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ
test DDFUEL_R avg_hourly_wage_R

/* various tests reject exogeneity of the two Quantity remaining, but fail to reject prices as exog in the levels equation.*/
preserve
use $my_results\exponential2.dta, clear
renvars, subst("_b_" "")
renvars, pref("_b_")
save $my_results\exponential2.dta, replace

restore


bssize refine using $my_results\exponential2.dta
bssize display using $my_results\exponential2.dta
bssize analyze using $my_results\exponential2.dta, pdb(5)

/* says we need 2800 reps */







/***************************************************************************************************/
/* Exponential Hurdle.  4th lags only as IVS for Q . start testing down*/
bssize initial, tau(0.05) pdb(5)

/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev  WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ  _Iq*

/* Full list of exogenous variables that are included in the participation equation */
global exog_part _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

/* Full list of exogenous variables that are excluded from both the participation and levels equations (excluded instruments)
note that c.recip_ACL isn't really an instrument in the way we usually think of it. But it's not in the main equations -- it enters as an interaction but not alone.  
*/

global IVs  lag4Q_quota_remaining_BOQ c.recip_ACL 
global level_controls  qrresid4
global selection_controls 
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 



bootstrap, reps($bootreps) seed($common_seed) cluster(clustvar)  saving($my_results\exponential2.dta, replace): boot_nehurdle_generic_exp
estimates title: Exponential Endog Spatial Hurdle 1. 4th lags for Quantities. P is exog

local replacer append

est store Endog_exponentialB_sp3
est save `churdle_compare', `replacer'





















/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/* Log-Log Hurdle. 1st and 4th lags as price instruments 4th only for Q */
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/



bssize initial, tau(0.05) pdb(5)

/* estimate a log-log model */

/* endog1, the first endogenous variable */
global endog1 ln_live_priceGDP

/* endog2, the second endogenous variable */
global endog2 ln_quota_remaining_BOQ


/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction ln_fraction_remaining_BOQ

global exog_lev  WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ c.lnfp  c.ln_avg_hourly_wage_R _Iq*


/* Full list of exogenous variables that are included in the participation equation */
global exog_part _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

/* Full list of exogenous variables that are excluded from both the participation and levels equations (excluded instruments)
note that c.recip_ACL isn't really an instrument in the way we usually think of it. But it's not in the main equations -- it enters as an interaction but not alone.  
*/

global IVs  lag4Q_ln_quota_remaining_BOQ lag1Q_ln_live_priceGDP lag4Q_ln_live_priceGDP
global selection_controls  qrresid4
global level_controls  pres4 qrresid4
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 

bootstrap, reps($bootreps) seed($common_seed) cluster(clustvar)  saving($my_results\exponential3.dta, replace): boot_nehurdle_generic_exp

estimates title: Exponential Endog Spatial Hurdle L-L . 4th lags for Quantities. 1st and 4th lags for P 
local replacer append
est store Endog_log_log1


est save `churdle_compare', `replacer'


/* The Log-log model says that both P and Q are exogenous, so we can just estimate the NE HURDLE */








/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/* Linear-Log Hurdle. 1st and 4th lags as price instruments 4th only for Q */
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/

bssize initial, tau(0.05) pdb(5)

/* estimate a log-log model */

/* endog1, the first endogenous variable */
global endog1 ln_live_priceGDP

/* endog2, the second endogenous variable */
global endog2 ln_quota_remaining_BOQ


/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction ln_fraction_remaining_BOQ

global exog_lev  WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ c.lnfp  c.ln_avg_hourly_wage_R _Iq*


/* Full list of exogenous variables that are included in the participation equation */
global exog_part _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

/* Full list of exogenous variables that are excluded from both the participation and levels equations (excluded instruments)
note that c.recip_ACL isn't really an instrument in the way we usually think of it. But it's not in the main equations -- it enters as an interaction but not alone.  
*/

global IVs  lag4Q_ln_quota_remaining_BOQ lag1Q_ln_live_priceGDP lag4Q_ln_live_priceGDP
global selection_controls  qrresid4
global level_controls  pres4 qrresid4
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 

bootstrap, reps($bootreps) seed($common_seed) cluster(clustvar)  saving($my_results\linear_log3.dta, replace): boot_nehurdle_generic

estimates title: Exponential Endog Spatial Hurdle Linear-Log . 4th lags for Quantities. 1st and 4th lags for P 
local replacer append
est store Endog_lin_log1


est save `churdle_compare', `replacer'


/* The Log-log model says that both P and Q are exogenous, so we can just estimate the NE HURDLE */













log close
