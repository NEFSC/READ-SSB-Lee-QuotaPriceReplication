
#delimit cr
version 15.1
pause off

/* input datasets */
local prices $data_main/dmis_output_species_prices_${vintage_string}.dta
local deflators_in "$data_external/deflatorsQ_${vintage_string}.dta"
local fuels  "$data_external\diesel_${vintage_string}.dta"


local bls_vintage "2021_10_14"
local labor "$BLS_folder\data_folder\main\BLS_QCEW_relevant_wages_`bls_vintage'.dta"

/* output datasets */

local price_clean $data_main/prices_deflators_fuel_${vintage_string}.dta

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


tempfile laborprice
save `laborprice', replace







/* fuel. we'll use May 1 fuel prices or 1st observed month if May isn't available. Be careful of first and last years */
use `fuels', clear
drop if DDFUELNYH==.
gen year=year(daten)
gen month=month(daten)
gen mark=0
replace mark=1 if month==5
bysort year: egen tm=total(mark)
bysort year: replace mark=1 if tm==0 & mark==0 & _n==1
keep if mark==1
keep year DDFUELNYH
rename year fishing_year
tempfile fuelprice
save `fuelprice'

use  `deflators_in', clear
keep dateq  fGDPDEF_2010Q1 fPCU483483 fPCU31173117_2010Q1

rename fGDPDEF_2010Q1 fGDP
rename fPCU483483 fwater_transport
rename fPCU31173117_2010Q1 fseafoodproductpreparation

notes fGDP: Implicit price deflator
notes fwater: Industry PPI for water transport services
notes fseafood: Industry PPI for seafood product prep and packaging
tempfile deflators
save `deflators'






/* Load in Annual Output Prices and merge fuel prices*/
use `prices', clear
merge m:1 fishing_year using `fuelprice', keep(1 3)
assert _merge==3
drop _merge

/* and merge deflators*/
gen dateq=qofd(dofm(trip_monthly_date))
merge m:1 dateq using `deflators', keep(1 3)
assert _merge==3
drop _merge


/* and merge laborprice*/
merge m:1 dateq using `laborprice', keep(1 3)
assert _merge==3 | dateq>=yq(2020,4)



/*I've normalized by GDP deflator */
replace dlr_dollar=dlr_dollar/fGDP
rename dlr_dollar dlr_dollarGDP
gen DDFUEL_R=DDFUELNYH/fGDP

gen avg_wkly_wage_R=avg_wkly_wage/fGDP


gen avg_hourly_wage=avg_wkly_wage/(40)
gen avg_hourly_wage_R=avg_wkly_wage_R/(40)

collapse (sum) dlr_live dlr_dollar (first) DDFUELNYH DDFUEL_R fGDP avg_wkly_wage avg_wkly_wage_R avg_hourly_wage avg_hourly_wage_R, by(stockcode fishing_year stock_id)

gen live_priceGDP=dlr_dollar/dlr_live
tsset stockcode fishing_year
keep stockcode fishing_year live_price  DDFUELNYH DDFUEL_R fGDP avg_wkly_wage avg_wkly_wage_R avg_hourly_wage avg_hourly_wage_R
gen lag_live_priceGDP=l1.live_price


save `price_clean', replace
