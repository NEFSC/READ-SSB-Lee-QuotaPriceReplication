/*this is a do file to a make some exploratory plots

based on the Estimation Sample dataset
 */

cap log close

local logfile "first_stage_exploratory_ES_${vintage_string}.smcl"
log using ${my_results}/`logfile', replace

set scheme s2mono
mat drop _all
est drop _all
*local quota_available_indices "${data_intermediate}/quota_available_indices_${vintage_string}.dta"
local in_price_data "${data_main}/quarterly_estimation_dataset_${vintage_string}.dta" 


local allstocks CCGOM_yellowtail GBE_cod GBW_cod GBE_haddock GBW_haddock GB_winter GB_yellowtail GOM_cod GOM_haddock GOM_winter plaice pollock redfish SNEMA_yellowtail white_hake witch_flounder SNEMA_winter
/* changing the flavor to GDPDEF, water, or seafood will vary up the deflated variable.*/
local flavor GDPDEF 
use `in_price_data', clear




cap drop qtr
order z1 z2 z3 z4 z5 z6 z7 z8 z9 z10 z11 z12 z13 z14 z15 z16 z17, after(compensation)

drop if fy>=2020
gen lease_only_sector=inlist(from_sector_name,"NEFS 4", "Maine Sector/MPBS")
/* there's only a few obs in Q1 of FY2010 and Q2 of FY2010. I'm pooling them into Q3 of 2010. 
replace q_fy=3 if q_fy<=2 & fy==2010*/
gen fyq=yq(fy,q_fy)
drop q_fy
gen q_fy=quarter(dofq(fyq))

gen cons=1
gen qtr1 = q_fy==1
gen qtr2 = q_fy==2
gen qtr3 = q_fy==3
gen qtr4 = q_fy==4


gen end=mdy(5,1,fy+1)
gen begin=mdy(5,1,fy)
gen season_remain=(end-date1)/(end-begin)

gen season_elapsed=1-season_remain

preserve
use  "$data_external/deflatorsQ_${vintage_string}.dta", clear
keep dateq  fGDPDEF_2010Q1 fPCU483483 fPCU31173117_2010Q1

rename fGDPDEF_2010Q1 fGDP
rename fPCU483483 fwater_transport
rename fPCU31173117_2010Q1 fseafoodproductpreparation

notes fGDP: Implicit price deflator
notes fwater: Industry PPI for water transport services
notes fseafood: Industry PPI for seafood product prep and packaging
tempfile deflators
save `deflators'
restore

gen dateq=qofd(date1)
format dateq %tq
merge m:1 dateq using `deflators', keep(1 3)
assert _merge==3
drop _merge


gen compensationR_GDPDEF=compensation/fGDP

gen compensationR_water=compensation/fwater_transport
gen compensationR_seafood=compensation/fseafoodproductpreparation





/* I am trying to get info on transaction volumes, so I need to fix up the negatives and convert to positives*/
foreach var of varlist z1-z17 {
	clonevar `var'_raw=`var'
	replace `var'=abs(`var')
}

cap drop total_lbs
egen total_lbs=rowtotal(z1-z17)

cap drop avg_price
gen avg_price=compensation/total_lbs

 /* set up interaction variable */
gen lease_only_pounds=lease_only_sector*total_lbs
clonevar totalpounds2=total_lbs
clonevar lease_only_pounds2=lease_only_pounds




Zdelabel






gen nstocks=0

