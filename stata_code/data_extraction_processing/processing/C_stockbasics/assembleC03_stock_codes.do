/*construct a keyfile for stock codes.
*/


version 15.1
#delimit cr
pause on
local infile ${data_main}/var_stock_name_link.csv

local savename ${data_main}/stock_codes_${vintage_string}.dta
clear
input str20 stock_name  str10 stock_id stockcode
"Halibut" "HALGMMA"	101
"Ocean Pout" "OPTGMMA" 102
"Northern Windowpane" "FLGMGBSS" 103
"Southern Windowpane" "FLDSNEMA"	104
"Wolffish" "WOLGMMA"	105
"Other" "OTHER"	999
end
tempfile others
save `others', replace



import delimited `infile', clear varnames(1)
egen stockcode=sieve(var), char(0123456789)
destring stockcode, replace
drop var
gen str10 stock_id=""
replace stock_id="YELCCGM" if stockcode==1
replace stock_id="CODGBE" if stockcode==2
replace stock_id="CODGBW" if stockcode==3
replace stock_id="HADGBE" if stockcode==4
replace stock_id="HADGBW" if stockcode==5
replace stock_id="FLWGB" if stockcode==6
replace stock_id="YELGB" if stockcode==7
replace stock_id="CODGMSS" if stockcode==8
replace stock_id="HADGM" if stockcode==9
replace stock_id="FLWGMSS" if stockcode==10
replace stock_id="PLAGMMA" if stockcode==11
replace stock_id="POKGMASS" if stockcode==12
replace stock_id="REDGMGBSS" if stockcode==13
replace stock_id="YELSNE" if stockcode==14
replace stock_id="HKWGMMA" if stockcode==15
replace stock_id="WITGMMA" if stockcode==16
replace stock_id="FLWSNEMA" if stockcode==17


append using `others'

notes stock_id: stock_id comes from DMIS
notes stock_name: this is just decoding the stockcode variable

replace stock_name=subinstr(stock_name,"CC/GOM","CCGOM",.)
replace stock_name=subinstr(stock_name,"SNE/MA","SNEMA",.)
replace stock_name=subinstr(stock_name,"_"," ",.)
replace stock_name=ltrim(rtrim(itrim(stock_name)))
replace stock_name="Other" if stockcode==999

replace stock_name="GBE Cod" if stockcode==2
replace stock_name="GBW Cod" if stockcode==3
replace stock_name="GBE Haddock" if stockcode==4
replace stock_name="GBW Haddock" if stockcode==5


recode stockcode 1 7 14=123 2 3 8=81 4 5 9=147  6 10 17=120   11=124 12=269  13=240 15=153 16=122 101=159 102=250 103 104=125 105=512, gen(nespp3)
gen stockarea="Unit"
replace stockarea="GOM" if inlist(stockcode, 8,9,10)
replace stockarea="GB" if inlist(stockcode, 6,7)
replace stockarea="GBE" if inlist(stockcode, 2,4)
replace stockarea="GBW" if inlist(stockcode, 3,5)
replace stockarea="SNEMA" if inlist(stockcode, 14,17)
replace stockarea="CCGOM" if inlist(stockcode, 1)





notes stockarea: this is the name of the stock area. The stock areas are not necessarily the same across species
compress

gen str30 spstock2=""
replace spstock2="haddockGB" if inlist(stockcode,4,5)
replace spstock2="codGB" if inlist(stockcode,2,3)
replace spstock2="redfish" if inlist(stockcode,13)
replace spstock2="pollock" if inlist(stockcode,12)
replace spstock2="witchflounder" if inlist(stockcode,16)
replace spstock2="winterflounderGB" if inlist(stockcode,6)
replace spstock2="haddockGOM" if inlist(stockcode,9)
replace spstock2="whitehake" if inlist(stockcode,15)
replace spstock2="winterflounderGOM" if inlist(stockcode,10)
replace spstock2="yellowtailflounderCCGOM" if inlist(stockcode,1)
replace spstock2="yellowtailflounderGB" if inlist(stockcode,7)
replace spstock2="yellowtailflounderSNEMA" if inlist(stockcode,14)
replace spstock2="codGOM" if inlist(stockcode,8)
replace spstock2="americanplaiceflounder" if inlist(stockcode,11)


sort stockcode 
bysort stockcode: assert _N==1
rename stock_name stock
order stock_id stockcode stock nespp3 stockarea
save `savename', replace

