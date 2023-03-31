
version 15.1
#delimit cr
local in_data ${data_intermediate}/single_stock_trades_${vintage_string}.dta
local price_data ${data_internal}/output_prices_${vintage_string}.dta
local out_data ${data_intermediate}/monthly_single_stock_${vintage_string}.dta
set scheme s2mono
use `in_data', replace
cap mkdir ${exploratory}\monthly
gen myid=_n
reshape long z, i(myid) j(stockcode)
drop if z==0
gen ntrades=1
rename z pounds
drop total single basket nstocks q_fy avg_price

label define mystock 0 "nothing" 1 "CCGOM Yellowtail Flounder" 2 "GBE Cod" 4 "GBE Haddock" 6 "GB Winter Flounder" 7 "GB Yellowtail Flounder" 8 "GOM Cod" 9 "GOM Haddock" 10 "GOM Winter Flounder" 11 "Plaice" 12 "Pollock" 13 "Redfish" 14 "SNEMA Yellowtail Flounder" 15 "White Hake" 16 "Witch Flounder" 17 "SNEMA Winter Flounder" 99 "Wolffish" 98 "Southern Windowpane" 97 "Ocean Pout" 96 "Northern Windowpane" 95 "Halibut"
label define mystock 3 "GBW Cod" 5 "GBW Haddock", modify
label values stockcode mystock
cap rename stockcode stockcode
tab stockcode

gen quota_price=compensation/pounds
gen monthly=mofd(dofc(transfer_date))

collapse (sum) pounds compensation (sum) ntrades (mean)unw_quota_price=quota_price (sd)sdp=quota_price, by(monthly stockcode)
/* collapsed to the monthly level */



recode stockcode 1 7 14=123 2 3 8=81 4 5 9=147  6 10 17=120   11=124 12=269  13=240 15=153 16=122 , gen(nespp3)
gen stockarea="Unit"
replace stockarea="GOM" if inlist(stockcode, 8,9,10)
replace stockarea="GB" if inlist(stockcode, 6,7)
replace stockarea="GBE" if inlist(stockcode, 2,4)
replace stockarea="GBW" if inlist(stockcode, 3,5)
replace stockarea="SNEMA" if inlist(stockcode, 14,17)
replace stockarea="CCGOM" if inlist(stockcode, 1)
gen quota_price=compensation/pounds


tsset stockcode monthly
replace monthly=monthly-4
label var monthly "Month of fishing year"

replace pounds=pounds/1000
label var pounds "ACE Pounds traded (000s)"
label var compensation "Value of ACE traded"
label var ntrades "Number of trades"
label var quota_price "ACE price"

save `out_data', replace





tsfill, full
format monthly %tm
xtline quota_price if inlist(stockcode,1,7,9,11,14,16,17), byopts(title("Monthly Quota Prices, selected stocks")) cmissing(n) tmtick(#5)
replace pounds=0 if pounds==.
/*first trades were in July, 2010 -- change the graph axes slightly */
qui summ monthly

local firstper=`r(min)'-2
local lastper=`r(max)'

local tlines " tline(612(12)708, lpattern(dash) lcolor(gs10)) "

decode stockcode, gen(mystocks)
levelsof mystocks, local(stocklist)
foreach l of local stocklist{

twoway  (tsline quota_price if mystocks=="`l'", cmissing(n)) (tsline ntrades if mystocks=="`l'", yaxis(2) cmissing(n) ms(none) lpattern(blank)) , xlabel(`firstper'(12)`lastper')  `tlines' name(p1, replace) legend(off) ytitle("", axis(2)) ttitle("") tlabel("") nodraw
twoway (bar pounds monthly if mystocks=="`l'") (tsline ntrades if mystocks=="`l'", yaxis(2) cmissing(n)), name(q1, replace) ytitle("", axis(2)) nodraw xlabel(`firstper'(12)`lastper', angle(45)) xmtick(##4) `tlines'

graph combine p1 q1, cols(1) imargin(zero) title("`l'") xcommon
graph export "${exploratory}/monthly/monthly_market_summary_`l'.png", as(png) replace width(2000)

}

/*
twoway  (tsline quota_price if mystocks=="`l'", cmissing(n)) (tsline ntrades if mystocks=="`l'", yaxis(2) cmissing(n) ms(none) lpattern(blank)) , xlabel(`firstper'(4)`lastper') name(p1, replace) legend(off) ytitle("", axis(2)) ttitle("") tlabel("") nodraw
twoway (bar pounds quarter if mystocks=="`l'") (tsline ntrades if mystocks=="`l'", yaxis(2) cmissing(n)), name(q1, replace) ytitle("", axis(2)) nodraw xlabel(`firstper'(4)`lastper', angle(45)) xmtick(##4)

graph combine p1 q1, cols(1) imargin(tiny)
*/
