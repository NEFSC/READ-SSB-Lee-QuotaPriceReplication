/* quarterly prices from the single-stock trades */
version 15.1
#delimit cr
pause on
set scheme s2mono
local in_data ${data_intermediate}/single_stock_trades_${vintage_string}.dta
local out_data ${data_intermediate}/quarterly_single_stock_${vintage_string}.dta
cap mkdir ${exploratory}\quarterly

use `in_data', replace
cap rename stockcode stockcode

gen myid=_n
reshape long z, i(myid) j(stockcode)
drop if z==0
gen ntrades=1

rename z pounds
drop total single basket nstocks q_fy avg_price

label define mystock 0 "nothing" 1 "CCGOM Yellowtail Flounder" 2 "GBE Cod" 4 "GBE Haddock" 6 "GB Winter Flounder" 7 "GB Yellowtail Flounder" 8 "GOM Cod" 9 "GOM Haddock" 10 "GOM Winter Flounder" 11 "Plaice" 12 "Pollock" 13 "Redfish" 14 "SNEMA Yellowtail Flounder" 15 "White Hake" 16 "Witch Flounder" 17 "SNEMA Winter Flounder" 99 "Wolffish" 98 "Southern Windowpane" 97 "Ocean Pout" 96 "Northern Windowpane" 95 "Halibut"
label define mystock 3 "GBW Cod" 5 "GBW Haddock", modify

label values stockcode mystock
tab stockcode

rename transfer_date report_date
replace report_date=dofc(report_date)
format report_date %td
gen monthly=mofd(report_date)

gen adj_date=report_date-mdy(5,1,fy)+mdy(1,1,fy)
gen quarter=qofd(adj_date)
format quarter %tq
drop adj_date
gen quota_price=compensation/pounds

collapse (sum) pounds compensation (sum) ntrades (mean)unw_quota_price=quota_price (sd)sdp=quota_price, by(quarter stockcode)
gen quota_price=compensation/pounds


recode stockcode 1 7 14=123 2 3 8=81 4 5 9=147  6 10 17=120   11=124 12=269  13=240 15=153 16=122 , gen(nespp3)
gen stockarea="UNIT"
replace stockarea="GOM" if inlist(stockcode, 8,9,10)
replace stockarea="GB" if inlist(stockcode, 6,7)
replace stockarea="GBE" if inlist(stockcode, 2,4)
replace stockarea="GBW" if inlist(stockcode, 3,5)
replace stockarea="SNEMA" if inlist(stockcode, 14,17)
replace stockarea="CCGOM" if inlist(stockcode, 1)


tsset stockcode quarter
replace pounds=pounds/1000

label var pounds "ACE Pounds traded (000s)"
label var compensation "Value of ACE traded"
label var ntrades "Number of trades"
label var quota_price "ACE price"

label var quarter "quarter of fishing year"

save `out_data', replace


tsfill, full
xtline quota_price if inlist(stockcode,1,7,9,11,14,16,17), byopts(title("Monthly Quota Prices, selected stocks")) cmissing(n)

replace pounds=0 if pounds==.

qui summ quarter
local firstper=`r(min)'
local lastper=`r(max)'

local tlines " tline(204(4)236, lpattern(dash) lcolor(gs10)) "

decode stockcode, gen(mystocks)
levelsof mystocks, local(stocklist)
foreach l of local stocklist{

twoway  (tsline quota_price if mystocks=="`l'", cmissing(n)) (tsline ntrades if mystocks=="`l'", yaxis(2) cmissing(n) ms(none) lpattern(blank)) , xlabel(`firstper'(4)`lastper') `tlines' name(p1, replace) legend(off) ytitle("", axis(2)) ttitle("") tlabel("") nodraw
twoway (bar pounds quarter if mystocks=="`l'") (tsline ntrades if mystocks=="`l'", yaxis(2) cmissing(n)), name(q1, replace) ytitle("", axis(2)) nodraw xlabel(`firstper'(4)`lastper', angle(45)) xmtick(##4) `tlines'
 
graph combine p1 q1, cols(1) imargin(tiny) title("`l'") xcommon
graph export "${exploratory}/quarterly/quarterly_market_summary_`l'.png", as(png) replace width(2000)

}







