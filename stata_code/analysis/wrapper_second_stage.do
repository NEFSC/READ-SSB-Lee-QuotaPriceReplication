/* this is a wraper to do the second stage. 
You started off experimenting with OLS and related models. But now you've settled in on a hurdle model.  */
version 15.1
#delimit cr


do "${analysis_code}/small/M04-explanatory_churdle_semilog.do"


do "${analysis_code}/small/M03-explanatory_churdle_noboot.do"
do "${analysis_code}/small/M03B-explanatory_churdle_noboot.do"
do "${analysis_code}/small/M05-explanatory_churdle_no_omit_noboot.do"







do "${analysis_code}/small/M09B-exog-spatial_hurdle.do"

/* code to load in results and compute margins*/

do "${analysis_code}/small/N01_loadin_results.do"
/* just need to look at the noomit results */
do "${analysis_code}/small/N01A_loadin_noomit.do" 
do "${analysis_code}/small/N02_margins_preferred_models.do"
do "${analysis_code}/small/N03_margins_tables.do"

