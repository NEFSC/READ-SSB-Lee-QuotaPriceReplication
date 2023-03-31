version 15.1
#delimit cr
pause on
set scheme s2mono
local quota_data ${data_main}/monthly_quota_available_${vintage_string}.dta
local output_price_data ${data_main}/dmis_output_species_prices_${vintage_string}.dta
local quota_price_data ${data_intermediate}/annual_quota_prices_${vintage_string}.dta


use `quota_data', replace

/* drop the un-allocated stocks */
drop if stockcode>=100
/* one index of quota availability */
bysort trip_monthly_date: egen tqb=total(quota_remaining_bom)
gen monthly_fishing_year=trip_monthly_date-4
gen share=quota_remaining_bom/tqb
format monthly_fishing_year %tm
tsset stockcode monthly_fishing_year
label define mystock 0 "nothing" 1 "CCGOM Yellowtail Flounder" 2 "GBE Cod" 4 "GBE Haddock" 6 "GB Winter Flounder" 7 "GB Yellowtail Flounder" 8 "GOM Cod" 9 "GOM Haddock" 10 "GOM Winter Flounder" 11 "Plaice" 12 "Pollock" 13 "Redfish" 14 "SNEMA Yellowtail Flounder" 15 "White Hake" 16 "Witch Flounder" 17 "SNEMA Winter Flounder" 99 "Wolffish" 98 "Southern Windowpane" 97 "Ocean Pout" 96 "Northern Windowpane" 95 "Halibut"
label define mystock 3 "GBW Cod" 5 "GBW Haddock", modify
label values stockcode mystock
label var monthly_fishing_year "Month of Fishing Year"

qui summ monthly_fishing_year
local firstper=`r(min)'
local lastper=`r(max)'

/* the big panel isn't that great -- too much variability across stocks */
xtline quota_charge, ttitle("Month") tmtick(##4) tlabel(`firstper'(12)`lastper', angle(45)) 

foreach var of varlist quota_charge cumulative_quota_use quota_remaining_eom quota_remaining_bom{
replace `var'=`var'/1000000
}
label var quota_charge "monthly quota used (M)"
label var cumulative_quota_use "cumulative quota used (M)" 
label var quota_remaining_bom "quota remaining (M)" 
label var quota_remaining_eom "quota remaining (M)" 
label var fraction_remaining_bom "fraction of initial quota remaining"



local tlines " tline(612(12)708, lpattern(dash) lcolor(gs10)) "

decode stockcode, gen(mystocks)
levelsof mystocks, local(stocklist)

local overlay_opts overlay legend(order(1 "2010" 2 "2011" 3 "2012" 4 "2013" 5 "2014" 6 "2015" 7 "2016" 8 "2017" 9 "2018") rows(3))  xlabel(0(2)12) ttitle("Month of Fishing Year")


/*Plot usage for each stock individually.  First over the fully time series. Then stacking over months */
foreach l of local stocklist{

twoway  (tsline quota_charge if mystocks=="`l'", cmissing(n)) , xlabel(`firstper'(12)`lastper')  name(p1, replace) legend(off) ttitle("") tlabel("") nodraw
twoway  (tsline cumulative_quota_use if mystocks=="`l'", cmissing(n)), name(q1, replace)   xlabel(`firstper'(12)`lastper', angle(45)) xmtick(##4)  nodraw

graph combine p1 q1, cols(1) imargin(zero) title("`l'") xcommon
graph export "${exploratory}/monthly/monthly_quota_use_`l'.png", as(png) replace width(2000)

preserve
keep if mystocks=="`l'"
tsset fishing_year month_of_fy
xtline quota_charge, overlay legend(off) ttitle("") xlabel(`firstper'(12)`lastper') tlabel("")  name(o1, replace) nodraw 

xtline cumulative_quota_use, overlay legend(off) ttitle("")  xlabel(`firstper'(12)`lastper') tlabel("")  name(o2, replace) nodraw

xtline quota_remaining_bom, `overlay_opts' name(o3, replace)  nodraw

xtline fraction_remaining_bom, `overlay_opts' name(o4, replace)nodraw

graph combine o1 o2 o3 o4,  imargin(zero) title("`l'") xcommon

graph export "${exploratory}/monthly/overlay_panel_usage_`l'.png", as(png) replace width(2000)

restore
graph drop _all
}



