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
/****************************************************************/
/***********************PART A - Non-groundfish******************/
/* Define the "other" group as species that make up at least 1% of the aggregate non-Groundfish activity by our fleet (by either pounds or value) in each year
Nominal values are fine 
It's a little endogenous. But we need to filter out the species and stocks that don't matter
1.Get the live pounds and value from DMIS.  Keep the rows that meet our filter.  Recompute a weighting
2. Merge the survey data to the output of 1 */
/****************************************************************/
/****************************************************************/


/***********************PART B - groundfish******************/
/*************************************************************/
/*
3.  Get the stock codes, stock_id, nespp3, svspp, and itisspp
4.  get the dataset of stockcode, stockarea, and statistical areas and merge it to the nespp3, svspp, itisspp keys
5.  merge the survey catch to the stockareas definitions from 4 
6.  We could make another overlap indicator by adjusting the indicator variable to be zero if a species was never caught by the BT (2009-2020) in that area 
7.  Drop some variables and unmatched merges.  Drop some rows. And save the groundfish data 
8.  stack on the "non groundfish" data 

*/




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

collapse (sum) expcatchnum expcatchwt expcatchwt_dollar expcatchnum_dollar expcatchwt_pound expcatchnum_pound, by(cruise6 tow stratum station fishing_year stockcode stock_id)

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

preserve
/* 6. we could make another overlap indicator by adjusting the indicator variable to be zero if a species was never caught by the BT (2009-2020) in that area */
keep svspp statarea stock_id stockmarker  area_km2 stockcode stock _merge
duplicates drop
bysort stockcode statarea: assert _N==1
gen stockmarker_survey=stockmarker
replace stockmarker_survey=0 if _merge==2
drop _merge

gen area_km2_survey=stockmarker_survey*area_km2
notes drop _dta in 2/6
notes renumber _dta
notes statarea: statistical areas corresponding to a stock 
notes stockmarker: ==1 for all rows
notes stockmarker_survey: ==1 if a species was caught in the statarea during the 2009-2020 period 
notes area_km2: square km inside that statarea IN the US water 
notes area_km2_survey: area_km2*stockmarker_survey
notes stockcode: Chad's numeric for stock codes
notes stock_id: DMIS code for stock
save `required_survey', replace
restore


/* 7. Drop some variables and unmatched merges.  Drop some rows. And save the groundfish data */
drop if _merge==2
drop _merge


keep cruise6 tow stratum station svspp expcatchnum expcatchwt stock_id stockcode stock nespp3 itisspp fishing_year

drop if fishing_year<=2008


/* 8.  stack on the "non groundfish" data */
append using `other_survey'

/* done to here */
/* need to recode different ways to count the other 
replace expcatchnum=expcatchnum_dollar if stockcode==999
replace expcatchwt=expcatchwt_dollar if stockcode==999
*/







/* FK for expcatchnum */

preserve
bysort fishing_year stockcode: egen tnum=total(expcatchnum)
gen q_num_=expcatchnum/tnum

levelsof stockcode, local (mystockcodes)
global stocksave `mystockcodes'


keep cruise6 tow stratum station fishing_year stockcode q_num_*
reshape wide q_num_, i(cruise6 tow stratum station fishing_year) j(stockcode)


foreach var of varlist q_num_*{
	replace `var'=0 if `var'==.
}


foreach A of local mystockcodes{
	local working:  list mystockcodes - A
		foreach B of local working{
			gen Fk_surveynum_`A'x`B'=min(q_num_`A',q_num_`B')
	}
}


collapse (sum) Fk_surveynum_*, by(fishing_year)
reshape long Fk_surveynum_, i(fishing_year) j(stock) string
split stock, gen(stock) parse("x")
destring stock1 stock2, replace
rename Fk_surveynum_ Fk_surveynum

gen Ru_surveynum=1-Fk_surveynum/(2-Fk_surveynum)



compress
drop stock
tempfile Fk_surveynums
save `Fk_surveynums', replace
restore



/* FK for expcatchnum */


bysort fishing_year stockcode: egen tw=total(expcatchwt)
gen q_wt_=expcatchwt/tw

levelsof stockcode, local (mystockcodes)
global stocksave `mystockcodes'


keep cruise6 tow stratum station fishing_year stockcode q_wt_*

reshape wide q_wt_, i(cruise6 tow stratum station fishing_year) j(stockcode)


foreach var of varlist q_wt_*{
	replace `var'=0 if `var'==.
}


foreach A of local mystockcodes{
	local working:  list mystockcodes - A
		foreach B of local working{
			gen Fk_surveywt_`A'x`B'=min(q_wt_`A',q_wt_`B')
	}
}


collapse (sum) Fk_surveywt_*, by(fishing_year)
reshape long Fk_surveywt_, i(fishing_year) j(stock) string
split stock, gen(stock) parse("x")
destring stock1 stock2, replace
rename Fk_surveywt Fk_surveywt

gen Ru_surveywt=1-Fk_surveywt/(2-Fk_surveywt)

compress
drop stock


merge 1:1 fishing_year stock1 stock2 using `Fk_surveynums'
assert _merge==3
drop _merge

/* bring in the stock names from the stock_codes dataset and label the stock1 variable */
rename stock1 stockcode
merge m:1 stockcode using "${data_main}/stock_codes_${vintage_string}.dta"

assert _merge==3 | (_merge==2 & stockcode==999)
drop _merge
/* There are some _merge==2 because I don't have stockarea definitions. Right now, this is just OTHER
drop _merge */






replace stock="Non-Groundfish" if stockcode==999
labmask stockcode, values(stock)
rename stockcode stock1

drop stock nespp3 stockarea stock_id


/* apply the same labels to stock2 */
label values stock2 stockcode
 rename Fk_surveynum FK_surveynum
 rename Fk_surveywt FK_surveywt
order fishing_year stock1 stock2 FK*
sort stock1 stock2 fishing_year
notes FK_surveynum : Finger-Kreinen computed on survey numbers
notes FK_surveywt : Finger-Kreinen computed on survey kg




notes Ru_surveynum: Ruzicka distance metric 1-(FK/2FK) computed on survey numbers
notes Ru_surveywt: Ruzicka distance metric 1-(FK/2FK) computed survey kg
save "${data_main}/overlap_indices_survey_nofilter_${vintage_string}.dta", replace

gen first=cond(stock1<stock2, stock1,stock2)
gen second=cond(stock1<stock2,stock2,stock1)
label values first second stockcode
egen id=group(first second)
bysort id fishing_year: keep if _n==1

drop stock1 stock2
rename first stock1
rename second stock2
compress
order id stock1 stock2 fishing_year
sort id fishing_year
tsset id fishing_year
save "${data_main}/overlap_indices_survey_nofilter_dyadic_${vintage_string}.dta", replace


