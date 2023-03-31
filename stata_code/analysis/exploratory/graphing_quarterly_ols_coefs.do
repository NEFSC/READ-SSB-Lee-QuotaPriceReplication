/* read in the dta */
local ols_coefs "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
cap mkdir "${my_images}/quarterly"
set scheme s2mono
use `ols_coefs', clear
tsset stockcode dateq
/* need to tsfill to get the t-axis to be the same for all coefficients*/
tsfill, full
keep if fishing_year<=2019 & fishing_year>=2010
drop if fishing_year==2010 & q_fy<=2

gen upper=b + 1.645*se
gen lower=b - 1.645*se
levelsof stockcode, local(mystocks)

local tsropts "legend(order(2 "Estimated Price" 1 "90% Confidence Interval")) ytitle("Price($)")  yline(0, lwidth(vthin) lpattern(dash)) xlabel(200(4)240, format(%tqCCYY) angle(45) grid) xmtick(##4) xtitle("") ylabel(, grid)" 
/*
to turn off the ylines in the grid, 
 ylabel(, grid)"  to 
  ylabel(, nogrid)" 
  
  */

foreach stocknum of local mystocks {
	preserve
	local mm: label stockcode `stocknum'
	
	keep if stockcode==`stocknum'

	sort stockcode dateq
	twoway (rarea lower upper dateq, color(gs14) cmissing(n)) (tsline b, cmissing(n) lwidth(medthick) lpattern(solid)),  title("Quota Price of `mm'") `tsropts'

	graph export "${my_images}/quarterly/price_`stocknum'.png", replace as(png) width(2000)
	
	drop if b==.
	tsfill
	
	sort stockcode dateq
	twoway  (rcap upper lower dateq) (connected b dateq, sort cmissing(n)),  title("Quota Price of `mm'") `tsropts'
	graph export "${my_images}/quarterly/priceB_`stocknum'.png", replace as(png) width(2000)

	restore
}

/* 2010Q1 is 200.  
2020Q1 is 240. */


/*We need to custom set the axes for some of the quota
GBE_cod
GBE_haddock
GBW_haddock
GOM_haddock
GOM_Winter
Redfish
SNEMA Yellowtail
SNEMA Winter

 */



























