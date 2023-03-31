
#delimit cr
version 15.1
local input_dataset "${data_main}/processed_ace_trade_${vintage_string}.dta"

use `input_dataset', clear



/* flag the single stock trades */

gen nstocks=0
foreach var of varlist z1-z17{
	replace nstocks=nstocks+1 if `var'>0
}

gen single_stock=nstocks==1
gen basket=nstocks~=1


/* how many are single stock trades */	
foreach var of varlist z1-z17{
	*qui count if `var'>0
	*di "stock `var' has `r(N)' observations"
	qui count if `var'>0 & single_stock==1
	di "stock `var' has `r(N)' observations that are single-stock trades"
	tab fy if `var'>0 & single_stock==1
}



preserve
keep if single==1
save "${data_intermediate}/single_stock_trades_${vintage_string}.dta", replace

restore

keep if single~=1
save "${data_intermediate}/basket_trades_${vintage_string}.dta", replace
