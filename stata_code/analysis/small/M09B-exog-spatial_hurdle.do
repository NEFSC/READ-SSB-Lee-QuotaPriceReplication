
	
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

	
	
stata's churdle is fixed.


churdle margins, dydx(age) predict(ytrun)  <- is equivalent to churdle margins, eyex(age) predict(e(0,.))

churdle margins, dydx(age) predict(ycen)  <- is equivalent to churdle margins, eyex(age) ystar

*/
cap log close

local mylogfile "${my_results}/M09B_exog_spatial_hurdle.smcl" 
log using `mylogfile', replace

#delimit cr
version 15.1
clear all
spmatrix clear
est  drop _all
set scheme s2mono
/*bootstrap options */
global common_seed 06240628
global bootreps 1000

*global vintage_string "2021_09_13"

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
local final_results ${my_results}/quota_price_hurdle_results_${vintage_string}.ster


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
/* Program  a softcoded version of the churdle with a control function */
/**If you want one of the endogenous variables to be exogenous, all you need to do is omit it's residual from the $level_controls or $selection_controls macro.  
	You still end up running the 1st stage OLS models, but don't plug them into the 2nd stage.
	You need to be careful about the list of IVs though.  
*******************************************************/
/*********************************************************/
/* this is probably bad coding to use globals and a program without an arg, but whatever */

cap drop pres4
cap drop qrresid4

cap program drop boot_churdle_generic
program boot_churdle_generic, rclass
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc  select(c.$endog2 $exog_part  $interaction $selection_controls)

drop pres4 qrresid4
end program






cap program drop boot_churdle_generic_exp
program boot_churdle_generic_exp, rclass
	regress $endog1 $exog_full  $IVs
	predict pres4, residual
 
	regress $endog2  $exog_full $IVs

	predict qrresid4, residual

	nehurdle badj_GDP $endog1 c.$endog2 $interaction $exog_lev $level_controls , trunc select(c.$endog2 $exog_part  $interaction $selection_controls)

drop pres4 qrresid4
end program






/* readin the previous churdle results */





/* load in linear hurdle */
qui est describe using `churdle_compare'

local numest=r(nestresults)
forvalues est=1(1)`numest'{
	est use `churdle_compare', number(`est')
	est store comp_`est'
}




notes quota_remaining_BOQ: This is in 000s of mt
notes ln_quota_remaining_BOQ: logged of 000s of mt


label var quota_remaining_BOQ "Quota Remaining"

label var live_priceGDP "Live Price"
label var ln_live_priceGDP "Log Live Price"
label var ln_quota_remaining_BOQ "Log Quota Remaining"
label var ln_fraction_remaining_BOQ "Log Fraction Quota Remaining"
label var stock_QR_Index "Quota Remaining Index"
label var lnfp "Log Fuel Price"
label var ln_stock_QR_Index "Log Quota Remaining Index"
label var WTswt_quota_remaining_BOQ "Inverse Distance Lag of Quota Remaining"
label var WTDswt_quota_remaining_BOQ "Distance Lag of Quota Remaining"

 
label var WTswt_ln_quota_remaining_BOQ "Inverse Distance Lag of log Quota Remaining"
label var WTDswt_ln_QR_BOQ "Distance Lag of log Quota Remaining"






/* estimate the linear model under exogeneity and test down
   estimate the log-log model under exogeneity and test down. 
   When I start testing down the log-linear model, I get exogeneity also. Which is a little odd. but okay.

*/

/*******************Models under exogeneity************************************/


/* fit the null model to get e(ll_0) for the linear and exponential models */

	nehurdle badj_GDP, select() vce(cluster clustvar) trunc
	scalar ll_0linear=e(ll)

	nehurdle badj_GDP, select() vce(cluster clustvar) trunc exponential
	scalar ll_0exp=e(ll)


/*************************************/
/********Simple models ***************/
/* Is there a time effect */


nehurdle badj_GDP _Iq*,  select(_Iq*) vce(cluster clustvar) exponential
est store exp_Q


nehurdle badj_GDP _Iq*,  select(_Iq*) vce(cluster clustvar) trunc
est store linear_Q



/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/******************************* Linear-Linear *******************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/


/* estimate the exog linear model */
local levelrhs live_priceGDP quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ c.DDFUEL_R  c.avg_hourly_wage_R _Iq* 
local selectionrhs c.quota_remaining_BOQ#c.recip_ACL c.quota_remaining_BOQ  _Iq* 

nehurdle badj_GDP `levelrhs', select(`selectionrhs') vce(cluster clustvar) trunc
est title: linear_P0
est store linear_P0


/* test down by removing DDFUEL_R*/
local levelrhs live_priceGDP quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ  c.avg_hourly_wage_R _Iq* 
local selectionrhs c.quota_remaining_BOQ#c.recip_ACL c.quota_remaining_BOQ   _Iq* 

nehurdle  badj_GDP `levelrhs', select(`selectionrhs') vce(cluster clustvar) trunc
est title: linear_P1
est store linear_P1


local levelrhs live_priceGDP quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ  _Iq* 
local selectionrhs _Iq* c.quota_remaining_BOQ#c.recip_ACL c.quota_remaining_BOQ  

