/* read in the dta */
set scheme s2mono

local ols_coefs "${data_main}/inter_qtr_v2_${vintage_string}.dta"
cap mkdir "${my_images}/quarterly"

use `ols_coefs', clear
egen g=group(stockcode modeltype)
tsset g fyq
/* need to tsfill to get the t-axis to be the same for all coefficients*/
tsfill, full

replace Estimate=. if Estimate==0 & standard_error==0

gen upper=Estimate + 1.645*standard_error
gen lower=Estimate - 1.645*standard_error
levelsof stockcode, local(mystocks)

local tsropts "legend(order(2 "Estimated Price" 1 "95% Confidence Interval")) ytitle("Price($)") xlabel(#11, format(%tqCCYY) angle(45)) xmtick(##4, grid) " 
/*
foreach stocknum of local mystocks {
	preserve
	local mm: label stockcode `stocknum'
	
	keep if stockcode==`stocknum' & modeltype=="replication"

	sort stockcode fyq
	tsset fyq
	twoway (rarea lower upper fyq, color(gs14) cmissing(n)) (tsline Estimate, cmissing(n) lwidth(medthick)),  title("Quota Price of `mm'") `tsropts'

	graph export "${my_images}/quarterly/first_stageP_`stocknum'.png", replace as(png) width(2000)
	
	
	restore
}

*/

/* compare stage 1 
basic: just run OLS on the raw data with sandwich SE's
dropout: drop if less than 5 and recompute total_lbs 
cooksd: use cooksd to drop outlier rows.



replication: zeros out RHS vars if there are less than 5 obs, drops high leverage rows (cooksd>2)
model2: zeros out RHS vars if there are less than 5 obs
parsim: zeros out RHS vars if there are less than 5 obs; drops high leverage rows (cooksd>2); drops out RHS vars that are stastically insignificant and recomputes total pounds before estimating again
zero_out1: zeros out RHS vars if there are less than 5 obs, drops high leverage rows (cooksd>2); recomputes total pounds before final estimation.  


*/
local tsropts "legend(order(1 "Preferred" 2 "basic" 3 "CooksD" 4 "model2" )) ytitle("Price($)") xlabel(#11, format(%tqCCYY) angle(45)) xmtick(##4, grid) " 

foreach stocknum of local mystocks {
	preserve
	local mm: label stockcode `stocknum'
	
	keep if stockcode==`stocknum' & inlist(modeltype,"replication", "basic","cooksd", "dropout")
	/*Some of the estimates are kind of nuts */
	replace Estimate=. if Estimate>5 & stockcode<=20 & Estimate~=.
	replace Estimate=. if Estimate<-5 & stockcode<=20 & Estimate~=.

	sort stockcode fyq
	tsset model fyq
	
	twoway (tsline Estimate if modeltype=="basic", cmissing(n)) (tsline Estimate if modeltype=="replication", cmissing(n)) (tsline Estimate if modeltype=="cooksd", cmissing(n)) (tsline Estimate if modeltype=="model2", cmissing(n)), title("Quota Price of `mm'")  `tsropts'
/*	xtline Estimate,  title("Quota Price of `mm'") `tsropts' cmissing( n n n n) */

	graph export "${my_images}/quarterly/compare_first_stagesA_`stocknum'.png", replace as(png) width(2000)
	
	
	restore
}






local tsropts "legend(order(1 "Preferred" 2 "dropout" 3 "parsim" 4 "zero_out1" )) ytitle("Price($)") xlabel(#11, format(%tqCCYY) angle(45)) xmtick(##4, grid) " 

foreach stocknum of local mystocks {
	preserve
	local mm: label stockcode `stocknum'
	
	keep if stockcode==`stocknum' & inlist(modeltype,"replication", "dropout","parsim", "zero_out1")
	/*Some of the estimates are kind of nuts */
	replace Estimate=. if Estimate>5 & stockcode<=20 & Estimate~=.
	replace Estimate=. if Estimate<-5 & stockcode<=20 & Estimate~=.

	sort stockcode fyq
	tsset model fyq
	
	twoway (tsline Estimate if modeltype=="replication", cmissing(n)) (tsline Estimate if modeltype=="dropout", cmissing(n)) (tsline Estimate if modeltype=="parsim", cmissing(n)) (tsline Estimate if modeltype=="zero_out1", cmissing(n)), title("Quota Price of `mm'")  `tsropts'
/*	xtline Estimate,  title("Quota Price of `mm'") `tsropts' cmissing( n n n n) */

	graph export "${my_images}/quarterly/compare_first_stagesB_`stocknum'.png", replace as(png) width(2000)
	
	
	restore
}



local tsropts "legend(order(1 "Preferred" 2 "zero_out1" )) ytitle("Price($)") xlabel(#11, format(%tqCCYY) angle(45)) xmtick(##4, grid) " 

foreach stocknum of local mystocks {
	preserve
	local mm: label stockcode `stocknum'
	
	keep if stockcode==`stocknum' & inlist(modeltype,"replication", "model2","parsim", "zero_out1")
	/*Some of the estimates are kind of nuts */
	replace Estimate=. if Estimate>5 & stockcode<=20 & Estimate~=.
	replace Estimate=. if Estimate<-5 & stockcode<=20 & Estimate~=.

	sort stockcode fyq
	tsset model fyq
	twoway (rarea lower upper fyq if modeltype=="replication", color(blue) cmissing(n)  fcolor(%25) fintensity(25)) (rarea lower upper fyq if modeltype=="zero_out1", color(gs3) cmissing(n)  fcolor(%25) fintensity(25) lpattern(dash)),  title("Quota Price of `mm'") `tsropts'

/*	xtline Estimate,  title("Quota Price of `mm'") `tsropts' cmissing( n n n n) */

	graph export "${my_images}/quarterly/compare_first_stagesC_`stocknum'.png", replace as(png) width(2000)
	
	
	restore
}



local tsropts "legend(order(1 "Preferred" 2 "basic" )) ytitle("Price($)") xlabel(#11, format(%tqCCYY) angle(45)) xmtick(##4, grid) " 

foreach stocknum of local mystocks {
	preserve
	local mm: label stockcode `stocknum'
	
	keep if stockcode==`stocknum' & inlist(modeltype,"replication", "basic")
	/*Some of the estimates are kind of nuts */
	replace Estimate=. if Estimate>5 & stockcode<=20 & Estimate~=.
	replace Estimate=. if Estimate<-5 & stockcode<=20 & Estimate~=.

	sort stockcode fyq
	tsset model fyq
	twoway (rarea lower upper fyq if modeltype=="replication", color(blue) cmissing(n)  fcolor(%25) fintensity(25)) (rarea lower upper fyq if modeltype=="basic", color(gs3) cmissing(n)  fcolor(%25) fintensity(25) lpattern(dash)),  title("Quota Price of `mm'") `tsropts'

/*	xtline Estimate,  title("Quota Price of `mm'") `tsropts' cmissing( n n n n) */

	graph export "${my_images}/quarterly/compare_first_stagesD_`stocknum'.png", replace as(png) width(2000)
	
	
	restore
}


