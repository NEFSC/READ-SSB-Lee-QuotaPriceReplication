global svy_images ${my_images}/survey
cap mkdir $svy_images
local graphopts ylabel(38(2)44) xlabel(-72(2)-66) ytitle("Latitude") xtitle("Longitude") 

use "${data_main}/survey_center_of_mass_${vintage_string}.dta", replace
twoway  scatter lat lon if stockcode<=17,  `graphopts' mlabel(stock) mlabangle(-45) mlabsize(vsmall) mlabposition(9)
		graph export "${svy_images}/centers_overall.png", replace as(png)  width(2000)

export delimited using "${data_main}/overall_centers_${vintage_string}.csv", replace


use "${data_main}/survey_yearly_center_of_mass_${vintage_string}.dta", replace
drop if fishing_year==2020


twoway  (connected lat lon if stockcode==2 , mlabel(fishing_year))  (connected lat lon if stockcode==3 , mlabel(fishing_year))  (connected lat lon if stockcode==8 , mlabel(fishing_year)), ///
	legend(order( 1 "GBE Cod" 2 "GBW Cod" 3 "GOM Cod") rows(1))  `graphopts'

		graph export "${svy_images}/centers_cod.png", replace as(png)  width(2000)


twoway  (connected lat lon if stockcode==1 , mlabel(fishing_year))  (connected lat lon if stockcode==7 , mlabel(fishing_year))  (connected lat lon if stockcode==14 , mlabel(fishing_year)), ///
	legend(order( 1 "CCGOM Yellowtail" 2 "GB Yellowtail" 3 "SNE Yellowtail") rows(1)) `graphopts'

		graph export "${svy_images}/centers_yellowtail.png", replace as(png)  width(2000)

		
		
twoway  (connected lat lon if stockcode==4 , mlabel(fishing_year))  (connected lat lon if stockcode==5 , mlabel(fishing_year))  (connected lat lon if stockcode==9 , mlabel(fishing_year)), ///
	legend(order( 1 "GBE Haddock" 2 "GBW Haddock" 3 "GOM Haddock") rows(1)) `graphopts'

		graph export "${svy_images}/centers_haddock.png", replace as(png)  width(2000)
		
twoway  (connected lat lon if stockcode==6 , mlabel(fishing_year))  (connected lat lon if stockcode==10 , mlabel(fishing_year))  (connected lat lon if stockcode==17 , mlabel(fishing_year)), ///
	legend(order( 1 "GB Winter" 2 "GOM Winter" 3 "SNEMA Winter") rows(1)) `graphopts'

		graph export "${svy_images}/centers_winter.png", replace as(png)  width(2000)

		
		twoway  (connected lat lon if stockcode==11 , mlabel(fishing_year))  (connected lat lon if stockcode==12 , mlabel(fishing_year))  (connected lat lon if stockcode==13 , mlabel(fishing_year)) ///
		(connected lat lon if stockcode==15 , mlabel(fishing_year)) (connected lat lon if stockcode==16 , mlabel(fishing_year)), ///
	legend(order( 1 "Plaice" 2 "Pollock" 3 "Redfish" 4 "White Hake" 5 "Witch") rows(2)) `graphopts'

		graph export "${svy_images}/centers_units.png", replace as(png)  width(2000)

		
		
				twoway  (connected lat lon if stockcode==2 , mlabel(fishing_year))  (connected lat lon if stockcode==3 , mlabel(fishing_year))  (connected lat lon if stockcode==4 , mlabel(fishing_year)) ///
		(connected lat lon if stockcode==5 , mlabel(fishing_year)) (connected lat lon if stockcode==7 , mlabel(fishing_year)) (connected lat lon if stockcode==6 , mlabel(fishing_year)), ///
	legend(order( 1 "GBE Cod" 2 "GBW Cod" 3 "GBE Haddock" 4 "GBW Haddock" 5 "GB Yellowtail" 6 "GB Winter" ) rows(2)) `graphopts'

		graph export "${svy_images}/centers_GB.png", replace as(png)  width(2000)

		
		
		twoway  (connected lat lon if stockcode==8 , mlabel(fishing_year))  (connected lat lon if stockcode==1 , mlabel(fishing_year))  (connected lat lon if stockcode==9 , mlabel(fishing_year)) ///
		(connected lat lon if stockcode==10 , mlabel(fishing_year)) , ///
	legend(order( 1 "GOM Cod" 2 "GoM Yellowtail" 3 "GOM Haddock" 4 "GOM Winter") rows(2)) `graphopts'

		graph export "${svy_images}/centers_GOM.png", replace as(png)  width(2000)