nehurdle badj_GDP `levelrhs', select(`selectionrhs') vce(cluster clustvar)  trunc
est title: linear_P2
est store linear_P2


/*************************************************************************************************************/
/************************* NON-SPATIAL VERSION OF THE PREFERRED LINEAR MODEL *********************************/
/*************************************************************************************************************/

local levelrhs c.live_priceGDP c.quota_remaining_BOQ  _Iq* 
local selectionrhs c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL    _Iq* 

nehurdle badj_GDP `levelrhs', select(`selectionrhs') vce(cluster clustvar) trunc
est title: linear_P3NS

est store linear_P3NS
est save `final_results' , replace
/*************************************************************************************************************/
/*************************************************************************************************************/




/*************************************************************************************************************/
/************************* PREFERRED LINEAR MODEL *********************************/
/*************************************************************************************************************/

local levelrhs c.live_priceGDP c.quota_remaining_BOQ c.WTswt_quota_remaining_BOQ c.WTDswt_quota_remaining_BOQ  _Iq* 
local selectionrhs c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL    _Iq* 

nehurdle badj_GDP `levelrhs', select(`selectionrhs') vce(cluster clustvar) trunc
est title: linear_P3
est store linear_P3
est save `final_results' , append
/*************************************************************************************************************/
/*************************************************************************************************************/





scalar r2p_linear3=1-(e(ll)/ll_0linear)

est table linear*, stats(r2 aic bic N ll)
/* AIC/BIC like the most parsimonious model best -- fit, by the likelihood function is slightly worse though than models 0 and 1.  But that's okay. 

Takeaway
1. price and q have anticipated effects
2. Spatial weights matter -- nearby stocks (WT) are complements and when the QR of them increases, quota price goes up. Faraway (WTD) are substitutes and when the quantities of them increases, prices go down.  
3. Fuel price doesn't matter.  Wages do. But wages are cyclical and we may be mis-attributing other intra-year factors to the wage effect.

*/

/* DWH Test of exogeneity in a CF style of the linear_P3 model */

global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

cap drop pres4
cap drop qrresid4

	regress live_priceGDP  c.WTswt_quota_remaining_BOQ c.WTDswt_quota_remaining_BOQ  _Iq* $IVs
	predict pres4, residual
 
	regress  quota_remaining_BOQ  c.WTswt_quota_remaining_BOQ c.WTDswt_quota_remaining_BOQ  _Iq* $IVs

	predict qrresid4, residual

nehurdle badj_GDP `levelrhs' qrresid4 pres4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc

test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum




/* DWH Test of exogeneity in a CF style of the linear_P3NS model */
local levelrhs c.live_priceGDP c.quota_remaining_BOQ  _Iq* 
local selectionrhs c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL    _Iq* 

global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

cap drop pres4
cap drop qrresid4

	regress live_priceGDP    _Iq* $IVs
	predict pres4, residual
 
	regress  quota_remaining_BOQ   _Iq* $IVs

	predict qrresid4, residual

nehurdle badj_GDP `levelrhs' qrresid4 pres4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc

test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum


















est restore linear_P3


margins, dydx(*) predict(ycen) asobserved post




/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/******************************* Log-Linear ***************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/



local levelrhs live_priceGDP quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL   WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ  _Iq*
local selectionrhs _Iq* c.quota_remaining_BOQ#c.recip_ACL c.quota_remaining_BOQ  


nehurdle badj_GDP `levelrhs',  select(`selectionrhs') vce(cluster clustvar) trunc exponential

/*interestingly, these are jointly significant -- probably because they are collinear */
test  WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ
est title: exp_P1
est store exp_P1




local levelrhs live_priceGDP quota_remaining_BOQ   WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ  _Iq*
local selectionrhs _Iq* c.quota_remaining_BOQ#c.recip_ACL c.quota_remaining_BOQ
nehurdle badj_GDP `levelrhs',  select(`selectionrhs') vce(cluster clustvar) trunc exponential
est title: exp_P2
est store exp_P2
test  WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ


/* experiment with dropping one, the other or both */

/*************************************************************************************************************/
/************************* NON-SPATIAL VERSION OF THE PREFERRED EXPONENTIAL MODEL *********************************/
/*************************************************************************************************************/



local levelrhs live_priceGDP quota_remaining_BOQ  _Iq*
local selectionrhs  c.quota_remaining_BOQ  c.quota_remaining_BOQ#c.recip_ACL  _Iq*

nehurdle badj_GDP `levelrhs',  select(`selectionrhs') vce(cluster clustvar) trunc exponential
est title: exp_P1NS
est store exp_P1NS

est save `final_results' , append
/*************************************************************************************************************/
/*************************************************************************************************************/




/*************************************************************************************************************/
/*************************  PREFERRED EXPONENTIAL MODEL *********************************/
/*************************************************************************************************************/

local levelrhs live_priceGDP quota_remaining_BOQ  WTDswt_quota_remaining_BOQ  _Iq*
local selectionrhs  c.quota_remaining_BOQ  c.quota_remaining_BOQ#c.recip_ACL  _Iq*

nehurdle badj_GDP `levelrhs',  select(`selectionrhs') vce(cluster clustvar) trunc exponential
est title: exp_P1D
est store exp_P1D

