/* read in the dta */
/* would be nice to add commas to the formatting 
would be nice to have no decimal point, except to 2 places for the average price per pound.

local estab_opts "cells("mean(fmt(%8.0gc)) sd(fmt(%8.0gc))") label replace nogaps"

Good enough for now. I can probably just add commas later.


You need to switch the in data over to quarterly_estimation_dataset_{$vintage_string}

Note: This data here isn't exactly the estimation sample as presented in the text, because I modified the estimation sample slightly for 



/*swap in the cooksd prices for FY2012, Q4 */
/* 0 back up the b, r2, n , se, z badj 
1 Replace the b, r2, n se z, badj with corresponding cookds values for 2012, q4 */
foreach var of varlist b r2 n se badj z {
   
  clonevar `var'_old=`var'
  replace `var'=`var'_cooksd if fishing_year==2012 & q_fy==4

}

notes: b and badj is are nominal prices with the 2012Q4 substitution.
notes: b_replic and badj_replic are in real2010Q1 prices.











*/ 
local in_price_data "${data_main}/quarterly_estimation_dataset_${vintage_string}.dta"



use `in_price_data', clear
keep if fy<=2019
Zlabel_pounds

label var fy "Fishing Year"
label var compensation "Compensation (nominal)"
label var interaction "LeaseOnly*totalpounds"
label var avg_price "Average Price per Pound (nominal)"
label var lease_only "Lease-Only Seller"
label var total_lbs "Total Pounds"

order z1 z2 z3 z4 z5 z6 z7 z8 z9 z10 z11 z12 z13 z14 z15 z16 z17, after(compensation)


/* I am trying to get info on transaction volumes, so I need to fix up the negatives and convert to positives*/
foreach var of varlist z1-z17 {
	clonevar `var'_raw=`var'
	replace `var'=abs(`var')
}

cap drop total_lbs
egen total_lbs=rowtotal(z1-z17)

cap drop avg_price
gen avg_price=compensation/total_lbs
label var avg_price "Average Price per Pound (nominal)"
label var total_lbs "Total Pounds"


local stats compensation avg_price z1-z17 interaction lease_only total_lbs
local stats2 avg_price lease_only 


/* we need to format the prices and the lease_only dummy a little differently.  Can't exactly do it in one command, the best I can do is run the esttab twice and then copy/paste it in*/


/*******************************************/
/*******************************************/
/*options for making tables */
/*******************************************/
/*******************************************/

/* you haven't figure out how to get the digits right on average price and lease_only*/


qui summ avg_price
local Eprice =round(r(mean), .01)
local sdprice =round(r(sd), .01)

qui summ lease_only
local Elease_only=round(r(mean), .01)
local sdlease_only =round(r(sd), .01)


local price_line `" Average Prices is `Eprice' with sd `sdprice' "'
local lease_line `" Average Lease only is `Elease_only' with sd `sdlease_only' "'

local estpost_opts_grand "statistics(mean sd) columns(statistics) quietly"
local estab_opts_grand "cells("mean(fmt(%8.0fc)) sd(fmt(%8.0fc))") label replace nogaps nonumbers alignment(rr)"

local estab_opts_grand_small "cells("mean(fmt(%8.3fc)) sd(fmt(%9.2fc))") label replace nogaps nonumbers alignment(rr)"

estpost tabstat `stats', `estpost_opts_grand'
esttab .,   `estab_opts_grand'  addnotes("`price_line'" "`lease_line'")
esttab . using ${my_tables}/first_stage_averages_ES.tex, `estab_opts_grand' addnotes("`price_line'" "`lease_line'")



estpost tabstat `stats2', `estpost_opts_grand'
esttab .,   `estab_opts_grand_small'
esttab . using ${my_tables}/first_stage_averages_pr_inter_ES.tex, `estab_opts_grand_small'



/* summary statistics by year */ 



/*******************************************/
/*******************************************/
/*options for the "by" set of statistics */
/*******************************************/
/*******************************************/
local  estpost_opts_by "statistics(mean sd) columns(statistics) listwise nototal quietly"
local  estpost_opts_by "statistics(mean sd) columns(statistics)  nototal quietly"

local estab_opts_by "main(mean %8.2gc ) aux(sd %8.2gc) nostar noobs nonote label replace nogaps nonumbers unstack alignment(r)"

local estab_opts_by_small "main(mean %03.2f) aux(sd %03.2f) nostar noobs nonote label replace nogaps nonumbers unstack alignment(r)"



/* count up observations */
gen mark=1
bysort fy: egen transactions=total(mark)
label var transactions "Transactions"




estpost tabstat `stats' transactions, by(fy)  `estpost_opts_by'

/* look at it */	
esttab .,  `estab_opts_by'

esttab . using ${my_tables}/first_stage_averages_by_yr_ES.tex,`estab_opts_by' 


estpost tabstat `stats2' , by(fy)  `estpost_opts_by'
/* look at it */	

esttab .,  `estab_opts_by_small'

esttab . using ${my_tables}/first_stage_averages_by_yr_pr_inter_ES.tex,`estab_opts_by_small' 



/* cast the 2010Q1 and Q2 trades to Q3 */
replace q_fy=3 if fy==2010 & q_fy<3
gen fishing_quarter=yq(fy, q_fy)
format fishing_quarter %tq

cap drop transactions
bysort fishing_quarter: egen transactions=total(mark)
label var transactions "Transactions"
generate date_text2 = string(fishing_quarter, "%tq")



estpost tabstat `stats' transactions if fy<=2012, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2010_2012_ES.tex, `estab_opts_by'

/* just the prices and interaction */
estpost tabstat `stats2'  if fy<=2012, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2010_2012_pr_inter_ES.tex, `estab_opts_by_small'




estpost tabstat `stats' transactions if fy>=2013 & fy<=2014, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2013_2014_ES.tex, `estab_opts_by'

/* just the prices and interaction */
estpost tabstat `stats2' transactions if fy>=2013 & fy<=2014, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2013_2014_pr_inter_ES.tex, `estab_opts_by_small'



estpost tabstat `stats' transactions if fy>=2015 & fy<=2016, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2015_2016_ES.tex, `estab_opts_by'

/* just the prices and interaction */
estpost tabstat `stats2' transactions if fy>=2015 & fy<=2016, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2015_2016_pr_inter_ES.tex, `estab_opts_by_small'




estpost tabstat `stats' transactions if fy>=2017 & fy<=2018, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2017_2018_ES.tex, `estab_opts_by'
/* just the prices and interaction */
estpost tabstat `stats2' transactions if fy>=2017 & fy<=2018, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2017_201_pr_inter_ES.tex, `estab_opts_by_small'




estpost tabstat `stats' transactions if fy>=2019 & fy<=2019, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_2019_ES.tex, `estab_opts_by'
/* just the prices and interaction */
estpost tabstat `stats2' transactions if fy>=2019 & fy<=2019, by(date_text2) `estpost_opts_by'
esttab . using ${my_tables}/first_stage_201_pr_inter_ES.tex, `estab_opts_by_small'


