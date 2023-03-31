
/************************************/
/************************************/
#delimit cr
version 15.1
mat drop _all
est drop _all


/* location of nominal prices */
local nominal_stata "${data_main}/inter_qtr_v2_nom_${vintage_string}.dta"
/* location of real prices */
local real_prices "${data_main}/inter_qtr_v2_${vintage_string}.dta"
local joined_prices "${data_main}/inter_qtr_both_${vintage_string}.dta"

/* Stock code dataset */


/********************JOIN THE NOMINAL and REAL PRICE regression results ************************/

use `nominal_stata', clear
rename Estimate Estimate
replace modeltype=modeltype+"N"
drop model
tempfile nominals
save `nominals', replace
use `real_prices', clear
drop model


append using `nominals'

/* Get them into the same form as the data that comes from R */

gen dateq=yq(fy,q_fy)

/* keep just a subset of the models -- real and nominal for the replication and the cooksd model */
keep if inlist(modeltype,"replic", "replicN", "cookdsN", "cooksd")
pause

rename Estimate b
rename standard_error se




pause
gen z=b/se	
gen badj=b
/* price=0 if not statistically significant */
replace badj=0 if abs(z)<=1.645
/* price=0 if negative or not a quota stock.*/
replace badj=0 if badj<=0 & inlist(stockcode,1818,999)==0

/* price =0 if no price was estimated */
replace badj=0 if badj==.
/* price =0 in the first 2 quarters of 2010 -- there were no trades then. */

replace badj=. if dateq<=yq(2010,2)

/*set badj to missing for SNE/MA winter flounder prior to FY2012 */
replace badj=. if dateq<yq(2012,1) & stockcode==17


keep fyq fy q_fy stockcode b se badj r2 n modeltype z

foreach var of varlist b se badj r2 n z{
	rename `var' `var'_
}

pause

reshape wide b_ se_ badj_ r2_ n_ z_, i(fyq fy q_fy stockcode) j(modeltype) string
rename fyq dateq

save `joined_prices', replace 

