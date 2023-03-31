/* this is a wrapper to do all my data-importing and data cleaning */
/* read in quarterly and yearly coefficients from Chad's hedonic model. Clean up a little bit */
#delimit cr
version 15.1
set scheme s2mono


/*construct and graph one index per year for quota and quota availability*/
do "${analysis_code}/exploratory/indicesA01_fishery_level.do"



do "${analysis_code}/exploratory/indicesA02_stock_level.do"
