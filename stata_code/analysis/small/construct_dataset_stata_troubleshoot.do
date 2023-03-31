
local mylogfile "${my_results}/troubleshooting_churdle_data_setup.smcl" 
cap log close
log using `mylogfile', replace



#delimit cr
version 16.1
pause on
clear all
spmatrix clear

local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local  constraining ${data_main}/most_constraining_${vintage_string}.dta
local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"


local output "${data_main}/test_dataset_${vintage_string}.dta"





use `prices'
/* drop the interaction and constant */

merge 1:1 stockcode dateq using `constraining'

drop if inlist(stockcode,1818,9999,101,102,103,104,105)
drop if inlist(fishing_year, 2009,2020,2021)
drop if _merge==2
drop _merge

/* drop 2009 and 2020 
2009, we've already created our lags, so this is safe to drop. 
2020, we can't add survey data, so we won't use to estimate 
*/
merge 1:1 stockcode dateq using `spset_key'
tab _merge
assert _merge==3
bysort _ID: assert _n==1
drop _merge





gen badj_GDP=badj/fGDP

gen bpos=badj_GDP>0 
replace bpos=. if badj_GDP==.
gen lnfp=ln(DDFUEL_R)

/*Experiment with the "selection" equation */


keep stockcode badj_GDP quota_remaining_BOQ ln_quota_remaining_BOQ
compress
save `output', replace


log close

