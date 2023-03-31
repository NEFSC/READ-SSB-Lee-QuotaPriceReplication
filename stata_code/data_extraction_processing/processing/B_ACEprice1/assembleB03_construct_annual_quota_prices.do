/* annual prices from the single-stock trades */
version 15.1
#delimit cr

local in_data ${data_intermediate}/single_stock_trades_${vintage_string}.dta
local price_data ${data_internal}/output_prices_${vintage_string}.dta
local out_data ${data_intermediate}/annual_quota_prices_${vintage_string}.dta

use `in_data', replace



gen myid=_n
reshape long z, i(myid) j(stocknum)
drop if z==0
rename z pounds
drop total single basket nstocks q_fy avg_price

label define mystock 0 "nothing" 1 "CCGOM Yellowtail Flounder" 2 "GB Cod East" 4 "GB Haddock East" 6 "GB Winter Flounder" 7 "GB Yellowtail Flounder" 8 "GOM Cod" 9 "GOM Haddock" 10 "GOM Winter Flounder" 11 "Plaice" 12 "Pollock" 13 "Redfish" 14 "SNEMA Yellowtail Flounder" 15 "White Hake" 16 "Witch Flounder" 17 "SNEMA Winter Flounder" 99 "Wolffish" 98 "Southern Windowpane" 97 "Ocean Pout" 96 "Northern Windowpane" 95 "Halibut"
label define mystock 3 "GB_Cod_West" 5 "GB_Haddock_West", modify
label values stocknum mystock
tab stocknum

gen price=compensation/pounds
regress price ibn.stocknum, noc
gen marker=1
gen pweight=floor(pounds)
/* prices, weighted by size of trade */
collapse (mean)price (sd)sdp=price  (rawsum) marker [fweight=pweight], by(fy stocknum)
rename marker ntransactions




recode stocknum 1 7 14=123 2 3 8=81 4 5 9=147  6 10 17=120   11=124 12=269  13=240 15=153 16=122 , gen(nespp3)
gen stockarea="UNIT"
replace stockarea="GOM" if inlist(stocknum, 8,9,10)
replace stockarea="GB" if inlist(stocknum, 6,7)
replace stockarea="GBE" if inlist(stocknum, 2,4)
replace stockarea="GBW" if inlist(stocknum, 3,5)
replace stockarea="SNEMA" if inlist(stocknum, 14,17)
replace stockarea="CCGOM" if inlist(stocknum, 1)


rename fy fishing_year
rename stocknum stockcode
save `out_data', replace
