
	
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

local mylogfile "${my_results}/churdleA_noboot.smcl" 
log using `mylogfile', replace

#delimit cr
version 15.1
clear all
spmatrix clear
est  drop _all

/*bootstrap options */
global common_seed 06240628
global bootreps 500


local stock_concentration ${data_main}/quarterly_stock_concentration_index_${vintage_string}.dta
local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta
local stock_concentration_noex ${data_main}/quarterly_stock_concentration_index_no_ex_${vintage_string}.dta
local stock_disjoint ${data_main}/quarterly_stock_disjoint_index_${vintage_string}.dta

local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local spset_key2 "${data_main}/truncated_spset_id_keyfile_${vintage_string}.dta"
local spatial_lags ${data_main}/spatial_lags_${vintage_string}.dta
local spatial_lagsT ${data_main}/spatial_lags_${vintage_string}.dta

local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local  constraining ${data_main}/most_constraining_${vintage_string}.dta


/* results files */

local linear_hurdle ${my_results}/linear_hurdleNB_${vintage_string}.ster
local log_indep_hurdle ${my_results}/log_indep_hurdleNB_${vintage_string}.ster
local spatial_hurdle ${my_results}/spatial_hurdleNB_${vintage_string}.ster
local exponential_hurdle ${my_results}/exponential_hurdleNB_${vintage_string}.ster
local exponential_spatial_hurdle ${my_results}/exponential_spatial_hurdleNB_${vintage_string}.ster



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

foreach var of varlist stock_PQR_Index stock_QR_Index stock_no_ex_PQR_Index stock_no_ex_QR_Index fishery_QR_Index fishery_PQR_Index {
    replace `var'=`var'/100
	
	gen ln_`var'=ln(`var')
}




foreach var of varlist stock_shannon_Q stock_shannon_PQ  stock_Nshannon_Q stock_Nshannon_PQ stock_HHI_Q stock_HHI_PQ stock_no_ex_shannon_Q stock_no_ex_shannon_PQ stock_no_ex_HHI_Q stock_no_ex_HHI_PQ fishery_shannon_Q fishery_HHI_Q fishery_shannon_PQ fishery_HHI_PQ {
	
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
/* need to add controls for quarter of the FY */

/* live price is endog, use 4th lag as IV */



gen bpos=badj_GDP>0 
replace bpos=. if badj_GDP==.
gen lnfp=ln(DDFUEL_R)

egen clustvar=group(stockcode fishing_year)



/* This is a hardcoded version of the hurdle */
cap drop pres4
cap drop qrresid4

cap program drop boot_nehurdle
program boot_nehurdle, rclass
	regress live_priceGDP   _Iq* stock_QR_Index stock_Nshannon_Q i.stock_distance_type#c.DDFUEL_R recip_ACL lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ
	predict pres4, residual
 
 regress quota_remaining_BOQ   _Iq* stock_QR_Index stock_Nshannon_Q i.stock_distance_type#c.DDFUEL_R recip_ACL lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ

	predict qrresid4, residual

nehurdle badj_GDP live_priceGDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL _Iq* stock_QR_Index stock_Nshannon_Q i.stock_distance_type#c.DDFUEL_R pres4 qrresid4, trunc  select(c.quota_remaining_BOQ#c.recip_ACL c.quota_remaining_BOQ _Iq* qrresid4)

drop pres4 qrresid4
end program
bootstrap, reps(10) seed($common_seed): boot_nehurdle
/*********************************************************/
/*********************************************************/





/*********************************************************/
/*********************************************************/
/* Program  a softcoded version of the NEHURDLE with a control function */
/*********************************************************/
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

/*********************************************************/
/*********************************************************/
/* End  a softcoded version  */
/*********************************************************/
/*********************************************************/











/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION A:
Levels on the right and left sides

*/
/*************************************************************************************/
/*************************************************************************************/


/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev  stock_QR_Index stock_Nshannon_Q i.stock_distance_type#c.DDFUEL_R  _Iq*

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



cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum

pause


estimates title: Linear Hurdle Endogenous Q and P
est store level_spec

local saver replace
est save `linear_hurdle', `saver'
local saver append


/* same as immediately above, but under exogeneity */
nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select(c.$endog2 $exog_part  $interaction) vce(cluster clustvar)
estimates title: Linear Hurdle Exogenous Q and P
est save `linear_hurdle', `saver'


est store EX_level_spec


/* Testing down 
The first specification said that the DDFUEL_R's interaction was not significant, so we'll go ahead and re-estimate without those 3 variables.

*/


global exog_lev  stock_QR_Index stock_Nshannon_Q _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)


cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum


estimates title: Linear Hurdle Endogenous Q and P testing down

est save `linear_hurdle', `saver'

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select(c.$endog2 $exog_part  $interaction)  vce(cluster clustvar)
est store EX_level_specA
estimates title: Linear Hurdle Exogenous Q and P testing down

est save `linear_hurdle', `saver'


/*
We still find evidence for exogeneity of both quota remaining and prices.  We also have shannon_Q coefficient that is small in magnitude and statistically insignificant, so we'll estimate one more model without the shannon_Q
 */


global exog_lev  stock_QR_Index _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)




cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum

estimates title: Linear Hurdle Endogenous Q and P Parsim

est save `linear_hurdle', `saver'

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select(c.$endog2 $exog_part  $interaction)  vce(cluster clustvar)


estimates title: Linear Hurdle Exogenous Q and P Parsim

est save `linear_hurdle', `saver'






/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION B:
In this bit of code, I am estimating model 2
 Estimate the model with depvars in logs 
This is a little tricky to explain/interpret, but:

(1): Y = a ln(quota_remaining_BOQ) + bln(fraction_remaining)

is equivalent to 

(2): Y = c ln(quota_remaining_BOQ) - b ln(ACL)

a=b+c <--> c=a-b

(1) regress badj ln_quota_remaining_BOQ ln_fraction_remaining_BOQ
nlcom _b[ln_quota_remaining_BOQ]-_b[ln_fraction_remaining_BOQ]

will give you the "c" coefficient.


To go the other way
(2) regress badj ln_quota_remaining_BOQ lnACL
nlcom _b[ln_quota_remaining_BOQ]-_b[lnACL]
will give you the "a" coefficient

Look at Z01_test_log_formulations.do

*/
/*************************************************************************************/
/*************************************************************************************/



global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev ln_fraction_remaining_BOQ ln_stock_QR_Index ln_stock_Nshannon_Q i.stock_distance_type#c.lnfp _Iq* 

global exog_part _Iq* ln_fraction_remaining_BOQ


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls  qrresid4
global level_controls  pres4 qrresid4


global selectionrhs $exog_part $interaction c.$endog2  $selection_controls

/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum

estimates title: Linear-log Hurdle Endogenous Q and P

local saver replace
est save `log_indep_hurdle', `saver'
local saver append



nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
estimates title: Linear-log Hurdle Exogenous Q and P

est save `log_indep_hurdle', `saver'

est store EX_log_spec

/* the log spec model has ambiguous evidence about the exogeneity of some of the RHS vars, the quantity remaining in the participation equation */
global level_controls


/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls, trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)    vce(cluster clustvar)
test [selection]qrresid4
estimates title: Linear-log Hurdle Exogenous Level Eq
est store log_specE

est save `log_indep_hurdle', `saver'



/* Testing down 
The first specification said that the DDFUEL_R's interaction was not significant, so we'll go ahead and re-estimate without those 3 variables.

*/

global exog_lev ln_fraction_remaining_BOQ ln_stock_QR_Index  _Iq* 
global selection_controls  qrresid4
global level_controls  pres4 qrresid4
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)



nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)

est store EX_log_specA

estimates title: Linear-log Hurdle Exogenous P Q, testing down

est save `log_indep_hurdle', `saver'



/* the log spec model has ambiguous evidence about the exogeneity of some of the RHS vars, the quantity remaining in the participation equation */

/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum
est store log_specA

estimates title: Linear-log Hurdle Endogenous P Q, testing down
est save `log_indep_hurdle', `saver'


global level_controls  


/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
est store log_specEA
estimates title: Linear-log Hurdle Exogenous Level Equation 
est save `log_indep_hurdle', `saver'




