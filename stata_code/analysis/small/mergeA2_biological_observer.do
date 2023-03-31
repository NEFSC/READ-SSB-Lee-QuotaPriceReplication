/* merge in ACLs and catch to the dataset with prices in it.*/

#delimit cr
version 15.1
pause off


/* input datasets */
local obs_by_stock ${data_main}/observed_by_stock_$vintage_string.dta
local observer_all ${data_main}/sector_coverage_rates_$vintage_string.dta
local bio_data $data_external/annual_catch_and_acl_$vintage_string.dta 
local price_clean $data_main/prices_deflators_fuel_${vintage_string}.dta



/* output datasets */
local biod $data_main/prices_deflators_and_biological_$vintage_string.dta 

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
gen utilization= (sector_livemt_catch/ sector_livemt_acl)


/**************************************************************/
/* construct dummies for the highest utilization in each area */
/**************************************************************/
gen stockarea2=stockarea
replace stockarea2="GB" if inlist(stockarea,"GBE","GBW")

/* highest GOM is either the GOM or CC/GOM */
/* highest GB is GBE, GBW,or GB, or CC/GOM */
/* highest SNEMA is highest SNEMA or CCGOM*/
/* highest unit is highest unit */
/* 521 will always be a problem: It is part of CCGOM for Yellowtail, GB from Cod, Haddock, and SNEMA for Winter */
/* There's nothing I can really do here about it -- I either group CC/GOM in with each OR I leave it by itself.*/

sort stockarea2 fishing_year utilization
/*pick the top stock and top 2 stocks by utilization in each stock area */
bysort stockarea2 fishing_year (utilization): gen maxU1=_n==_N
bysort stockarea2 fishing_year (utilization): gen maxU2=_n>=_N-1


gen util50=utilization>=.50
gen util75=utilization>=.75
gen util90=utilization>=.90

tsset
foreach var of varlist utilization util50 util75 util90 maxU1 maxU2 {
gen lag_`var'=l.`var'
}
tsset
gen acl_change=((sector_livemt_acl-l1.sector_livemt_acl)/l1.sector_livemt_acl)

gen acl_up=acl_change>=0


notes acl_change: fractional year-on-year change in ACL.
notes utilization: ACL utilization rate
notes acl_up: ACL increased


merge 1:1 stockcode fishing_year using `price_clean', keep(1 3)

assert _merge==3
drop _merge
label var sector_livemt_acl "annual sector ACL (000s mt)"
label var sector_livemt_catch "annual sector catch(000s mt)"

save `biod', replace
