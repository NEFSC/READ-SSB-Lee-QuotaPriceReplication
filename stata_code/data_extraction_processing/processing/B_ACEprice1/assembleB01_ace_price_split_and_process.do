/* this code eventually does data cleaning linked ace transactions, then splits the datasets into three: swaps, excluded, and processed. Processed can later be split into single and basket.*/

#delimit;
version 15.1;
pause off;


clear;
use "${data_intermediate}/ace_step1_${vintage_string}.dta", replace;

/* Data cleaning step: */

/* some data corrections based on comdt_desc*/
/*3842 references a trade between 20 and 16 that was supposed to be dabs */
replace z1=0 if transfer_num==3823;
replace z11=25000 if transfer_num==3841;
drop if inlist(transfer_num,3841, 3842);
/* 3992 references a double trade between 12 and 7 that was un-done.*/
drop if inlist(transfer_num,3990,3992);

/*  (3786 is a transfer of 2014 quota, probably to balance)*/
foreach var of varlist transfer_date  transfer_init transfer_app transfer_ack{;
replace `var'=tc(30apr2015 11:59:59) if transfer_num==3786;
};
replace fy=2014 if inlist(transfer_num,3786);
replace month_fy=12 if inlist(transfer_num,3786);
replace q_fy=4 if inlist(transfer_num,3786);

cap rm "${data_internal}/ace_trade_excluded_${vintage_string}.dta";

qui count;
local begin_obs =`r(N)';


preserve;
/*clear out the remaining barter-type transactions  I'll keep the rows that have a compensation in it and nothing that indicates that there is a tbd component*/
keep if inlist(transfer_num,993, 1890, 2483, 3241, 3245, 3246, 3251, 3256, 3277, 3312, 3320, 3321, 3329, 3345, 3369, 3992, 4128, 4667, 4993, 5467, 6431, 6432);
save "${data_internal}/ace_trade_excluded_${vintage_string}.dta", replace;
restore;
drop if inlist(transfer_num,993, 1890, 2483, 3241, 3245, 3246, 3251, 3256, 3277, 3312, 3320, 3321, 3329, 3345, 3369, 3992, 4128, 4667, 4993, 5467, 6431, 6432);

save "${data_intermediate}/ace_step2_${vintage_string}.dta", replace;





/* if you're going to experiment on linking quota<-->quota+cash, this is the place to do it.
do "${extraction_code}/assembleB01A_intermediate_ace_price_process.do"
 */


/* save the zero compensation datasets to somewhere else*/
/*need to change the way the keep if statement is written */
preserve;
keep if compensation==0;
qui count;
local swap_obs =`r(N)';

save "${data_internal}/potential_swaps_${vintage_string}.dta", replace;

restore;

keep if compensation~=0;
clonevar compensation_raw=compensation;
gen avg_price=compensation/total_lbs;
/* turn presumed marginal prices into total compensation*/
/* this is the problem */
replace compensation=compensation*total_lbs if compensation<3 & !((z4>0 | z5>0 | z12>0 |z13>0) & total_lbs>9);
replace avg_price=compensation/total_lbs;

/* considered and rejected */
/*set z4 and z5 =0 */

gen lease_only_sector=0;
replace lease_only_sector=1 if inlist(from_sector_name,"Maine Permit Bank","NEFS 4");


/* z18 is coded as total pounds*lease only sector
gen z18=lease_only_sector*total_lbs
*/


gen flag_in=0;
replace flag_in=1 if compensation>5 & total_lbs>50 ;
replace flag_in=1 if avg_price>0.045 & avg_price<5;

preserve;
keep if flag_in==0;
compress;

append using "${data_internal}/ace_trade_excluded_${vintage_string}.dta";
save "${data_internal}/ace_trade_excluded_${vintage_string}.dta", replace;
 
qui count;
local excluded_obs =`r(N)';
 
restore;
keep if flag_in==1;
compress;

qui count;
local end_obs =`r(N)';
save "${data_main}/processed_ace_trade_${vintage_string}.dta", replace;


di "You started with `begin_obs' observations.";
di "There are `swap_obs' potential swap observations";
di "There are `excluded_obs' observations that were excluded due to either unrealistic prices or barters";
di "You ended up with `end_obs' observations ";
di "hopefully `begin_obs'=`swap_obs' + `excluded_obs' + `end_obs'";
assert `begin_obs'==`swap_obs' + `excluded_obs' + `end_obs';