est save `final_results' , append
/*************************************************************************************************************/
/*************************************************************************************************************/


scalar r2p_expPID=1-(e(ll)/ll_0exp)


local levelrhs live_priceGDP quota_remaining_BOQ WTswt_quota_remaining_BOQ  _Iq*
local selectionrhs c.quota_remaining_BOQ#c.recip_ACL c.quota_remaining_BOQ   _Iq*

nehurdle badj_GDP `levelrhs',  select(`selectionrhs') vce(cluster clustvar) trunc exponential
est title: exp_P1T

est store exp_P1T







est table exp_*, stats(r2 aic bic N ll)



/* Prefers P1D, although P1 and P1T are very close. P2, where we do not include any spatial weights is a bit worse. What you'd expect from the classical hypothesis testing */

est restore exp_P1D
est replay


/*************************************************************************************************************/
/*************************************************************************************************************/
/* DWH Test of exogeneity in a CF  for exp_P1D*/


local levelrhs live_priceGDP quota_remaining_BOQ  WTDswt_quota_remaining_BOQ  _Iq*
local selectionrhs  c.quota_remaining_BOQ  c.quota_remaining_BOQ#c.recip_ACL  _Iq*

global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

cap drop pres4
cap drop qrresid4

	regress live_priceGDP WTDswt_quota_remaining_BOQ  _Iq*  $IVs
	predict pres4, residual
 
	regress  quota_remaining_BOQ  WTDswt_quota_remaining_BOQ  _Iq* $IVs

	predict qrresid4, residual

nehurdle badj_GDP `levelrhs' qrresid4 pres4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc exponential

test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum


/*************************************************************************************************************/
/*************************************************************************************************************/
/* DWH Test of exogeneity in a CF  for exp_PNS*/
local levelrhs live_priceGDP quota_remaining_BOQ  _Iq*
local selectionrhs  c.quota_remaining_BOQ  c.quota_remaining_BOQ#c.recip_ACL  _Iq*
global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL


cap drop pres4
cap drop qrresid4

	regress live_priceGDP  _Iq*  $IVs
	predict pres4, residual
 
	regress  quota_remaining_BOQ   _Iq* $IVs

	predict qrresid4, residual

nehurdle badj_GDP `levelrhs' qrresid4 pres4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc exponential

test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum



/*************************************************************************************************************/
/***************************APPENDIX MODELS********************************************************************************/

/* put linear_P0 into the final results */
est restore linear_P0
est save `final_results' , append


/* exp_P0 */
/* estimate the exog linear model */
local levelrhs live_priceGDP quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ c.DDFUEL_R  c.avg_hourly_wage_R _Iq* 
local selectionrhs c.quota_remaining_BOQ#c.recip_ACL c.quota_remaining_BOQ  _Iq* 
global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL


cap drop pres4
cap drop qrresid4

	regress live_priceGDP  _Iq*  $IVs
	predict pres4, residual
 
	regress  quota_remaining_BOQ   _Iq* $IVs

	predict qrresid4, residual

nehurdle badj_GDP `levelrhs' qrresid4 pres4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc exponential

test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum

nehurdle badj_GDP `levelrhs',  select(`selectionrhs' ) vce(cluster clustvar) trunc exponential
est title: exp_P0
est save `final_results' , append





/* Linear and exponential models with previous quarter's live price as a RHS as a proxy for live price  (not an IV)*/


/* Linear*/

/* DWH Test of exogeneity in a CF style of the linear_P3NS model */
local levelrhs c.lag1Q_live_priceGDP c.quota_remaining_BOQ  _Iq* 
local selectionrhs c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL    _Iq* 

/* DWH Test of exogeneity in a CF style of the linear_P3 model */

global IVs lag4Q_quota_remaining_BOQ c.recip_ACL

cap drop pres4
cap drop qrresid4

	regress  quota_remaining_BOQ  c.WTswt_quota_remaining_BOQ c.WTDswt_quota_remaining_BOQ  _Iq* $IVs

	predict qrresid4, residual

nehurdle badj_GDP `levelrhs' qrresid4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc

test [selection]qrresid4
test [badj_GDP]qrresid4, accum

/* this result says exogenous, so estimate under exogeneity */



nehurdle badj_GDP `levelrhs', select(`selectionrhs' ) vce(cluster clustvar) trunc
est title:linear_P3proxy
est save `final_results' , append

/* Exponential*/


/* DWH Test of exogeneity in a CF style of the linear_P3NS model */
local levelrhs c.lag1Q_live_priceGDP c.quota_remaining_BOQ  _Iq* 
local selectionrhs c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL    _Iq* 

/* DWH Test of exogeneity in a CF style of the linear_P3 model */

global IVs lag4Q_quota_remaining_BOQ c.recip_ACL

cap drop pres4
cap drop qrresid4

	regress  quota_remaining_BOQ  c.WTswt_quota_remaining_BOQ c.WTDswt_quota_remaining_BOQ  _Iq* $IVs

	predict qrresid4, residual

nehurdle badj_GDP `levelrhs' qrresid4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc exponential

test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum



nehurdle badj_GDP `levelrhs' , select(`selectionrhs' ) vce(cluster clustvar) trunc exponential
est title: exp_P1Dproxy

