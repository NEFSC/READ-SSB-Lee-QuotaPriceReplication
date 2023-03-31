/* code to construct spatial weights matrices from the distance datasets */


#delimit cr
version 15.1
pause on
/* this has prices and all the relevant RHS variables */
local pricefile "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"

local overlap_dataset "${data_main}/overlap_indices_${vintage_string}.dta"
local overlap_survey1_dataset "${data_main}/overlap_indices_survey_nofilter_${vintage_string}.dta"

local savefile "${data_main}/distance_matrices_${vintage_string}.dta"


use `overlap_dataset', clear

label define stockcode 999 "Non-Groundfish", modify
merge 1:1 stock1 stock2 fishing_year using `overlap_survey1_dataset'
/* note: the fishing based overlaps have data for 2007-2020. The survey has 2009-2019. Survey also doesn't have non-groundfish yet. So we expect _merge==1 <--> fy 2007 or fy2008  */

assert _merge==1 if inlist(fishing_year,2007,2008)
keep if fishing_year>=2009
drop _merge



/* final tidy ups */
/* 1.  drop the non-allocated stocks*/
drop if inlist(stock1,101,102,103,104,105)
drop if inlist(stock2,101,102,103,104,105)

/* drop out Ru_discard */
drop Ru_discard

keep fishing_year stock1 stock2 Ru*

/* When I constructed the data, I did not construct Ru for stock1==stock2*/
count if stock1==stock2
assert r(N)==0

/* So, we need to create an extra observation and fill it stock1=stock2 and Ru*=1 */

bysort fishing_year stock1: gen marker=_n==1
expand 2 if marker==1, gen(mymark)
foreach var of varlist  Ru_pounds Ru_revenue Ru_charged Ru_surveywt Ru_surveynum{
	replace `var'=1 if mymark==1
}
replace stock2=stock1 if mymark==1

foreach var of varlist  Ru_pounds Ru_revenue Ru_charged Ru_surveywt Ru_surveynum{
	assert `var'==1 if mymark==1
}

drop marker mymark

rename Ru_pounds Ru_land
rename Ru_revenue Ru_rev
rename Ru_charged Ru_catch
rename Ru_surveywt Ru_swt
rename Ru_surveynum Ru_snum



/* regression dataset has stockcode, fishing_year, quarter, and a bunch of stuff */

/* make the Nearest 1 and 2 neighbors */
foreach wvar in land rev catch swt snum{
	bysort stock1 fishing_year (Ru_`wvar'):  gen NN1_`wvar'=_n==1
	bysort stock1 fishing_year (Ru_`wvar'):  gen NN2_`wvar'=_n<=2
	assert stock1~=stock2 if NN1_`wvar'==1  & fishing_year<=2019
	assert stock1~=stock2 if NN2_`wvar'==1   & fishing_year<=2019
}

/*  Make Inverse distance and inverse distance squared.  
	Set the "inverse distance" to zero for own-stocks. 
	Set ID to 0 for anything containing SNEMA Winter before 2012. 
	Row normalized ID ID2.  Probably also need spectral normalized
*/
foreach wvar in land rev catch swt snum{
	gen ID_`wvar'=1/Ru_`wvar'
	replace ID_`wvar'=0 if stock1==stock2
	replace ID_`wvar'=0 if stock1==17 & fishing_year<=2012
	replace ID_`wvar'=0 if stock2==17 & fishing_year<=2012

	gen ID2_`wvar'=1/(Ru_`wvar')^2
	replace ID2_`wvar'=0 if stock1==stock2
	replace ID2_`wvar'=0 if stock1==17 & fishing_year<=2012
	replace ID2_`wvar'=0 if stock2==17 & fishing_year<=2012

}


compress
notes: The 2020 bottom trawl survey shouldn't be used there was only 1 cruise6 (202002) and it wasn't comprehensive (COVID).
save `savefile', replace
/* note:  

*/

