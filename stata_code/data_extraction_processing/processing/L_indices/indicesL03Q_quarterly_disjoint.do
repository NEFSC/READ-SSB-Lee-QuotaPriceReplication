/*This constructs indexes for stock-quarters 
1.  quota availability.
2.  output price weighted quota index
3.  Shannon
4.  HHI


For all of the indices here, we do not include stock i in the calculation of stock i's index .  See the line where we drop out the "own-stock" 
All indices are constructed using stocks that are caught together (using the required_stocks) dataset 
*/


version 15.1
#delimit cr
local quota_data ${data_main}/quarterly_quota_available_$vintage_string.dta

local output_price_data ${data_main}/dmis_output_stock_quarterly_prices_${vintage_string}.dta

local required_stocks ${data_main}/required_stocks_${vintage_string}.dta
local stock_decoder ${data_main}/stock_codes_${vintage_string}.dta


local stock_disjoint ${data_main}/quarterly_stock_disjoint_index_${vintage_string}.dta




/*construct a "disjoint" datatable.  */

use `required_stocks', clear
drop if stockcode>=100
keep stockcode
duplicates drop
compress

preserve
rename stockcode required
tempfile stocklist
save `stocklist'
restore
cross using `stocklist'
sort stockcode required
/* this dataset contains a cross of stockcode onto itself */

tempfile stock_crossed
save `stock_crossed', replace

merge 1:1 stockcode required using `required_stocks'
drop if stockcode>=100
drop if required>=100

rename required targeted
keep stockcode targeted _merge
gen need_quota=0
replace need_quota=1 if _merge==3
drop _merge

save `stock_crossed', replace



*******************************************/
/* output-price weighted */
/********************************************/
use `output_price_data', clear
drop if stockcode>=100
drop if fishing_year>=2020

keep fishing_year stockcode stock_id quarterly dealer_live_price
tempfile output_prices
save `output_prices', replace




use `quota_data', replace
/* drop the un-allocated stocks */
drop if stockcode>=100
levelsof stockcode, local(start_stock)

/* we need to drop snema winter from any quota index prior to 2012 because it didn't have quota */
drop if fishing_year<2012 & stockcode==17

keep stockcode fishing_year quarterly quota_remaining_BOQ
merge 1:1 fishing_year stockcode quarterly using `output_prices'

drop if fishing_year<=2009
drop if fishing_year>=2020
drop if fishing_year<2012 & stockcode==17

assert _merge==3
drop _merge




gen pq=dealer_live*quota_remaining_BOQ

count
scalar start=`r(N)'


/* form all pairwise combinations between the Quota remaining dataset and the required dataset */
joinby stockcode using `stock_crossed'

replace pq=pq/1000000
label var pq "unit=1M dollars"
replace quota_remaining_BOQ=quota_remaining_BOQ/1000000
label var quota_remaining_BOQ "units=1M lbs"



keep if need_quota==0
/* here is where we construct our shannon and HHI indices by targeted quarterly */
bysort quarterly targeted: egen tqb=total(quota_remaining_BOQ)
gen share=quota_remaining_BOQ/tqb
gen lns=ln(share)



drop tqb

bysort quarterly targeted need_quota: egen tbq=total(pq)
gen sharePQ=pq/tbq
gen lnsPQ=ln(sharePQ)


gen shannon_Q=-1*share*lns

gen shannon_PQ=-1*sharePQ*lnsPQ

/* HHI*/
gen HHI_Q=share^2
gen HHI_PQ=sharePQ^2


bysort quarterly targeted: gen N=_N
gen shannon_max=ln(N)

collapse (sum) pq quota_remaining_BOQ shannon_Q shannon_PQ HHI_Q HHI_PQ (first) shannon_max, by(targeted fishing_year quarterly)
gen q_of_fy=quarter(dofq(quarterly))
gen Nshannon_Q=shannon_Q/shannon_max
gen Nshannon_PQ=shannon_PQ/shannon_max


rename targeted stockcode


merge m:1 stockcode using `stock_decoder'


drop if stockcode>=100
/* fill in the missings for the unit stocks */
replace quarterly=yq(2010,1) if quarterly==. & _merge==2
tsset stockcode quarterly
tsfill, full


/* fill in stock attributes */
foreach var of varlist stock_id stock stockarea{
	replace `var'=`var'[1] if `var'=="" & _merge==. | _merge==2
}

/* fill in stock attributes */

foreach var of varlist nespp3  {
	replace `var'=`var'[1] if `var'==. & _merge==. | _merge==2
}


/* fill in disjointness indices for the unit stocks */

foreach var of varlist pq quota_remaining_BOQ  HHI_Q HHI_PQ   shannon_max{
	replace `var'=0 if `var'==. & _merge==. | _merge==2
}

/* the disjoint shannon isn't defined for the unit stocks- -there's nothing there */

replace fishing_year=yofd(dofq(quarterly)) if fishing_year==.
replace q_of_fy=quarter(dofq(quarterly)) if q_of_fy==.



/*make sure I have what I think I should have */
tsset
assert strmatch("`r(balanced)'","strongly balanced")
drop _merge

order stockcode stock nespp3 stockarea
tsset stockcode quarterly
label define mystock 0 "nothing" 1 "CCGOM Yellowtail Flounder" 2 "GBE Cod" 4 "GBE Haddock" 6 "GB Winter Flounder" 7 "GB Yellowtail Flounder" 8 "GOM Cod" 9 "GOM Haddock" 10 "GOM Winter Flounder" 11 "Plaice" 12 "Pollock" 13 "Redfish" 14 "SNEMA Yellowtail Flounder" 15 "White Hake" 16 "Witch Flounder" 17 "SNEMA Winter Flounder" 99 "Wolffish" 98 "Southern Windowpane" 97 "Ocean Pout" 96 "Northern Windowpane" 95 "Halibut", replace
label define mystock 3 "GBW Cod" 5 "GBW Haddock", modify
label values stockcode mystock


/* label */

rename pq PQR_Index

rename quota_remaining QR_Index
label var PQR_Index "sum Price *quota remaining, disjoint species"
label var QR_Index "sum quota remaining, disjoint species"



foreach var of varlist  shannon_Q HHI_Q shannon_PQ HHI_PQ QR_Index PQR_Index Nshannon_Q Nshannon_PQ{
    notes `var': Disjoint version of the index.
    rename `var' stockD_`var'
}



tsset
assert strmatch("`r(balanced)'","strongly balanced")

qui summ stockcode
assert strmatch("`r(min)'","1")
assert strmatch("`r(max)'","17")

levelsof stockcode, local(end_stock)

assert "`end_stock'"=="`start_stock'"

save `stock_disjoint', replace 


