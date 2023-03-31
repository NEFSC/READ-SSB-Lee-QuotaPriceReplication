import fred DDFUELNYH, daterange(2006-01-01 .) clear aggregate(monthly, avg)

save $data_external/diesel_$vintage_string.dta, replace
