/* this is a wrapper to do the estimation. I have left behind do files that estimated models that are rejected. */
version 15.1
#delimit cr


/*extract and process ACE price data
This is done in R 
run the aceprice_project_wrapper.R) 
*/

/****************************************************************/
/*********************These are outdated*************************/
/****************************************************************/
/*Estimate the inequality constrained OLS model by year */
/*do "${analysis_code}/small/ols_regressions2.do" */
/*
do "${analysis_code}/small/ols_tested_down.do"

do "${analysis_code}/small/ols_tested_down_seafood.do"
do "${analysis_code}/small/ols_tested_down_water.do"
do "${analysis_code}/small/ols_tested_down_GDPDEF.do"

do "${analysis_code}/small/eda_trade_dataset.do"*/

/*
do "${analysis_code}/small/nls_tested_quarterlyA.do"

do "${analysis_code}/small/nls_tested_elapsedB.do"
do "${analysis_code}/small/nls_tested_elapsedD.do"



do "${analysis_code}/small/nls_tested_quarterlyA_nominal.do"

/*Estimate the inequality constrained OLS model by year that allows for a fixed per-pound discount every quarter*/
do "${analysis_code}/small/ols_regressions3_quarterly_cents_discount.do"

*/
/****************************************************************/
/****************************************************************/

do "${analysis_code}/small/wrapper_nls_tested_ABCD.do"

do "${analysis_code}/exploratory/explore_quarterly_joined_data.do"

/*Join the biological data */

do "${analysis_code}/small/mergeB_add_bio_to_coeffs.do"




/*need to repeat the merge and explantory regs for the B and D formulations */

/*Do some ESDA 

do ${analysis_code}/exploratory/graphingA04Q_explore_market_transactions.do
do ${analysis_code}/exploratory/graphingA05Q_market_volumes.do
do ${analysis_code}/exploratory/graphingA06_fishing_overlap.do

do ${analysis_code}/exploratory/first_stage_exploratory1.do
do ${analysis_code}/exploratory/NLS_exploratory1.do

*/
