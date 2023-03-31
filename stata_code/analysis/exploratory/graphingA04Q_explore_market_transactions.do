
/* how many observations do we have from the from the single, basket, and swaps combined */

#delimit  ;
version 15.1 ;
pause off;
clear;
set scheme s2mono;

cap mkdir ${exploratory}/market;
global market_figs ${exploratory}/market;

use "${data_intermediate}/cleaned_quota_$vintage_string.dta", clear ;


cap drop qtr;
order z1-z17, after(to_sector_name);
drop if fy>=2020;
gen lease_only_sector=inlist(from_sector_name,"NEFS 4", "Maine Sector/MPBS");
/* there's only a few obs in Q1 of FY2010 and Q2 of FY2010. I'm pooling them into Q3 of 2010. */
replace q_fy=3 if q_fy<=2 & fy==2010;
gen fyq=yq(fy,q_fy);
drop q_fy;
gen q_fy=quarter(dofq(fyq));

gen cons=1;
gen qtr1 = q_fy==1;
gen qtr2 = q_fy==2;
gen qtr3 = q_fy==3;
gen qtr4 = q_fy==4;


gen end=mdy(5,1,fy+1);
gen begin=mdy(5,1,fy);
gen season_remain=(end-date1)/(end-begin);

gen season_elapsed=1-season_remain;

Zdelabel;



gen nstocks=0;

foreach var of varlist CCGOM_yellowtail- SNEMA_winter{;
	replace nstocks=nstocks+1 if `var'>0;
};





format fyq %tq;
gen single_stock=nstocks==1;

Zrelabel;
foreach var of varlist z1-z17{;
replace `var'=1 if `var'>=1;
replace `var'=0 if `var'<1;

};

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
collapse (sum) z1-z17, by(fyq fy q_fy single_stock);



foreach v of var * {;
        label var `v' "`l`v''";
};

label def mytype 1 "Single" 0 "Basket and Swap";
label values single_stock mytype;
xtset single_stock fyq;
local tlines "tline(200(4)240, lpattern(dash) lcolor(gs12) lwidth(vthin)) " ;
local panelopts ttitle("Quarter") tlabel(200(8)240, angle(45))  ytitle("Number of Trades") xlabel(, format(%tqCCYY));
xtline z2 z3, `tlines' `panelopts';

graph export ${market_figs}/gb_cod_Qmarket_activity.png, replace as(png);

xtline z4 z5, `tlines' `panelopts';

graph export ${market_figs}/gb_haddock_Qmarket_activity.png, replace as(png);


xtline z1 z7 z14, `tlines' `panelopts';
graph export ${market_figs}/yellowtail_Qmarket_activity.png, replace as(png);


xtline z6 z10 z17, `tlines' `panelopts';
graph export ${market_figs}/winter_Qmarket_activity.png, replace as(png);

xtline z8 z9, `tlines' `panelopts';
graph export ${market_figs}/gom_cod_hadock_Qmarket_activity.png, replace as(png);


xtline z12 z13 z15, `tlines' `panelopts';
graph export ${market_figs}/unit_round_Qmarket_activity.png, replace as(png);


xtline z11 z16, `tlines' `panelopts';
graph export ${market_figs}/unit_flat_Qmarket_activity.png, replace as(png);

local ylines "yline(200(4)240, lpattern(dash) lcolor(gs12) lwidth(vthin)) " ;

local figopts legend(order( 2 "single stock trades" 1 "basket trades")) ytitle("Quarter") ylabel(200(8)240) ylabel(, format(%tqCCYY));

#delimit ;
foreach var of varlist z1-z17{;
preserve;

	replace `var'=`var'*-1 if single==1;
	local myl: variable label `var';
	twoway (bar `var' fyq if single==0, horizontal) (bar `var' fyq if single==1, horizontal),  `figopts' `ylines';
	graph export "${market_figs}/`myl'_Qmarket_activity.png", replace as(png);

restore;
};

