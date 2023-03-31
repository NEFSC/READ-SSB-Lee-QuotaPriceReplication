/*this is a do file to a make some exploratory plots */

cap log close

local mylogfile "${my_results}/second_stage_exploratory1.smcl" 
log using `mylogfile', replace


#delimit cr
version 15.1
set scheme s2mono

pause on
clear all
spmatrix clear
global common_seed 06240628
cap log close
local stock_concentration ${data_main}/quarterly_stock_concentration_index_${vintage_string}.dta


local stock_concentration_noex ${data_main}/quarterly_stock_concentration_index_no_ex_${vintage_string}.dta

local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta

local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local  constraining ${data_main}/most_constraining_${vintage_string}.dta


/* read in the spmatrices previously created */
do "${processing_code}/K_spatial/K09_readin_stswm.do"


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
merge 1:1 stockcode dateq using `spset_key'
tab _merge
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


/* merge in quarterly "fishery available indices" this is a m:1 merge */

merge m:1 quarterly using `fishery_concentration'
drop if _merge==2
assert _merge==3
drop _merge

/* roll back to dateq */
rename  quarterly dateq


gen badj_GDP=badj/fGDP
gen ihs_badj_GDP=asinh(badj_GDP)

gen del=live_priceGDP-badj_GDP
gen ihs_del=asinh(del)



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



spgenerate Wrev_livep=Wi2S_rev*live_priceGDP
spgenerate Wswt_livep=Wi2S_swt*live_priceGDP
spgenerate Wrev_ihs_livep=Wi2S_rev*ihs_live_priceGDP
spgenerate Wswt_ihs_livep=Wi2S_swt*ihs_live_priceGDP
spgenerate Wrev_ln_quota_remaining_BOQ=Wi2S_rev*ln_quota_remaining_BOQ
spgenerate Wswt_ln_quota_remaining_BOQ=Wi2S_swt*ln_quota_remaining_BOQ
spgenerate Wrev_ihs_quota_remaining_BOQ=Wi2S_rev*ihs_quota_remaining_BOQ
spgenerate Wswt_ihs_quota_remaining_BOQ=Wi2S_swt*ihs_quota_remaining_BOQ

spgenerate Wrev_ihs_L1quota_remaining_BOQ=Wi2S_rev*lag1Q_ihs_quota_remaining_EOQ
spgenerate Wswt_ihs_L4quota_remaining_BOQ=Wi2S_swt*lag4Q_ihs_quota_remaining_EOQ

 
spgenerate Wswt_ihs_L1_livep=WiiS_swt*lag1Q_ihs_live_priceGDP
spgenerate Wswt_ihs_L4_livep=WiiS_swt*lag4Q_ihs_live_priceGDP

spgenerate Wrev_ihs_L1_livep=WiiS_rev*lag1Q_ihs_live_priceGDP 
spgenerate Wrev_ihs_L4_livep=WiiS_rev*lag4Q_ihs_live_priceGDP 


spgenerate Wrev_quota_remaining_BOQ=Wi2S_rev*quota_remaining_BOQ
spgenerate Wswt_quota_remaining_BOQ=Wi2S_swt*quota_remaining_BOQ

spgenerate Wrev_otherR=Wi2S_rev*otherR
spgenerate Wswt_otherR=Wi2S_swt*otherR

spgenerate Wrev_ihs_otherR=Wi2S_rev*ihs_otherR
spgenerate Wswt_ihs_otherR=Wi2S_swt*ihs_otherR

spgenerate Wrev_badj=Wi2S_rev*badj_GDP
spgenerate Wswt_badj=Wi2S_swt*badj_GDP




/* classify as nearshore 25nm, intermediate 25-75nm, and far over 75nm from land. This gives us 4 stocks in the nearshore, 8 in the intermediate, and 4 that are offshore).  
This is intended to help me capture cost differences - fuel is related to cost, but so is distance*/
gen stock_distance_type=0
replace stock_distance_type=1 if inlist(stockcode,5,9,11,12,13,15,16,17)
replace stock_distance_type=2 if inlist(stockcode,2,4,6,7)
label define stock_dist 0 "nearshore" 1 "intermediate" 2 "far" 
label values stock_distance_type stock_dist



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

gen lny=ln(badj_GDP)


/* variables to look at

badj_GDP
quota_remaining_BOQ

recip_ACL
lag1Q_quota_remaining_BOQ
lag4Q_quota_remaining_BOQ

live_priceGDP
i.stock_distance_type#c.DDFUEL_R
Wswt_quota_remaining_BOQ
proportion_observed 
 
 
ln_live_priceGDP

 
 
 */

/* second stages */


/* Diversity /concentration indices */
/*the no_ex indices don't vary across all of the stocks.  They will only be different for stocks that have different boundaries.   */
/* unit stocks, GBE, GBW, GOM */
xtsum  stock_no_ex_shannon_PQ stock_no_ex_shannon_Q  stock_no_ex_HHI_Q stock_no_ex_HHI_PQ if inlist(stockcode,11, 12, 13,15,16)
xtsum  stock_no_ex_shannon_PQ stock_no_ex_shannon_Q  stock_no_ex_HHI_Q stock_no_ex_HHI_PQ if inlist(stockcode,2,4)
xtsum  stock_no_ex_shannon_PQ stock_no_ex_shannon_Q  stock_no_ex_HHI_Q stock_no_ex_HHI_PQ if inlist(stockcode,3,5)
xtsum  stock_no_ex_shannon_PQ stock_no_ex_shannon_Q  stock_no_ex_HHI_Q stock_no_ex_HHI_PQ if inlist(stockcode,8,9,10)

summ stock_* fishery_*





/* for any estimation, you'll probably need to rescale the _PQR_index and _QR index by dividing by 100 again, they are on the range of 30-300 */

foreach var of varlist stock_PQR_Index stock_QR_Index stock_no_ex_PQR_Index stock_no_ex_QR_Index fishery_QR_Index fishery_PQR_Index {
    replace `var'=`var'/100
	
	
}


/* then shannon and HHI are highly inversely correlated */
scatter stock_shannon_Q stock_HHI_Q
corr stock_shannon_Q stock_HHI_Q
xtline stock_shannon_Q stock_HHI_Q

/* the P-weighted shannon and HHI are not */
corr stock_HHI_Q stock_HHI_PQ stock_shannon_Q stock_shannon_PQ


/*

HHI: compute the shares for each stock. Square and sum.
HHI= 1/N is the minimum, if every stock has the same amount.  
HHI= 1 maximum unevenness (concentration)

Shannon: compute shares for each stock. Multiply by the natural log. Sum and take the negative.
Shannon 0 is maximum unevenness (minimum diversity)
Shannon: ln(1/N) is the minimum unevenness (maximum diversity)
*/

/* the QR index quite unrelated to the HHI and shannon: abs(corr) is less than 0.10 */
corr stock_HHI_Q stock_shannon_Q stock_QR_Index

/* 
If there is lots of other quota remaining, I expect this to increase prices.
*/

/* using the output-price weighted indices adds in a bunch of correlation */

/* the correlation is much higher if we use the fishery level index */
corr fishery_HHI_Q fishery_shannon_Q fishery_QR_Index if stockcode==2


corr stock_HHI_Q stock_HHI_PQ 
corr stock_shannon_Q stock_shannon_PQ

corr stock_HHI_Q  stock_shannon_PQ


/* include 
fishery_QR_Index stock_HHI_Q

order

fishery_QR_Index fishery_shannon_Q
*/



cap log close