/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION C:
 Estimate the model with depvars in levels, with the spatial lags 

*/
/*************************************************************************************/
/*************************************************************************************/

/*  */





/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev Wswt_quota_remaining_BOQ Wswt_livep  i.stock_distance_type#c.DDFUEL_R  _Iq*

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







/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum
est store slx1

estimates title: Linear Hurdle Spatial Endogenous Q and P

local saver replace
est save `spatial_hurdle', `saver'
local saver append



nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
est store EX_slx1
estimates title: Linear Hurdle Spatial Exogenous Q and P
est save `spatial_hurdle', `saver'


/* Still evidence that DDFUEL_R does not belong in the level equation. Still evidence that prices are exog. Some evidence that quantity is endogenous. */



global exog_lev Wswt_quota_remaining_BOQ Wswt_livep  _Iq*
global level_controls  qrresid4
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)



/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
estimates title: Linear Hurdle Spatial Endogenous Q and P testing down
est save `spatial_hurdle', `saver'

est store slx1A

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
est store EX_slx1A
estimates title: Linear Hurdle Spatial Exogenous Q and P testing down
est save `spatial_hurdle', `saver'



/*Try the revenue based spatial lag X */

global exog_lev Wrev_quota_remaining_BOQ Wrev_livep  _Iq*

global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)


/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
est store slx2

estimates title: Linear Hurdle Spatial Endogenous Q and P testing down Revenue W
est save `spatial_hurdle', `saver'

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
est store EX_slx2

estimates title: Linear Hurdle Spatial Exogenous Q and P testing down Revenue W
est save `spatial_hurdle', `saver'

  


/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION D:
 Estimate the model with depvars in levels, with the spatial lags in logs

*/
/*************************************************************************************/
/*************************************************************************************/


global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev ln_fraction_remaining_BOQ Wswt_ln_quota_remaining_BOQ Wswt_ln_livep  i.stock_distance_type#c.lnfp  _Iq*

global exog_part ln_fraction_remaining_BOQ _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls  qrresid4
global level_controls  pres4 qrresid4


global selectionrhs $exog_part $interaction c.$endog2  $selection_controls

/* estimate the control function version */



/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum
est store slx_ln1

estimates title: Linear-log Hurdle Spatial Endogenous Q and P

est save `spatial_hurdle', `saver'
local saver append

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
est store EX_slx_ln1


estimates title: Linear-log Hurdle Spatial Exog Q and P
est save `spatial_hurdle', `saver'


/* based on model 1, we want to estimate with no level_controls */
global level_controls 

/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4

estimates title: Linear-log Hurdle Spatial Endogenous Q and P testing down
est store slx_ln1A
est save `spatial_hurdle', `saver'

/* try without the spatial lag of prices */

global exog_lev ln_fraction_remaining_BOQ Wswt_ln_quota_remaining_BOQ  i.stock_distance_type#c.lnfp  _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)


/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4

estimates title: Linear-log Hurdle Spatial Endogenous Q and P testing down B
est store slx_ln1B
est save `spatial_hurdle', `saver'


/* without the fuel price interactions */
global exog_lev ln_fraction_remaining_BOQ Wswt_ln_quota_remaining_BOQ _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)


/* estimate the DWH version */

cap drop pres4
cap drop qrresid4

regress $endog1 $exog_full  $IVs
predict pres4, residual
 
regress $endog2  $exog_full $IVs
predict qrresid4, residual


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4

estimates title: Linear-log Hurdle Spatial Endogenous Q and P testing down C
est store slx_ln1C
est save `spatial_hurdle', `saver'


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
estimates title: Linear-log Hurdle Spatial Exogenous Q and P testing down C
est save `spatial_hurdle', `saver'



/* extra spatial models
4 mod  (Linear Hurdle Spatial Exogenous Q and P testing down)
*/



global endog1 live_priceGDP

global endog2 quota_remaining_BOQ

global interaction c.recip_ACL#c.$endog2

global exog_lev Wswt_quota_remaining_BOQ   _Iq*

global exog_part _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

global level_controls  
global level_controls  pres4 qrresid4
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 





nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)  
est store EX_slx1A
estimates title: Linear Hurdle Spatial Exogenous Q and P testing down
est save `spatial_hurdle', `saver'




/* 6 mod */





global endog1 live_priceGDP

global endog2 quota_remaining_BOQ

global interaction c.recip_ACL#c.$endog2

global exog_lev Wswt_quota_remaining_BOQ Wswt_livep  i.stock_distance_type#c.DDFUEL_R  _Iq*

global exog_part _Iq* 


global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)


global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

global selection_controls  
global level_controls  pres4 qrresid4
global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 


global exog_lev Wrev_quota_remaining_BOQ   _Iq*

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
est store EX_slx1A
estimates title: Linear Hurdle Spatial Exogenous Q and P testing down Revenue W
est save `spatial_hurdle', `saver'











/* 11 mods 1 */





global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev Wswt_ln_quota_remaining_BOQ Wswt_ln_livep  i.stock_distance_type#c.lnfp  _Iq*

global exog_part ln_fraction_remaining_BOQ _Iq* 


global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls  qrresid4
global level_controls  


global selectionrhs $exog_part $interaction c.$endog2  $selection_controls

/* estimate the control function version */


/* based on model 1, we want to estimate with no level_controls */

/* try without the spatial lag of prices */

/* without the fuel price interactions */
global exog_lev Wswt_ln_quota_remaining_BOQ _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
estimates title: Linear-log Hurdle Spatial Exogenous Q and P testing down D
est save `spatial_hurdle', `saver'

















global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev  ln_fraction_remaining_BOQ Wswt_ln_quota_remaining_BOQ Wswt_ln_livep  i.stock_distance_type#c.lnfp  _Iq*

global exog_part ln_fraction_remaining_BOQ _Iq* 


global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls  qrresid4
global level_controls  


global selectionrhs $exog_part $interaction c.$endog2  $selection_controls

/* estimate the control function version */


/* based on model 1, we want to estimate with no level_controls */

/* try without the spatial lag of prices */

/* without the fuel price interactions */
global exog_lev Wswt_ln_quota_remaining_BOQ  ln_fraction_remaining_BOQ _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
estimates title: Linear-log Hurdle Spatial Exogenous Q and P testing down D
est save `spatial_hurdle', `saver'


/* without the fuel price interactions */
global exog_lev Wswt_ln_quota_remaining_BOQ  _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, trunc  select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
estimates title: Linear-log Hurdle Spatial Exogenous Q and P testing down D
est save `spatial_hurdle', `saver'













/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION E:
"exponential" -- log y on the right sides

*/
/*************************************************************************************/
/*************************************************************************************/


/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev  stock_QR_Index stock_Nshannon_Q i.stock_distance_type#c.DDFUEL_R  _Iq*

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





/* DWH test */

cap drop pres4
cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls ,  exponential select(c.$endog2 $exog_part  $interaction $selection_controls)   vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum
est store level_exp_spec



estimates title: Exponential Hurdle Endogenous Q and P

local saver replace
est save `exponential_hurdle', `saver'
local saver append





/* same as immediately above, but under exogeneity */
nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev,  exponential select(c.$endog2 $exog_part  $interaction)  vce(cluster clustvar)
est store EX_level_exp_spec

estimates title: Exponential Hurdle Exogenous Q and P
est save `exponential_hurdle', `saver'

/* Testing down 
The first specification said that the DDFUEL_R's interaction was not significant, so we'll go ahead and re-estimate without those 3 variables.

*/


global exog_lev  stock_QR_Index stock_Nshannon_Q _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)



/* DWH test */

cap drop pres4
cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls ,  exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum
	est store level_exp_spec_A
estimates title: Exponential Hurdle Endogenous Q and P Testing down
est save `exponential_hurdle', `saver'

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev,  exponential select(c.$endog2 $exog_part  $interaction)  vce(cluster clustvar)
est store EX_level_exp_specA
estimates title: Exponential Hurdle Exogenous Q and P Testing down
est save `exponential_hurdle', `saver'


/*
We still find only weak evidence for exogeneity of both quota remaining and prices in the levels equation.  We also have shannon_Q coefficient that is small in magnitude and statistically insignificant, so we'll estimate one more model without the shannon_Q
 */


