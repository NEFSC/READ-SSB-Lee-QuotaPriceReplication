/* this is a wrapper to do all my data-importing and data cleaning */
/* read in quarterly and yearly coefficients from Chad's hedonic model. Clean up a little bit */
#delimit cr
version 15.1
set scheme s2mono


/*various graphs of the quota market (prices, quantities, transactions) MONTHLY level */
do "${analysis_code}/exploratory/graphingA01_monthly_singlestock.do"

/*various graphs of the quota market (prices, quantities, transactions) QUARTERLY level */
do "${analysis_code}/exploratory/graphingA02_quarterly_singlestock.do"

/*detailed graphs of quota usage at the monthly level */
do "${analysis_code}/exploratory/graphingA03_monthly_usage.do"

/*create graphs of monthly market activity (quantities, number of transactions) that includes baskets and swaps */
do "${analysis_code}/exploratory/graphingA04_market_transactions.do"


/*create graphs of monthly market activity (quantities) that includes baskets and swaps */
do "${analysis_code}/exploratory/graphingA05_market_volumes.do"



/*create graphs of monthly market activity (quantities) that includes baskets and swaps */
do "${analysis_code}/exploratory/trade_fraction_of_totals.do"
