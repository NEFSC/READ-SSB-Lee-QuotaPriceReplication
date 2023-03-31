#delimit cr
*vintage_lookup_and_reset

local quota_price_dataset "${my_results}/ols_tested_mergedGDP_${vintage_string}.dta" 
local deflator_dataset "$data_external/deflatorsQ_${vintage_string}.dta"
local dmis "$data_external/dmis_trip_catch_discards_universe_$vintage_string.dta" 



use `deflator_dataset', clear
keep dateq fGDPDEF_2010Q1
tempfile deflators
save `deflators', replace



use `dmis', replace
keep if mult_year>=2007
rename mult_year fishing_year



gen dateq=qofd(dofc(trip_date))
merge m:1 dateq using `deflators', keep(1 3)
assert _merge==3

gen dlr_dollarGDP=dlr_dollar/fGDP


cap drop dropme



/* compute quota costs */
/* these are the total pounds charged--landed plus discard */
gen charged_pounds=pounds+discard


/* revenue and quota costs for the entire trip */
bysort trip_id: egen total_revenue_GDP=total(dlr_dollarGDP)




/*
Define x_i^A, x_i^B as the pounds of stocks A and B caught on trip i (in fishing year y).  

Define X^A, X^B as the aggregate catch of stocks A and B (in fishing year y)

Define q_i^A=x_i^A / X^A and q_i^B=x_i^B / X^BA.  

 Cz_{A,B}= \sum_i min(q_i^A, q_i^B)

Czekanowski, Finger-Kreinen, and Bray-Curtis are all the same thing. 
 
 FK are very clear in their paper that the individual terms in q_i^A is  the value of A in location i divided by the sum total of A across all locations

 
We want to compute this for all pairs of species A, B

 
For this project, we will compute 4 FKs for 
quantity charged (pounds landed+discarded)
quantity landed (pounds)
discard (discard)
revenue (landed*price)


I thought about doing it for quota costs and discard quota costs. However, I only have an annual quota price. This means that we're just scaling the x_i^A by badj.  For the non-zero badj, we then just end up dividing it out in the denominator.  So, there's nothing there.
*/

* test run
*keep if fishing_year>=2018



/* FK for quantity charged */

preserve
bysort fishing_year stockcode: egen yearly_charged=total(charged_pounds)
gen q_charged_=charged_pounds/yearly_charged

keep trip_id fishing_year stockcode q_charged_

levelsof stockcode, local (mystockcodes)
global stocksave `mystockcodes'

reshape wide q_charged_, i(trip_id fishing_year) j(stockcode)


foreach var of varlist q_charged*{
	replace `var'=0 if `var'==.
}


