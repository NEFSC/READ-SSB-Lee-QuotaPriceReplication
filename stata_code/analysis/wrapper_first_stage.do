/* this is a wraper to do some exploratory data analysis and robustness checks on the first stage  */
version 15.1
#delimit cr
set scheme s2mono

/*Code to make summary stats prior to the first stage

The ESAMP tables are not great  */
do "${analysis_code}/table_making/first_stage_summary_stats_POP.do"
do "${analysis_code}/table_making/first_stage_summary_stats_ESAMP.do"


/*Do some some graphing on the market volumes, transactions, overlap, and results of the first stage regression. */

do ${analysis_code}/exploratory/graphingA04Q_explore_market_transactions.do
do ${analysis_code}/exploratory/graphingA05Q_market_volumes.do
do ${analysis_code}/exploratory/graphingA06_fishing_overlap.do

/*graph the fraction traded */
do ${analysis_code}/exploratory/trade_fraction_of_totals.do



/* graph results from the specification in R */
do "${analysis_code}/exploratory/graphing_quarterly_ols_coefs.do"

/*try alternative specifications for the first stage in stata */
do "${analysis_code}/small/L01_first_stage.do"
/* and graph them */
do "${analysis_code}/exploratory/L02-graphing_first_stage_results.do"
do "${analysis_code}/exploratory/L05_first_stage_tests.do"


do ${analysis_code}/table_making/first_stage_R2_table.do

do ${analysis_code}/exploratory/first_stage_exploratory1_POP.do
do ${analysis_code}/exploratory/first_stage_exploratory1_ESAMP.do

do ${analysis_code}/exploratory/NLS_exploratory1.do


