/* These are taken from GARFOs catch accounting webpages
https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/h/groundfish_catch_accounting
Jonathan Cummings scrapedscraped the 2010-2017 data. I copy/pasted the 2018 by hand into a csv. 
I need the ACLs and sector landings
*/



#delimit;
tempfile usc;
import delimited ${data_external}\catch_history\us_canada.csv, clear;
rename sector_mt sector_livemt;
cap drop v14;
cap drop v15;

keep fishing_year stockcode stock_id data_type sector_livemt;
replace data_type=lower(data_type);
rename sector_livemt sector_livemt_;
reshape wide sector_livemt, i(fishing_year stockcode stock_id) j(data_type) string;
notes: 2009 Cod catch data taken from  TRAC. 2015. Eastern Georges Bank Cod. TRAC Status Report 2015/01  ;
notes: 2009 haddock catch data taken from Transboundary Resources Assessment Committee Status Report 2015/02 (Revised) : Eastern Georges Bank Haddock;
notes: 2009 quotas from Federal Register /Vol. 74, No. 11;
save `usc';

clear;
tempfile d2009;
import delimited ${data_external}\catch_history\catch2009.csv, clear stringcols(_all);
cap drop v14;
cap drop v15;
save `d2009';


tempfile d2019;
import delimited ${data_external}\catch_history\catch2019.csv, clear  stringcols(_all);
cap drop v14;
cap drop v15;
save `d2019';


clear;
import delimited ${data_external}\catch_history\catch2018.csv, clear  stringcols(_all);
cap drop v14;
cap drop v15;
append using `d2019' `d2009';



/*
foreach var of varlist total commercial sector recreational statewater{;
egen m`var'=sieve(`var'), char(0123456789.);
destring m`var', replace;
drop `var';
rename m`var' `var';
};

*/
tempfile acl2018;
notes: 2009 quotas from Federal Register Vol. 74, No. 11;
notes: 2009 catches NMFS quota monitoring website (https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports//2009_2010_Comparison.htm);
save `acl2018', replace;



clear;
import delimited ${data_external}\catch_history\catchHist.csv, clear stringcols(_all);

keep if inlist(data_type,"ACL","Catch");
append using `acl2018';

replace stock="SNE/MA Yellowtail Flounder" if stock=="SNE Yellowtail Flounder";
replace stock="GB Cod" if stock=="GB cod";
replace stock="GOM Cod" if stock=="GOM cod";

foreach var of varlist total commercial-other smallmesh{;
egen m`var'=sieve(`var'), char(0123456789.);
destring m`var', replace;
drop `var';
rename m`var' `var';
};
destring year, replace;
pause;
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

/*no subacl for snema winter in 2010, 2011,2012. I'm going to fill it in with total commercial acl */

replace sector_livemt=commercial_livemt  if inlist(fishing_year,2010,2011,2012) & stock=="SNE/MA Winter Flounder" & sector_livemt==.;

/*no sector subacls for 2009..fill in with total acl*/

replace sector_livemt=commercial_livemt  if inlist(fishing_year,2009) & sector_livemt==.;
replace sector_livemt=total_livemt  if inlist(fishing_year,2009) & sector_livemt==.;




keep fishing_year stockcode stock data_type sector_livemt;
replace data_type=lower(data_type);
rename sector_livemt sector_livemt_;
reshape wide sector_livemt, i(fishing_year stockcode stock) j(data_type) string;
save $data_external/annual_catch_and_acl_$vintage_string.dta, replace;



keep if stockcode==.;
replace stockcode=0;
append using `usc';
keep fishing_year stockcode stock sector_livemt_acl sector_livemt_catch stock_id;
gen species=81 if stock_id=="CODGBE";
replace species=81 if stock=="GB Cod";

replace species=147 if stock_id=="HADGBE";
replace species=147 if stock=="GB Haddock";
keep fishing_year stockcode sector_livemt_acl sector_livemt_catch species;
replace stockcode=99 if species==81 & stockcode==0;

replace stockcode=98 if species==147 & stockcode==0;
keep fishing_year stockcode sector_livemt_acl sector_livemt_catch species;
reshape wide sector_livemt_acl sector_livemt_catch, i(fishing species) j(stockcode);

/*sector_livemt_acl sector_livemt_catch*/

gen sector_livemt_acl3=sector_livemt_acl99-sector_livemt_acl2;
gen sector_livemt_acl5=sector_livemt_acl98-sector_livemt_acl4;

gen sector_livemt_catch3=sector_livemt_catch99-sector_livemt_catch2;
gen sector_livemt_catch5=sector_livemt_catch98-sector_livemt_catch4;

reshape long;
drop if species==81 & inlist(stockcode,4,5,98);
drop if species==147 & inlist(stockcode,2,3,99);


gen stock_id="CODGBE" if stockcode==2;
replace stock_id="CODGBW" if stockcode==3;

replace stock_id="HADGBE" if stockcode==4;
replace stock_id="HADGBW" if stockcode==5;

replace stock_id="CODGB" if stockcode==99;
replace stock_id="HADGB" if stockcode==98;

drop species;
gen flag=1;



append using $data_external/annual_catch_and_acl_$vintage_string.dta; 
replace stock="GB Cod" if stockcode==99;
replace stock="GB Haddock" if stockcode==98;
replace stock="GBE Cod" if stockcode==2;
replace stock="GBW Cod" if stockcode==3;
replace stock="GBE Haddock" if stockcode==4;
replace stock="GBW Haddock" if stockcode==5;
drop if stockcode==.;


bysort stockcode fishing_year: assert _N==1;
replace sector_livemt_catch=round(sector_livemt_catch,.1);
replace sector_livemt_acl=round(sector_livemt_acl,.1);

save  $data_external/annual_catch_and_acl_$vintage_string.dta, replace; 