est save `final_results' , append






/* Linear and exponential models with a revenue based spatial weights matrix */




/* Linear*/

/* DWH Test of exogeneity in a CF style of the linear_P3NS model */
local levelrhs c.live_priceGDP c.quota_remaining_BOQ  WTrev_quota_remaining_BOQ WTDrev_quota_remaining_BOQ _Iq* 
local selectionrhs c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL    _Iq* 

/* DWH Test of exogeneity in a CF style of the linear_P3 model */

global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

cap drop pres4
cap drop qrresid4

	regress live_priceGDP WTDswt_quota_remaining_BOQ  _Iq*  $IVs
	predict pres4, residual
 
	regress  quota_remaining_BOQ  WTDswt_quota_remaining_BOQ  _Iq* $IVs

	predict qrresid4, residual
nehurdle badj_GDP `levelrhs' qrresid4 pres4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc

test [selection]qrresid4
test [badj_GDP]qrresid4, accum
test [badj_GDP]pres4, accum

/* this result says exogenous, so estimate under exogeneity */



nehurdle badj_GDP `levelrhs', select(`selectionrhs' ) vce(cluster clustvar) trunc
est title: linear_P3rev
est save `final_results' , append





/* Exponential*/

/* DWH Test of exogeneity in a CF style of the linear_P3NS model */
local levelrhs c.live_priceGDP c.quota_remaining_BOQ   WTDrev_quota_remaining_BOQ _Iq* 
local selectionrhs c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL    _Iq* 

/* DWH Test of exogeneity in a CF style of the linear_P3 model */

global IVs lag4Q_live_priceGDP lag4Q_quota_remaining_BOQ c.recip_ACL

cap drop pres4
cap drop qrresid4

	regress live_priceGDP WTDswt_quota_remaining_BOQ  _Iq*  $IVs
	predict pres4, residual
 
	regress  quota_remaining_BOQ  WTDswt_quota_remaining_BOQ  _Iq* $IVs

	predict qrresid4, residual
nehurdle badj_GDP `levelrhs' qrresid4 pres4, select(`selectionrhs'  qrresid4) vce(cluster clustvar) trunc exponential



test [selection]qrresid4
test [lnbadj_GDP]qrresid4, accum
test [lnbadj_GDP]pres4, accum



nehurdle badj_GDP `levelrhs' , select(`selectionrhs' ) vce(cluster clustvar) trunc exponential
est title: exp_P1rev

est save `final_results' , append



































/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/******************************* Log-Log**************************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/






local log_levelrhs ln_live_priceGDP c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ     c.lnfp  c.ln_avg_hourly_wage_R  _Iq*
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  
nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc exponential

est store LL1


local log_levelrhs ln_live_priceGDP c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ     c.ln_avg_hourly_wage_R  _Iq*
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  
nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc exponential
test WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ


est store LL2


local log_levelrhs ln_live_priceGDP c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ  c.ln_avg_hourly_wage_R  _Iq*
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  
nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc exponential

est store LL3




local log_levelrhs ln_live_priceGDP c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ  c.ln_avg_hourly_wage_R  _Iq*
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ   
nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc exponential

est store LL4




local log_levelrhs ln_live_priceGDP c.ln_quota_remaining_BOQ    WTDswt_ln_QR_BOQ   _Iq*
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  
nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc exponential

est store LL5

/* I think the quarterly seasonality of wages is creating a problem here -- there's something seasonal that is correlated with wages and that is getting loaded on the wage coefficient */

local log_levelrhs ln_live_priceGDP c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ _Iq*
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  
nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc exponential

est store LL_P0

scalar r2p_LL_P0=1-(e(ll)/ll_0exp)



local log_levelrhs ln_live_priceGDP c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  
nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc exponential

est store LL_P

est table LL*, stats(r2 aic bic N ll)

est table LL4 LL_P, stats(r2 aic bic N ll) star(.1 .05 .01)



/* lets look at the three preferred */
est table exp_P1D LL_P linear_P3, stats(r2 aic bic N ll) star(.1 .05 .01) equations(1,2,3)

/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/
/******************************* Linear-Log **********************************/
/*****************************************************************************/
/*****************************************************************************/
/*****************************************************************************/



local log_levelrhs ln_live_priceGDP c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ     c.lnfp  c.ln_avg_hourly_wage_R  _Iq*
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  

nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc

est store lin_log1
scalar r2p_Lin_log1=1-(e(ll)/ll_0linear)


local log_levelrhs ln_live_priceGDP c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ  _Iq*
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  

nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc
est store lin_log2
scalar r2p_Lin_log2=1-(e(ll)/ll_0linear)


local log_levelrhs ln_live_priceGDP c.ln_quota_remaining_BOQ    WTswt_ln_quota_remaining_BOQ WTDswt_ln_QR_BOQ  
local log_selectionrhs _Iq* c.ln_fraction_remaining_BOQ c.ln_quota_remaining_BOQ  

nehurdle badj_GDP `log_levelrhs',  select(`log_selectionrhs') vce(cluster clustvar) trunc
est store lin_log3

scalar r2p_Lin_log3=1-(e(ll)/ll_0linear)

est table lin_log1 lin_log2 lin_log3, stats(r2 aic bic N ll) star(.1 .05 .01)


scalar list

