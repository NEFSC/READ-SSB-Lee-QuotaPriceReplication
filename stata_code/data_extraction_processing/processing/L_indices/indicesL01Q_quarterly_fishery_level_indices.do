/*This constructs one index per year for quota and quota availability.
Shannon, HHI
Price-, Quota-price, and unweighted index

NOTE, although I coded up a quota-price weighted index, putting this on the RHS is quite endogenous.

*/


version 15.1
#delimit cr
local quota_data ${data_main}/quarterly_quota_available_$vintage_string.dta
local output_price_data ${data_main}/dmis_output_stock_quarterly_prices_${vintage_string}.dta
local quota_price_data ${data_intermediate}/annual_quota_prices_${vintage_string}.dta


local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta


cap mkdir ${exploratory}/single_index
global single_index ${exploratory}/single_index




/********************************************/
/* output-price weighted */
/********************************************/
use `output_price_data', clear
drop if stockcode>=100
drop if fishing_year>=2020
keep fishing_year stockcode stock_id quarterly dealer_live_price
tempfile output_prices
save `output_prices', replace


use `quota_data', replace

/* drop the un-allocated stocks */
drop if stockcode>=100
/* we need to drop snema winter from any quota index prior to 2012 because it didn't have quota */
drop if fishing_year<2012 & stockcode==17

/* one index of quota availability */
merge 1:1 fishing_year stockcode quarterly using `output_prices'
drop if fishing_year<=2009
drop if fishing_year>=2020
drop if fishing_year<2012 & stockcode==17

assert _merge==3

replace quota_remaining_BOQ=0 if quota_remaining_BOQ==.



gen val=dealer_live_price*quota_remaining_BOQ
replace val=0 if val==.

bysort quarterly fishing_year: egen tv=total(val)
gen sharePQ=val/tv
gen lnsPQ=ln(sharePQ)
replace lnsPQ=0 if lnsPQ==.



/*Shannon */
gen shannon_PQ=-1*sharePQ*lnsPQ
/* HHI*/
gen HHI_PQ=sharePQ^2

drop sharePQ
drop lnsPQ





/********************************************/
/* unweighted index of quota availability */
/********************************************/
bysort quarterly: egen tqb=total(quota_remaining_BOQ)
gen share=quota_remaining_BOQ/tqb
gen lns=ln(share)
drop tqb




gen shannon_Q=-1*share*lns
/* HHI*/
gen HHI_Q=share^2

bysort quarterly: gen N=_N
gen shannon_max=ln(N)
collapse (sum) shannon_Q HHI_Q  shannon_PQ HHI_PQ quota_remaining_BOQ val (first) shannon_max, by(quarterly fishing_year)
gen q_of_fy=quarter(dofq(quarterly))
gen Nshannon_Q=shannon_Q/shannon_max
gen Nshannon_PQ=shannon_PQ/shannon_max

tsset fishing_year q_of_fy

/*rescale */

replace quota_remaining_BOQ=quota_remaining_BOQ/1000000
replace val=val/1000000

rename quota_remaining_BOQ QR_Index
rename val PQR_Index

foreach var of varlist  shannon_Q HHI_Q shannon_PQ HHI_PQ QR_Index PQR_Index Nshannon_Q Nshannon_PQ{
    rename `var' fishery_`var'
}


save `fishery_concentration', replace









