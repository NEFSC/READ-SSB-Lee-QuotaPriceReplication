/* merge in ACLs and catch to the dataset with prices in it.*/

#delimit cr
version 15.1
pause off


/* input datasets */
local obs_by_stock ${data_main}/observed_by_stock_$vintage_string.dta
local observer_all ${data_main}/sector_coverage_rates_$vintage_string.dta

/* this has annual catch and ACLs in it */
local bio_data $data_external/annual_catch_and_acl_$vintage_string.dta 
local price_clean $data_main/quarterly_prices_deflators_fuel_${vintage_string}.dta



/* output datasets */
local biod $data_main/quarterly_prices_deflators_and_biological_$vintage_string.dta 

use `bio_data', clear
keep fishing_year stockcode stock sector_livemt_acl sector_livemt_catch
/*rescale to 1000s of mt */
foreach var of varlist sector_livemt_acl sector_livemt_catch   {
replace `var'=`var'/1000
}



tsset stockcode fishing_year
/* observer coverage by stock*/

merge 1:1 stockcode fishing_year using `obs_by_stock', keep(1 3)
drop _merge
gen lag_proportion_obs=l1.proportion_observed
pause
/* targeted observer coverage rates */
merge m:1 fishing_year using `observer_all', keep(1 3)
drop _merge

pause
keep if stockcode<=17
/*
gen allocated=1
replace allocated=0 if stock=="SNE/MA Winter Flounder" & fishing_year<=2012
bysort fishing_year: egen Nalloc=total(allocated)


sort fishing_year allocated utilization

bysort fishing_year allocated (utilization): gen utilization_rank=_n
*/
gen yearly_utilization= (sector_livemt_catch/ sector_livemt_acl)
tsset stockcode fishing_year
gen acl_changeYOY=((sector_livemt_acl-L1.sector_livemt_acl)/L1.sector_livemt_acl)
gen acl_up=acl_changeYOY>=0



merge 1:m stockcode fishing_year using `price_clean', keep(1 3)

assert _merge==3 | fishing_year==2009
drop _merge

sort stockcode fishing_year quarterly
tsset stockcode quarterly


notes acl_changeYOY: fractional year-on-year change in ACL.
notes yearly_utilization: ACL utilization rate (Yearly) from the quota monitoring
notes acl_up: ACL increased

compress
label var sector_livemt_acl "annual sector ACL (000s mt)"
label var sector_livemt_catch "annual sector catch(000s mt)"
save `biod', replace
