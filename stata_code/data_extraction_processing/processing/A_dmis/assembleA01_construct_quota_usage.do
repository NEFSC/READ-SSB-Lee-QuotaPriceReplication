/* construct monthly quota usage from dmis */
#delimit;
use  $data_external/dmis_trip_catch_discards_universe_$vintage_string.dta, replace;

gen live_removals=pounds+discard;
gen trip_monthly_date=mofd(dofc(trip_date));
format trip_monthly_date %tm;

gen quota_charge=pounds+discard;
collapse (sum) quota_charge, by(mult_year trip_monthly_date stock_id stockcode);

bysort stock_id mult_year (trip_monthly_date): gen cumulative_quota_use=sum(quota_charge);
replace cumul=round(cumulative_quota_use);
gen month_of_fy=month(dofm(trip_monthly_date))-4;
replace month_of_fy=month_of_fy+12 if month<=0;
rename mult_year fishing_year;
notes quota_charge: pounds plus discards from DMIS;
notes cumulative_quota_use: Running sum (within a fishing year) of quota_charge from DMIS;
notes: stockcode corresponds to chad's encoding of ace prices;
save $data_external/dmis_monthly_quota_usage_$vintage_string.dta, replace;
