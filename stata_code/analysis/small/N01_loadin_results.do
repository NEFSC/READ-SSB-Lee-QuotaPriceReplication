
	
/*
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

local mylogfile "${my_results}/N01A_churdle_readin.smcl" 
log using `mylogfile', replace

#delimit cr
version 15.1
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


xi _Iq*


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

local numest=r(nestresults)
forvalues est=1(1)`numest'{
	est use `linear_hurdle', number(`est')
	est store linear`est'
}


/* load in logged RHS hurdle */
qui est describe using `log_indep_hurdle'
local numest=r(nestresults)

forvalues est=1(1)`numest'{
	est use `log_indep_hurdle', number(`est')
	est store log_indep`est'
}


/* load in spatial_hurdle hurdle */
qui est describe using `spatial_hurdle'
local numest=r(nestresults)

forvalues est=1(1)`numest'{
	est use `spatial_hurdle', number(`est')
	est store spatial_`est'
}



/* load in exp hurdle hurdle */
qui est describe using `exponential_hurdle'
local numest=r(nestresults)

forvalues est=1(1)`numest'{
	est use `exponential_hurdle', number(`est')
	est store exp_`est'
}



/* load in exp hurdle hurdle */
qui est describe using `exponential_spatial_hurdle'
local numest=r(nestresults)

forvalues est=1(1)`numest'{
	est use `exponential_spatial_hurdle', number(`est')
	est store exp_spatial_`est'
}


est table linear*, star(0.10 .05 .01 ) stats(N r2)


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
est table linear1 linear2, star(0.10 .05 .01 )

/* linear 1 vs linear 2: */

est restore linear1
/* We fail to reject exogeneity of P and QR (.56) in the linear model in both equations */
test [badj_GDP]pres4, notest
test [badj_GDP]qrresid4, accum notest
test [selection]qrresid4, accum 


/* We fail to reject the null of  the stockdistance*Fuel price =0 linear model in both equations */

est restore linear2
test [badj_GDP]0b.stock_distance_type#c.DDFUEL_R,  notest
test [badj_GDP]1.stock_distance_type#c.DDFUEL_R,  accum notest
test [badj_GDP]2.stock_distance_type#c.DDFUEL_R,  accum 




/* THIS IS THE PREFERRED LINEAR MODEL */
/* of the linear specifications, this is our preferred one -- the shannon does not seem to affect quota prices */
est restore linear6
/* THIS IS THE PREFERRED LINEAR MODEL */





/* we also estimated linear5, which is linear 6, but without exog assumed. We again fail to reject exogeneity of P and QR */


/* 
Linear model :   (Linear Hurdle Exogenous Q and P Parsim)


*/















/* linear-log models */
est table log_indep*, star(0.10 .05 .01 ) stats(N r2)
/* different exog story
QR may not be exog to the selection equation
	*/


	
est restore log_indep3
/* remove the fuel price RHS vars */

/* this is probably the best specification too 

The coefficient on ln_live_priceGDP feels too large	 -- need to compute the elasticities on this*/
/* THIS IS THE PREFERRED LINEAR -Log MODEL */
est restore log_indep4

/* of the log on the RHS specifications, this is our preferred one -- the shannon does not seem to affect quota prices */
/* THIS IS THE LINEAR -Log MODEL */




est table exp_? exp_??, star(0.10 .05 .01 ) stats(N r2)

/* in the exponential form, we FTR exogeneity */
estimates restore exp_1
est replay
test [lnbadj_GDP]pres4, notest
test [lnbadj_GDP]qrresid4, accum notest
test [selection]qrresid4, accum 

est table exp_1 exp_2 exp_3 exp_4 exp_5 exp_6 exp_7, star(.1 .05 .01)


estimates restore exp_2
est replay
test [lnbadj_GDP]0b.stock_distance_type#c.DDFUEL_R,  notest
test [lnbadj_GDP]1.stock_distance_type#c.DDFUEL_R,  accum notest
test [lnbadj_GDP]2.stock_distance_type#c.DDFUEL_R,  accum

est restore exp_5
/* THIS IS THE Log-linear MODEL */
/* jointly, I get a p-value of .12 */
test [lnbadj_GDP]qrresid4, notest
test [lnbadj_GDP]pres4, accum 



/* PREFERRED 
exponential model:   (Exponential Hurdle Exogenous Q and P Testing down 2)
 
	

*/


est restore exp_6
est replay





/* of the log on the RHS specifications, this is our preferred one -- the shannon does not seem to affect quota prices */

est table log_indep*, star(.1 .05 .01)
est restore log_indep4

/* PREFERRED 
Linear-log  model :   (Linear-log Hurdle Exogenous P Q, testing down)
 
	

*/


/* LOG-LOG models */

est table exp_8 exp_9 exp_1?, star(0.10 .05 .01 )
/* Exog: we find evidence for endogenous QR in the price level equation
We find evidence for exog price in the level equation and exog QR in the participation equation 
This eliminates models 8, 9 ,10,11,12,13,15,17, 19
Models 14 16 and 18 are reasonable
 */

/* 
Log-log  model : 

results are a little funky -- increase in fuel prices increase the price of quota.This suggests that fuel and quota are substitutes.   (Linear-log Hurdle Exogenous P Q, testing down)
 
*/
 
 /* 3 reasonable models 
 all say the same things about the more important variables*/
 est table exp_14 exp_16 exp_18, star(0.10 .05 .01 )
 
 /* done review to here */
 
 
est table spatial_*, star(0.10 .05 .01 ) stats(N r2)
/* first, we get pretty consistent findings that QR and livep are exog, so we can focus on the exog models */
est table spatial_2 spatial_4 spatial_6 spatial_8 spatial_12 spatial_13 spatial_14 spatial_15 spatial_16 spatial_17, star(0.10 .05 .01 )

/* pretty good evidence that we don't want fraction remaining in the level equations or fuel prices*/
/* at least for the levels-levels, we find that the spatial lag doesn't matter.  And spatial 6, reduces to a non-spatial version
*/


est table  spatial_6 spatial_8 spatial_12 spatial_15 spatial_16 spatial_17, star(0.10 .05 .01 )

/* 12 and 16 and 15*17 are accidentally the same  But the are only the same because on was bootstrapped (and nothing changes) .*/

est restore spatial_15


/* preferred spatial */
est table  spatial_15 , star(0.10 .05 .01 )





/* exponential spatial hurdle */
est table exp_spatial_1*, star(0.10 .05 .01 ) stats(N r2)




 est table exp_spatial_1 exp_spatial_2 exp_spatial_3 exp_spatial_4 , star(0.10 .05 .01 )

 /* 3 and 5 okay*/

 
 /* model 8 is best. model 10 is the same
 
 need to look at these again.
 */
 
 est table exp_spatial_1  exp_spatial_3  exp_spatial_7 exp_spatial_8 exp_spatial_9 exp_spatial_10, star(0.10 .05 .01 )

 
 /* with the revenues spatial weights matrix, model 12 is best. Model 14 is the same as 12. */
 
  est table exp_spatial_5  exp_spatial_6  exp_spatial_11 exp_spatial_12 exp_spatial_13 exp_spatial_14, star(0.10 .05 .01 )

  
  






/*HERE ARE My preferred models */





/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION A:
Levels on the right and left sides
est save `linear_hurdle', `saver'

