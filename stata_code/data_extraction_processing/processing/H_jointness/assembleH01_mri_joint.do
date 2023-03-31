version 15.1
#delimit cr
/* this is code that will reshape the DMIS data so that I can construct a jointness measure at the MRI level*/
use $data_external/dmis_trip_catch_discards_universe_$vintage_string.dta, clear
drop if mult_year<=2008
/* this dataset should have no missing values missing */
mdesc
di "`r(miss_vars)'"


cap drop _merge
gen monthly_date=mofd(dofc(trip_date))
format monthly_date %tm

gen catch_live_pounds=pounds+discard
notes catch_live_pounds: pounds plus discard


levelsof stockcode, local(mystocks)

/*This takes a little while...maybe a minute or two */
qui foreach l of local mystocks{
preserve
noi di "working on stock `l'"
	tempfile dmis1
	local dsp1 `"`dsp1'"`dmis1'" "'  
	/* restrict to only rows where stock l was caught or charged*/
	gen tt=stockcode==`l' & catch_live_pounds>0
	bysort trip_id mult_mri: egen tagtrip=total(tt)

	keep if tagtrip>=1
	collapse (sum) pounds landed dlr_dollar catch_live_pounds, by(mult_mri mult_year monthly_date stockcode)

	reshape wide pounds landed dlr_dollar catch_live_pounds, i(mult_mri mult_year monthly_date) j(stockcode)
	gen stockcode=`l'

	
	foreach var of varlist pounds* landed* dlr_dollar* catch_live_pounds*{
		replace `var'=0 if `var'==.
	}
	egen tland=rowtotal(landed*)
	gen tland_ex=tland-landed`l'
	
	
	egen tcatch=rowtotal(catch_live_pounds*)
	gen tcatch_ex=tcatch-catch_live_pounds`l'

	save `dmis1', replace

restore
}
clear
append using `dsp1'


rename mult_mri mri

order stockcode tland* tcatch tcatch_ex, after( monthly_date)
sort mri mult_year monthly_date stockcode
rename mult_year fy

save $data_intermediate/mri_monthly_$vintage_string.dta, replace
/* of course, there are some "duplicate" MRIs: belong to multiple memberids or just affiliated with multiple permit numbers.
 This mostly seems to be A CPH issue */



/*once you get here, you can compute monthly production based stuff.  

fy	mri	monthly_date	stock_code	tland	tland_ex	tcatch	tcatch_ex	pounds1	landed1	dlr_dollar1	catch_live_pounds1
2009	5	2009m6	1	20797	20797	24960.33	24904.39	0	0	0	55.93695
2009	5	2009m6	8	27102	19001	32194.33	22228.97	0	0	0	55.93695
2009	5	2009m6	9	25132	24847	29926.33	29572.37	0	0	0	55.93695

You'll need to figure out 'lag' prices to compute an IV.
You'll also need to work out what to do when the denominator (landings, value) is zero. 

And OTHER
*/
