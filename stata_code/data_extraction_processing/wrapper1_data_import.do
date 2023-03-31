/* this is a wrapper to do all my data-importing . This code is data downloading and minimal processing. 
Some of this code may take a long time. Other parts may require VPN.*/
/* read in quarterly and yearly coefficients from Chad's hedonic model. Clean up a little bit */
version 15.1
#delimit cr




/****Coefficients from the hedonic model*********************************************/
/* the input data here comes from Chad's hedonics. It is just prices, cleaned up a bit and there's no reason you can't get it yourself. */
do "${extraction_code}/extractA01_ace_price_cleanup.do"


/*extract psc data */
do "${extraction_code}/extractA02_psc_extractor.do"

/*Assemble Annual ACLs */
do "${extraction_code}/extractA03_acl_import.do"
do "${extraction_code}/extractA03S_acl_import.do"


/*extract diesel price data */
do "${extraction_code}/extractA04_diesel_no2_FRED.do"


/****DMIS****************************************/
/*extract catch and discard data 
Takes a long while
Requires VPN*/
do "${extraction_code}/extractB01_dmis_catch_and_discards.do"



/*********************************************************/
/*extract ace price data   Requires network access.
Requires VPN
*/

do "${extraction_code}/extractB02_ace_prices.do"



/*********************************************************/
/*Read in Intra-Sector ACE prices
*/

do "${extraction_code}/extractB03_intrasector_ace_prices.do"


/*********************************************************/
/*Read in Sector Member ids
*/


do "${extraction_code}/wrapperC_sector_memberids.do"


/*********************************************************/
/*Read in inter-sector trade details (mostly memberids)
*/

do "${extraction_code}/wrapperD_intersector_transactions.do"


/****Dealer data****************************************/

/* 
Takes a long while
Requires VPN

do "${extraction_code}/extractZ01_dealer_prices.do"

*/
