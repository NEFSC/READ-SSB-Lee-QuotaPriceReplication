local minimum_sizes "${data_main}/minimum_sizes_${vintage_string}.dta"
local svdbs_itis "${data_raw}/svdbs/svdbs_itis_lookup_${vintage_string}.dta"
local itis "${data_raw}/itis_lookup_${vintage_string}.dta"

local minimum_sizes_out "${data_main}/minimum_sizes_svspp_${vintage_string}.dta"

/* this section takes the minimum size dataset and joins it to the svdbs_itis lookup (svspp + itis) through the itis lookup (nespp3 and itis) */
use `minimum_sizes', clear
summ fishing_year
local first=r(min)
local last =r(max)
local expander `last'-`first'+1

use `svdbs_itis', clear
merge 1:m itisspp using `itis'
destring svspp, replace
drop if inlist(svspp,193, 310)


*keep if nespp3~=.
rename _merge _mergeSVDBS_ITIS


replace svspp=193 if itisspp==630979 /* Ocean Pout */
replace svspp=310 if itisspp==620992 /*Deepsea red crab */
replace svspp=104 if itisspp==172783 /* Fourspot flounder*/
replace svspp=112 if itisspp==166283 /* #John Dory*/
replace svspp=36 if itisspp==161731 /* Menhaden*/


replace svspp=311 if itisspp==98671 /* Cancer Crabs unk*/
replace svspp=317 if itisspp==98455 /* Spider crabs*/
replace svspp=150 if itisspp==159772 /* Hagfish*/
replace svspp=188 if itisspp==166284 /* John Dory*/
replace svspp=714 if itisspp==98670 /* Cancer Crabs unk*/



replace comname=common_name_itis if inlist(itisspp,630979, 620992)
replace sciname=scientific_name if inlist(itisspp,630979, 620992)
replace comname=common_name_itis if comname==""
replace sciname=scientific_name_itis if sciname==""
drop common_name_itis scientific_name_itis
drop if inlist(itisspp,172783,161732,98417)

drop if svspp==.
drop if nespp3==.
duplicates drop
drop if inlist(nespp3,526,141,117,126,332,336)
drop if nespp3==326 & svspp==160
drop if nespp3==456 & svspp==820
drop if nespp3==431 & svspp==861
drop if nespp3==326 & svspp==160
drop if nespp3==526 & itisspp==161989

sort nespp3

expand `expander'
sort nespp3

egen fishing_year=fill(`first'/`last' `first'/`last')
drop _merge

tempfile svdbs
save `svdbs', replace

use `minimum_sizes', clear
sort stockcode fishing_year
gen id=_n
merge m:1 nespp3 fishing_year using `svdbs', keep(1 3)
drop _merge
destring svspp, replace
keep stock_id stockcode stock stockarea nespp3 fishing_year minimum_inches svspp itisspp sciname
/* check 1 observation per row */
bysort stock_id stockcode stock stockarea nespp3 fishing_year: assert _N==1
assert svspp~=. | stockcode==999

notes: this is a dataset with stockcode, stock_id, nespp3, stockarea, and minimum sizes 
save `minimum_sizes_out', replace
