/* graph monthly quota available indices after
indicesL02Q_quarterly_stock_level.do */

version 15.1
#delimit cr
pause off
set scheme s2mono

global single_index ${exploratory}/single_index
cap mkdir ${single_index}

global stock_indices ${exploratory}/stock_indices
cap mkdir ${stock_indices}



local fishery_concentration ${data_main}/quarterly_stock_concentration_index_${vintage_string}.dta

use `fishery_concentration', replace
keep if stockcode<=99



local tlines "tline(200(4)240, lpattern(dash) lcolor(gs12) lwidth(vthin)) " 
local panelopts ttitle("Month") tlabel(200(8)240, angle(45) format(%tqCCYY)) 

xtline stock_PQR_Index, `tlines' `panelopts'  ytitle("p-weighted Quota Remaining index") name(stock_output_value,replace)
graph export ${stock_indices}/quarterly_stock_PQR_Index.png, as(png) width(2000) replace


xtline stock_QR_Index, `tlines' `panelopts'  ytitle("Quota Remaining index") name(quota_remain,replace)
graph export ${stock_indices}/quarterly_stock_QR_Index.png, as(png) width(2000) replace

xtline stock_HHI_Q, `tlines' `panelopts'  ytitle("HHI") name(HHI,replace)
graph export ${stock_indices}/quarterly_stock_HHI_Q.png, as(png) width(2000) replace


xtline stock_HHI_PQ, `tlines' `panelopts'  ytitle("p-weighted HHI") name(HHI_Q,replace)
graph export ${stock_indices}/quarterly_stock_HHI_PQ.png, as(png) width(2000) replace



xtline stock_shannon_Q, `tlines' `panelopts'  ytitle("Shannon") name(shannon,replace)
graph export ${stock_indices}/quarterly_stock_Shannon_Q.png, as(png) width(2000) replace

xtline stock_shannon_PQ, `tlines' `panelopts'  ytitle("p-weighted Shannon") name(shannon_Q,replace)

graph export ${stock_indices}/quarterly_stock_Shannon_PQ.png, as(png) width(2000) replace






/* graph monthly quota available indices after
indicesL01Q_fishery_level.do */

local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta
use `fishery_concentration', clear



local graph_opts overlay legend(order(1 "2010" 2 "2011" 3 "2012" 4 "2013" 5 "2014" 6 "2015" 7 "2016" 8 "2017" 9 "2018" 10 "2019") rows(2)) ttitle("Quarter of FY")

xtline fishery_shannon_Q,  ytitle("Shannon H")  `graph_opts'
graph export ${single_index}/quarterly_shannonQ.png, as(png) width(2000) replace
xtline fishery_HHI_Q, `graph_opts' ytitle("HHI")
graph export ${single_index}/quarterly_HHIQ.png, as(png) width(2000) replace

xtline fishery_QR_Index, `graph_opts' ytitle("Quota Index (unweighted M)") 
graph export ${single_index}/quarterly_unweighted_quota_available.png, as(png) width(2000) replace








xtline fishery_PQR_Index, `graph_opts' ytitle("Quota Index (p weighted M)") 
graph export ${single_index}/quarterly_pweighted_quota_available.png, as(png) width(2000) replace

xtline fishery_shannon_PQ, `graph_opts' ytitle("Shannon Index (p weighted)")  
graph export ${single_index}/quarterly_pweighted_shannon_available.png, as(png) width(2000) replace

xtline fishery_HHI_PQ, `graph_opts' ytitle("HHI (p weighted)") 
graph export ${single_index}/quarterly_pweighted_HHI_available.png, as(png) width(2000) replace
