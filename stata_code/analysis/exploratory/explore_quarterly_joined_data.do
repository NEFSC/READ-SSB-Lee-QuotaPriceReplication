/* read in the dta */

local infile "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"


local spatial_lags "${data_main}/spatial_lags${vintage_string}.dta"


use `infile', clear
/* no bio data for 2020. */

tab fishing_year merge_biod

/*
assert _merge==3
drop _merge
*/
tsset stockcode dateq
compress

merge 1:1 stockcode dateq using `spatial_lags'

drop if fishing_year>=2020
/* drop the interactions and Intercepts */
drop if inlist(stockcode, 1818 ,9999)


gen badj_GDP=badj/fGDP
gen ihs_badj_GDP=asinh(badj_GDP)
order fishing_year dateq stockcode badj_GDP  live_priceGDP pounds quota_charge cumulative_quota_use yearly_utilization acl_changeYOY

/* just can't help experimenting with them */
reg badj_GDP live_priceGDP
xtreg badj_GDP live_priceGDP, fe
poisson badj_GDP live_priceGDP
xtpoisson badj_GDP live_priceGDP, fe

xtpoisson badj_GDP live_priceGDP acl_changeYOY acl_up ln_quota_remaining_BOQ fraction_remaining_EOQ , fe


areg badj_GDP live_priceGDP acl_changeYOY acl_up ln_quota_remaining_BOQ fraction_remaining_EOQ , absorb(stockcode)
areg badj_GDP ln_live_priceGDP ln_quota_remaining_BOQ fraction_remaining_EOQ , absorb(stockcode)


xtpoisson badj_GDP live_priceGDP acl_changeYOY acl_up ln_quota_remaining_BOQ fraction_remaining_EOQ , fe
xtreg badj_GDP live_priceGDP acl_changeYOY acl_up ln_quota_remaining_BOQ fraction_remaining_EOQ i.q_fy, i(stockcode) fe


/* I don't like the i.qfy formulation in xtreg, because it imposes too much structure. A constant discount (cents per pound) in each quarter that is the same in all years. 
Poisson, ihs, or ln is a bit more palatable.
*/