est table exp_P1D LL_P0 linear_P3 lin_log3, stats(r2 aic bic N ll k) star(.1 .05 .01) 



/*OLS based on the linear functional form */

regress badj_GDP live_priceGDP quota_remaining_BOQ WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ _Iq*, vce(cluster clustvar)
est store OLS

/* grab the OLS coefficients */
local OLS_price=_b[live_priceGDP]
local OLS_QR= _b[quota_remaining_BOQ]
local estout_opts nobaselevels cells(b (star fmt(3)) se(par fmt(2)))  starlevels(* 0.10 ** 0.05 *** 0.01) wrap substitute(_cons Constant _ \_ # "$\times$") equations(select=1:1:1:1:., outcome=2:2:2:2:1, lnsig=3:3:3:3:.) stats(r2 aic bic  N  ll k, fmt(%04.3f %5.1fc  %7.1fc %3.0f %5.1fc %2.0f))

local label_opts label varlabels(_Iq_fy_2 "Quarter 2" _Iq_fy_3 "Quarter 3" _Iq_fy_4 "Quarter 4") collabels(none) mlabels ("Exponential1" "Exponential2" "Linear1" "Linear2" "OLS")

local reorder order(live_priceGDP ln_live_priceGDP quota_remaining_BOQ ln_quota_remaining_BOQ  Fraction_Quota_Remaining  ln_fraction_remaining_BOQ WTDswt_quota_remaining_BOQ WTDswt_ln_QR_BOQ WTswt_quota_remaining_BOQ WTswt_ln_quota_remaining_BOQ) rename(select:c.quota_remaining_BOQ#c.recip_ACL Fraction_Quota_Remaining)

estout exp_P1D LL_P0 linear_P3 lin_log3 OLS, `reorder' `estout_opts' `label_opts'

esttab  exp_P1D LL_P0 linear_P3 lin_log3 OLS using ${my_tables}\second_stage_coef_table.tex, replace `reorder' `estout_opts' `label_opts' noobs nonumbers  alignment(r)

local reorder order(live_priceGDP quota_remaining_BOQ   WTDswt_quota_remaining_BOQ WTswt_quota_remaining_BOQ)   rename(participation:c.quota_remaining_BOQ#c.recip_ACL Fraction_Quota_Remaining)

local small_estout_opts nobaselevels cells(b (star fmt(3)) se(par fmt(2)))  starlevels(* 0.10 ** 0.05 *** 0.01) wrap substitute(_cons Constant _ \_ aic AIC bic BIC r2 R$^2$ ll "Log-Likelihood") equations(participation=1:1:., outcome=2:2:1) stats(r2 aic bic  N  ll , fmt(%04.3f %5.0fc  %7.0fc %3.0f %5.0fc)) drop(lnsigma:_cons)


local label_opts label varlabels(_Iq_fy_2 "Quarter 2" _Iq_fy_3 "Quarter 3" _Iq_fy_4 "Quarter 4") collabels(none) mlabels ("Exponential" "Linear" "OLS")
estout exp_P1D linear_P3  OLS,  `reorder' `small_estout_opts' `label_opts' 

esttab  exp_P1D linear_P3  OLS using ${my_tables}\small_second_stage_coef_table.tex, replace `reorder' `small_estout_opts' `label_opts' noobs nonumbers  alignment(r)




/*note  -churdle's r2_p is "mcfaddens pseudo r2= 

	ereturn scalar r2_p = 1 - e(ll)/e(ll_0)
	
	nehurdle returns the squared correlation between the censored prediction and the actual values.
	
	predict nelin_cen, ycen
	corr nelin_cen badj_GDP if e(sample)
	di r(rho)^2

	
To get the mcfadden's pseudo R2, you can do:


	nehurdle badj_GDP, select() vce(cluster clustvar) trunc
	scalar ll_0linear=e(ll)

	nehurdle badj_GDP, select() vce(cluster clustvar) trunc exponential
	scalar ll_0exp=e(ll)
	
	run the regression that you want and then do
	
	scalar r2_pm=1-e(ll)-ll_0exp
	
*/	



/*
nehurdle margins, dydx(age) predict(ytrun)  <- is equivalent to churdle margins, eyex(age) predict(e(0,.))
nehurdle margins, dydx(age) predict(ycen)  <- is equivalent to churdle margins, eyex(age) 
*/
local working_model exp_P1D
est restore `working_model'
gen hand_esample=e(sample)





local T_pr_D "Marginal Effect on Positive Prices"
local T_pr_E "Elasticities of Probability of Positive"
local T_pr_SE "Semi- Elasticities of Probability of Positive"



local T_ycenD "Marginal Effect on  Prices"
local T_ycenE "Elasticities of Prices"

local T_ytrunE "Elasticities of Positive Prices"
local T_ytrunD "Marginal Effect on Positive Prices"





/* here are the effects of marginal changes in x on the ycen, ytrun, and psel */
/************ycen ****************************/
margins, dydx(*) predict(ycen)  asobserved post
estimates store ycen_D_`working_model', title(`T_ycenD')
est restore `working_model'
estimates esample: if hand_esample, replace

/************ytrun ****************************/
margins, dydx(*) predict(ytrun)  asobserved post
estimates store ytrun_D_`working_model',title(`T_ytrunD')
est restore `working_model'
estimates esample: if hand_esample, replace

/************psel****************************/
margins, dydx(*) predict(psel) asobserved post
estimates store prD_`working_model',title(`T_pr_D')
est restore `working_model'
estimates esample: if hand_esample, replace






/* here are the elasticities of continuous x on the ycen, ytrun, and psel */
/************ycen ****************************/
margins, eyex(live_priceGDP quota_remaining_BOQ WTDswt_quota_remaining_BOQ) predict(ycen) asobserved post
estimates store ycen_E_`working_model', title(`T_ycenE'')
est restore `working_model'
estimates esample: if hand_esample, replace
/************ytrun ****************************/
margins, eyex(live_priceGDP quota_remaining_BOQ WTDswt_quota_remaining_BOQ) predict(ytrun) asobserved post
estimates store ytrun_E_`working_model', title(`T_ytrunE'')
est restore `working_model'
estimates esample: if hand_esample, replace
/************psel****************************/

margins, eyex(recip_ACL quota_remaining_BOQ) predict(psel) asobserved post
estimates store prE_`working_model',title(`T_pr_E')
est restore `working_model'
estimates esample: if hand_esample, replace




margins, dyex(recip_ACL quota_remaining_BOQ) predict(psel) asobserved post
estimates store prSE_`working_model',title(`T_pr_SE')
est restore `working_model'
estimates esample: if hand_esample, replace





local estout_opts nobaselevels cells(b (star fmt(3)) se(par fmt(2)))  starlevels(* 0.10 ** 0.05 *** 0.01) wrap 
local label_opts label varlabels(_Iq_fy_2 "Quarter 2" _Iq_fy_3 "Quarter 3" _Iq_fy_4 "Quarter 4") collabels(none)
/*local reorder order(live_priceGDP ln_live_priceGDP quota_remaining_BOQ ln_quota_remaining_BOQ  c.quota_remaining_BOQ#c.recip_ACL  ln_fraction_remaining_BOQ WTDswt_quota_remaining_BOQ WTDswt_ln_QR_BOQ WTswt_quota_remaining_BOQ WTswt_ln_quota_remaining_BOQ) */

local reorder order(live_priceGDP quota_remaining_BOQ WTDswt_quota_remaining_BOQ )



estout ytrun_D_`working_model' ytrun_E_`working_model' ycen_D_`working_model' ycen_E_`working_model', `reorder' `estout_opts' `label_opts'








