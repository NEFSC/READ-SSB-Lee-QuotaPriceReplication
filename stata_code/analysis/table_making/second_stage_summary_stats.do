/*this is a do file to a make some exploratory plots

You need to add an "if e(sample) type code. 

 */

cap log close

local mylogfile "${my_results}/second_stage_exploratory1.smcl" 
log using `mylogfile', replace


#delimit cr
version 15.1
clear all
spmatrix clear
global common_seed 06240628


local stock_concentration ${data_main}/quarterly_stock_concentration_index_${vintage_string}.dta
local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta
local stock_concentration_noex ${data_main}/quarterly_stock_concentration_index_no_ex_${vintage_string}.dta
local stock_disjoint ${data_main}/quarterly_stock_disjoint_index_${vintage_string}.dta

local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local spset_key2 "${data_main}/truncated_spset_id_keyfile_${vintage_string}.dta"
local spatial_lags ${data_main}/spatial_lags_${vintage_string}.dta
local spatial_lagsT ${data_main}/Tspatial_lags_${vintage_string}.dta

local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local  constraining ${data_main}/most_constraining_${vintage_string}.dta


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

gen lny=ln(badj_GDP)





/* for any estimation, you'll probably need to rescale the _PQR_index and _QR index by dividing by 100 again, they are on the range of 30-300 */

foreach var of varlist stock_PQR_Index stock_QR_Index stock_no_ex_PQR_Index stock_no_ex_QR_Index fishery_QR_Index fishery_PQR_Index {
    replace `var'=`var'/100
	
	
}





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

gen mark=1
replace mark=0 if stockcode==17 & fishing_year<=2011
replace mark=0 if fishing_year==2010 & q_fy<=2
drop if mark==0



label var dateq "Quarter"

label var fishing_year "Fishing Year"
label var b "Quota Price"
label var badj "Quota Price (nominal)"
label var quota_remaining_BOQ "Quota Remaining ('000mt)"
label var fraction_remaining_BOQ "Fraction Quota Remaining"
label var bpos "Positive Quota Price"
label var DDFUEL_R "Diesel Fuel Price (real)"
label var badj_GDP "Quota Price (real)"
label var live_priceGDP "Output Price, (live pounds real dollars)"
label var totaltargetcoveragelevel "Targeted Observer Coverage Rate"
label var proportion_observed "Fraction of Catch Observed (stock)"
label var realizedcoveragelevel "Fraction of Trips Observed (fishery)"




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


/* we need to format the prices and the lease_only dummy a little differently.  Can't exactly do it in one command, the best I can do is run the esttab twice and then copy/paste it in*/

local stats bpos badj_GDP live_priceGDP  quota_remaining_BOQ  fraction_remaining_BOQ proportion_observed realizedcoveragelevel   WTswt_quota_remaining_BOQ WTDswt_quota_remaining_BOQ Quarter1 Quarter2 Quarter3 Quarter4


/*********************************************/
/*********************************************/
/* TABULATE BY positive/zero */
/*********************************************/
/*********************************************/
cap drop count
egen count=total(mark)
label var count "Observations"





/*******************************************/
/*******************************************/
/*options for the statistics */
/*******************************************/
/*******************************************/
local estpost_opts_grand "statistics(mean sd) columns(statistics)"
local estab_opts_grand "cells("mean(fmt(%06.2fc)) sd(fmt(%06.2fc))") label replace nogaps nonumbers noobs alignment(rr)"



estpost tabstat `stats' count, `estpost_opts_grand'
esttab .,   `estab_opts_grand'
esttab . using ${my_tables}/second_stage_summary.tex, `estab_opts_grand'





/*********************************************/
/*********************************************/
/* TABULATE BY positive/zero */
/*********************************************/
/*********************************************/
cap drop count
bysort bpos : egen count=total(mark)
label var count "Observations"



/* by split by positive and zero */
local  estpost_opts_by "statistics(mean sd) columns(statistics) listwise"

local estab_opts_by "main(mean %04.2fc ) aux(sd %04.2fc) nostar noobs nonote label replace nogaps nonumbers unstack alignment(r) eqlabels("Quota Price=0" "Quota Price>0")"

local estab_opts_by_small "main(mean %03.2f) aux(sd %03.2f) nostar noobs nonote label replace nogaps nonumbers unstack alignment(r)"


local remove bpos
local stats2 : list stats - remove


estpost tabstat `stats2' count, by(bpos)  `estpost_opts_by'

