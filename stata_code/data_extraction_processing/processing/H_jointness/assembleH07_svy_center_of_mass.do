version 15.1
#delimit cr
clear
local FSCS_SVBIO "${data_raw}/svdbs/UNION_FSCS_SVBIO_${vintage_string}.dta"
local FSCS_SVCATmFSCS_SVSTA  "${data_main}/FSCS_CAT_SVSTA${vintage_string}.dta"
local minimum_sizes "${data_main}/minimum_sizes_svspp_${vintage_string}.dta"
local stockareas "${data_main}/stock_area_definitions_${vintage_string}.dta"
local stockcodebook "${data_main}/stock_codes_${vintage_string}.dta"
local itis_svspp_nespp3  "${data_main}/its_svdbs_merge_cleaned_${vintage_string}.dta"
local dmis_composition "$data_external/dmis_yearly_nespp4_composition_$vintage_string.dta" 
local cruises  "${data_raw}/svdbs/cruises_${vintage_string}.dta"

global cm_to_inches 0.3937007874

local required_survey ${data_main}/required_stocks_with_survey_${vintage_string}.dta
/* the minimum sizes dataset contains the useful species codes (SVSPP,NESPP, ITIS_TSN). For a jointness index without a size filter, we can just need 1 row per species. */





/***************************PART A********************************/
/*1.Get the live pounds and value from DMIS.  Keep the rows that meet our filter.  Recompute a weighting*/
use `dmis_composition', replace

destring nespp3, replace
do "${processing_code}/extractA01a_rebin_nespp3.do"
/*composite skates */
replace nespp3=365 if inlist(nespp3,364,365,366,367,368,369,370,372,373,377,378)
collapse (sum) landed pounds dlr_live dlr_landed dlr_dollar dollar_ssb, by(mult_year nespp3)
bysort mult_year: egen tp=total(pounds)
gen pfrac=pounds/tp
bysort mult_year: egen td=total(dlr_dollar)
gen dfrac=dlr_dollar/td
drop tp td
gen pkeep=pfrac>=.01
gen dkeep=dfrac>=.01



keep if pkeep==1 | dkeep==1 

bysort mult_year: egen tp=total(pounds)
bysort mult_year: egen td=total(dlr_dollar)

gen dollar_factor=dlr_dollar/td
gen pound_factor=pounds/tp
drop tp td
keep mult_year nespp3 dollar_factor pound_factor
rename mult_year fishing_year
gen stockcode=999
gen stock_id="OTHER"
tempfile other_composition
save `other_composition', replace




/* 2. Merge the survey data to the output of 1  */

use `FSCS_SVCATmFSCS_SVSTA', replace
merge m:1 svspp using `itis_svspp_nespp3', keep(1 3)
drop if fishing_year<=2008
drop _merge
merge m:1 fishing_year nespp3 using `other_composition'
drop if fishing_year<=2008
keep if _merge==3
gen expcatchwt_dollar=expcatchwt*dollar_factor
gen expcatchnum_dollar=expcatchnum*dollar_factor

gen expcatchwt_pound=expcatchwt*pound_factor
gen expcatchnum_pound=expcatchnum*pound_factor

collapse (sum) expcatchnum expcatchwt expcatchwt_dollar expcatchnum_dollar expcatchwt_pound expcatchnum_pound, by(cruise6 tow stratum station fishing_year stockcode stock_id beglat beglon endlat endlon)
clonevar OG_expcatchnum=expcatchnum
clonevar OG_expcatchwt=expcatchwt


tempfile other_survey
save `other_survey', replace














/***********************PART B - groundfish******************/


/*3. Get the stock codes, stock_id, nespp3, svspp, and itisspp*/

use `minimum_sizes', clear 
keep stock_id stockcode stock nespp3 svspp itisspp
duplicates drop
tempfile gf
save `gf', replace


/*4.  get the dataset of stockcode, stockarea, and statistical areas and merge it to the nespp3, svspp, itisspp keys*/
use `stockareas', clear
keep if stockmarker==1
rename stockcode stock_id

egen stockcode=sieve(code), char(0123456789.)
drop species stockarea code 
destring stockcode, replace
drop if stockcode==999

merge m:1 stockcode stock_id using `gf'
drop if _merge==2
drop _merge
tempfile working_stock_areas
save `working_stock_areas'

/* 5.  merge the survey catch to the stockareas definitions from 4 */
use `FSCS_SVCATmFSCS_SVSTA', replace
merge m:1 svspp statarea using `working_stock_areas'
/*  merge=1 = not a groundfish, or a groundfish not caught in the US stockareas. We drop these safely.
merge=2 indicates the BT never caught any fish in those stock areas */

drop if _merge==1




/* 7. Drop some variables and unmatched merges.  Drop some rows. And save the groundfish data */
drop if _merge==2
drop _merge


/* 8.  stack on the "non groundfish" data */
append using `other_survey'

keep cruise6 tow stratum station svspp expcatchnum expcatchwt stock_id stockcode stock nespp3 itisspp fishing_year beglat beglon endlat endlon
drop if fishing_year<=2008

/* fill in begin or end if one is missing */
replace beglat=endlat if beglat==.
replace beglon=endlon if beglon==.
replace endlat =beglat if endlat==.
replace endlon=beglon if endlon==.

/* drop if both are missing */
count if beglat==.
drop if beglat==.

/* convert lat-lon format to degrees 
Format is DDMM.MMM

It's pretty good data, so we can just do floor and mod
cruise6	tow	stratum	station
201202	1	01260	341
*/


foreach var of varlist beglat beglon endlat endlon{
replace `var'=floor(`var'/100) + mod(`var',100)/60
}
gen lat=(beglat+endlat)/2
gen lon=(beglon+endlon)/2
preserve
collapse (mean) lat=lat lon=lon [iw=expcatchwt], by(fishing_year stock_id stockcode itisspp nespp3 stock)
replace lon =lon*-1
save "${data_main}/survey_yearly_center_of_mass_${vintage_string}.dta", replace


restore
keep if fishing_year>=2010 & fishing_year<=2019
collapse (mean) lat=lat lon=lon [iw=expcatchwt], by(stock_id stockcode itisspp nespp3 stock)
replace lon =lon*-1
save "${data_main}/survey_center_of_mass_${vintage_string}.dta", replace

