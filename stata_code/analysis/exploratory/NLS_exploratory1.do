/*this is a do file to a make some exploratory plots */

cap log close
set scheme s2mono

local logfile "NLS_exploratory_${vintage_string}.smcl"
log using ${my_results}/`logfile', replace
global linear_table1 ${my_tables}/linear_table1.tex
global poisson_table1 ${my_tables}/poisson_table1.tex

local in_price_data "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"


local allstocks CCGOM_yellowtail GBE_cod GBW_cod GBE_haddock GBW_haddock GB_winter GB_yellowtail GOM_cod GOM_haddock GOM_winter plaice pollock redfish SNEMA_yellowtail white_hake witch_flounder SNEMA_winter
/* changing the flavor to GDPDEF, water, or seafood will vary up the deflated variable.*/
local flavor GDPDEF 
use `in_price_data', clear

gen badj_GDP=badj/fGDP

gen markin=1
replace markin=0 if fishing_year==2012 & stock=="GBE Cod"
*replace markin=0 if stockname=="GBW_haddock"
local ifconditional 
local ifconditional "if markin==1"


bysort stock: egen mb=median(badj)
graph box badj_GDP, over(stock, label(angle(45)) sort(mb))  ytitle("Real Quota Price")
graph export "${my_images}/descriptive/box_quota_prices_over_stock.png", as(png) replace width(2000)

graph box live_priceGDP, over(stock, label(angle(45)) sort(mb)) ytitle("Real Live Price")
graph export "${my_images}/descriptive/box_output_prices_over_stock.png", as(png) replace width(2000)



graph box yearly_utilization if q_fy==1, over(stock, label(angle(45)) sort(mb)) ytitle("Utilization Rate(%)")
graph export "${my_images}/descriptive/box_util_over_stock.png", as(png) replace width(2000)

graph box acl_change  if q_fy==1, over(stock, label(angle(45)) sort(mb)) ytitle("Year-on-Year change in ACL")
graph export "${my_images}/descriptive/box_aclchange_over_stock.png", as(png) replace width(2000)

graph box acl_change  if q_fy==1, nooutsides over(stock, label(angle(45)) sort(mb))  ytitle("Year-on-Year change in ACL")
graph export "${my_images}/descriptive/boxnoout_aclchange_over_stock.png", as(png) replace width(2000)


/*****************************************************/
/********************Yearly utilization *********************/
/*****************************************************/
/* utilization rates are correlated over time */
tsset
scatter yearly_utilization l4.yearly_utilization if q_fy==1
graph export "${my_images}/descriptive/utilization_lag_scatter.png", as(png) replace width(2000)





xtline badj_GDP, ytitle("Quota price")
graph export "${my_images}/descriptive/panel_quota_price_full.png", as(png) replace width(2000)



xtline badj_GDP if inlist(stockcode,4,5,12,13)==0, ytitle("Quota price")
graph export "${my_images}/descriptive/panel_quota_price_subs.png", as(png) replace width(2000)




log close
