/*this is a do file to a make some exploratory plots

You need to add an "if e(sample) type code. 

 */

cap log close

local mylogfile "${my_results}/second_stage_appendix.smcl" 
log using `mylogfile', replace


#delimit cr
version 15.1
pause off
clear all
spmatrix clear
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

local final_results ${my_results}/coverage_results${vintage_string}.ster

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



/* readin the previous churdle results */




label var dateq "Quarter"

label var fishing_year "Fishing Year"
label var b "Quota Price"
label var badj "Quota Price (nominal)"
label var quota_remaining_BOQ "Quota Remaining"
label var fraction_remaining_BOQ "Proportion of Quota Remaining"
label var bpos "Positive Quota Price"
label var DDFUEL_R "Diesel Fuel Price (real)"
label var badj_GDP "Quota Price (real)"
label var live_priceGDP "Output Price, (live pounds real)"

label var fraction_remaining_BOQ "Proportion of Quota Remaining"
label var proportion_observed "Fraction of Catch Observed"
label var realizedcoveragelevel "Fraction of Trips Observed"

label var totaltargetcoveragelevel "Targed Observer Coverage Rate"


label var stock_QR_Index "Quota Remaining Simple Index"
label var stock_shannon_Q "Quota Remaining Shannon Index"
label var stock_HHI_Q "Quota Remaining HHI"
label var avg_hourly_wage_R "Hourly Wage (real)"

label var WTswt_quota_remaining_BOQ "Spatial Lag (ID) of Quota Remaining"
label var WTDswt_quota_remaining_BOQ "Spatial Lag (D) of Quota Remaining"


label var WTswt_otherR "Spatial Lag (ID) of Quota Remaining*output price"
label var WTDswt_otherR "Spatial Lag of Quota (D) Remaining*output price"


gen Quarter1=q_fy==1
gen Quarter2=q_fy==2
gen Quarter3=q_fy==3
gen Quarter4=q_fy==4


label var Quarter1 "Quarter 1" 
label var Quarter2 "Quarter 2" 
label var Quarter3 "Quarter 3" 
label var Quarter4 "Quarter 4" 



/* load in linear hurdle */
qui est describe using `final_results'

local numest=r(nestresults)
forvalues est=1(1)`numest'{
	est desc using `final_results', number(`est')
	local newtitle=r(title)
	est use `final_results', number(`est')
	est store `newtitle'
}

/* Linear models */
/* locals to control options of the entire table */
local estout_opts nobaselevels cells(b (star fmt(3)) se(par fmt(2)))  starlevels(* 0.10 ** 0.05 *** 0.01) wrap substitute(_cons Constant _ \_ aic AIC bic BIC r2 R$^2$ ll Log-Likelihood)   
/* locals to add statistics and format */
local stats stats(r2 aic bic  N  ll k, fmt(%04.3f %5.1fc  %7.1fc %3.0f %6.1fc %2.0f))

/* locals to rename variables and "match" across specifications */
local frac_rename selection:c.quota_remaining_BOQ#c.recip_ACL FractionQuotaRemaining badj_GDP:c.quota_remaining_BOQ#c.recip_ACL FractionQuotaRemaining 
local spatial_lags_rename  badj_GDP:WTrev_quota_remaining_BOQ WTswt_quota_remaining_BOQ  badj_GDP:WTDrev_quota_remaining_BOQ WTDswt_quota_remaining_BOQ
local price_rename  badj_GDP:lag1Q_live_priceGDP live_priceGDP
local rename rename(`frac_rename' `spatial_lags_rename' `price_rename') 


/* locals to control order */
local reorder order(live_priceGDP  quota_remaining_BOQ proportion_observed  WTDswt_quota_remaining_BOQ  WTswt_quota_remaining_BOQ) 

/* locals to tidy up  */
local label_opts label varlabels(_Iq_fy_2 "Quarter 2" _Iq_fy_3 "Quarter 3" _Iq_fy_4 "Quarter 4") collabels(none) mlabels ("L1" "L2" "L3" "L4" "L5")

/* make the table */
estout linear_P3 linear_P3rev  linear_P3NS linear_P3proxy linear_P0, `rename' `reorder' `estout_opts' `stats' `label_opts'  

esttab  linear_P3 linear_P3rev  linear_P3NS linear_P3proxy linear_P0 using ${my_tables}\appendix_linear.tex, replace `rename' `reorder' `estout_opts' `stats' `label_opts'  noobs nonumbers  alignment(r)



/* Exponential Models */

/* locals to rename variables and "match" across specifications */
local frac_rename selection:c.quota_remaining_BOQ#c.recip_ACL FractionQuotaRemaining lnbadj_GDP:c.quota_remaining_BOQ#c.recip_ACL FractionQuotaRemaining 
local spatial_lags_rename  lnbadj_GDP:WTrev_quota_remaining_BOQ WTswt_quota_remaining_BOQ  lnbadj_GDP:WTDrev_quota_remaining_BOQ WTDswt_quota_remaining_BOQ
local price_rename  lnbadj_GDP:lag1Q_live_priceGDP live_priceGDP
local rename rename(`frac_rename' `spatial_lags_rename' `price_rename') 
/* locals to tidy up  */
local label_opts label varlabels(_Iq_fy_2 "Quarter 2" _Iq_fy_3 "Quarter 3" _Iq_fy_4 "Quarter 4") collabels(none) mlabels ("E1" "E2" "E3" "E4" "E5")

estout exp_P1D exp_P1rev exp_P1NS exp_P1Dproxy exp_P0, `rename' `reorder' `estout_opts' `stats' `label_opts'  
esttab  exp_P1D exp_P1rev exp_P1NS exp_P1Dproxy exp_P0 using ${my_tables}\appendix_exponential.tex, replace `rename' `reorder' `estout_opts' `stats' `label_opts'  noobs nonumbers  alignment(r)

log close
