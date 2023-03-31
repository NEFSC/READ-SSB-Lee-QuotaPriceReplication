/* this is a wraper to do the second stage. 
You started off experimenting with OLS and related models. But now you've settled in on a hurdle model.  */
version 15.1
#delimit cr
set scheme s2mono


/* exploratory graphs of the monthly and quarterly quota available indices */
do "$analysis_code/exploratory/graphingB01_monthly_fishery_quota_avail_indices.do"
do "$analysis_code/exploratory/graphingB02_quarterly_fishery_quota_avail_indices.do"


/* add some exploratory analysis of the second stage here
do "${analysis_code}/exploratory/second_stage_exploratory1.do"

 */
do "${analysis_code}/table_making/second_stage_summary_stats.do"

