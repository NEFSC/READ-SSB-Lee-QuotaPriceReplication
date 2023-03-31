/*this is a do file to a make some exploratory plots

You need to add an "if e(sample) type code. 

 */

cap log close

local mylogfile "${my_results}/first_stage_R2_table.smcl" 
log using `mylogfile', replace


#delimit cr
version 15.1
pause on
clear all
spmatrix clear
global common_seed 06240628


local stock_concentration ${data_main}/quarterly_stock_concentration_index_${vintage_string}.dta
local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta
local stock_concentration_noex ${data_main}/quarterly_stock_concentration_index_no_ex_${vintage_string}.dta
local stock_disjoint ${data_main}/quarterly_stock_disjoint_index_${vintage_string}.dta

local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local spset_key2 "${data_main}/truncated_spset_id_keyfile_${vintage_string}.dta"
local spatial_lags ${data_main}/spatial_lags_${vintage_string}.dta
local spatial_lagsT ${data_main}/Tspatial_lags_${vintage_string}.dta

local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local  constraining ${data_main}/most_constraining_${vintage_string}.dta


/* read in the spmatrices previously created */
do "${processing_code}/K_spatial/K09T_readin_trunc_stswm.do"


use `prices', clear
drop if fishing_year==2010 & q_fy<=2
drop if fishing_year<=2009
drop if fishing_year>=2020 

sort fishing_year q_fy n r2
bysort fishing_year q_fy: keep if _n==1



keep fishing_year q_fy r2 n
sort fishing_year q_fy

label var fishing_year "Fishing Year"
label var q_fy "Quarter"
label var r2 "R^2"
label var n "Observations"


/* cast to strings to get fine control of display formats */
format r2 %03.2fc

tostring r2, gen(myr2) usedisplayformat force
drop r2 
rename myr2 r2


tostring n, gen(myn) usedisplayformat force
drop n
rename myn n
replace n="("+n +")"


label var r2 "R^2"

sort fishing_year q_fy
order fishing_year q_fy r2 n



preserve
tempfile r2

keep fishing_year q_fy r2
rename r2 Q
reshape wide Q, i(fishing_year) j(q_fy)
gen str2 var="r2"
save `r2', replace

restore

keep fishing_year q_fy n
rename n Q
reshape wide Q, i(fishing_year) j(q_fy)
gen str2 var="n"
append using `r2'


gsort fishing_year - var

tostring fishing_year, gen(myfishing_year) usedisplayformat force
drop fishing_year
rename myfishing_year fishing_year
replace fishing_year="" if var=="n"
order fishing_year Q1 Q2 Q3 Q4

texsave fishing_year Q1 Q2 Q3 Q4 using  ${my_tables}/first_stage_r2.tex, frag replace varlabels


import delimited using  ${my_tables}/first_stage_r2.tex, clear

/*strip off bottom */

keep if _n<=26
/* strip off top */
drop if _n<=6

/* save */
export delimited using  ${my_tables}/first_stage_r2.tex, novarnames replace



log close
