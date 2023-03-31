/* Import observer coverage information from Chad*/
version 15.1
clear

local inputfile ${data_external}/stock_fy_proportions.csv
local stockcodes ${data_main}/stock_codes_${vintage_string}.dta
local savefile ${data_main}/observed_by_stock_${vintage_string}.dta


import delimited using `inputfile'
cap drop v1
cap drop all_catch
rename observer observed
reshape wide catch proportion, i(fy stock_name) j(observed)

rename catch0 catch_non
rename catch1 catch_observed
rename proportion_catch0 proportion_non
rename proportion_catch1 proportion_observed
order fy stock_name catch* proportion*

gen stockcode=.
replace stockcode=1 if inlist(stock_name,"CC/GOM_Yellowtail_Flounder")
replace stockcode=2 if inlist(stock_name,"GB_Cod_East")
replace stockcode=3 if inlist(stock_name,"GB_Cod_West")
replace stockcode=4 if inlist(stock_name,"GB_Haddock_East")
replace stockcode=5 if inlist(stock_name,"GB_Haddock_West")
replace stockcode=6 if inlist(stock_name,"GB_Winter_Flounder")
replace stockcode=7 if inlist(stock_name,"GB_Yellowtail_Flounder")
replace stockcode=8 if inlist(stock_name,"GOM_Cod")
replace stockcode=9 if inlist(stock_name,"GOM_Haddock")
replace stockcode=10 if inlist(stock_name,"GOM_Winter_Flounder")

replace stockcode=11 if inlist(stock_name,"Plaice")
replace stockcode=12 if inlist(stock_name,"Pollock")
replace stockcode=13 if inlist(stock_name,"Redfish")
replace stockcode=14 if inlist(stock_name,"SNE/MA_Yellowtail_Flounder")
replace stockcode=15 if inlist(stock_name,"White_Hake")
replace stockcode=16 if inlist(stock_name,"Witch_Flounder")

replace stockcode=17 if inlist(stock_name,"SNE_Winter_Flounder")


replace stockcode=101 if inlist(stock_name,"Halibut")
replace stockcode=102 if inlist(stock_name,"Ocean_Pout")
replace stockcode=103  if inlist(stock_name,"Northern_Windowpane")
replace stockcode=104 if inlist(stock_name,"Southern_Windowpane")
replace stockcode=105 if inlist(stock_name,"Wolffish")
replace stockcode=999 if inlist(stock_name,"NONGROUNDFISH")

     
merge m:1 stockcode using `stockcodes' 


replace stock_id="NONGF" if stockcode==999
replace stock="NONGF" if stockcode==999
replace stockarea="NA" if stockcode==999

drop stock_name
drop _merge
rename fy fishing_year
save `savefile', replace
