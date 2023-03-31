/* Code to estimate yearly non-linear hedonic models for ACE Prices.

this code is pretty janky. Even though the base specification is the same for all years, each year is different and I have to look at all the years individually.*/
/* I'm going to use 5% one tailed that happens to be P=0.10 as my criteria for a cutoff to test down */

/************************************/
/************************************/
/* You have to hand edit the file NLS_by_year.tex 
to remove the extra lines corresponding to the "equation name" from NLS.
*/
/************************************/
/************************************/
#delimit cr
version 15.1
pause off
mat drop _all
est drop _all
local logfile "${my_results}/explore2013.smcl" 
cap log close 
log using `logfile', replace

*local quota_available_indices "${data_intermediate}/quota_available_indices_${vintage_string}.dta"
local in_price_data "${data_intermediate}/cleaned_quota.dta" 



/* changing the flavor to GDPDEF, water, or seafood will vary up the deflated variable.*/
local flavor GDPDEF 

local NLS_out ${my_tables}/NLS_by_year.tex
local estout_relabel "b_SNEMA_winter:_cons SNEMA_winter b_CCGOM_yellowtail:_cons CCGOM_Yellowtail b_GBE_cod:_cons GBE_Cod b_GBW_cod:_cons GBW_Cod b_GBE_haddock:_cons GBE_Haddock b_GBW_haddock:_cons GBW_Haddock b_GB_winter:_cons GB_Winter b_GB_yellowtail:_cons GB_Yellowtail b_GOM_cod:_cons GOM_Cod b_GOM_haddock:_cons GOM_Haddock b_GOM_winter:_cons GOM_Winter b_plaice:_cons Plaice b_pollock:_cons Pollock b_redfish:_cons Redfish b_SNEMA_yellowtail:_cons SNEMA_Yellowtail b_white_hake:_cons White_hake b_witch_flounder:_cons Witch b_q1:_cons Q1 b_q2:_cons Q2 b_q3:_cons Q3 b_q4:_cons Q4 b_interaction:_cons interaction b_cons:_cons Constant"
local estout_opts "replace style(tex) starlevels(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(2))) stats(r2 rmse aic bic) varlabels(`estout_relabel') mlabels(2010 2011 2012 2013 2014 2015 2016 2017 2018 2019)  substitute(_ \_) "

*local out_coefficients "${my_results}/nls_least_squares_quarterly_`flavor'${vintage_string}.dta" 

vintage_lookup_and_reset




/* small program to initialize each year */
capture program drop year_initialize
program year_initialize

	est replay nls`1'
	cap drop markin
	gen markin=.
	replace markin=1 if fy==`1'

end

/* small program to adjust totalpounds*/