global exog_lev stock_QR_Index _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global selection_controls 
global level_controls  pres4 qrresid4




/* DWH test */

cap drop pres4
cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls ,  exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [lnbadj_GDP]qrresid4
test [lnbadj_GDP]pres4, accum
	estimates title: Exponential Hurdle Endogenous Q and P Testing down 2
est save `exponential_hurdle', `saver'


est store level_exp_spec_B

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev,  exponential select(c.$endog2 $exog_part  $interaction)  vce(cluster clustvar)

estimates title: Exponential Hurdle Exogenous Q and P Testing down 2
est save `exponential_hurdle', `saver'

est store EX_level_exp_specB

global level_controls  qrresid4



/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [lnbadj_GDP]qrresid4
	est store level_exp_spec_C

estimates title: Exponential Hurdle Endogenous Levels Eq 
est save `exponential_hurdle', `saver'




/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION F:
 Estimate the model with depvars in logs  and log y on the LHS

*/
/*************************************************************************************/
/*************************************************************************************/



global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev ln_fraction_remaining_BOQ ln_stock_QR_Index ln_stock_Nshannon_Q i.stock_distance_type#c.lnfp _Iq* 

global exog_part  ln_fraction_remaining_BOQ _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls  qrresid4
global level_controls  pres4 qrresid4


global selectionrhs $exog_part $interaction c.$endog2  $selection_controls



/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum
	
	estimates title: Log-log Hurdle Endogenous Q and P
est save `exponential_hurdle', `saver'
est store log_exp_spec


nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)
estimates title: Log-log Hurdle Exogenous Q and P
est save `exponential_hurdle', `saver'

est store EX_log_exp_spec

/* the log spec model has ambiguous evidence about the exogeneity of some of the RHS vars, the quantity remaining in the participation equation */
global level_controls qrresid4



/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
	estimates title: Log-log Hurdle Endogenous Q and P TestA 
est save `exponential_hurdle', `saver'

est store log_exp_specE

/* */









/* Testing down 
The first specification said that the DDFUEL_R's interaction was not significant, so we'll go ahead and re-estimate without those 3 variables.

*/

global exog_lev ln_fraction_remaining_BOQ ln_stock_QR_Index  _Iq* 
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global selection_controls  qrresid4
global level_controls  pres4 qrresid4



nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)

estimates title: Log-log Hurdle Exogenous  Q and P Test B
est save `exponential_hurdle', `saver'
est store EX_log_exp_specA

/* the log spec model has ambiguous evidence about the exogeneity of some of the RHS vars, the quantity remaining in the participation equation */


/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum

	estimates title: Log-log Hurdle Endogenous  Q and P Test B
est save `exponential_hurdle', `saver'
est store log_exp_specA



global level_controls  


/* DWH test */
	cap drop pres4
	cap drop qrresid4

	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4

	
estimates title: Log-log Hurdle Endogenous  Participation Test B
est save `exponential_hurdle', `saver'

est store log_exp_specEA









global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev ln_fraction_remaining_BOQ ln_stock_QR_Index i.stock_distance_type#c.lnfp _Iq* 

/* perhaps try 
global exog_lev ln_fraction_remaining_BOQ ln_stock_QR_Index i(0 1).stock_distance_type#c.lnfp _Iq* 

*/

global exog_part  ln_fraction_remaining_BOQ _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls 

global selectionrhs $exog_part $interaction c.$endog2  $selection_controls

/* the log spec model has ambiguous evidence about the exogeneity of some of the RHS vars, the quantity remaining in the participation equation */
global level_controls qrresid4



/* DWH test */
	cap drop pres4
	cap drop qrresid4

	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [lnbadj_GDP]qrresid4
	
	estimates title: Log-log Hurdle Endogenous Q and P TestEB 
est save `exponential_hurdle', `saver'

est store log_exp_specEB

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)

estimates title: Log-log Hurdle Exogenous Q and P TestEB 
est save `exponential_hurdle', `saver'




global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev ln_fraction_remaining_BOQ ln_stock_QR_Index i(0 1).stock_distance_type#c.lnfp _Iq* 


