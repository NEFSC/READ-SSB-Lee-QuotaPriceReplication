/* code to use DMIS to construct Quarterly stock-level prices 
At least for East vs west, we might want to fill in just average of the two -- 
landings are probably really sparse

We'll use the dlr_dollar, dlr_live, dlr_landed to construct prices*/
#delimit;

local stock_in "${data_main}/dmis_output_stock_prices_${vintage_string}.dta";


use `stock_in', clear;
cap drop month;
gen month=month(dofm(trip_monthly_date));
gen m_fy=month-4;
replace m_fy=m_fy+12 if m_fy<=0;

gen q_fy=irecode(m_fy,0,3,6,9,12);

collapse (sum) landed pounds dlr_live dlr_landed dlr_dollar stockobs, by(fishing_year q_fy stock_id stockcode);

notes q_fy: quarter of fishing_year (q_fy=1 for MJJ =2 for ASO =3 NDJ 4 FMA);
gen quarterly=yq(fishing_year, q_fy);
notes quarterly: quarter, where MJJ is quarter 1 of the fishing_year;

gen dealer_live_price=dlr_dollar/dlr_live;
gen dealer_landed_price=dlr_dollar/dlr_landed;

replace dealer_live_price=0 if dealer_live_price==. & stockcode>=100;
replace dealer_landed_price=0 if dealer_landed_price==. & stockcode>=100;
format quarterly %tq;

order stockcode stock_id quarterly fishing_year q_fy;
notes: stockcode corresponds to chad's encoding of ace prices;

/* ensure no missing */
xtset stockcode quarterly;
assert "`r(balanced)'"=="strongly balanced";
/* positive prices for the allocated groundfish */
assert dealer_live>0 if stockcode<100;


replace dealer_live_price=0 if dealer_live_price==. & stockcode>=100;
replace dealer_landed_price=0 if dealer_landed_price==. & stockcode>=100;



save "${data_main}/dmis_output_stock_quarterly_prices_${vintage_string}.dta", replace;



/* code to use DMIS to construct SPECIES level prices  
We'll use the dlr_dollar, dlr_live, dlr_landed to construct prices*/
clear;
use $data_external/dmis_trip_catch_universe_$vintage_string.dta, replace;
drop if dlr_dollar==0;
egen stockobs=tag(trip_id stock_id);


/* contract to month */

gen trip_monthly_date=mofd(dofc(trip_date));
gen fishing_year=yofd(dofm(trip_monthly_date));
gen month=month(dofm(trip_monthly_date));
replace fishing_year=fishing_year-1 if month<=4;
format trip_monthly_date %tm;

gen m_fy=month-4;
replace m_fy=m_fy+12 if m_fy<=0;
gen q_fy=irecode(m_fy,0,3,6,9,12);
gen quarterly=yq(fishing_year, q_fy);
notes quarterly: quarter, where MJJ is quarter 1 of the fishing_year;
format quarterly %tq;



/* this bit helps me create 1 price for GB cod and haddock each */
replace stock_id="CODGBE" if inlist(stock_id,"CODGBE", "CODGBW","CODGMSS");
replace stock_id="HADGBE" if inlist(stock_id,"HADGBE", "HADGBW","HADGM");
replace stock_id="YELCCGM" if inlist(stock_id,"YELCCGM", "YELGB","YELSNE");
replace stock_id="FLWGB" if inlist(stock_id,"FLWGB","FLWGMSS","FLWSNEMA");

replace stock_id="FLDSNEMA" if inlist(stock_id,"FLDSNEMA","FLGMGBSS");
gen expand=1;
replace expand=3 if inlist(stock_id,"CODGBE","HADGBE","YELCCGM","FLWGB");
replace expand=2 if inlist(stock_id,"FLDSNEMA");

collapse (sum) landed  pounds dlr_live dlr_landed dlr_dollar stockobs, by(fishing_year q_fy quarterly stock_id expand);
gen dealer_live_price=dlr_dollar/dlr_live;
gen dealer_landed_price=dlr_dollar/dlr_landed;

