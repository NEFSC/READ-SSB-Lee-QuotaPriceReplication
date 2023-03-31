/*This constructs one index per year for quota and quota availability.
Shannon, HHI
Price-, Quota-price, and unweighted index

NOTE, although I coded up a quota-price weighted index, putting this on the RHS is quite endogenous.

*/


version 15.1
#delimit cr
local quota_data ${data_main}/monthly_quota_available_${vintage_string}.dta
local output_price_data ${data_main}/dmis_output_species_prices_${vintage_string}.dta
local quota_price_data ${data_intermediate}/annual_quota_prices_${vintage_string}.dta

local outfile ${data_intermediate}/fishery_level_monthly_quota_available_indices_${vintage_string}.dta


cap mkdir ${exploratory}/single_index
global single_index ${exploratory}/single_index














/********************************************/
/* output-prices  */
/********************************************/
use `output_price_data', clear
drop if stockcode>=100
drop if fishing_year>=2020
keep fishing_year stockcode stock_id trip_monthly_date dealer_live_price
tempfile output_prices
save `output_prices', replace


use `quota_data', replace


/* drop the un-allocated stocks */
drop if stockcode>=100
/* we need to drop snema winter from any quota index prior to 2012 because it didn't have quota */
drop if fishing_year<2012 & stockcode==17


/* one index of quota availability */
merge 1:1 fishing_year stockcode trip_monthly_date using `output_prices'
drop if fishing_year<=2009
drop if fishing_year>=2020
drop if fishing_year<2012 & stockcode==17

assert _merge==3


replace quota_remaining_BOM=0 if quota_remaining_BOM==.

/* no quotas for SNEMA Winter before 2013*/
gen val=dealer_live_price*quota_remaining_BOM
replace val=0 if val==.

bysort trip_monthly_date fishing_year: egen tv=total(val)
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
bysort trip_monthly_date: egen tqb=total(quota_remaining_BOM)
gen share=quota_remaining_BOM/tqb
gen lns=ln(share)
drop tqb




gen shannon_Q=-1*share*lns
/* HHI*/
gen HHI_Q=share^2

bysort trip_monthly_date: gen N=_N
gen shannon_max=ln(N)

collapse (sum) shannon_Q HHI_Q  shannon_PQ HHI_PQ quota_remaining_BOM val (first) shannon_max, by(trip_monthly_date fishing_year)
gen month=month(dofm(trip_month))
gen fy_month=month-4
replace fy_month=fy_month+12 if fy<=0
tsset fishing_year fy_month
gen Nshannon_Q=shannon_Q/shannon_max
gen Nshannon_PQ=shannon_PQ/shannon_max

/*rescale */

replace quota_remaining_BOM=quota_remaining_BOM/1000000
replace val=val/1000000
rename quota_remaining_BOM QR_Index
rename val PQR_Index

foreach var of varlist  shannon_Q HHI_Q shannon_PQ HHI_PQ QR_Index PQR_Index Nshannon_Q Nshannon_PQ{
    rename `var' fishery_`var'
}


save `outfile', replace