global exog_part  ln_fraction_remaining_BOQ _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls 

global selectionrhs $exog_part $interaction c.$endog2  $selection_controls

/* the log spec model has ambiguous evidence about the exogeneity of some of the RHS vars, the quantity remaining in the participation equation */
global level_controls qrresid4



/* DWH test */
	cap drop pres4
	cap drop qrresid4

	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [lnbadj_GDP]qrresid4
	estimates title: Log-log Hurdle Endogenous Q and P TestEC 
est save `exponential_hurdle', `saver'

est store log_exp_specEC



nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)

estimates title: Log-log Hurdle Exogenous Q and P TestEC 
est save `exponential_hurdle', `saver'



global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev ln_fraction_remaining_BOQ ln_stock_QR_Index c.lnfp _Iq* 


global exog_part ln_fraction_remaining_BOQ _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls 

global selectionrhs $exog_part $interaction c.$endog2  $selection_controls

/* the log spec model has ambiguous evidence about the exogeneity of some of the RHS vars, the quantity remaining in the participation equation */
global level_controls qrresid4



/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls) vce(cluster clustvar)
test [lnbadj_GDP]qrresid4

	estimates title: Log-log Hurdle Endogenous Q and P TestED 
est save `exponential_hurdle', `saver'

est store log_exp_specED




nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction)  vce(cluster clustvar)

estimates title: Log-log Hurdle Exogenous Q and P TestED
est save `exponential_hurdle', `saver'
























/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION G:
 Estimate the exponential model with indevars in levels, with the spatial lags 

*/
/*************************************************************************************/
/*************************************************************************************/

/* Saving done to here.
estimates title: Exponential Spatial Hurdle Endogenous Q and P, 

local saver replace
est save `exponential_spatial_hurdle', `saver'
local saver append




 */



/* endog1, the first endogenous variable */
global endog1 live_priceGDP

/* endog2, the second endogenous variable */
global endog2 quota_remaining_BOQ

/* interaction : an interaction of an endogenous variable and an exogenous one */
global interaction c.recip_ACL#c.$endog2

/* Full list of exogenous variables that are included in the levels equation */
global exog_lev Wswt_quota_remaining_BOQ Wswt_livep  i.stock_distance_type#c.DDFUEL_R  _Iq*

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










/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum
estimates title: Exponential Spatial Hurdle Endogenous Q and P

local saver replace
est save `exponential_spatial_hurdle', `saver'
local saver append


est store slx_exp_1



nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)
estimates title: Exponential Spatial Hurdle Exogenous Q and P 
est save `exponential_spatial_hurdle', `saver'

est store EX_slx_exp_1


/* Still evidence that DDFUEL_R does not belong in the level equation. Still evidence that prices are exog. Some evidence that quantity is endogenous. */



global exog_lev Wswt_quota_remaining_BOQ Wswt_livep  _Iq*
global level_controls  qrresid4
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)




/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
	estimates title: Exponential Spatial Hurdle Endogenous Q and P, testing down
est save `exponential_spatial_hurdle', `saver'

est store slx_exp_1A

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)
estimates title: Exponential Spatial Hurdle Exogenous Q and P, testing down
est save `exponential_spatial_hurdle', `saver'

est store EX_slx_exp_1A



/*Try the revenue based spatial lag X */

global exog_lev Wrev_quota_remaining_BOQ Wrev_livep  _Iq*
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)




/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
	estimates title: Exponential Spatial Hurdle Endogenous Q and P, Revenue Based W
est save `exponential_spatial_hurdle', `saver'

est store END_slx2
nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)
estimates title: Exponential Spatial Hurdle Exogenous Q and P, Revenue Based W
est save `exponential_spatial_hurdle', `saver'

est store EX_slx2









global endog1 live_priceGDP

global endog2 quota_remaining_BOQ

global interaction c.recip_ACL#c.$endog2

global exog_part _Iq* 
global exog_lev Wswt_quota_remaining_BOQ  _Iq*



/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

global selection_controls  qrresid4
global level_controls  qrresid4

global selectionrhs $exog_part $interaction c.$endog2  $selection_controls 

