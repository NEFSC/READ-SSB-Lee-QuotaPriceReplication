/* this is a wrapper to do all my data-importing . This code is data downloading and minimal processing. 
Some of this code may take a long time. Other parts may require VPN.*/
/* read in quarterly and yearly coefficients from Chad's hedonic model. Clean up a little bit */
version 15.1
#delimit cr
pause off


/*extract and process ACE price data
This is done in R:
run the aceprice_project_wrapper.R 
*/



/*extract psc data */
do "${extraction_code}/extractA02_psc_extractor.do"

/*Assemble Annual ACLs */
do "${extraction_code}/extractA03S_acl_import.do"


/*extract diesel price data */
do "${extraction_code}/extractA04_diesel_no2_FRED.do"
do "${extraction_code}/extractA05_external_data_FRED.do"




/****DMIS****************************************/
/*extract catch and discard data 
Takes a long while
Requires VPN*/
do "${extraction_code}/extractB01_dmis_catch_and_discards.do"




do "${extraction_code}/extractZ02_crew_sizes.do"

/****SVDBS****************************************/
/*extract Survey data 
Takes a long while
Requires VPN*/

do "${extraction_code}/extractC01_survey_extraction.do"


/****process DMIS to get monthly quota usage and prices*/
do "${processing_code}/A_dmis/assembleA01_construct_quota_usage.do"
do "${processing_code}/A_dmis/assembleA02_construct_dmis_prices.do"
do "${processing_code}/A_dmis/assembleA03_construct_monthly_quota_available.do"



/****process DMIS to get Quarterly quota usage and prices*/
do "${processing_code}/A_dmis/assembleA01Q_construct_quarterly_quota_usage.do"
do "${processing_code}/A_dmis/assembleA02Q_construct_quarterly_dmis_prices.do"
do "${processing_code}/A_dmis/assembleA03Q_construct_quarterly_quota_available.do"





/* stockarea mapping 
make a dataset containing the stocks and their corresponding areas*/
do "${processing_code}/C_stockbasics/assembleC01_stockarea_mapping.do"


/*make a keyfile dataset for stock codes */
do "${processing_code}/C_stockbasics/assembleC03_stock_codes.do"

/*make a dataset that uses an definition to determine requires stocks. */
do "${processing_code}/C_stockbasics/assembleC02_construct_required_stocks.do"


/*make a dataset containing minimum sizes*/
do "${processing_code}/C_stockbasics/assembleC04_minimum_sizes.do"
/*Tidy that up and bring in the svspp and ITIS TSN codes */
do "${processing_code}/C_stockbasics/assembleC05_tidyup_stock_codes.do"


/*Append statistical areas to the survey atch */
do "${processing_code}/J_Survey/J02_itis_nespp3_svspp_keyfile.do"
do "${processing_code}/J_Survey/J01_merge_stat_areas.do"




do "${extraction_code}/extractA06_observer_coverage.do"
do "${extraction_code}/extractA07_observer_coverage_by_stock"


/*Join the pricing, observer, and ACL data at the yearly level*/

do "${analysis_code}/small/mergeA_prices_and_deflators.do"
do "${analysis_code}/small/mergeA2_biological_observer.do"


/*Join the pricing, observer, and ACL data at the quarterly level*/

do "${analysis_code}/small/mergeAQ_quarterly_prices_and_deflators.do"
do "${analysis_code}/small/mergeA2Q_biological_observer.do"


/* construct and join the aggregate jointness metric based on DMIS trips*/
do "${processing_code}/H_jointness/assembleH04_aggregate_joint.do"

/* construct and join the aggregate jointness metric based on DMIS trips*/
do "${analysis_code}/anna/gear_level_jointness.do"



/* construct and join the aggregate jointness metric based on Survey data without a length filter*/
do "${processing_code}/H_jointness/assembleH06_bottomtrawl_overlaps_nofilter.do"

do "${processing_code}/H_jointness/assembleH07_svy_center_of_mass.do"



/* construct indices of quota availability at the fishery and stock level.*/
do "${processing_code}/L_indices/indicesL01_fishery_level.do"
do "${processing_code}/L_indices/indicesL01Q_quarterly_fishery_level_indices.do"

do "${processing_code}/L_indices/indicesL02_stock_level.do"
do "${processing_code}/L_indices/indicesL02Q_quarterly_stock_level.do"


do "${processing_code}/L_indices/indicesL02B_stock_level_no_exclude.do"
do "${processing_code}/L_indices/indicesL02QB_quarterly_stock_level_noex.do"

do "${processing_code}/L_indices/indicesL03Q_quarterly_disjoint.do"


/* re-estimate in stata */
do "${analysis_code}/small/L01_first_stage.do"
do "${analysis_code}/small/L02_first_stage_nominal.do"

do "${analysis_code}/small/L04_integrate_stata_first_stage.do"

/* read in the OLS coefficients from R */
do "${analysis_code}/small/import_ols_coefs_from_R.do"


do "${processing_code}/K_spatial/K01_Distance_matrices.do"
do "${processing_code}/K_spatial/K01A_Distance_in_sp.do"
do "${processing_code}/K_spatial/K01AT_Distance_in_sp_truncated.do"

do "${processing_code}/K_spatial/K08_extract_most_constraining.do"

do "${processing_code}/K_spatial/K10_generate_spatial_lags.do"
do "${processing_code}/K_spatial/K10T_generate_spatial_lags.do"












/*do "${processing_code}/K_spatial/K02_spatial_lags.do" */


/* construct and join the aggregate jointness metric based on Survey data doesnt work yet, haven't coded the length filter
do "${processing_code}/H_jointness/assembleH06_bottomtrawl_overlaps.do"
*/

