/* graph monthly quota available indices after
indicesL02_stock_level.do */

version 15.1
#delimit cr
pause off
set scheme s2mono

global single_index ${exploratory}/single_index
cap mkdir ${single_index}

global stock_indices ${exploratory}/stock_indices
cap mkdir ${stock_indices}



local in_quota_available ${data_intermediate}/quota_available_indices_${vintage_string}.dta

use `in_quota_available', replace
keep if stockcode<=99
/* graph */
local tlines "tline(612(12)720, lpattern(dash) lcolor(gs12) lwidth(vthin)) " 
local panelopts ttitle("Month") tlabel(612(24)720, angle(45) format(%tmCCYY))  

keep if stockcode<=99

xtline stock_PQR_Index , `tlines' `panelopts'  ytitle("p-weighted Quota Remaining Index") name(pqr_index,replace)
graph export ${stock_indices}/monthly_stock_PQR_Index.png, as(png) width(2000) replace


xtline stock_QR_Index , `tlines' `panelopts'  ytitle("Quota Remaining Index") name(qr_index,replace)
graph export ${stock_indices}/monthly_stock_QR_Index.png, as(png) width(2000) replace



xtline stock_HHI_Q, `tlines' `panelopts'  ytitle("HHI") name(HHI_Q,replace)
graph export ${stock_indices}/monthly_stock_HHI_Q.png, as(png) width(2000) replace


xtline stock_HHI_PQ, `tlines' `panelopts'  ytitle("p-weighted HHI") name(HHI_PQ,replace)
graph export ${stock_indices}/monthly_stock_HHI_PQ.png, as(png) width(2000) replace



xtline stock_shannon_Q, `tlines' `panelopts'  ytitle("Shannon") name(shannon_Q,replace)
graph export ${stock_indices}/monthly_stock_Shannon_Q.png, as(png) width(2000) replace

xtline stock_shannon_PQ, `tlines' `panelopts'  ytitle("p-weighted Shannon") name(shannon_PQ,replace)

graph export ${stock_indices}/monthly_stock_Shannon_PQ.png, as(png) width(2000) replace




/* graph monthly quota available indices after
indicesL01_fishery_level.do */

local outfile ${data_intermediate}/fishery_level_monthly_quota_available_indices_${vintage_string}.dta

use `outfile', clear



local graph_opts overlay legend(order(1 "2010" 2 "2011" 3 "2012" 4 "2013" 5 "2014" 6 "2015" 7 "2016" 8 "2017" 9 "2018" 10 "2019") rows(2)) ttitle("Month of FY")



xtline fishery_shannon_Q,  ytitle("Shannon H")  `graph_opts'
graph export ${single_index}/monthly_shannon_Q.png, as(png) width(2000) replace

xtline fishery_HHI_Q, `graph_opts' ytitle("HHI")
graph export ${single_index}/monthly_HHI_Q.png, as(png) width(2000) replace

xtline fishery_QR_Index, `graph_opts' ytitle("Quota Index") 
graph export ${single_index}/monthly_QR_Index.png, as(png) width(2000) replace

xtline fishery_PQR_Index, `graph_opts' ytitle("Quota Value Index ") 
graph export ${single_index}/monthly_PQR_Index.png, as(png) width(2000) replace

xtline fishery_shannon_PQ, `graph_opts' ytitle("Shannon Index (p weighted)")  
graph export ${single_index}/monthly_shannon_PQ.png, as(png) width(2000) replace

xtline fishery_HHI_PQ, `graph_opts' ytitle("HHI (p weighted)") 
graph export ${single_index}/monthly_HHI_PQ.png, as(png) width(2000) replace
