version 15.1
#delimit cr

local acl_data ${data_external}/annual_acls_${vintage_string}.dta
local acl_data  $data_external/annual_catch_and_acl_$vintage_string.dta
local usage_data ${data_external}/dmis_monthly_quota_usage_${vintage_string}.dta
local outfile ${data_main}/monthly_quota_available_$vintage_string.dta

use `acl_data', replace
cap drop sector_livemt_catch
gen sector_live_pounds=sector_livemt*2204.62

keep fishing_year stockcode stock sector_live_pounds
tempfile quota_pounds
save `quota_pounds', replace


use `usage_data'
drop if fishing_year<=2008
replace stockcode=103 if strmatch(stock_id,"FLGMGBSS")
qui summ fishing_year
local maxyr=`r(max)'
/* mismatches 
1. DMIS is updated through May/June 2019 -- but I only have 
starting quota quota data through 2018. 
2. GBE and GBW cod and haddock are unresolved
	right now, I'm coding quotas as GBE
	usage is coded as GBE and GBW.
*/


merge m:1 stockcode fishing_year using `quota_pounds'
drop if fishing_year>`maxyr'
assert inlist(stockcode,98,99)| fishing_year==2009 if _merge==2
assert inlist(stockcode,98,99)==0 if _merge==3


drop if _merge==2
drop _merge
sort stockcode fishing_year month_of_fy
egen id=group(stockcode fishing_year)

xtset id month

rename cumulative cumul_quota_use_EOM
gen cumul_quota_use_BOM=l1.cumul_quota_use_EOM

replace cumul_quota_use_BOM=0 if month_of_fy==1 & cumul_quota_use_BOM==.


gen quota_remaining_EOM=sector_live_pounds-cumul_quota_use_EOM
gen quota_remaining_BOM=l1.quota_remaining_EOM
replace quota_remaining_BOM=sector_live_pounds if month_of_fy==1 & quota_remaining_BOM==.
gen fraction_remaining_EOM=quota_remaining_EOM/sector_live_pounds
gen fraction_remaining_BOM=quota_remaining_BOM/sector_live_pounds

gen fraction_used_EOM=cumul_quota_use_EOM/sector_live_pounds
gen fraction_used_BOM=cumul_quota_use_BOM/sector_live_pounds


drop id sector_live_pounds

keep stockcode fishing_year trip_monthly_date quota_remaining_EOM quota_remaining_BOM fraction_remaining_EOM fraction_remaining_BOM cumul_quota_use_EOM cumul_quota_use_BOM fraction_used_EOM fraction_used_BOM

label var cumul_quota_use_EOM "Cumulative Quota used at the end of the month, pounds"
label var cumul_quota_use_BOM  "Cumulative Quota used at the beginning of the month, pounds"
label var quota_remaining_EOM  "Quota remaining at the end of the month, pounds"
label var quota_remaining_BOM  "Quota remaining at the beginning of the month, pounds"
label var fraction_remaining_EOM  "Fraction of Quota remaining at the end of the month, pounds"
label var fraction_remaining_BOM "Fraction of Quota remaining at the beginning of the month, pounds"

label var fraction_used_EOM "Fraction of Quota Used at the end of the month, pounds"
label var fraction_used_BOM "Fraction of Quota Used at the beginning of the month, pounds"


save  `outfile', replace
