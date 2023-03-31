
	
/*
construct spatial lags
*/
cap log close

local mylogfile "${my_results}/create_T_spatial_lags.smcl" 
log using `mylogfile', replace

#delimit cr
version 15.1
pause on
clear all
spmatrix clear
est  drop _all



local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local spset_key2 "${data_main}/truncated_spset_id_keyfile_${vintage_string}.dta"

local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local constraining ${data_main}/most_constraining_${vintage_string}.dta

local outfile ${data_main}/Tspatial_lags_${vintage_string}.dta




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

merge 1:1 stockcode dateq using `spset_key2'
drop if stockcode==17 & fishing_year<2012
assert _merge==3
bysort _ID: assert _n==1
drop _merge




gen badj_GDP=badj/fGDP
/* cast missing to zero */
replace badj_GDP=0 if badj_GDP==.

gen ihs_badj_GDP=asinh(badj_GDP)

gen del=live_priceGDP-badj_GDP
gen ihs_del=asinh(del)



/* construct a variable representing the revenue from the other */
gen otherR=live_priceGDP*quota_remaining_BOQ
gen ihs_otherR=asinh(otherR)
gen ln_otherR=ln(otherR)




/* construct some traditional spatial lags, where RHS variables are inverse distance, inverse squared distance weighted so that 'close' stocks can affect each other  

I need to use these ones 

*/

/* Before you do anything, you should normalize properly */







spgenerate WTrev_livep=WiiJ_rev*live_priceGDP
spgenerate WTswt_livep=WiiJ_swt*live_priceGDP

spgenerate WTrev_ln_livep=WiiJ_rev*ln_live_priceGDP
spgenerate WTswt_ln_livep=WiiJ_swt*ln_live_priceGDP


spgenerate WTrev_ihs_livep=WiiJ_rev*ihs_live_priceGDP
spgenerate WTswt_ihs_livep=WiiJ_swt*ihs_live_priceGDP
spgenerate WTrev_ln_quota_remaining_BOQ=WiiJ_rev*ln_quota_remaining_BOQ
spgenerate WTswt_ln_quota_remaining_BOQ=WiiJ_swt*ln_quota_remaining_BOQ
spgenerate WTrev_ihs_quota_remaining_BOQ=WiiJ_rev*ihs_quota_remaining_BOQ
spgenerate WTswt_ihs_quota_remaining_BOQ=WiiJ_swt*ihs_quota_remaining_BOQ

spgenerate WTrev_ihs_L1quota_remaining_BOQ=WiiJ_rev*lag1Q_ihs_quota_remaining_EOQ
spgenerate WTswt_ihs_L4quota_remaining_BOQ=WiiJ_swt*lag4Q_ihs_quota_remaining_EOQ





/* quota used and transforms */
spgenerate WTrev_cumul_quota_use_BOQ=WiiJ_rev*cumul_quota_use_BOQ
spgenerate WTswt_cumul_quota_use_BOQ=WiiJ_swt*cumul_quota_use_BOQ

spgenerate WTrev_ln_cumul_quota_use_BOQ=WiiJ_rev*ln_quota_remaining_BOQ
spgenerate WTswt_ln_cumul_quota_use_BOQ=WiiJ_swt*ln_quota_remaining_BOQ
spgenerate WTrev_ihs_cumul_quota_use_BOQ=WiiJ_rev*ihs_quota_remaining_BOQ
spgenerate WTswt_ihs_cumul_quota_use_BOQ=WiiJ_swt*ihs_quota_remaining_BOQ

spgenerate WTrev_ihs_L1cumul_quota_use_BOQ=WiiJ_rev*lag1Q_ihs_cumul_quota_use_BOQ
spgenerate WTswt_ihs_L4cumul_quota_use_BOQ=WiiJ_swt*lag4Q_ihs_cumul_quota_use_BOQ







 
spgenerate WTswt_ihs_L1_livep=WiiJ_swt*lag1Q_ihs_live_priceGDP
spgenerate WTswt_ihs_L4_livep=WiiJ_swt*lag4Q_ihs_live_priceGDP

spgenerate WTrev_ihs_L1_livep=WiiJ_rev*lag1Q_ihs_live_priceGDP 
spgenerate WTrev_ihs_L4_livep=WiiJ_rev*lag4Q_ihs_live_priceGDP 


spgenerate WTrev_quota_remaining_BOQ=WiiJ_rev*quota_remaining_BOQ
spgenerate WTswt_quota_remaining_BOQ=WiiJ_swt*quota_remaining_BOQ

spgenerate WTrev_otherR=WiiJ_rev*otherR
spgenerate WTswt_otherR=WiiJ_swt*otherR

spgenerate WTrev_ihs_otherR=WiiJ_rev*ihs_otherR
spgenerate WTswt_ihs_otherR=WiiJ_swt*ihs_otherR


spgenerate WTrev_ln_otherR=WiiJ_rev*ln_otherR
spgenerate WTswt_ln_otherR=WiiJ_swt*ln_otherR


spgenerate WTrev_badj=WiiJ_rev*badj_GDP
spgenerate WTswt_badj=WiiJ_swt*badj_GDP




/* construct some disjoint measures */
spgenerate WTDrev_quota_remaining_BOQ=W00J_rev*quota_remaining_BOQ
spgenerate WTDswt_quota_remaining_BOQ=W00J_swt*quota_remaining_BOQ

spgenerate WTDrev_cumul_quota_use_BOQ=W00J_rev*cumul_quota_use_BOQ
spgenerate WTDswt_cumul_quota_use_BOQ=W00J_swt*cumul_quota_use_BOQ




spgenerate WTDrev_ln_QR_OQ=W00J_rev*ln_quota_remaining_BOQ
spgenerate WTDswt_ln_QR_BOQ=W00J_swt*ln_quota_remaining_BOQ

spgenerate WTDrev_otherR=W00J_rev*otherR
spgenerate WTDswt_otherR=W00J_swt*otherR

spgenerate WTDrev_ihs_otherR=W00J_rev*ihs_otherR
spgenerate WTDswt_ihs_otherR=W00J_swt*ihs_otherR


spgenerate WTDrev_ln_otherR=W00J_rev*ln_otherR
spgenerate WTDswt_ln_otherR=W00J_swt*ln_otherR


spgenerate WTDrev_badj=W00J_rev*badj_GDP
spgenerate WTDswt_badj=W00J_swt*badj_GDP


keep fishing_year dateq stockcode WT*



save `outfile', replace




log close
