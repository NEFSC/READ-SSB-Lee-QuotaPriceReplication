#delimit cr
pause on
global overlap_images ${my_images}/overlap
cap mkdir $overlap_images
set scheme s2mono

local overlap_dataset "${data_main}/overlap_indices_${vintage_string}.dta"
local overlap_survey1_dataset "${data_main}/overlap_indices_survey_nofilter_${vintage_string}.dta"

use `overlap_dataset', clear
label define stockcode 999 "Non-Groundfish", modify
merge 1:1 stock1 stock2 fishing_year using `overlap_survey1_dataset'
/* note: the fishing based overlaps have data for 2007-2020. The survey has 2009-2019. Survey also doesn't have non-groundfish yet. So we expect _merge==1 <--> fy 2007 or fy2008  */

assert _merge==1 if inlist(fishing_year,2007,2008)
drop if stock1>=100
drop if stock2>=100
keep if fishing_year>=2010 & fishing_year<=2019
local overlap_graph_opts "tlabel(2010(4)2018, angle(45)) tmtick(##4, grid)  ttitle("") legend(off)  lpattern(solid dash) ytitle("")"

foreach stocknum of numlist 1/17 {
	preserve
	local mm: label stockcode `stocknum'
	
	keep if stock1==`stocknum'

	/* make a set of observations for stock1=stock2 */
	xtset stock2 fishing_year
	qui xtsum
	local exp=r(Tbar)

	expand 2 if _n<=`exp', gen(flag)
	replace stock2=stock1 if flag==1

	foreach var of varlist FK*{
		replace `var'=1 if flag==1
	}
	foreach var of varlist Ru_*{
		replace `var'=0 if flag==1
	}

	
	sort stock1 stock2 fishing_year
	/*xtline  FK_surveywt , `overlap_graph_opts' byopts(title("Similarity of `mm' to: ") note(""))
	xtline FK_revenue FK_charged FK_surveywt FK_surveynum  if stock2<=100 | stock2==999, `overlap_graph_opts' byopts(title("Similarity of `mm' to: "))

	graph export "${overlap_images}/overlapT_`stocknum'.png", replace as(png) width(2000) 
	*/
 	
	
	xtline  Ru_surveywt Ru_surveynum, `overlap_graph_opts' byopts(title("Distance from `mm' to: ") note("")) legend(order(1 "Weight (pounds)" 2 "Abundance (numbers)" ) rows(1))
	graph export "${overlap_images}/RUT_distance_`stocknum'.png", replace as(png)  width(2000) 

	/* construct inverse distances and graph 
	gen ID=1/Ru_surveywt 
	xtline  ID, `overlap_graph_opts' byopts(title("Inverse Distance from `mm' to: ") note(""))
	graph export "${overlap_images}/RUT_ID_`stocknum'.png", replace as(png)  width(2000) 
*/
	restore
}