*/
/*************************************************************************************/
/*************************************************************************************/
est restore linear6






/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION B:
*/
/*************************************************************************************/
/*************************************************************************************/

est restore log_indep4



/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION C:
 Estimate the model with depvars in levels, with the spatial lags 
 `spatial_hurdle',

SECTION D:
 Estimate the model with depvars in levels, with the spatial lags in logs
`spatial_hurdle'
*/
/*************************************************************************************/
/*************************************************************************************/
est table spatial_13 spatial_15 , star(0.10 .05 .01 )



/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION E:
"exponential" -- log y on the right sides
`exponential_hurdle'
SECTION F:
 Estimate the model with depvars in logs  and log y on the LHS
`exponential_hurdle'

/*************************************************************************************/
******************************/


 est table exp_14 exp_16 exp_18, star(0.10 .05 .01 )

*******************************************************/





/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION G:
 Estimate the exponential model with indevars in levels, with the spatial lags 
`exponential_spatial_hurdle'
*/
/*************************************************************************************/
/*************************************************************************************/
 
  /* PREFERRED */
  est table exp_spatial_8 exp_spatial_12 , star(0.10 .05 .01 )

 
 
/*************************************************************************************/
/*************************************************************************************/
/* 
SECTION H:
 Estimate the exponential model with indepvars in logs, with the spatial lags in logs

*/
/*************************************************************************************/
/*************************************************************************************/


label var quota_remaining_BOQ "Quota Remaining 000mt"

label var live_priceGDP "Live Price"
label var ln_live_priceGDP "Log Live Price"
label var ln_quota_remaining_BOQ "Log Quota Remaining 000mt"
label var ln_fraction_remaining_BOQ "Log Fraction Quota Remaining"
label var stock_QR_Index "Quota Remaining Index"
label var lnfp "Log Fuel Price"
label var ln_stock_QR_Index "Log Quota Remaining Index"


/* outptu the linear and linear-log to a table */

local estout_tex_options  style(tex) cells(b(star fmt(%9.3f)) se(par))   stats(N r2 ll aic bic, fmt(%9.0g %9.3f %6.1g %5.0f %6.0f) labels("N" "R-squared" "ln(L)" "AIC" "BIC")) legend label collabels(none) substitute(_ \_) varlabels(_cons Constant) replace  nobaselevels



estout linear6 log_indep4 spatial_15 using ${my_tables}/second_stage_lin.tex, `estout_tex_options' mlabels("Linear" "Linear-Log" "Spatial1" "Spatial2", titles) 





estout exp_14 exp_16 exp_18 exp_spatial_8 exp_spatial_12 using ${my_tables}/second_stage_exp.tex, `estout_tex_options' mlabels("Exp1" "Exp2" "Exp3" "Exp Spatial1" "Exp Spatial2", titles) 






/* 
estimate simpler models

1. quarter*quota_remaining
2. quarter*fraction_remaining

3. live_price in the participation 


Looking at the log-likelihoods, AIC, BIC, it looks like there are 3 "best" models


linear6 
exp_spatial8 
exp_spatial_12 

but 8 10 12 14 are all really simiar.


and maybe  exp_16, but this is tricky to think about because this is an endogenous model

exp_spatial 15-18 are a good bt worse, according to lnL, AIC and BIC.
 */
 
 
log close