/* 2nd model 


local T_pr_D "Marginal Effect on Positive Prices"
local T_pr_E "Elasticities of Probability of Positive"

local T_ycenD "Marginal Effect on  Prices"
local T_ycenE "Elasticites of Prices"

local T_ytrunE "Elasticites of Positive Prices"
local T_ytrunD "Marginal Effect on Positive Prices"

*/




local working_model2 linear_P3
est restore `working_model2'


/* here are the effects of marginal changes in x on the ycen, ytrun, and psel */

/************ycen ****************************/

margins, dydx(*) predict(ycen) asobserved post
estimates store ycen_D_`working_model2', title(`T_ycenD')
est restore `working_model2'
estimates esample: if hand_esample, replace


/************ytrun ****************************/

margins, dydx(*) predict(ytrun) asobserved post
estimates store ytrun_D_`working_model2', title(`T_ytrunD')
est restore `working_model2'
estimates esample: if hand_esample, replace


/************psel****************************/

margins, dydx(*) predict(psel) asobserved post
estimates store prD_`working_model2',title(`T_pr_D')
est restore `working_model2'
estimates esample: if hand_esample, replace


/* here are the elasticities of continuous x on the ycen, ytrun, and psel */
/************ycen ****************************/
margins, eyex(live_priceGDP quota_remaining_BOQ WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ) predict(ycen) asobserved post
estimates store ycen_E_`working_model2', title(`T_ycenE'')
est restore `working_model2'
estimates esample: if hand_esample, replace
/************ytrun ****************************/

margins, eyex(live_priceGDP quota_remaining_BOQ WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ) predict(ytrun) asobserved post
estimates store ytrun_E_`working_model2', title(`T_ytrunE'')
est restore `working_model2'
estimates esample: if hand_esample, replace
/************psel ****************************/

margins, eyex(recip_ACL quota_remaining_BOQ) predict(psel) asobserved post
estimates store prE_`working_model2',title(`T_pr_E')

est restore `working_model2'
estimates esample: if hand_esample, replace




margins, dyex(recip_ACL quota_remaining_BOQ) predict(psel) asobserved post
estimates store prSE_`working_model2',title(`T_pr_SE')
est restore `working_model2'
estimates esample: if hand_esample, replace




local estout_opts nobaselevels cells(b (star fmt(3)) se(par fmt(2)))  starlevels(* 0.10 ** 0.05 *** 0.01) wrap substitute(_cons Constant _ \_)   style(tex)
local label_opts label varlabels(_Iq_fy_2 "Quarter 2" _Iq_fy_3 "Quarter 3" _Iq_fy_4 "Quarter 4") mlabels("Exponential" "Linear" "Exponential" "Linear") collabels(none)
local reorder order(live_priceGDP  quota_remaining_BOQ   WTDswt_quota_remaining_BOQ WTswt_quota_remaining_BOQ) 

estout ytrun_D_`working_model2' ytrun_E_`working_model2' ycen_D_`working_model2' ycen_E_`working_model2', `reorder' `estout_opts' `label_opts' drop(recip_ACL)


