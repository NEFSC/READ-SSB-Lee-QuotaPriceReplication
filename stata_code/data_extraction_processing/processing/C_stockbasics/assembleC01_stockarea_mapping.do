/* make a small dataset of stockareas */

/* read in the square_km of each stockarea */
clear
import delimited ${data_external}/gis/stat_area_km.csv
keep id km2
compress
rename id statarea
rename km2 area_km2
tempfile square_km
save `square_km'



local outfile ${data_main}/stock_area_definitions_${vintage_string}.dta


clear
input str20(code species stockarea stockcode)
z1 	 "Yellowtail Flounder" 	 CCGOM	 YELCCGM
z2 	 Cod 	 GB-East	 CODGBE
z3 	 Cod 	 GB-West 	 CODGBW
z4 	 Haddock 	 GB-East 	 HADGBE
z5 	 Haddock 	 GB-West 	 HADGBW
z6 	 "Winter Flounder" 	 GB 	 FLWGB
z7 	 Yellowtail 	 GB 	 YELGB
z8 	 Cod 	 GOM 	 CODGMSS
z9 	 Haddock 	 GOM 	 HADGM
z10 	 "Winter Flounder" 	 GOM 	 FLWGMSS
z11 	 Plaice 	 Unit 	 PLAGMMA
z12 	 Pollock 	 Unit 	 POKGMASS
z13 	 Redfish 	 Unit 	 REDGMGBSS
z14 	 "Yellowtail Flounder" 	 SNEMA 	 YELSNE
z15 	 "White Hake" 	 Unit 	 HKWGMMA
z16 	 "Witch Flounder" 	 Unit 	 WITGMMA
z17 	 "Winter Flounder" 	 SNEMA 	 FLWSNEMA
z101 	 "Halibut" 	 GMMA 	 HALGMMA
z102 	 "Ocean Pout" 	 GMMA 	 OPTGMMA
z103 	 "Windowpane Flounder" 	 N 	FLGMGBSS
z104 	 "Windowpane Flounder" 	 S 	FLDSNEMA
z105 	 "Wolffish" 	 GMMA 	WOLGMMA
z999 	 "Other" 	 Unit 	OTHER

end
compress

expand 43
sort code
local statareas 511/515 521 522 525 526 533 534 537/539 541/543 561 562 611/616 621/629 631/639
egen statarea=fill( `statareas' `statareas')

gen stockmarker=0
replace stockmarker=1 if stockcode=="YELCCGM" & inlist(statarea, 511,512,513,514,515,521)
replace stockmarker=1 if stockcode=="CODGBE" & inlist(statarea, 561,562)
replace stockmarker=1 if stockcode=="HADGBE" & inlist(statarea, 561,562)
replace stockmarker=1 if stockcode=="CODGBW" & inlist(statarea, 522,525,542,543,521,526,541,542,537,538,533,534,539, 541)
replace stockmarker=1 if stockcode=="HADGBW" & inlist(statarea, 522,525,542,543,521,526,541,542,537,538,533,534,539, 541)
replace stockmarker=1 if stockcode=="FLWGB" & inlist(statarea, 522,525,561,562,542,543)
replace stockmarker=1 if stockcode=="CODGMSS" & inlist(statarea, 511,512,513,514,515)
replace stockmarker=1 if stockcode=="HADGM" & inlist(statarea, 511,512,513,514,515)
replace stockmarker=1 if stockcode=="FLWGMSS" & inlist(statarea, 511,512,513,514,515)
replace stockmarker=1 if stockcode=="YELSNE" & inlist(statarea, 526,541,542,537,538,533,534,541)
replace stockmarker=1 if stockcode=="FLWSNEMA" & inlist(statarea, 521,526,537,538,533,534,541)
replace stockmarker=1 if stockcode=="YELGB" & inlist(statarea, 522,525,551,552,561,562)

/* GARM III map: noaa_5227_DS1.pdf pages 2-704, 2-724, 2-844*/
replace stockmarker=1 if stockcode=="OPTGMMA" & statarea>=511 & statarea<=623 

replace stockmarker=1 if stockcode=="FLGMGBSS" & inlist(statarea, 511,512,513,514,515,521,522,525,542,543, 561,551,562,552,465,464)
replace stockmarker=1 if stockcode=="FLDSNEMA" & inlist(statarea,526, 533,534, 537,538, 539, 541)
replace stockmarker=1 if stockcode=="HALGMMA" & inlist(statarea,511,512,513,514,515,521,522,525,526,561,551,562,552)


/* Data Poor Stock assessments 2007, noaa_3613_DS1.pdf page 245 */
replace stockmarker=1 if stockcode=="WOLGMMA" & inlist(statarea,512,513,514,515,521,522,525,526,537)


/* add on the southern stat areas for these stocks */
replace stockmarker=1 if inlist(stockcode,"CODGBW","HADGBW","YELSNE","FLWSNEMA","FLDSNEMA") & statarea>=611
/*
https://www.nefsc.noaa.gov/saw/sasi/uploads/2017_YEL_GB_FIG_all_figures.pdf*/

replace stockmarker=1 if stockarea=="Unit"

/* Need to create an adjusted stockmaker variable that is sometimes= 0 when there isn't actually any fishing in those stat areas. 
	This is important for the unit stocks and the southern stocks because there are lots of stat areas here which don't really have much fishing in it.

This is probably okay for a weighting matrix based on counting stat areas. but what about for area-wise? 

*/

/*******************************/




merge m:1 statarea using `square_km', keep(1 3)
assert _merge==3
drop _merge

/*******************************/
gen statarea_km=stockmarker*area_km2

save `outfile', replace
