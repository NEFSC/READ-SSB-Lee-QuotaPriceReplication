
/* how many observations do we have from the from the single, basket, and swaps combined */

#delimit  ;
version 15.1 ;
pause on;
clear;
set scheme s2mono;

cap mkdir ${exploratory}/market;
global market_figs ${exploratory}/market;
local in_price_data "${data_intermediate}/cleaned_quota_${vintage_string}.dta" ;

use `in_price_data', clear;


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



preserve;
use  "$data_external/deflatorsQ_${vintage_string}.dta", clear;
keep dateq  fGDPDEF_2010Q1 fPCU483483 fPCU31173117_2010Q1;

rename fGDPDEF_2010Q1 fGDP;
rename fPCU483483 fwater_transport;
rename fPCU31173117_2010Q1 fseafoodproductpreparation;

notes fGDP: Implicit price deflator;
notes fwater: Industry PPI for water transport services;
notes fseafood: Industry PPI for seafood product prep and packaging;
tempfile deflators;
save `deflators';
restore;

gen dateq=qofd(date1);
format dateq %tq;
merge m:1 dateq using `deflators', keep(1 3);
assert _merge==3;
drop _merge;


gen compensationR_GDPDEF=compensation/fGDP;

gen compensationR_water=compensation/fwater_transport;
gen compensationR_seafood=compensation/fseafoodproductpreparation;





 /* set up interaction variable */
gen lease_only_pounds=lease_only_sector*total_lbs;
clonevar totalpounds2=total_lbs;
clonevar lease_only_pounds2=lease_only_pounds;




Zdelabel;



gen nstocks=0;

foreach var of varlist CCGOM_yellowtail- SNEMA_winter{;
	replace nstocks=nstocks+1 if `var'>0;
};



format fyq %tq;
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
collapse (sum) z1-z17, by(fyq fy q_fy single_stock);

/* change units to 100,000 lbs */
foreach var of varlist z1-z17 {;
        replace `var'=`var'/100000;
};


foreach v of var * {;
        label var `v' "`l`v''";
};

label def mytype 1 "Single" 0 "Basket and Swap";
label values single_stock mytype;
xtset single_stock fyq;
local tlines "tline(200(4)240, lpattern(dash) lcolor(gs12) lwidth(vthin)) " ;
local panelopts ttitle("Quarter") tlabel(200(8)240, angle(45)) ytitle("Pounds (000,000s)") xlabel(, format(%tqCCYY));
xtline z2 z3, `tlines' `panelopts';
graph export ${market_figs}/gb_cod_Qmarket_volume.png, replace as(png);


xtline z4 z5, `tlines' `panelopts';

graph export ${market_figs}/gb_hadock_Qmarket_volume.png, replace as(png);


xtline z1 z7 z14, `tlines' `panelopts';
graph export ${market_figs}/yellowtail_Qmarket_volume.png, replace as(png);


xtline z6 z10 z17, `tlines' `panelopts';
graph export ${market_figs}/winter_Qmarket_volume.png, replace as(png);

xtline z8 z9, `tlines' `panelopts';
graph export ${market_figs}/gom_cod_hadock_Qmarket_volume.png, replace as(png);


xtline z12 z13 z15, `tlines' `panelopts';
graph export ${market_figs}/unit_round_Qmarket_volume.png, replace as(png);


xtline z11 z16, `tlines' `panelopts';
graph export ${market_figs}/unit_flat_Qmarket_volume.png, replace as(png);

local ylines "yline(200(4)240, lpattern(dash) lcolor(gs12) lwidth(vthin)) " ;

local figopts legend(order( 2 "single stock pounds" 1 "basket pounds")) ytitle("Quarter") ylabel(200(8)240) ylabel(, format(%tqCCYY));

foreach var of varlist z1-z17{;
preserve;

	replace `var'=`var'*-1 if single==1;
	local myl: variable label `var';
	twoway (bar `var' fyq if single==0, horizontal) (bar `var' fyq if single==1, horizontal),  `figopts' `ylines';
	graph export "${market_figs}/`myl'_Qmarket_volume.png", replace as(png);

restore;
};

foreach var of varlist z1-z17{;
bysort fyq: egen t`var'=total(`var');
local myl: variable label `var';
gen fraction_basket_`var'=`var'/t`var';
label var fraction_basket_`var' "`myl'";
drop t`var';
};
keep if single_stock==0;
drop z1-z17;
drop single_stock;


local xlines xline(200(4)240, lpattern(dash) lcolor(gs12) lwidth(vthin));
local graph_opts xtitle("Quarter") xlabel(200(8)240, angle(45))  xlabel(, format(%tqCCYY));

foreach var of varlist fraction_basket_z1-fraction_basket_z17{;
local myl: variable label `var' ;
twoway (bar `var' fyq), `xlines' `graph_opts'  ytitle("`myl' Basket Fraction") ;
graph export "${market_figs}/`myl'_Qbasket_fraction.png", replace as(png);
};