/*print it on screen */
estout ytrun_D_`working_model' ytrun_D_`working_model2' ycen_D_`working_model'  ycen_D_`working_model2' , `reorder' `estout_opts' `label_opts' drop(recip_ACL)
estout ytrun_D_`working_model' ytrun_D_`working_model2' ycen_D_`working_model'  ycen_D_`working_model2' using ${my_tables}\second_stage_margins.tex, replace `reorder' `estout_opts' `label_opts' drop(recip_ACL)

/*print it on screen */
estout ytrun_E_`working_model' ytrun_E_`working_model2' ycen_E_`working_model'  ycen_E_`working_model2' ,  `reorder' `estout_opts' `label_opts'
estout ytrun_E_`working_model' ytrun_E_`working_model2' ycen_E_`working_model'  ycen_E_`working_model2'  using ${my_tables}\second_stage_elasticities.tex, replace `estout_opts' `label_opts'


local probit_keep "noomitted"
/*print it on screen */
local label_opts label mlabels(none) collabels(none)  varlabels(_Iq_fy_2 "Quarter 2" _Iq_fy_3 "Quarter 3" _Iq_fy_4 "Quarter 4")  

local reorder order(quota_remaining_BOQ) drop(recip_ACL)

estout prD_`working_model' prD_`working_model2' prE_`working_model'  prE_`working_model2' , `reorder' `estout_opts' `label_opts' `probit_keep'
estout prD_`working_model' prD_`working_model2' prE_`working_model'  prE_`working_model2'  using ${my_tables}\second_stage_prob_fx.tex, replace  `reorder' `estout_opts' `label_opts'  `probit_keep'


/*The probit parts of the 4 models are the same, so rather than have duplicated text, I'll just make a table with 2 cols.*/
estout prD_`working_model' prE_`working_model'  , `reorder'  `estout_opts' `label_opts'  `probit_keep'
estout prD_`working_model' prE_`working_model'  using "${my_tables}\second_stage_prob_fx.tex", replace  `reorder' `estout_opts' `label_opts'  `probit_keep'



