/* code to assemble a quarterly dataset of

Fuel prices
live output prices
1st and 4th lags of live output prices

*/
#delimit cr
version 15.1
pause off

/* input datasets */
local pricesQ "$data_main/dmis_output_species_quarterly_prices_${vintage_string}.dta"
local pricesQ "$data_main/dmis_output_stock_quarterly_prices_${vintage_string}.dta"

local deflators_in "$data_external/deflatorsQ_${vintage_string}.dta"
local fuels  "$data_external/diesel_${vintage_string}.dta"
local quarterly_usage "$data_external/dmis_quarterly_quota_usage_$vintage_string.dta"

local quarterly_available "${data_main}/quarterly_quota_available_$vintage_string.dta"




local bls_vintage "2021_10_14"
local labor "$BLS_folder\data_folder\main\BLS_QCEW_relevant_wages_`bls_vintage'.dta"

/* output datasets */
local price_clean $data_main/quarterly_prices_deflators_fuel_${vintage_string}.dta



/* Labor */

use `labor', replace
keep caldq dateq laborcat avg_wkly_wage
compress
/* crew averages are about 2.8, so we'll use 1 capt and 1.8 crew*/
gen weight=1
replace weight=1.8 if laborcat=="Crew"
drop if laborcat=="CaptA"

collapse (mean) avg_wkly_wage [iweight=weight], by(dateq)
label var avg "Average weekly wage proxy for groundfish crew (nominal)"
gen ln_wage=ln(avg)

rename dateq quarterly
tempfile laborprice
save `laborprice', replace




/* we'll use fuel prices in the first month of the quarter of the FY. Be careful of first and last years */
use `fuels', clear
drop if DDFUELNYH==.
gen fishing_year=year(daten)
gen month=month(daten)
replace fishing_year=fishing_year-1 if month<=4
gen m_fy=month-4
replace m_fy=m_fy+12 if m_fy<=0
gen q_fy=irecode(m_fy,0,3,6,9,12)


gen quarterly=yq(fishing_year, q_fy)
notes quarterly: quarter, where MJJ is quarter 1 of the fishing_year
format quarterly %tq

bysort fishing_year q_fy (m_fy): gen mark=_n
keep if mark==1
keep fishing_year quarterly DDFUELNYH
tsset quarterly
tempfile fuelpriceQ
save `fuelpriceQ'


/* just quarterly deflators. only need to rename the time variable to facilitate merging */
use  `deflators_in', clear
keep dateq  fGDPDEF_2010Q1 fPCU483483 fPCU31173117_2010Q1

rename fGDPDEF_2010Q1 fGDP
rename fPCU483483 fwater_transport
rename fPCU31173117_2010Q1 fseafoodproductpreparation

notes fGDP: Implicit price deflator
notes fwater: Industry PPI for water transport services
notes fseafood: Industry PPI for seafood product prep and packaging
tempfile deflators
rename dateq quarterly
save `deflators', replace

use `quarterly_usage', clear
keep stockcode quarterly fishing_year quota_charge 



merge 1:1 stockcode quarterly fishing_year using `quarterly_available'
drop _merge
tempfile quarter_used



save `quarter_used', replace



/* Load in Quarterly Output Prices and merge fuel prices*/
use `pricesQ', clear
merge 1:1 stockcode quarterly fishing_year using `quarter_used'
assert _merge==3
drop _merge


merge m:1 fishing_year quarterly using `fuelpriceQ', keep(1 3)
assert _merge==3
drop _merge

/* and merge deflators*/
merge m:1 quarterly using `deflators', keep(1 3)
assert _merge==3 
drop _merge


pause

/* and merge laborprice*/
merge m:1 quarterly using `laborprice', keep(1 3)
assert _merge==3 | quarterly>=yq(2020,4)
drop _merge


/*I've normalized by GDP deflator */
gen dlr_dollarGDP=dlr_dollar/fGDP
drop dlr_dollar 
gen DDFUEL_R=DDFUELNYH/fGDP

gen avg_wkly_wage_R=avg_wkly_wage/fGDP


gen avg_hourly_wage=avg_wkly_wage/(40)
gen avg_hourly_wage_R=avg_wkly_wage_R/(40)


gen live_priceGDP=dlr_dollarGDP/dlr_live
tsset stockcode quarterly 
compress

keep stockcode fishing_year quarterly live_priceGDP DDFUELNYH DDFUEL_R fGDP pounds quota_charge cumul_quota_use_EOQ cumul_quota_use_BOQ quota_remaining_EOQ quota_remaining_BOQ fraction_remaining_EOQ fraction_remaining_BOQ avg_wkly_wage avg_wkly_wage_R avg_hourly_wage  fraction_used_EOQ fraction_used_BOQ avg_hourly_wage_R

/*rescale to 1000s of mt */
foreach var of varlist quota_charge  quota_remaining_EOQ quota_remaining_BOQ  cumul_quota_use_EOQ cumul_quota_use_BOQ  {
replace `var'=`var'/(2204.62*1000)
label var `var' "thousands of metric tons"
}




foreach var of varlist live_priceGDP quota_charge quota_remaining_EOQ quota_remaining_BOQ fraction_remaining_EOQ fraction_remaining_BOQ cumul_quota_use_EOQ cumul_quota_use_BOQ fraction_used_EOQ fraction_used_BOQ{
	gen ln_`var' =ln(`var')
	gen ihs_`var'=asinh(`var')
	gen lag1Q_`var'=L1.`var'
	gen lag4Q_`var'=L4.`var'

	gen lag1Q_ln_`var'=L1.ln_`var'
	gen lag4Q_ln_`var'=L4.ln_`var'

	gen lag1Q_ihs_`var'=L1.ihs_`var'
	gen lag4Q_ihs_`var'=L4.ihs_`var'

}

drop if fishing_year<=2008
bysort stockcode quarterly: assert _N==1


save `price_clean', replace