capture program drop novalue_subtractor
program novalue_subtractor
	local i = 2
	while "``i''" != "" {
	di "``i''"
	replace totalpounds2=totalpounds2-``i'' if fy==`1'
	local ++i
	}
 replace lease_only_pounds2=lease_only_sector*totalpounds2 
end 


use `in_price_data', clear
do "${analysis_code}/small/final_dataclean.do"








/* Positive trades by fy */
preserve

foreach var of varlist CCGOM_yellowtail-SNEMA_winter{
replace `var'=`var'>1
rename `var' trades_`var'
}
collapse (sum) trades* , by(fy q_fy)
reshape long trades_ ,i(fy q_fy) j(stockname) string
rename trades_ trades_Q
reshape wide trades, i(fy stockname) j(q_fy)
tempfile trades
save `trades'

restore




/* set up tempfiles to store statsby results */
tempfile s2010 s2011 s2012 s2013 s2014 s2015 s2016 s2017 s2018 s2019


/* OLS and NLS models with ALL coefficients */


/* Pooled regression */
local rhs CCGOM_yellowtail GBE_cod GBW_cod GBE_haddock GBW_haddock GB_winter GB_yellowtail GOM_cod GOM_haddock GOM_winter plaice pollock redfish  SNEMA_yellowtail  white_hake witch_flounder SNEMA_winter

/* OLS where there is a quarterly per-pound discount (cents) that changes every quarter  */
	  /* this isn't good because it forces the stocks with near zero values to get discounted */

qui forvalues yr =2010(1)2019{
	di "estimating unconstrained OLS for year `yr'"
	regress compensationR_`flavor' `rhs' i1.lease_only_sector#c.total_lbs if fy==`yr'
	
	est store ols`yr'
	
	predict lev`yr' if e(sample), leverage

	nl (compensationR_`flavor' = {b: `rhs'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2  + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)
	est store nls`yr'
 }
 
 
 
 
 
 
 
  
 /* regress by quarter */
 
 
 
 qui forvalues quarter =212(1)215{
 regress compensationR_`flavor' `rhs' i1.lease_only_sector#c.total_lbs if fyq==`quarter'
est store ols`quarter'
}
 
  
 capture program drop novalue_subtractor2
program novalue_subtractor2
	local i = 2
	while "``i''" != "" {
	di "``i''"
	replace totalpounds2=totalpounds2-``i'' if fyq==`1'
	local ++i
	}
 replace lease_only_pounds2=lease_only_sector*totalpounds2 
end 

capture program drop year_initialize2
program year_initialize2

	est replay ols`1'
	cap drop markin
	gen markin=.
	replace markin=1 if fyq==`1'

end
est table ols21*




 
 local yr 212
 
 
 year_initialize2 `yr'
local rhs2 `rhs'



local zero GBE_haddock  GBW_haddock
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 




local zero SNEMA_yellowtail redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 


local zero GOM_winter
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 
est store ols`yr'tested




 
 local yr 213
 
 
 year_initialize2 `yr'
local rhs2 `rhs'





local zero   GBW_haddock GOM_winter redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 



local zero   GBE_haddock
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 

local zero   GBE_cod
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 
est store ols`yr'tested



 local yr 214
 
 
 year_initialize2 `yr'
local rhs2 `rhs'

local zero   GBE_cod GOM_winter redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 


local zero   pollock
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 



local zero   GBE_haddock GBW_haddock GB_winter GB_yellowtail white_hake
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 
est store ols`yr'tested




 local yr 215
 
 
 year_initialize2 `yr'
local rhs2 `rhs'

local zero   GBE_cod redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 


local zero   white_hake GOM_winter
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 

local zero   GBE_haddock GBW_haddock
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 

local zero   GB_winter
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fyq==`yr', robust 
est store ols`yr'tested


 /*
  
/****************************************************************/
/****************************************************************/
/**********************2013 *************************************/
/****************************************************************/
/****************************************************************/

  
/****************************************************************/
/****************************************************************/
/**********************2013 *************************************/
/****************************************************************/
/****************************************************************/

local yr 2013

year_initialize `yr'
local rhs2 `rhs'


local zero GBE_haddock  
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'

regress compensationR_`flavor' `rhs2'  lease_only_pounds2 if fy==`yr', robust 


nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4) + {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)




local zero redfish
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'


nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)






local zero GOM_winter
local rhs2: list rhs2-zero 
novalue_subtractor `yr' `zero'


nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_interaction}*lease_only_pounds2 + {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)



estimates title: Model A
est store refined_nl`yr'
estimates title: Model A
est store refined_nl`yr'
*est save $compare2013, replace

*statsby _b _se, by(markin) saving(`s2013', replace)  :  nl (compensationR_`flavor' = {b: `rhs2'}*(1+{b_q2}*qtr2+{b_q3}*qtr3 + {b_q4}*qtr4)+ {b_cons}*cons) if fy==`yr', vce(robust)	hasconstant(b_cons)


  /* 2013,  I'm getting a small negative price for GOM winter -- actual -$0.40, I'm going to just constrain it to zero. 
  While there are 30ish trades with GOM winter in it, most  have many many things going on. I think it's just those trades had bad bargaining.
  
*/


/*
https://www.stata.com/support/faqs/statistics/one-sided-tests-for-coefficients/
 In the special case where you are interested in testing whether a coefficient is greater than, less than, or equal to zero, you can calculate the p-values directly from the regression output. When the estimated coefficient is positive, as for weight, you can do so as follows:
H0: βweight = 0 	p-value = 0.008 (given in regression output)
H0: βweight <= 0 	p-value = 0.008/2 = 0.004
H0: βweight >= 0 	p-value = 1 − (0.008/2) = 0.996

When the estimated coefficient is negative, as for mpg, the same code can be used: 

*/
*/
log close
