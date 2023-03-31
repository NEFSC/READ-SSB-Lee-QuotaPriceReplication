#delimit  ;
version 15.1 ;
set scheme s2mono;
pause on;
clear;
cap mkdir ${exploratory}/market;
global market_figs ${exploratory}/market;

local acl_data ${data_external}/annual_catch_and_acl_${vintage_string}.dta ;

/* this is nearly raw from Chad */
local quota_trades ${data_intermediate}/nodrop_quota_${vintage_string}.dta ;

/* this omits a few observations with quota prices less than 0.0045 and prices over $6.*/
local in_price_data "${data_intermediate}/nodrop_quota_${vintage_string}.dta" 


local stock_key "${data_main}/stock_codes_${vintage_string}.dta";

use `quota_trades';
renvars, lower;

foreach var of varlist z1-z17{;
replace `var'=abs(`var');
};
collapse (sum) z1-z17, by(fy);
reshape long z, i(fy) j(stockcode);
replace z=z/2204;
rename z quota_transferred_mt;
rename fy fishing_year;


label var quota_transferred_mt "live mt of quota transferred" ;

/*merge m:1 stockcode using `stock_key', keep(1 3) ;
assert _merge==3;
drop _merge;
*/


merge 1:1 fishing_year stockcode using `acl_data' ;
/* i get some merge=2 and _merge=1 this is expected */

/* drop pre catch share, 2020 and later. Drop unallocated stocks */
drop if fishing_year<=2009;
drop if fishing_year>=2020;

drop if stockcode>=98;
tab _merge;
assert _merge==3;
drop _merge;

gen frac_acl=quota_transferred/sector_livemt_acl;
gen frac_catch=quota_transferred/sector_livemt_catch;
xtset stockcode fishing_year;
labmask stockcode, values(stock);
xtline frac_acl;

xtline frac_catch;


xtline frac_catch frac_acl, legend(order(1 "Catch" 2 "ACL")) byopts(title("Trade volume, relative to"));

graph export ${my_images}/descriptive/trade_volume_${vintage_string}.png, as(png) width(2000) replace;
preserve;
collapse (sum) quota_transferred sector_livemt_acl sector_livemt_catch, by(fishing_year);
gen frac_acl=quota_transferred/sector_livemt_acl;
gen frac_catch=quota_transferred/sector_livemt_catch;

tsline frac_catch frac_acl, legend(order(1 "Catch" 2 "ACL")) title("Trade volume, relative to");

graph export ${my_images}/descriptive/aggregate_trade_volume_${vintage_string}.png, as(png) width(2000) replace;
restore;

collapse (median) frac_acl frac_catch , by(fishing_year);

tsline frac_catch frac_acl, legend(order(1 "Catch" 2 "ACL")) title("Trade volume, relative to");
graph export ${my_images}/descriptive/median_trade_volume_${vintage_string}.png, as(png) width(2000) replace;




/* only un-matched is SNEMA YTF in 2010-2012 , which was not allocated */


/* merge in the sector ACLSs */


/* graph each individual stock as a function of total 
And graph aggregates */