/* look at it */	
esttab .,  `estab_opts_by' drop(Total:count)
esttab . using ${my_tables}/second_stage_split_appendix.tex, `estab_opts_by' drop(Total:count )


cap drop count
bysort bpos : egen count=total(mark)
label var count "Observations"

local r2 DDFUEL_R avg_hourly_wage_R
local stats3: list stats2 - r2


estpost tabstat `stats3' count, by(bpos)  `estpost_opts_by'

/* look at it */	
esttab .,  `estab_opts_by' drop(Total:count)
esttab . using ${my_tables}/second_stage_split0.tex, `estab_opts_by' drop(Total:count )






















pause
/*********************************************/
/*********************************************/
/* TABULATE BY QUARTER */
/*********************************************/
/*********************************************/
cap drop count
bysort q_fy : egen count=total(mark)
label var count "Observations"

 

local remove Quarter1 Quarter2 Quarter3 Quarter4
local stats2 : list stats - remove

local  estpost_opts_by "statistics(mean sd) columns(statistics) listwise"

local estab_opts_by "main(mean %04.2fc ) aux(sd %04.2fc) nostar nonote label replace nogaps nonumbers unstack alignment(r) eqlabels("Quarter 1" "Quarter 2" "Quarter 3" "Quarter 4")" 

local estab_opts_by_small "main(mean %03.2f) aux(sd %03.2f) nostar noobs nonote label replace nogaps nonumbers unstack alignment(r)"




estpost tabstat `stats2' count, by(q_fy)  `estpost_opts_by' 
/* look at it */	
esttab .,  `estab_opts_by' drop(Total:count)
esttab . using ${my_tables}/second_stage_split_qtr.tex, `estab_opts_by'  drop(Total:count )



/*********************************************/
/*********************************************/
/* TABULATE BY QUARTER and positive/zero */
/*********************************************/
/*********************************************/



cap drop count
bysort q_fy bpos: egen count=total(mark)
label var count "Observations"

/* by split by quarter, zeros only */
local  estpost_opts_by "statistics(mean sd) columns(statistics) listwise"

local estab_opts_by "main(mean %04.2fc ) aux(sd %04.2fc) nostar nonote label replace nogaps nonumbers unstack alignment(r) eqlabels("Quarter 1" "Quarter 2" "Quarter 3" "Quarter 4")" 

local estab_opts_by_small "main(mean %03.2f) aux(sd %03.2f) nostar noobs nonote label replace nogaps nonumbers unstack alignment(r)"


local remove bpos Quarter1 Quarter2 Quarter3 Quarter4
local stats2 : list stats - remove

estpost tabstat `stats2' count if bpos==0, by(q_fy)  `estpost_opts_by'

/* look at it */	
esttab .,  `estab_opts_by' drop(Total:count )
esttab . using ${my_tables}/second_stage_split_qtrb0.tex, `estab_opts_by' drop(Total:count )



/* by split by quarter */
local  estpost_opts_by "statistics(mean sd) columns(statistics) listwise"

local estab_opts_by "main(mean %04.2fc ) aux(sd %04.2fc) nostar nonote label replace nogaps nonumbers unstack alignment(r) eqlabels("Quarter 1" "Quarter 2" "Quarter 3" "Quarter 4")" 

local estab_opts_by_small "main(mean %03.2f) aux(sd %03.2f) nostar noobs nonote label replace nogaps nonumbers unstack alignment(r)"



estpost tabstat `stats2' count if bpos>0, by(q_fy)  `estpost_opts_by'

/* look at it */	
esttab .,  `estab_opts_by'
esttab . using ${my_tables}/second_stage_split_qtrbpos.tex, `estab_opts_by' drop(Total:count )





/* correlation table */
local estab_corr_opts not unstack compress noobs label nonumbers nostar nogaps


estpost corr `stats', matrix
esttab . , `estab_corr_opts'
esttab . using ${my_tables}/second_stage_corr_ALL.tex, `estab_corr_opts' replace alignment(r)

local remove bpos
local stats2 : list stats - remove


/*just the postive prices*/
estpost corr `stats2' if bpos==1, matrix

esttab . , `estab_corr_opts'
esttab . using ${my_tables}/second_stage_corr_bpos.tex, `estab_corr_opts' replace alignment(r)



/*just the zero prices*/

local remove badj_GDP
local stats2 : list stats2 - remove

/*just the postive prices*/
estpost corr `stats2' if bpos==0, matrix

esttab . , `estab_corr_opts'
esttab . using ${my_tables}/second_stage_corr_bzero.tex, `estab_corr_opts' replace alignment(r)



log close
