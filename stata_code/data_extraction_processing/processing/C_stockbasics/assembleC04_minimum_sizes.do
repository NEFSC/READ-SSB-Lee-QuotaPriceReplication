/*construct size limits by fishing year and stock.
*/


version 15.1
#delimit cr
pause off
local infile_name ${data_main}/stock_codes_${vintage_string}.dta
local outfile_name ${data_main}/minimum_sizes_${vintage_string}.dta


use `infile_name', replace
expand 15
bysort stockcode: gen fishing_year=_n+2006



gen minimum_inches=.
/* Fill in the regs in 2007 */
/* 

https://www.govinfo.gov/content/pkg/CFR-2006-title50-vol8/pdf/CFR-2006-title50-vol8-sec648-83.pdf
https://www.govinfo.gov/app/details/CFR-2008-title50-vol8/CFR-2008-title50-vol8-sec648-83
https://www.govinfo.gov/app/details/CFR-2009-title50-vol8/CFR-2009-title50-vol8-sec648-83
October 2009

Species	Sizes(inches)
Cod 	22 (55.9 cm)
Haddock 	19 (48.3 cm)
Pollock 	19 (48.3 cm)
Witch flounder (gray sole) 	14 (35.6 cm)
Yellowtail flounder 	13 (33.0 cm)
American plaice (dab) 	14 (35.6 cm)
Atlantic halibut 	36 (91.4 cm)
Winter flounder (blackback) 	12 (30.5 cm)
Redfish 	9 (22.9 cm)

*/




/* Cod: */
replace minimum_inches=22 if inlist(stockcode,2,3,8) 
 /* haddock */
replace minimum_inches=19 if inlist(stockcode,4,5,9)
 /* pollock:*/
 replace minimum_inches=19 if inlist(stockcode,12) 
 /* witch*/
replace minimum_inches=14 if inlist(stockcode,16) 
 /*  yellowtail*/
replace minimum_inches=13 if inlist(stockcode,1,7,14)
/*  plaice*/
replace minimum_inches=14 if inlist(stockcode,11) 
/*  halibut*/
replace minimum_inches=36 if inlist(stockcode,101)
 /*  Winter*/
replace minimum_inches=12 if inlist(stockcode,6,10,17) 
 /*  redfish*/
replace minimum_inches=9 if inlist(stockcode,13) 



/* make replacements in 2010*/
/*April 9, 2010: 
75 FR 18328 Apr. 9, 2010 (For the May 1 FY)
October 2010
Haddock 	18 (45.7 cm)
Atlantic halibut 	41 (104.1 cm)
*/

 /* haddock */
replace minimum_inches=18 if inlist(stockcode,4,5,9) & fishing_year>=2010
/*  halibut*/
replace minimum_inches=41 if inlist(stockcode,101) & fishing_year>=2010



/* make replacements in 2013 */
/*
78 FR 26158, May 3, 2013
78 FR 34587  - July 1, 2013

Minimum Fish Sizes (TL) for Commercial Vessels Species	Size(inches)
Cod 	19 (48.3 cm)
Haddock 	16 (40.6 cm)
Witch flounder (gray sole) 	13 (35.6 cm)
Yellowtail flounder 	12 (33.0 cm)
American plaice (dab) 	12 (33.0 cm)
Redfish 	7 (17.8 cm)

*/

/* Cod: */
replace minimum_inches=19 if inlist(stockcode,2,3,8) & fishing_year>=2013
 /* haddock */
replace minimum_inches=16 if inlist(stockcode,4,5,9) & fishing_year>=2013
 /* witch*/
replace minimum_inches=13 if inlist(stockcode,16) & fishing_year>=2013
 /*  yellowtail*/
replace minimum_inches=12 if inlist(stockcode,1,7,14) & fishing_year>=2013
/*  plaice*/
replace minimum_inches=12 if inlist(stockcode,11) & fishing_year>=2013
 /*  redfish*/
replace minimum_inches=9 if inlist(stockcode,13) & fishing_year>=2013



/* current cfr (feb 5, 2021) 
Species			Size(inches)
Cod				19 (48.3 cm)
Haddock			16 (40.6 cm)
Pollock			19 (48.3 cm)
Witch flounder 	13 (33 cm)
Yellowtail flor	12 (30.5 cm)
American plaice 12 (30.5 cm)
Atlantic halibut41 (104.1 cm)
Winter flounder 12 (30.5 cm)
Redfish			7 (17.8 cm)
*/

/* no minimum for white hake */
replace minimum_inches=0 if inlist(stockcode,15)

/* no minimum Other will be coded as -1 */
replace minimum_inches=-1 if inlist(stockcode,999)

/* no possession for Windowpane, wolf, and  ocean pout coded as 999 inches*/
replace minimum_inches=999 if inlist(stockcode,102,103,104,105)


save `outfile_name', replace
