local itis "${data_raw}/itis_lookup_${vintage_string}.dta"
local svdbs_itis "${data_raw}/svdbs/svdbs_itis_lookup_${vintage_string}.dta"
local output  "${data_main}/its_svdbs_merge_cleaned_${vintage_string}.dta"


/*Merge nespp3 to itis codes*/

use `itis', clear
drop if inlist(itisspp,160845, 160848)
drop if nespp3==526 & itisspp==161989
replace nespp3=365 if inlist(nespp3,364,365,366,367,368,369,370,372,373,377,378)
do "${processing_code}/extractA01a_rebin_nespp3.do"
duplicates drop itisspp nespp3, force
merge m:1 itisspp using `svdbs_itis', keep(3)
assert _merge==3
drop _merge
destring svspp, replace
save `output', replace