estout prD_`working_model' using "${my_tables}\second_stage_prob_margins.tex", replace  `reorder' `estout_opts' `label_opts'  `probit_keep'
/******************************************************************************/
/******************************************************************************/
/* plot the marginal effects of quota remaining on p[price>0] */
/******************************************************************************/
/******************************************************************************/
est restore linear_P3
margins , predict(psel) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot, ytitle("Probability of Positive Prices") title("") xtitle("Quota Remaining (1000s of mt)") xmtick(##4) xlabel( 0(1)5,  labsize(small))  recast(line) recastci(rarea)
graph export ${my_images}/postestimation/prob_positive_linear3.png, replace as(png) width(2000)


margins , dydx(quota_remaining_BOQ) predict(psel) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot, ytitle("Marginal Effect of Quota Remaining" "on Probability of Positive Prices") title("") xtitle("Quota Remaining (1000s of mt)") xmtick(##4) xlabel( 0(1)5, labsize(small))  recast(line) recastci(rarea)
graph export ${my_images}/postestimation/marginal_prob_positive_linear3.png, replace as(png) width(2000)

/******************************************************************************/
/******************************************************************************/
/* linear_P3 model */
/* plot the E[price|x,price>0] (YTRUN) as a function of quota_remaining  */
/* plot the E[price|x] (YCEN) as a function of quota_remaining  */
/******************************************************************************/
/******************************************************************************/
est restore linear_P3

/* options for all of these margins graphs and options for some of them */
local margin_opts  title("") xtitle("Quota Remaining (1000s of mt)") xmtick(##4) xlabel( 0(1)5,  labsize(small))  recast(line) recastci(rarea)
/* options for some of these margins graphs */

local ycen_dydx_opts ylabel(-1.50(.5)0) ytitle("Marginal Effect on Unconditional Predicted Prices") 
local ycen_opts ylabel(0(.2).8) ytitle("Unconditional Predicted Prices")
local ytrun_opts ylabel(0(.25)1)  ytitle("Conditional Predicted Prices")
local ytrun_dydx_opts ylabel(-.6(.2)0) ytitle("Marginal Effect on Conditional Predicted Prices")




margins, predict(ytrun) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot,  `margin_opts' `ytrun_opts'
graph export ${my_images}/postestimation/ytrun_qr_linear_P3.png, replace as(png) width(2000)



margins,dydx(quota_remaining_BOQ) predict(ytrun) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot,  `margin_opts' `ytrun_dydx_opts'
graph export ${my_images}/postestimation/ytrun_dydx_qr_linear_P3.png, replace as(png) width(2000)



margins, predict(ycen) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot, `margin_opts' `ycen_opts'
graph export ${my_images}/postestimation/ycen_qr_linear_P3.png, replace as(png) width(2000)



margins,dydx(quota_remaining_BOQ) predict(ycen) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot, `margin_opts' `ycen_dydx_opts'
graph export ${my_images}/postestimation/ycen_dydx_qr_linear_P3.png, replace as(png) width(2000)




/******************************************************************************/
/******************************************************************************/
/* exp_P1D model*/
/* plot the E[price|x,price>0] (YTRUN) as a function of quota_remaining  */
/* plot the E[price|x] (YCEN) as a function of quota_remaining  */
/******************************************************************************/
/******************************************************************************/

est restore exp_P1D


margins, predict(ytrun) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot, `margin_opts' `ytrun_opts'
graph export ${my_images}/postestimation/ytrun_qr_exp_P1D.png, replace as(png) width(2000)


margins,dydx(quota_remaining_BOQ) predict(ytrun) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot,  `margin_opts' `ytrun_dydx_opts'
graph export ${my_images}/postestimation/ytrun_dydx_qr_exp_P1D.png, replace as(png) width(2000)




margins, predict(ycen) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot, `margin_opts' `ycen_opts'
graph export ${my_images}/postestimation/ycen_qr_exp_P1D.png, replace as(png) width(2000)


margins,dydx(quota_remaining_BOQ) predict(ycen) at(quota_remaining_BOQ=(.2(.2)5))
marginsplot, `margin_opts' `ycen_dydx_opts'
graph export ${my_images}/postestimation/ycen_dydx_qr_exp_P1D.png, replace as(png) width(2000)




/* partial effects of live price */


/* options for all of these margins graphs and options for some of them */
local margin_opts  title("") xtitle("Live Price") xmtick(##4) xlabel( 0(1)4, labsize(small))  recast(line) recastci(rarea)
/* options for some of these margins graphs */


local ytrun_opts ylabel(0(1)4)  ytitle("Conditional Predicted Prices")
local ytrun_dydx_opts ylabel(0(.5)3) ytitle("Marginal Effect on Conditional Predicted Prices")


local ycen_opts ylabel(0(.5)2.5) ytitle("Unconditional Predicted Prices")
local ycen_dydx_opts ylabel(0(1)4) ytitle("Marginal Effect on Unconditional Predicted Prices") 


est restore linear_P3


margins, predict(ytrun) at(live_priceGDP=(.5(.1)3.5))
marginsplot,  `margin_opts' `ytrun_opts'
graph export ${my_images}/postestimation/ytrun_price_linear_P3.png, replace as(png) width(2000)



margins,dydx(live_priceGDP) predict(ytrun)  at(live_priceGDP=(.5(.1)3.5))
marginsplot,  `margin_opts' `ytrun_dydx_opts'
graph export ${my_images}/postestimation/ytrun_dydx_price_linear_P3.png, replace as(png) width(2000)



margins, predict(ycen) at(live_priceGDP=(.5(.1)3.5))
marginsplot, `margin_opts' `ycen_opts'
graph export ${my_images}/postestimation/ycen_price_linear_P3.png, replace as(png) width(2000)



margins,dydx(live_priceGDP) predict(ycen) at(live_priceGDP=(.5(.1)3.5))
marginsplot, `margin_opts' `ycen_dydx_opts'
graph export ${my_images}/postestimation/ycen_dydx_price_linear_P3.png, replace as(png) width(2000)


est restore exp_P1D


margins, predict(ytrun) at(live_priceGDP=(.5(.1)3.5))
marginsplot, `margin_opts' `ytrun_opts'
graph export ${my_images}/postestimation/ytrun_price_exp_P1D.png, replace as(png) width(2000)


margins,dydx(live_priceGDP) predict(ytrun) at(live_priceGDP=(.5(.1)3.5))
marginsplot,  `margin_opts' `ytrun_dydx_opts'
graph export ${my_images}/postestimation/ytrun_dydx_price_exp_P1D.png, replace as(png) width(2000)




margins, predict(ycen) at(live_priceGDP=(.5(.1)3.5))
marginsplot, `margin_opts' `ycen_opts'
graph export ${my_images}/postestimation/ycen_price_exp_P1D.png, replace as(png) width(2000)


margins,dydx(live_priceGDP) predict(ycen)at(live_priceGDP=(.5(.1)3.5))
marginsplot, `margin_opts' `ycen_dydx_opts'
graph export ${my_images}/postestimation/ycen_dydx_price_exp_P1D.png, replace as(png) width(2000)







log close

/* the partial effect of ACL on the Conditional mean ytrun is zero*/ 

/* the partial effect of ACL on the unonditional mean ycen really hard to compute.  Like incredibly hard. */ 
/*



est restore linear_P3
margins, dydx(*) predict(psel)
/* this is the partial effect of quota_remaining_BOQ on psel*/

margins, expression(normalden(xb(#1))*(_b[quota_remaining_BOQ] + recip_ACL*_b[c.quota_remaining_BOQ#c.recip_ACL]))

/* this is the partial effect of 1/ACL on psel*/
margins, expression(normalden(xb(#1))*(quota_remaining_BOQ*_b[c.quota_remaining_BOQ#c.recip_ACL]))

/* this is the partial effect of ACL on psel*/
margins, expression(normalden(xb(#1))*(quota_remaining_BOQ*_b[c.quota_remaining_BOQ#c.recip_ACL]*-1/(sectorACL^2)))
*/
