local FSCS_SVCAT "${data_raw}/svdbs/FSCS_SVCAT_${vintage_string}.dta"
local FSCS_SVSTA  "${data_raw}/svdbs/UNION_FSCS_SVSTA_${vintage_string}.dta"
local output  "${data_main}/FSCS_CAT_SVSTA${vintage_string}.dta"


use `FSCS_SVCAT',clear
merge m:1 cruise6 tow stratum station using `FSCS_SVSTA', keep(1 3)
assert _merge==3
drop _merge
rename area statarea
gen fishing_year=floor(cruise6/100)

save `output', replace
