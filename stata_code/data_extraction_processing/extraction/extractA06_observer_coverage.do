/* Import observer coverage information from FY2020 Multispecies Sesctor ASM Requirements Summary
You saved the pdf as an excel file and then moved the table you want to individual sheets
table1 table2*/
version 15.1
clear



import excel using ${data_external}/FY2021_Multispecies_Sector_ASM_Requirements_Summary.xlsx, sheet("table1") firstrow clear

rename A stock
/*drop B
*/
reshape long CV coveragerate, i(stock) j(year)
replace coveragerate=coverage/100
notes CV: this is the achieved CV by the NEFOP and ASM
notes coveragerate: this the the percentage of trips needed to be monitored to achieve the 30CV.

replace stock="GBE Cod" if stock=="GB Cod East"
replace stock="GBW Cod" if stock=="GB Cod West"


replace stock="GBE Haddock" if stock=="GB Haddock East"
replace stock="GBW Haddock" if stock=="GB Haddock West"


merge m:1 stock using ${data_main}\stock_codes_$vintage_string.dta
/* add in stock_codes for GB haddock and GB cod */
drop _merge
rename year fishing_year
replace stockcode=98 if stock=="GB Haddock"
replace stockcode=99 if stock=="GB Cod"

save ${data_main}\stock_coverage_rates_$vintage_string.dta, replace

clear
import excel using ${data_external}/FY2021_Multispecies_Sector_ASM_Requirements_Summary.xlsx, sheet("table4") firstrow
egen fishing_year=sieve(FishingYear), char(0123456789)
destring fishing_year, replace
drop FishingYear
renvars, lower
notes nefoptargetcoveragelevel: nefop targeted coverage level
notes asmtargetcoveragelevel: asm targeted coverage level
notes totaltargetcoveragelevel: Combined Targeted Coverage Level
notes  realizedcoveragelevel: actual coverage level by asm and nefop combined
save ${data_main}\sector_coverage_rates_$vintage_string.dta, replace


/*
stock

2020_07_30.dta", clear


Wolffish
*/
