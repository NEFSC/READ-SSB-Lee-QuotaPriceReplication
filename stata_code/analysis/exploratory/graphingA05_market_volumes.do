
/* how many observations do we have from the from the single, basket, and swaps combined */

#delimit  ;
version 15.1 ;
pause on;
clear;
set scheme s2mono;
cap mkdir ${exploratory}/market;
global market_figs ${exploratory}/market;

use "${data_intermediate}/cleaned_quota.dta", clear ;
do "${analysis_code}/small/final_dataclean.do";

gen single_stock=nstocks==1;
Zrelabel;
/* commented this out, now we are constructing monthly volumes, by basket/single
foreach var of varlist z1-z17{;
replace `var'=1 if `var'>=1;
replace `var'=0 if `var'<1;

};
*/

gen monthly_date=mofd(date1);
gen month_fy=month(date1)-4;
replace month_fy=month_fy+12 if month_fy<=0;

format monthly_date %tm;

foreach v of var * {;
        local l`v' : variable label `v';
            if `"`l`v''"' == "" {;
            local l`v' "`v'";
        };
};
collapse (sum) z1-z17, by(monthly_date fy month_fy single_stock);

/* change units to 100,000 lbs */
foreach var of varlist z1-z17 {;
        replace `var'=`var'/100000;
};


foreach v of var * {;
        label var `v' "`l`v''" ;
};

label def mytype 1 "Single" 0 "Basket and Swap";
label values single_stock mytype;
xtset single_stock monthly_date;
local tlines "tline(612(12)720, lpattern(dash) lcolor(gs12) lwidth(vthin)) " ;
local panelopts ttitle("Month") tlabel(612(12)720, angle(45)) ytitle("Pounds (000,000s)");
xtline z2-z3, `tlines' `panelopts';
graph export ${market_figs}/gb_cod_market_volume.png, replace as(png);



xtline z4-z5, `tlines' `panelopts';
graph export ${market_figs}/gb_hadock_market_volume.png, replace as(png);


xtline z1 z7 z14, `tlines' `panelopts';
graph export ${market_figs}/yellowtail_market_volume.png, replace as(png);


xtline z6 z10 z17, `tlines' `panelopts';
graph export ${market_figs}/winter_market_volume.png, replace as(png);

xtline z8 z9, `tlines' `panelopts';
graph export ${market_figs}/gom_cod_hadock_market_volume.png, replace as(png);


xtline z12 z13 z15, `tlines' `panelopts';
graph export ${market_figs}/unit_round_market_volume.png, replace as(png);


xtline z11 z16, `tlines' `panelopts';
graph export ${market_figs}/unit_flat_market_volume.png, replace as(png);

local ylines "yline(612(12)720, lpattern(dash) lcolor(gs12) lwidth(vthin)) " ;

local figopts legend(order( 2 "single stock pounds" 1 "basket pounds")) ytitle("Month") ylabel(612(12)720, angle(45));

foreach var of varlist z1-z17{;
preserve;

	replace `var'=`var'*-1 if single==1;
	local myl: variable label `var';
	twoway (bar `var' monthly_date if single==0, horizontal) (bar `var' monthly_date if single==1, horizontal),  `figopts' `ylines';
	graph export "${market_figs}/`myl'_market_volume.png", replace as(png);

restore;
};

foreach var of varlist z1-z17{;
bysort monthly_date: egen t`var'=total(`var');
local myl: variable label `var';
gen fraction_basket_`var'=`var'/t`var';
label var fraction_basket_`var' "`myl'";
drop t`var';
};
keep if single_stock==0;
drop z1-z17;
drop single_stock;


local xlines xline(612(12)720, lpattern(dash) lcolor(gs12) lwidth(vthin));
local graph_opts xtitle("Month") xlabel(612(12)720, angle(45)) ;

foreach var of varlist fraction_basket_z1-fraction_basket_z17{;
local myl: variable label `var' ;
twoway (bar `var' monthly_date), `xlines' `graph_opts'  ytitle("`myl' Basket Fraction") ;
graph export "${market_figs}/`myl'_basket_fraction.png", replace as(png);
};

