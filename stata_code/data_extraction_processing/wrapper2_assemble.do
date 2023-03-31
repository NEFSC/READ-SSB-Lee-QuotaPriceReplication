/* this is a wrapper to do the data cleaning  and reorganizing*/
version 15.1
#delimit cr




/****process DMIS to get monthly quota usage */
do "${processing_code}/A_dmis/assembleA01_construct_quota_usage.do"
do "${processing_code}/A_dmis/assembleA02_construct_dmis_prices.do"


/**** Construct quota available at the beginning of the month*/
do "${processing_code}/A_dmis/assembleA03_construct_monthly_quota_available.do"

 


/*********************************************************/
/*process ace price data */
 do "${processing_code}/B_ACEprice1/assembleB01_ace_price_split_and_process.do"
pause
do "${processing_code}/B_ACEprice1/assembleB02_construct_single_stock_trades.do"
do "${processing_code}/B_ACEprice1/assembleB03_construct_annual_quota_prices.do"

/*deal with swaps*/
do "${processing_code}/B_ACEprice1/assembleB04_process_quota_swaps.do"
/*********************************************************/


/* stockarea mapping 
make a dataset containing the stocks and their corresponding areas*/
do "${processing_code}/C_stockbasics/assembleC01_stockarea_mapping.do"

/*make a dataset that uses an definition to determine requires stocks. */
do "${processing_code}/C_stockbasics/assembleC02_construct_required_stocks.do"

/*make a keyfile dataset for stock codes */
do "${processing_code}/C_stockbasics/assembleC03_stock_codes.do"


/*stack all the between sectors together */
do "${processing_code}/wrapperD_between_sector_transactions.do"
/* clean up the inbound between-sector trades */
do "${processing_code}/wrapperE_between_sector_cleanup.do"

/*memberid stacking */
do "${processing_code}/assembleE01_memberids.do"


/* Assemble data for jointness*/
do "${processing_code}/wrapperH_jointness.do"
