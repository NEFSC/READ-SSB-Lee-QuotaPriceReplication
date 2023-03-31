/* final cleanup of the coeffs */
/* quarterly coefficients */
version 15.1
#delimit cr

local in_quarterly ${hedonicR_results}/hedonic_quarterlyR.dta
local out_quarterly ${hedonicR_results}/hedonic_quarterly_prices_${vintage_string}.dta

local in_annual ${hedonicR_results}/hedonic_yearlyR.dta
local out_annual ${hedonicR_results}/hedonic_yearly_prices_${vintage_string}.dta

use `in_quarterly', clear
cap drop stock_name
gen stock_name=var

rename Std std_error

label define mystock 0 "nothing" 1 "CCGOM Yellowtail Flounder" 2 "GBE Cod" 4 "GBE Haddock" 6 "GB Winter Flounder" 7 "GB Yellowtail Flounder" 8 "GOM Cod" 9 "GOM Haddock" 10 "GOM Winter Flounder" 11 "Plaice" 12 "Pollock" 13 "Redfish" 14 "SNEMA Yellowtail Flounder" 15 "White Hake" 16 "Witch Flounder" 17 "SNEMA Winter Flounder" 99 "Wolffish" 98 "Southern Windowpane" 97 "Ocean Pout" 96 "Northern Windowpane" 95 "Halibut"
label define mystock 3 "GBW Cod" 5 "GBW Haddock", modify

label value stock_name mystock

drop price date 
rename q_fy quarter_of_fy
renvars, lower

rename stock stockcode
recode stockcode 1 7 14=123 2 3 8=81 4 5 9=147  6 10 17=120   11=124 12=269  13=240 15=153 16=122 , gen(species)
gen stockarea="Unit"
replace stockarea="GOM" if inlist(stockcode, 8,9,10)
replace stockarea="GB" if inlist(stockcode, 6,7)
replace stockarea="GBE" if inlist(stockcode, 2,4)
replace stockarea="GBW" if inlist(stockcode, 3,5)
replace stockarea="SNEMA" if inlist(stockcode, 14,17)
replace stockarea="CCGOM" if inlist(stockcode, 1)


save `out_quarterly', replace

/* annual coefficients */

use `in_annual', clear
rename Std std_error
cap drop stock_name
gen stock_name=var

label define mystock 0 "nothing" 1 "CCGOM Yellowtail Flounder" 2 "GB Cod East" 4 "GB Haddock East" 6 "GB Winter Flounder" 7 "GB Yellowtail Flounder" 8 "GOM Cod" 9 "GOM Haddock" 10 "GOM Winter Flounder" 11 "Plaice" 12 "Pollock" 13 "Redfish" 14 "SNEMA Yellowtail Flounder" 15 "White Hake" 16 "Witch Flounder" 17 "SNEMA Winter Flounder" 99 "Wolffish" 98 "Southern Windowpane" 97 "Ocean Pout" 96 "Northern Windowpane" 95 "Halibut"
label define mystock 3 "GB Cod West" 5 "GB Haddock West", modify


label value stock_name mystock

drop price 
renvars, lower
rename stock stockcode

recode stockcode 1 7 14=123 2 3 8=81 4 5 9=147  6 10 17=120   11=124 12=269  13=240 15=153 16=122 , gen(species)
gen stockarea="Unit"
replace stockarea="GOM" if inlist(stockcode, 8,9,10)
replace stockarea="GB" if inlist(stockcode, 6,7)
replace stockarea="GBE" if inlist(stockcode, 2,4)
replace stockarea="GBW" if inlist(stockcode, 3,5)
replace stockarea="SNEMA" if inlist(stockcode, 14,17)
replace stockarea="CCGOM" if inlist(stockcode, 1)

save `out_annual', replace
