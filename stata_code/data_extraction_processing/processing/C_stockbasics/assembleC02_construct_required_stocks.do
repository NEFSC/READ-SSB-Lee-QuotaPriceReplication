local infile ${data_main}/stock_area_definitions_${vintage_string}.dta
local stockcodebook ${data_main}/stock_codes_${vintage_string}.dta

local outfile ${data_main}/required_stocks_${vintage_string}.dta
use `infile', clear

keep if stockmarker~=0

rename stockcode stock_id

egen stockcode=sieve(code), char(0123456789.)
destring stockcode, replace

levelsof stockcode, local(stocks)


foreach l of local stocks{
	tempfile new5555
	local dsp1 `"`dsp1'"`new5555'" "'  
	preserve
	levelsof statarea if stockcode==`l', local(myloc) separate(",")
	keep if inlist(statarea, `myloc')
	collapse (sum) stockmarker statarea_km, by(stockcode)
	rename stockcode required
	gen stockcode=`l'
	quietly save `new5555', replace
	restore
}

clear

append using `dsp1'
order stockcode required
notes: Raw data for constructing contiguity matrices for stocks.

merge m:1 stockcode using `stockcodebook', keep(1 3)

labmask stockcode, values(stock)
label values required stockcode
keep stockcode required stockmarker statarea_km 
rename stockmarker count_statareas

save  `outfile', replace