foreach A of local mystockcodes{
	local working:  list mystockcodes - A
		foreach B of local working{
			gen Fk_charged_`A'x`B'=min(q_charged_`A',q_charged_`B')
	}
}


collapse (sum) Fk_charged_*, by(fishing_year)
reshape long Fk_charged_, i(fishing_year) j(stock) string
split stock, gen(stock) parse("x")
destring stock1 stock2, replace
rename Fk_charged_ Fk_charged

gen Ru_charged=1-Fk_charged/(2-Fk_charged)



compress
drop stock
tempfile Fkcharged
save `Fkcharged', replace


restore

/* FK for pounds landed */

preserve
bysort fishing_year stockcode: egen yearly_charged=total(pounds)
gen q_pounds_=pounds/yearly_charged

keep trip_id fishing_year stockcode q_pounds_

levelsof stockcode, local (mystockcodes)
global stocksave `mystockcodes'

reshape wide q_pounds_, i(trip_id fishing_year) j(stockcode)


foreach var of varlist q_pounds_*{
	replace `var'=0 if `var'==.
}


foreach A of local mystockcodes{
	local working:  list mystockcodes - A
		foreach B of local working{
			gen FK_pounds_`A'x`B'=min(q_pounds_`A',q_pounds_`B')
	}
}


collapse (sum) FK_pounds_*, by(fishing_year)
reshape long FK_pounds_, i(fishing_year) j(stock) string
split stock, gen(stock) parse("x")
destring stock1 stock2, replace
rename FK_pounds_ FK_pounds


gen Ru_pounds=1-FK_pounds/(2-FK_pounds)

compress
drop stock
tempfile FK_pounds
save `FK_pounds', replace


restore








/* FK for revenue */
preserve
bysort fishing_year stockcode: egen yearly_rev=total(dlr_dollarGDP)
gen q_revenue_=dlr_dollarGDP/yearly_rev

keep trip_id fishing_year stockcode q_revenue_

levelsof stockcode, local (mystockcodes)
global stocksave `mystockcodes'

reshape wide q_revenue_, i(trip_id fishing_year) j(stockcode)


foreach var of varlist q_revenue_*{
	replace `var'=0 if `var'==.
}


foreach A of local mystockcodes{
	local working:  list mystockcodes - A
		foreach B of local working{
			gen Fk_revenue_`A'x`B'=min(q_revenue_`A',q_revenue_`B')
	}
}


collapse (sum) Fk_revenue_*, by(fishing_year)
reshape long Fk_revenue_, i(fishing_year) j(stock) string
split stock, gen(stock) parse("x")
destring stock1 stock2, replace
rename Fk_revenue_ Fk_revenue
gen Ru_revenue=1-Fk_revenue/(2-Fk_revenue)

compress
drop stock
tempfile revenue
save `revenue', replace
restore







/* FK for Discards */

preserve
bysort fishing_year stockcode: egen yearly_charged=total(discard)
gen q_discard_=discard/yearly_charged

keep trip_id fishing_year stockcode q_discard_

levelsof stockcode, local (mystockcodes)
global stocksave `mystockcodes'

reshape wide q_discard_, i(trip_id fishing_year) j(stockcode)


foreach var of varlist q_discard_*{
	replace `var'=0 if `var'==.
}


foreach A of local mystockcodes{
	local working:  list mystockcodes - A
		foreach B of local working{
			gen FK_discard_`A'x`B'=min(q_discard_`A',q_discard_`B')
	}
}


collapse (sum) FK_discard_*, by(fishing_year)
reshape long FK_discard_, i(fishing_year) j(stock) string
split stock, gen(stock) parse("x")
destring stock1 stock2, replace
rename FK_discard_ FK_discard
gen Ru_discard=1-FK_discard/(2-FK_discard)

compress
drop stock
tempfile FK_discard
save `FK_discard', replace


restore








clear
use `FK_discard'
/*
merge 1:1 fishing_year stock1 stock2 using `FK_discard'
assert _merge==3
drop _merge
*/


merge 1:1 fishing_year stock1 stock2 using `FK_pounds'
assert _merge==3
drop _merge



merge 1:1 fishing_year stock1 stock2 using `revenue'
assert _merge==3
drop _merge



merge 1:1 fishing_year stock1 stock2 using `Fkcharged'
assert _merge==3
drop _merge

/* bring in the stock names from the stock_codes dataset and label the stock1 variable */
rename stock1 stockcode
merge m:1 stockcode using "${data_main}/stock_codes_${vintage_string}.dta"

assert _merge==3
drop _merge

replace stock="Non-Groundfish" if stockcode==999
labmask stockcode, values(stock)
rename stockcode stock1

drop stock nespp3 stockarea stock_id


/* apply the same labels to stock2 */
label values stock2 stockcode
 
order fishing_year stock1 stock2 FK*
sort stock1 stock2 fishing_year
notes FK_pounds : Finger-Kreinen computed on landings
notes FK_discard : Finger-Kreinen computed on discard pounds
notes Fk_revenue : Finger-Kreinen computed on revenue
notes Fk_charged: Finger-Kreinen computed on catch

rename Fk_revenue  FK_revenue
rename Fk_charged  FK_charged



notes Ru_pounds : Ruzicka distance metric 1-(FK/2FK) computed on landings
notes Ru_discard : Ruzicka distance metric 1-(FK/2FK) computed discard pounds
notes Ru_revenue : Ruzicka distance metric 1-(FK/2FK) computed revenue
notes Ru_charged: Ruzicka distance metric 1-(FK/2FK) computed catch


save "${data_main}/overlap_indices_${vintage_string}.dta", replace

gen first=cond(stock1<stock2, stock1,stock2)
gen second=cond(stock1<stock2,stock2,stock1)
label values first second stockcode
egen id=group(first second)
bysort id fishing_year: keep if _n==1

drop stock1 stock2
rename first stock1
rename second stock2
compress
order id stock1 stock2 fishing_year
sort id fishing_year
tsset id fishing_year
save "${data_main}/overlap_indices_dyadic_${vintage_string}.dta", replace

