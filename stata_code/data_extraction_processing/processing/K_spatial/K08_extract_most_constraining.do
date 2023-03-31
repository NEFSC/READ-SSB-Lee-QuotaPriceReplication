/* This isn't exactly a spatial analysis
I'm using the stockarea definitions to extract attributes of the "most constraining" other stocks. I will get 

mc_badj
mc_fraction_remaining_BOQ
mc_ln_frac_remain_BOQ
*/
local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local keyfile ${data_main}/required_stocks_${vintage_string}.dta
local outfile ${data_main}/most_constraining_${vintage_string}.dta


use `prices', clear
gen badj_GDP=badj/fGDP
gen ihs_badj_GDP=asinh(badj_GDP)


keep dateq stockcode badj_GDP ihs_badj_GDP fraction_remaining_BOQ ln_fraction_remaining_BOQ ln_quota_remaining_BOQ quota_remaining_BOQ


rename stockcode required

tempfile td
save `td'


use `keyfile', clear

drop if stockcode==required
keep stockcode required
tempfile matcher
save `matcher'


joinby required using `td', unmatched(both)

/* _merge=1 are merges to unallocated stocks , these can be dropped 
_merge=2 are trying to match the constant an interaction to something. These also can be dropped */

keep if _merge==3
drop _merge

/* drop out SNEMA winter pre allocation. Drop out 2020*/

drop if fraction_remaining==. 

foreach var of varlist quota_remaining_BOQ fraction_remaining_BOQ ln_quota_remaining_BOQ ln_fraction_remaining_BOQ{
bysort stockcode dateq (`var'): egen mc_`var'=min(`var')
}

foreach var of varlist badj_GDP ihs_badj_GDP{
bysort stockcode dateq (`var'): egen max_`var'=max(`var')
}

keep stockcode dateq mc* max*
duplicates drop
tsset stockcode dateq


save `outfile', replace

/* rename


foreach var of varlist badj_GDP ihs_badj_GDP fraction_remaining_BOQ ln_fraction_remaining_BOQ ihs_fraction_remaining_BOQ ln_quota_remaining_BOQ ihs_quota_remaining_BOQ{
rename `var' mc_`var'
}
*/
