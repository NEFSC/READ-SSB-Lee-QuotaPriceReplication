/* code to extract bottomtrawl data for groundfish */

/* Part 1A: Get the SVSPP and ITIS codes from SVDBS */

#delimit ;

cap mkdir "${data_raw}/svdbs";

clear;
	odbc load,  exec("select * from svdbs.itis_lookup;") $mysole_conn;
	destring itisspp, replace;
	drop if itisspp==.;
	drop if svspp=="";

save "${data_raw}/svdbs/svdbs_itis_lookup_${vintage_string}.dta", replace;

clear;
/* Part 1B: Get the ITIS and NESPP from species_itis_ne*/

odbc load,  exec("select nespp4, species_itis, common_name, scientific_name from species_itis_ne ;") $mysole_conn;
renvarlab, lower;
destring, replace;
gen nespp3=floor(nespp4/10);
drop nespp4;
duplicates drop;
duplicates report nespp3;
sort nespp3;
rename species_itis itisspp;
rename common_name common_name_itis;
rename scientific_name scientific_name_itis;

destring, replace;
drop if nespp3==526 & itisspp==161989;

save "${data_raw}/itis_lookup_${vintage_string}.dta", replace;

/* Part 1C: Get just the multispeices codes*/

clear;

	odbc load,  exec("
select * from svdbs.itis_lookup where itisspp in (
select distinct species_itis from (
select distinct itis.nespp4, itis.species_itis, itis.common_name, itis.scientific_name from species_itis_ne itis, multispecieslist mul where itis.nespp4=mul.nespp4 order by species_itis)
) order by svspp;") $mysole_conn;

save "${data_raw}/svdbs/svdbs_itis_lookup_mul_${vintage_string}.dta", replace;

clear;









/* Part 2: Get all the Length-weight data from FSCS_SVBIO (or UNION_FSCS_SVBIO). I think I'm okay using FSCS_SVBIO since I only need 2009 and later data*/


/* Read in data 
1. Purpose_code= 10 and 11 for Bottom trawl and MA DMF bottom trawl (might want to exclude 11)
2. status_code=10 is audited data only
3. Season in ( 'SPRING', 'FALL') - umm, just the spring and fall surveys.
and ((stratum between 01260 and 01300) or (stratum between 01360 and 01400))

Somewhat surprisingly, alot of these variables are coming in as strings, not as numeric.
*/
	odbc load,  exec("select cruise6, tow, stratum, station,svspp,length, indwt from FSCS_SVBIO
where cruise6 in 
  (select distinct cruise6 from svdbs_cruises where purpose_code in(10,11) and status_code=10 and Season in ( 'SPRING', 'FALL')) and cruise6>=200200 ;") $mysole_conn;
destring, replace;
sort cruise6;
notes: this has the lengths and weights of measured fish at each tow.;
note: use this to filter on "exploitable biomass" don't forget to convert mm to inches.  ;

/*You will need to retain the "fraction exploitable" from this dataset
gen exploitable=length>=minimum
collapse (sum) indwt, by(cruise6 tow stratum svspp exploitable)
bysort cruise6 tow stratum svspp exploitable: gen tc=total(indwt)
gen frac_exploitable=indwt/tc
keep cruise6 tow stratum svspp exploitable frac_exploitable

*/
  destring cruise6 tow station, replace;

compress;
save "${data_raw}/svdbs/UNION_FSCS_SVBIO_${vintage_string}.dta",replace;

clear;
/* Part 3: Get all Total catch from  from union_FSCS_SVCAT

or do I need FSCS_SVCAT? */

/* note that union_FSCS_SVCAT does not inclues reccatchnum and reccatchwt */
	odbc load,  exec("select cruise6, tow, stratum, station, svspp, reccatchnum, reccatchwt, expcatchnum, expcatchwt from FSCS_SVCAT where cruise6 in 
  (select distinct cruise6 from svdbs_cruises where purpose_code in(10,11) and status_code=10 and Season in ( 'SPRING', 'FALL')) and cruise6>=200200 ") $mysole_conn;
  destring cruise6 tow station svspp  , replace;
  /* collapse because this is entered by sex and we just need totals by cruise6 tow stratum station svspp */
  collapse (sum) expcatchnum expcatchwt, by(cruise6 tow stratum station svspp);

save "${data_raw}/svdbs/FSCS_SVCAT_${vintage_string}.dta",replace;


/* merge in the fraction_exploitable from above and then multiply frac_exploitable by expcatchwt to get kg of exploitable per tow */


clear;
/* grab the areas */
/* Part 4: Get the Statistical Area from UNION_FSCS_SVSTA*/

#delimit;
	odbc load,  exec("select cruise6, tow, stratum, station, area, beglat, beglon, endlat, endlon from FSCS_SVSTA
where cruise6 in 
  (select distinct cruise6 from svdbs_cruises where purpose_code in(10,11) and status_code=10 and Season in ( 'SPRING', 'FALL'))
  and cruise6>=200201;") $mysole_conn;
  destring cruise6 tow area station, replace;
  save  "${data_raw}/svdbs/UNION_FSCS_SVSTA_${vintage_string}.dta",replace;

  
  clear;
  	odbc load,  exec("select * from svdbs_cruises where purpose_code in(10,11) and status_code=10 and Season in ( 'SPRING', 'FALL') and cruise6>=200900 ;") $mysole_conn;
destring, replace;
sort cruise6;
  save  "${data_raw}/svdbs/cruises_${vintage_string}.dta",replace;

