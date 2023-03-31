version 15.1
#delimit cr

*local acl_data ${data_external}/annual_acls_${vintage_string}.dta
local acl_data  $data_external/annual_catch_and_acl_$vintage_string.dta
local usage_data $data_external/dmis_quarterly_quota_usage_$vintage_string.dta
local outfile ${data_main}/quarterly_quota_available_$vintage_string.dta

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
sort stockcode fishing_year q_fy
egen id=group(stockcode fishing_year)

xtset id q_fy

rename cumulative cumul_quota_use_EOQ
gen cumul_quota_use_BOQ=l1.cumul_quota_use_EOQ

replace cumul_quota_use_BOQ=0 if q_fy==1 & cumul_quota_use_BOQ==.


gen quota_remaining_EOQ=sector_live_pounds-cumul_quota_use_EOQ
gen quota_remaining_BOQ=l1.quota_remaining_EOQ

replace quota_remaining_BOQ=sector_live_pounds if q_fy==1 & quota_remaining_BOQ==.

gen fraction_remaining_EOQ=quota_remaining_EOQ/sector_live_pounds
gen fraction_remaining_BOQ=quota_remaining_BOQ/sector_live_pounds

gen fraction_used_EOQ=cumul_quota_use_EOQ/sector_live_pounds
gen fraction_used_BOQ=cumul_quota_use_BOQ/sector_live_pounds


keep stockcode quarterly fishing_year quota_remaining_EOQ quota_remaining_BOQ fraction_remaining_EOQ fraction_remaining_BOQ cumul_quota_use_EOQ cumul_quota_use_BOQ fraction_used_EOQ fraction_used_BOQ


label var cumul_quota_use_EOQ "Cumulative Quota used at the end of the quarter, pounds"
label var cumul_quota_use_BOQ  "Cumulative Quota used at the beginning of the quarter, pounds"
label var quota_remaining_EOQ  "Quota remaining at the end of the quarter, pounds"
label var quota_remaining_BOQ  "Quota remaining at the beginning of the quarter, pounds"
label var fraction_remaining_EOQ  "Fraction of Quota remaining at the end of the quarter, pounds"
label var fraction_remaining_BOQ "Fraction of Quota remaining at the beginning of the quarter, pounds"

label var fraction_used_EOQ "Fraction of Quota Used at the end of the quarter, pounds"
label var fraction_used_BOQ "Fraction of Quota Used at the beginning of the quarter, pounds"

save  `outfile', replace
