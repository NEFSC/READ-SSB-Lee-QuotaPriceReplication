/*this is a do file to a make some exploratory plots

You need to switch the in data over to quarterly_estimation_dataset_{$vintage_string}

 */

cap log close

local logfile "first_stage_large_pooled_model_${vintage_string}.smcl"
log using ${my_results}/`logfile', replace


mat drop _all
est drop _all
*local quota_available_indices "${data_intermediate}/quota_available_indices_${vintage_string}.dta"
local in_price_data "${data_intermediate}/cleaned_quota_${vintage_string}.dta" 


local allstocks CCGOM_yellowtail GBE_cod GBW_cod GBE_haddock GBW_haddock GB_winter GB_yellowtail GOM_cod GOM_haddock GOM_winter plaice pollock redfish SNEMA_yellowtail white_hake witch_flounder SNEMA_winter
/* changing the flavor to GDPDEF, water, or seafood will vary up the deflated variable.*/
local flavor GDPDEF 
use `in_price_data', clear




cap drop qtr
order z1 z2 z3 z4 z5 z6 z7 z8 z9 z10 z11 z12 z13 z14 z15 z16 z17, after(to_sector_name)

drop if fy>=2020
gen lease_only_sector=inlist(from_sector_name,"NEFS 4", "Maine Sector/MPBS")
/* there's only a few obs in Q1 of FY2010 and Q2 of FY2010. I'm pooling them into Q3 of 2010.
replace q_fy=3 if q_fy<=2 & fy==2010 */
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



gen swap=0
foreach var of varlist z1_raw-z17_raw{
	replace swap=1 if `var'<0
}

gen basket=nstocks>=2
replace basket=1 if swap==1




local allstocks CCGOM_yellowtail GBE_cod GBW_cod GBE_haddock GBW_haddock GB_winter GB_yellowtail GOM_cod GOM_haddock GOM_winter plaice pollock redfish SNEMA_yellowtail white_hake witch_flounder SNEMA_winter


regress compensation (c.(`allstocks') c.lease_only_pounds)#i.fyq ibn.fyq, noconstant

log close