/* do not include the spatial lag of live prices */





/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
	estimates title: Exponential Spatial Hurdle Endogenous Q and P, testing down B
est save `exponential_spatial_hurdle', `saver'

est store slx_exp_1C

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)
estimates title: Exponential Spatial Hurdle Exogenous Q and P, testing down B
est save `exponential_spatial_hurdle', `saver'
est store slx_exp_1D



/* same, but exog Q in the participation equation */
global selection_controls  
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)



/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [lnbadj_GDP]qrresid4
	estimates title: Exponential Spatial Hurdle Endogenous Q and P, testing down E
est save `exponential_spatial_hurdle', `saver'

est store slx_exp_1E

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)
estimates title: Exponential Spatial Hurdle Exogenous Q and P, testing down E
est save `exponential_spatial_hurdle', `saver'
est store slx_exp_1F




/* reset particpation equation */

global selection_controls  qrresid4

global exog_lev Wrev_quota_remaining_BOQ  _Iq*

global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)






/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls) vce(cluster clustvar)
test [selection]qrresid4
	estimates title: Exponential Spatial Hurdle Endogenous Q and P, Revenue Based W testing down B
est save `exponential_spatial_hurdle', `saver'

est store slx_exp_2G

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)
estimates title: Exponential Spatial Hurdle Exogenous Q and P, Revenue Based W, testing down B
est save `exponential_spatial_hurdle', `saver'
est store slx_exp_2H


/* same, but exog Q in the participation equation */

global selection_controls  




/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls) vce(cluster clustvar)
	estimates title: Exponential Spatial Hurdle Endogenous Q and P, Revenue Based W testing down G
est save `exponential_spatial_hurdle', `saver'

est store slx_exp_2G

nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)
estimates title: Exponential Spatial Hurdle Exogenous Q and P, Revenue Based W, testing down H
est save `exponential_spatial_hurdle', `saver'
est store slx_exp_2H















/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION H:
 Estimate the exponential model with indepvars in logs, with the spatial lags in logs

 
*/
/*************************************************************************************/
/*************************************************************************************/


global endog1 ln_live_priceGDP

global endog2 ln_quota_remaining_BOQ

global interaction 

global exog_lev Wswt_ln_quota_remaining_BOQ Wswt_ln_livep  i.stock_distance_type#c.lnfp  _Iq*

global exog_part ln_fraction_remaining_BOQ _Iq* 


/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)

global IVs lag4Q_ln_live_priceGDP lag4Q_ln_quota_remaining_BOQ 

global selection_controls  qrresid4
global level_controls  pres4 qrresid4


global selectionrhs $exog_part $interaction c.$endog2  $selection_controls

/* estimate the control function version */




/* DWH test */

	cap drop pres4
	cap drop qrresid4
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , exponential select(c.$endog2 $exog_part  $interaction $selection_controls)  vce(cluster clustvar)
test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum
	estimates title: Exponential Spatial Hurdle Endogenous Q and P, indep in logs
est save `exponential_spatial_hurdle', `saver'
est store slx_exp_ln1
nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)
estimates title: Exponential Spatial Hurdle Exogenous Q and P, indep in logs
est save `exponential_spatial_hurdle', `saver'

est store EX_slx_exp_ln1



/* same but no fuel prices */

global exog_lev Wswt_ln_quota_remaining_BOQ Wswt_ln_livep   _Iq*

/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)




nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)  
estimates title: Exponential Spatial Hurdle Exogenous Q and P, indep in logs tested down


est save `exponential_spatial_hurdle', `saver'

est store EX_slx_exp_ln2



/* same but no spatial lag of prices */
global exog_lev Wswt_ln_quota_remaining_BOQ   _Iq*

/* cleaned of duplicates */
global exog_full $exog_part $exog_lev
global exog_full : list uniq global(exog_full)



nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev, exponential select($exog_part c.$endog2 $interaction) vce(cluster clustvar)

estimates title: Exponential Spatial Hurdle Exogenous Q and P, indep in logs tested down B


est save `exponential_spatial_hurdle', `saver'

est store EX_slx_exp_ln2B


























log close
