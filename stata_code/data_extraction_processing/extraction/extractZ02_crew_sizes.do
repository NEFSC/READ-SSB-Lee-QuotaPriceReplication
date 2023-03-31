
/*
Code to extra ace price data.

*/


#delimit;
version 15.1;
pause off;


clear;
odbc load,  exec("select mult_year, round(avg(crew), 2) as avg_crew from APSD.t_ssb_trip_current@garfo_nefsc where trip_id in (
	select distinct trip_id from APSD.t_ssb_catch_current@garfo_nefsc where FISHERY_GROUP='GROUND')  
	group by mult_year;")  $mysole_conn; 
renvarlab, lower;
destring, replace;
save "${data_internal}/average_crew_size_${vintage_string}.dta", replace;