foreach var of varlist CCGOM_yellowtail- SNEMA_winter{
	replace `var'=0 if `var'==.
	replace nstocks=nstocks+1 if abs(`var')>0
}


format fyq %tq
gen single_stock=nstocks==1


Zlabel_stocknums



tempfile working_tidy
save `working_tidy', replace
pause
/* single stock trades */
preserve
Zrelabel
keep if nstocks==1
foreach var of varlist z1-z17{
replace `var'=`var'>1
rename `var' trades_`var'
}
collapse (sum) trades* , by(fy q_fy)
reshape long trades_z ,i(fy q_fy) j(stockcode) string
rename trades_ single_stock_trades
gen quarterly=yq(fy,q_fy)
format quarterly %tq
order quarterly stockcode single_stock_trades
destring stockcode, replace
tempfile trades
save `trades'
restore


/* Positive trades by fy */
preserve
Zrelabel
foreach var of varlist z1-z17{
replace `var'=`var'>1
rename `var' trades_`var'
}
collapse (sum) trades* , by(fy q_fy)
reshape long trades_z ,i(fy q_fy) j(stockcode) string
rename trades_ total_trades
gen quarterly=yq(fy,q_fy)
format quarterly %tq
order quarterly stockcode total_trades
destring stockcode, replace

merge 1:1 quarterly fy q_fy stockcode using `trades'
assert _merge~=2
drop _merge
save `trades', replace
restore










gen quarterly=yq(fy,q_fy)
format quarterly %tq

/* permit bank activity */
gen permit_bank=inlist(from_sector_name,"Maine Permit Bank","NEFS 4")
gen singlestock=nstocks==1
collapse (sum) `allstocks' compensationR_GDPDEF total_lbs , by(fy quarterly permit_bank)

Zrelabel
reshape long z, i(fy quarterly permit_bank) j(stockcode)
rename z pounds
replace pounds=. if stockcode==17 & fy<=2012

bysort quarterly stockcode: egen tp=total(pounds)
gen frac=pounds/tp
merge m:1 stockcode using ${data_main}\stock_codes_${vintage_string}.dta, keep(1 3)
drop total_lbs
replace pounds=pounds/1000000
labmask stockcode, values(stock)


preserve
keep if permit_bank==1
xtset stockcode quarterly

local tlines tline(200(4)240, lpattern(dash) lcolor(gs12) lwidth(vthin))
local graph_opts ttitle("Quarter") xlabel(200(8)240, angle(45))  tlabel(, format(%tqCCYY)) ttitle("")  byopts(note(""))


xtline frac , ytitle("Fraction sold by Permit Banks") `tlines' `graph_opts'
graph export "${my_images}/descriptive/fraction_of_pounds_by_permit_bank_ES.png", as(png) replace width(2000)





xtline pound , ytitle("Millions of Pounds of Quota Sold by Permit Banks") `tlines' `graph_opts'
graph export "${my_images}/descriptive/pounds_soldby_permit_bank_ES.png", as(png) replace width(2000)

restore

collapse (sum) pounds, by(quarterly stockcode fy )
replace pounds=. if stockcode==17 & fy<=2012

xtset stockcode quarterly
xtline pounds, ytitle("Millions of Pounds of Quota Sold") `tlines' `graph_opts'
graph export "${my_images}/descriptive/quota_pounds_transacted_ES.png", as(png) replace width(2000)






/* not really sure what we need here  
Total trades?
mean value of each trade
timing of trades within a year (trades by quarter)
mean pounds per trade

all of this 'by year'


I've done much of this, in the exploratory graphing files./

*/


 
 
 use `trades', clear
merge m:1 stockcode using "${data_main}\stock_codes_${vintage_string}.dta", keep(1 3)
assert _merge==3
drop _merge
Zlabel_stocknums
labmask stockcode, values(stock)
replace total_trades=. if stockcode==17 & fy<=2012
tsset stockcode quarterly
local tlines tline(200(4)240, lpattern(dash) lcolor(gs12) lwidth(vthin))
local graph_opts ttitle("Quarter") xlabel(200(8)240, angle(45))  tlabel(, format(%tqCCYY)) ttitle("")  byopts(note("")) ylabel(0(10)50)
xtline total_trades, `tlines' `graph_opts' ytitle("Total Trades")
graph export "${my_images}/descriptive/trades_by_quarter_ES.png", replace as(png)






forvalues z=1/17{
preserve
keep if stockcode==`z'
local myl: label stockcode `z'
gen frac_single=single_stock_trades/total_trades
graph box frac_single ,over(q_fy) ytitle("fraction single stock")  title("`myl'")
graph export "${my_images}/descriptive/`myl'_box_singleQ_ES.png", replace as(png)

restore
}



/* trades per quarter */
use `working_tidy', replace

local esttab_opts cells("b") unstack noobs  collabels(none) nonumber eqlabels("Quarter 1" "Quarter 2" "Quarter 3" "Quarter 4", lhs("Fishing Year")) replace

estpost tabulate fy q_fy, nototal
esttab ., `esttab_opts'
esttab . using ${my_tables}/first_stage_tabulate_ES.tex, `esttab_opts'



/* trades per quarter with at least some swap aspects */

use `working_tidy', replace
drop CCGOM_yellowtail- SNEMA_winter interaction
renvars z1_raw-z17_raw,postdrop(4)

gen swap=0
foreach var of varlist z1-z17{
	replace swap=1 if `var'<0
}

keep if swap==1

local esttab_opts cells("b") unstack noobs  collabels(none) nonumber eqlabels("Quarter 1" "Quarter 2" "Quarter 3" "Quarter 4", lhs("Fishing Year")) replace

estpost tabulate fy q_fy, nototal
esttab ., `esttab_opts'
esttab . using ${my_tables}/first_stage_tabulate_swaps_ES.tex, `esttab_opts'




/* package and swaps combined*/

use `working_tidy', replace
keep if nstocks>=2

local esttab_opts cells("b") unstack noobs  collabels(none) nonumber eqlabels("Quarter 1" "Quarter 2" "Quarter 3" "Quarter 4", lhs("Fishing Year")) replace

estpost tabulate fy q_fy, nototal
esttab ., `esttab_opts'
esttab . using ${my_tables}/first_stage_tabulate_package_swaps_ES.tex, `esttab_opts'



log close
