/* construct monthly quota usage from dmis */
#delimit;
use $data_external/dmis_monthly_quota_usage_$vintage_string.dta, replace;

gen month=month(dofm(trip_monthly_date));
gen m_fy=month-4;
replace m_fy=m_fy+12 if m_fy<=0;

gen q_fy=irecode(m_fy,0,3,6,9,12);

collapse (sum) quota_charge, by(fishing_year q_fy stock_id stockcode);

bysort stock_id fishing_year (q_fy): gen cumulative_quota_use=sum(quota_charge);
notes q_fy: quarter of fishing_year (q_fy=1 for MJJ =2 for ASO =3 NDJ 4 FMA);
gen quarterly=yq(fishing_year, q_fy);
notes quarterly: quarter, where MJJ is quarter 1 of the fishing_year;

replace cumul=round(cumul);

format quarterly %tq;
order stockcode stock_id quarterly fishing_year q_fy;
notes quota_charge: pounds plus discards from DMIS;
notes cumulative_quota_use: Running sum (within a fishing year) of quota_charge from DMIS;
save $data_external/dmis_quarterly_quota_usage_$vintage_string.dta, replace;
