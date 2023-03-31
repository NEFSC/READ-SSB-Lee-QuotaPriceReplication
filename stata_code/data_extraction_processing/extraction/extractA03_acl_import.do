/* These are taken from GARFOs catch accounting webpages
https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/h/groundfish_catch_accounting
Jonathan Cummings scrapedscraped the 2010-2017 data. I copy/pasted the 2018 by hand into a csv. 
I just need the ACLs
*/



#delimit;
tempfile usc;
import delimited ${data_external}\catch_history\us_canada.csv, clear;
rename sector_mt sector_livemt;
cap drop v14;
cap drop v15;
save `usc';



tempfile d2019;
import delimited ${data_external}\catch_history\catch2019.csv, clear;
cap drop v14;
cap drop v15;
save `d2019';


clear;
import delimited ${data_external}\catch_history\catch2018.csv, clear;
cap drop v14;
cap drop v15;
append using `d2019', force;

foreach var of varlist total commercial sector recreational statewater{;
egen m`var'=sieve(`var'), char(0123456789.);
destring m`var', replace;
drop `var';
rename m`var' `var';
};
tempfile acl2018;


save `acl2018', replace;
clear;
import delimited ${data_external}\catch_history\catchHist.csv, clear;

foreach var of varlist commercial-other smallmesh{;
egen m`var'=sieve(`var'), char(0123456789.);
destring m`var', replace;
drop `var';
rename m`var' `var';
};
keep if data_type=="ACL";
append using `acl2018';


egen stock3=sieve(stock), omit(" " "/");
replace stock3=lower(stock3);



gen stockcode=.;
replace stockcode=1 if strmatch(stock3,"ccgomyellowtailflounder");
replace stockcode=6 if strmatch(stock3,"gbwinterflounder");
replace stockcode=7 if strmatch(stock3,"gbyellowtailflounder");
replace stockcode=8 if strmatch(stock3,"gomcod");
replace stockcode=9 if strmatch(stock3,"gomhaddock");
replace stockcode=10 if strmatch(stock3,"gomwinterflounder");
replace stockcode=11 if strmatch(stock3,"plaice");
replace stockcode=12 if strmatch(stock3,"pollock");
replace stockcode=13 if strmatch(stock3,"redfish");

replace stockcode=14 if inlist(stock3,"snemayellowtailflounder","sneyellowtailflounder");
replace stockcode=15 if strmatch(stock3,"whitehake");
replace stockcode=16 if strmatch(stock3,"witchflounder");
replace stockcode=17 if strmatch(stock3,"snemawinterflounder");

/*I'm adding on stockcoes for halibut, ocean pout, n windowpane, s windowpane and wolffish 
I'm starting them in the 100s.*/
replace stockcode=101 if strmatch(stock3,"halibut");
replace stockcode=102 if strmatch(stock3,"oceanpout");
replace stockcode=103 if strmatch(stock3,"northernwindowpane");
replace stockcode=104 if strmatch(stock3,"southernwindowpane");
replace stockcode=105 if strmatch(stock3,"wolffish");


rename year fishing_year;

order fishing_year stockcode;
sort fishing_year stockcode;
cap drop stock2;
compress;       

renvars total-smallmesh, postfix("_livemt");
ds;
save $data_external/annual_acls_$vintage_string.dta, replace;



keep if stockcode==.;
replace stockcode=0;
append using `usc';
keep fishing_year stockcode stock sector_livemt stock3 stock_id;
gen species=81 if stock_id=="CODGBE";
replace species=81 if stock3=="gbcod";

replace species=147 if stock_id=="HADGBE";
replace species=147 if stock3=="gbhaddock";
keep fishing_year stockcode sector species;
replace stockcode=99 if species==81 & stockcode==0;

replace stockcode=98 if species==147 & stockcode==0;
keep fishing_year stockcode sector species;
reshape wide sector_livemt, i(fishing species) j(stockcode);
gen sector_livemt3=sector_livemt99-sector_livemt2;
gen sector_livemt5=sector_livemt98-sector_livemt4;
reshape long;
drop if species==81 & inlist(stockcode,4,5,98);
drop if species==147 & inlist(stockcode,2,3,99);


gen stock_id="CODGBE" if stockcode==2;
replace stock_id="CODGBW" if stockcode==3;

replace stock_id="HADGBE" if stockcode==4;
replace stock_id="HADGBW" if stockcode==5;

replace stock_id="CODGB" if stockcode==99;
replace stock_id="CODGB" if stockcode==98;

drop species;
gen flag=1;



append using $data_external/annual_acls_$vintage_string.dta; 
replace stock="GB Cod" if stockcode==99;
replace stock="GB Haddock" if stockcode==98;
replace stock="GBE Cod" if stockcode==2;
replace stock="GBW Cod" if stockcode==3;
replace stock="GBE Haddock" if stockcode==4;
replace stock="GBW Haddock" if stockcode==5;
drop if stockcode==.;


bysort stockcode fishing_year: assert _N==1;

save  $data_external/annual_acls_$vintage_string.dta, replace; 

/*

fishing_year  total_livemt  sector_liv~t  herringfis~t  other_livemt
stockcode     data_type_~t  commonpool~t  scallopfis~t  smallmesh_~t
stock         commercial~t  recreation~t  statewater~t  stock3
*/
*drop species;

/* stockcode=2 == CODGBE
4 = HADDOCK GBE
0 = GB respectively */

/* stock_id stock code fishing_year sector_mt */


