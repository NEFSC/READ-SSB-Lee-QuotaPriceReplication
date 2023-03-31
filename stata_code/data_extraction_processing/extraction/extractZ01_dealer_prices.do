
/*
Code to extract 
1. GB East Cod/Haddock can be converted to GB West Cod/haddock after FW5X? in approx 20014. GBW cannot be converted to GBE
2. Plaice has been constraining
nespp3, 
81 cod 
120 winter
122 witch
123 yellowtail
124 plaice
147 haddock
153 white hake
240 redfish
269 pollock



*/


#delimit;
version 15.1;
pause on;

timer on 1;

local out_data ${data_intermediate}/annual_prices_${vintage_string}.dta


clear;



quietly forvalues yr=2009/2020{;
	tempfile new5555;
	local dsp1 `"`dsp1'"`new5555'" "'  ;
	clear;
	odbc load,  exec("select sum(spplndlb) as landings, sum(sppvalue) as value, nespp3, month, year from cfdbs.cfders`yr' 
		where spplndlb is not null and
		nespp3 in (81,120,122,123,124,147,153,240,269) and
		spplndlb>=1 and sppvalue/spplndlb<=40  
		group by nespp3, month, year;") $mysole_conn;
	renvarlab, lower;
	destring, replace;
	compress;

	
	quietly save `new5555';
};
clear;
append using `dsp1';

/* construct fishing year */
drop if month==0;
gen monthly=ym(year, month);
gen outputprice=value/landings;
gen fy_month=monthly-4;

gen fy=yofd(dofm(fy_month));
gen month_fy=month(fy_month);
notes month_fy: 1==May, 12==April;
drop fy_month;

gen q_fy=ceil(month_fy/3);
notes q_fy: 1==MJJ 2==ASO 3==NDJ 4==FMA;
save ${data_internal}/output_prices_${vintage_string}.dta,replace;

