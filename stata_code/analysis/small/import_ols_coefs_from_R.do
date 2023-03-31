/* read in the dta constructed by R 
Replace some prices with those from Stata
*/
local inPrices "${data_main}/inter_prices_qtr_${vintage_string}.dta" 

local joined_prices "${data_main}/inter_qtr_both_${vintage_string}.dta"

local stockcodes "${data_main}/stock_codes_${vintage_string}.dta"

local biod $data_main/quarterly_prices_deflators_and_biological_$vintage_string.dta 

local savefile "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"


use `inPrices', clear
/*Prices (b's) are non-negative by construction. 0 is on the boundary of the parameter space, which is slightly difficult for testing purposes.

	But, I'm going to ignore this and state 
	H0: b=0
	HA: b>0
	One tail test. If I want the tail to have 
	
	5%, I need to use z=1.645
	2.5%	z=1.96
	1% 2.33
	.5% 2.58
	

	need to think about this. There are stocks with price at or near 0. There are other stocks that have so few trades that we can't actually estimate anything (like with a price =1 )
	*/
	
drop std_error t_value pval rlmValue rlmstd rlmt_value rlm_r2 rlm_n date
rename Estimate b
rename WhiteSE se
gen dateq=yq(fy,q_fy)
format dateq %tq
decode var, gen(stockcode1)
egen stockcode=sieve(stockcode1), char(0123456789)
destring stockcode, replace

replace stockcode=9999 if stockcode1=="(Intercept)"
replace stockcode=1818 if stockcode1=="inter2"

drop stockcode1



merge m:1 stockcode using `stockcodes', keep(1 3)
assert _merge==3 | inlist(stockcode,9999,1818)
drop _merge
drop var stock_name

replace stock="Interaction" if stockcode==1818
replace stock="Intercept" if stockcode==9999

labmask stockcode, values(stock)


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







merge 1:1 dateq fy q_fy stockcode using `joined_prices'
rename _merge _mergeRStata



/* these are some final data cleaning for coefs that don't make sense 
1. Chad had some redfish with odd prices. I'm not seeing that. 
2. Chad had some pollock with odd high prices.  I'm seeing 3 observations with prices less than zero, but nothing particularly high.
3. Chad had some GBE Cod with odd high prices.  I'm seeing 3 prices higher than $2.45.  I'm not sure if these are wrong  I'm going to leave them.
4. The GBE and GBW haddock always have price=0. There's a obs where they are estimated very imprecisely.
*/

rename dateq quarterly 
rename fy fishing_year
merge 1:1 stockcode fishing_year quarterly using `biod'
/*I have some mis-merges
1 - interaction, intercept, and recent data where we don't have survey/dmis ready FY2020)
2 - pre 2009 */
rename  quarterly dateq
rename _merge merge_biod
notes merge_biod: ==1 these are for the interaction, intercept, or FY2020
notes merge_biod: ==2 for 2009, where we don't have quota prices.
compress
*drop if fishing_year<=2009



/*swap in the cooksd prices for FY2012, Q4 */
/* 0 back up the b, r2, n , se, z badj 
1 Replace the b, r2, n se z, badj with corresponding cookds values for 2012, q4 */
foreach var of varlist b r2 n se badj z {
   
  clonevar `var'_old=`var'
  replace `var'=`var'_cooksd if fishing_year==2012 & q_fy==4

}

notes: b and badj is are nominal prices with the 2012Q4 substitution.
notes: b_replic and badj_replic are in real2010Q1 prices.
















save `savefile', replace
