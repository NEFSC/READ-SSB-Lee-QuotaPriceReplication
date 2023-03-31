/* Might be better to get the starting quotas from GARFO's website directly */

#delimit;


local firstpsc 2010;
local lastpsc 2019;
foreach yr of numlist `firstpsc'(1)`lastpsc'{;
	clear;
	tempfile mypsc;
	local pscHold`"`pscHold'"`mypsc'" "'  ;

	import delimited "https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Sectors/PSC/psc_lbs_`yr'.csv";
	quietly save `mypsc';
};
clear;

append using `pscHold';
replace sector=ltrim(rtrim(itrim(sector)));
gen sims_sector_id=.;
replace sims_sector_id=2 if strmatch(sector,"CP")==1;
replace sims_sector_id=3 if strmatch(sector,"FGS")==1;
replace sims_sector_id=6 if strmatch(sector,"MCCS")==1;
replace sims_sector_id=6 if strmatch(sector,"PCS")==1;
replace sims_sector_id=5 if strmatch(sector,"SHS1")==1;
replace sims_sector_id=7 if strmatch(sector,"NEFS 7")==1;
replace sims_sector_id=8 if strmatch(sector,"NEFS 4")==1;
replace sims_sector_id=9 if strmatch(sector,"NEFS 8")==1;
replace sims_sector_id=10 if strmatch(sector,"NEFS 11")==1;
replace sims_sector_id=11 if strmatch(sector,"NEFS 12")==1;
replace sims_sector_id=12 if strmatch(sector,"NEFS 2")==1;
replace sims_sector_id=13 if strmatch(sector,"NEFS 3")==1;
replace sims_sector_id=14 if strmatch(sector,"NEFS 1")==1;
replace sims_sector_id=15 if strmatch(sector,"NEFS 10")==1;

replace sims_sector_id=16 if strmatch(sector,"NEFS 13")==1;
replace sims_sector_id=17 if strmatch(sector,"NEFS 9")==1;
replace sims_sector_id=18 if strmatch(sector,"NEFS 5")==1;
replace sims_sector_id=19 if strmatch(sector,"TSS")==1;
replace sims_sector_id=20 if strmatch(sector,"NEFS 6")==1;


replace sims_sector_id=21 if strmatch(sector,"NCCS")==1;
replace sims_sector_id=22 if strmatch(sector,"SHS3")==1;
replace sims_sector_id=23 if strmatch(sector,"MPBS")==1;
replace sims_sector_id=24 if strmatch(sector,"MPB")==1;

replace sims_sector_id=25 if strmatch(sector,"NHPB")==1;
replace sims_sector_id=26 if strmatch(sector,"SHS2")==1;
replace sims_sector_id=27 if strmatch(sector,"MOON")==1;



rename sector sector_abbreviation;
notes sims_sector_id: The Port Clyde Community sector was renamed the Maine Coast Community Sector in FY2013.;
egen total_pounds=rowtotal(gbcod-pollock);
rename fishingyear fishing_year;

save $data_external/annual_psc_by_mri_$vintage_string.dta, replace;

drop if sims_sector_id==2;
collapse (sum) gbcod-pollock, by(fishing_year);
notes: common pool omitted;

renvars gbcod-pollock, prefix("pounds");

reshape long pounds, i(fishing_year) j(stock) string;

gen stockcode=.;
replace stockcode=1 if strmatch(stock,"ccgomyellowtailflounder");
replace stockcode=2 if strmatch(stock,"gbcod");
replace stockcode=4 if strmatch(stock,"gbhaddock");
replace stockcode=6 if strmatch(stock,"gbwinterflounder");
replace stockcode=7 if strmatch(stock,"gbyellowtailflounder");
replace stockcode=8 if strmatch(stock,"gomcod");
replace stockcode=9 if strmatch(stock,"gomhaddock");
replace stockcode=10 if strmatch(stock,"gomwinterflounder");
replace stockcode=11 if strmatch(stock,"plaice");
replace stockcode=12 if strmatch(stock,"pollock");
replace stockcode=13 if strmatch(stock,"redfish");

replace stockcode=14 if strmatch(stock,"snemayellowtailflounder");
replace stockcode=15 if strmatch(stock,"whitehake");
replace stockcode=16 if strmatch(stock,"witchflounder");
replace stockcode=17 if strmatch(stock,"snemawinterflounder");
/*I'm adding on stockcoes for halibut, ocean pout, n windowpane, s windowpane and wolffish 
I'm starting them in the 100s.*/
replace stockcode=101 if strmatch(stock,"halibut");
replace stockcode=102 if strmatch(stock,"oceanpout");
replace stockcode=103 if strmatch(stock,"northernwindowpane");
replace stockcode=104 if strmatch(stock,"southernwindowpane");
replace stockcode=105 if strmatch(stock,"wolffish");

order fishing_year stockcode;      
compress; 
save $data_external/annual_aggregate_psc_$vintage_string.dta, replace;




/*
merge 1:1 mri fishing_year using $my_workdir/mqrs_annual_$today_date_string.dta, keep(1 3);

rename _merge merge_psc_to_mqrs;
notes: merge_psc_to_mqrs is the merge variable for psc to mqrs;
saveold $my_workdir/psc_processed_$today_date_string.dta, replace version(12);
*/

