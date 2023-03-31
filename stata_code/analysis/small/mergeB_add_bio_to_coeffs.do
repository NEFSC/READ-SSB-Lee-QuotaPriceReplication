/* merge in ACLs and catch to the dataset with prices in it.*/

#delimit cr
version 15.1
pause off



/* input datasets */
local cOLS_coefficients "${my_results}/constrained_least_squares_${vintage_string}.dta" 
local cOLS_coefficients "${my_results}/nls_least_squares_quarterly_GDPDEF${vintage_string}.dta" 
local biod $data_main/prices_deflators_and_biological_$vintage_string.dta 

/* output datasets */
local out_dataset "${my_results}/ols_tested_mergedGDP_${vintage_string}.dta" 

/* load in the coefficients and merge to the biological, prices, and deflators from the previous step*/

use `cOLS_coefficients', clear
drop if stockcode==.
merge 1:1 fishing_year stockcode using `biod'


assert stockcode>=98 | fishing_year==2009 if _merge==2
drop if _merge==2
assert _merge==3
drop _merge
tsset stockcode fishing_year


merge m:1 stockcode using ${data_main}/stock_codes_${vintage_string}.dta, keep(1 3)
assert _merge==3
drop _merge
/*Prices (b's) are non-negative by construction. 0 is on the boundary of the parameter space, which is slightly difficult for testing purposes.

	But, I'm going to ignore this and state 
	H0: b=0
	HA: b>0
	One tail test. If I want the tail to have 
	
	5%, I need to use z=1.645
	2.5%	z=1.96
	1% 2.33
	.5% 2.58
	

	need to think about this. There are stocks with price at or near 0. There are other stocks that have so few trades that we can't actually estimate anything (like with a price =1 )
	*/
gen z=b/se	
gen badj=b
replace badj=0 if abs(z)<=1.645
replace badj=0 if se==0
replace badj=0 if badj==.
replace badj=. if inlist(stockcode,17) & fishing_year<=2012

replace badj=b if stockname=="witch_flounder" & fishing_year==2013

/* construct inshore, offshore, unit stock variables */
gen distance=0
replace distance=2 if strmatch(stockname,"GB*")
replace distance=1 if strmatch(stockname,"*GOM*") | strmatch(stockname,"SNEMA*") 

/* construct a species variable */
gen species=stockname
replace species=subinstr(species,"GOM_","",1)
replace species=subinstr(species,"SNEMA_","",1)
replace species=subinstr(species,"GBE_","",1)
replace species=subinstr(species,"GBW_","",1)
replace species=subinstr(species,"GB_","",1)


/* construct qp_ratio */
gen qp_ratio=badj/live_priceGDP

save `out_dataset', replace

