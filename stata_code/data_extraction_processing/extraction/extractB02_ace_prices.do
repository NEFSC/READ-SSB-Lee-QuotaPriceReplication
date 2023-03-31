
/*
Code to extra ace price data.

*/


#delimit;
version 15.1;
pause off;


clear;
/* Read in sector names*/
odbc load,  exec("select distinct sector_id, sector_name  from mqrs.sector_profile a;" )  $mysole_conn; 


renvarlab, lower;
destring, replace;
sort sector_id;
drop if sector_id==0;
drop if  inlist(sector_name,"Hook Gear Sector", "Port Clyde Community Groundfish Sector", "Maine Sector", "Maine");
bysort sector_id: assert _N==1;
save "${data_internal}/sector_names_${vintage_string}.dta", replace;


/* Read in trade data*/

clear;
odbc load,  exec("select b.transfer_number, b.from_sector_id, b.to_sector_id, a.stock, a.live_pounds, b.status, 
                   b.compensation, b.transfer_date, b.transfer_init, b.transfer_app, b.transfer_ack, b.comp_id, b.comodt_desc       
                   from sector.transfers@garfo_nefsc b, sector.transfer_stock@garfo_nefsc a
                   where b.transfer_number = a.transfer_number;" )  $mysole_conn; 
renvarlab, lower;
destring, replace;
keep if status=="C";
save "${data_internal}/ace_raw_${vintage_string}.dta", replace;

/* pull in sector names */
rename from_sector_id sector_id;
merge m:1 sector_id using "${data_internal}/sector_names_${vintage_string}.dta", keep(1 3);
rename sector_id from_sector_id;
rename sector_name from_sector_name;
drop _merge;

rename to_sector_id sector_id;
merge m:1 sector_id using "${data_internal}/sector_names_${vintage_string}.dta", keep(1 3);
rename sector_id to_sector_id;
rename sector_name to_sector_name;
drop _merge;




/* date is coming in as a clock, need to convert it to date date 
replace transfer_date=dofc(transfer_date);
format transfer_date %td;
*/
drop if from_sector_id==.;
replace compensation=0 if compensation==.;

/* hack, SNEMA Winter is z17 */
#delimit ;
replace stock="Z SNE/MA Winter Flounder" if strmatch(stock,"SNE/MA Winter Flounder");

sort stock;
levelsof stock, local(stocklist);
local i=0;
foreach s of local stocklist{;
local ++i;
gen z`i'=0;
replace z`i'=live_pounds if strmatch(stock,"`s'");
};
replace stock="SNE/MA Winter Flounder" if strmatch(stock,"Z SNE/MA Winter Flounder");

/* check this is correct */
foreach s of numlist `i'/1{;
di "this is z`s'" ;
tab stock if z`s'~=0;
assert r(r)==1;
};

/* fixed to here */

/*Reshape the data to wide. The reported compensation is for the entire transfer_id.*/
collapse (sum) z1-z17 (mean) compensation, by(from_sector_id to_sector_id from_sector_name to_sector_name transfer_date transfer_init transfer_app transfer_ack transfer_number status comodt_desc comp_id);
/* have to label after the collapse */
local i=0;
foreach s of local stocklist{;
local ++i;
label var z`i' "`s'";
};

/* construct fishing year*/
gen fy=yofd(dofc(transfer_date));
replace fy=fy-1 if month(dofc(transfer_date))<=4;
/*construct month of fishing year */
gen month_fy=month(dofc(transfer_date))-4; 
replace month_fy=month_fy+12 if month_fy<=0;
notes month_fy: 1==May, 12==April;
/*construct quarter of fishing year variables */
gen q_fy=ceil(month_fy/3);
notes q_fy: 1==MJJ 2==ASO 3==NDJ 4==FMA;
qui summ fy;
local terminal_year `r(max)';
di `terminal_year';

egen total_lbs=rowtotal(z1-z17);
save "${data_intermediate}/ace_step1_${vintage_string}.dta", replace;