expand 2 if expand>=2, gen(mytag);
replace stock_id="CODGBW" if stock_id=="CODGBE" & mytag==1;
replace stock_id="HADGBW" if stock_id=="HADGBE" & mytag==1;
replace stock_id="YELGB" if stock_id=="YELCCGM" & mytag==1;
replace stock_id="FLWGMSS" if stock_id=="FLWGB" & mytag==1;
replace stock_id="FLGMGBSS" if stock_id=="FLDSNEMA" & mytag==1;
drop mytag;

expand 2 if inlist(stock_id,"CODGBE", "HADGBE","YELCCGM","FLWGB"), gen(mytag);
replace stock_id="CODGMSS" if stock_id=="CODGBE" & mytag==1;
replace stock_id="HADGM" if stock_id=="HADGBE" & mytag==1;
replace stock_id="YELSNE" if stock_id=="YELCCGM" & mytag==1;
replace stock_id="FLWSNEMA" if stock_id=="FLWGB" & mytag==1;
cap drop mytag;
cap drop expand;


#delimit;
gen stockcode=.;

replace stockcode=1 if strmatch(stock_id,"YELCCGM");
replace stockcode=2 if strmatch(stock_id,"CODGBE");
replace stockcode=3 if strmatch(stock_id,"CODGBW");
replace stockcode=4 if strmatch(stock_id,"HADGBE");
replace stockcode=5 if strmatch(stock_id,"HADGBW");
replace stockcode=6 if strmatch(stock_id,"FLWGB");
replace stockcode=7 if strmatch(stock_id,"YELGB");

replace stockcode=8 if strmatch(stock_id,"CODGMSS");
replace stockcode=9 if strmatch(stock_id,"HADGM");
replace stockcode=10 if strmatch(stock_id,"FLWGMSS");
replace stockcode=11 if strmatch(stock_id,"PLAGMMA");
replace stockcode=12 if strmatch(stock_id,"POKGMASS");
replace stockcode=13 if strmatch(stock_id,"REDGMGBSS");
replace stockcode=14 if strmatch(stock_id,"YELSNE");
replace stockcode=15 if strmatch(stock_id,"HKWGMMA");
replace stockcode=16 if strmatch(stock_id,"WITGMMA");
replace stockcode=17 if strmatch(stock_id,"FLWSNEMA");
/*I'm adding on stockcods for halibut, ocean pout, n windowpane, s windowpane and wolffish 
I'm starting them in the 100s.*/
replace stockcode=101 if strmatch(stock_id,"HALGMMA");
replace stockcode=102 if strmatch(stock_id,"OPTGMMA");
replace stockcode=103 if strmatch(stock_id,"FLGMGBSS");
replace stockcode=104 if strmatch(stock_id,"FLDSNEMA");
replace stockcode=105 if strmatch(stock_id,"WOLGMMA");
replace stockcode=999 if strmatch(stock_id,"OTHER");


sort fishing_year stockcode quarterly;
tsset stockcode quarterly;
tsfill, full;
gen flag=dlr_dollar==.;
foreach var of varlist landed pounds dlr_live dlr_landed dlr_dollar stockobs{;
replace `var'=0 if `var'==.;
};
foreach var of varlist stock_id{;
bysort stockcode (q_fy): replace `var'=`var'[_n-1] if `var'=="";
};




foreach var of varlist  dealer_live_price dealer_landed_price{;
clonevar L`var'=`var';
bysort stockcode (quarterly): replace L`var'=L`var'[_n-1] if L`var'==.;
clonevar F`var'=`var';
gsort - stockcode -quarterly, generate(groupvar);
bysort stockcode (groupvar): replace F`var'=F`var'[_n-1] if F`var'==.;
gen np=(L`var'+F`var')/2;
replace `var'=np if `var'==.;
cap drop F`var';
cap drop L`var';
cap drop np;
cap drop groupvar;
};
cap drop flag;
order stock_id fishing_year quarterly;
/* zero prices for the no-possession stocks , instead of missing */
replace dealer_live_price=0 if dealer_live_price==. & stockcode>=100;
replace dealer_landed_price=0 if dealer_landed_price==. & stockcode>=100;
replace fishing_year=yofd(dofq(quarterly)) if fishing_year==.;
replace q_fy=quarter(dofq(quarterly)) if q_fy==.;

save ${data_main}/dmis_output_species_quarterly_prices_${vintage_string}.dta,replace;

