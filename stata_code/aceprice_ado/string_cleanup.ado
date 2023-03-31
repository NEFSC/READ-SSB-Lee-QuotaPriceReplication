/*
Syntax

string_cleanup var 

do some cleanup on the memberid variable


Note, you need to account for ties here */
program string_cleanup

	version 15.1
	args varname
	cap drop `varname'C 
	cap drop lenC
	cap drop rejected

	cap drop wholesector
	gen `varname'C=strlower(subinstr(`varname',"-","",.))
	replace `varname'C=subinstr(`varname'C,"unknown","",.)
	
	gen rejected=0
	replace rejected=1 if inlist(`varname'C,"rejected","error")
	
	replace `varname'C=subinstr(`varname'C,"rejected","",.)
	replace `varname'C=subinstr(`varname'C,"error","",.)
	replace `varname'C=subinstr(`varname'C,"null","",.)

	gen wholesector=0
	replace wholesector=1 if inlist(`varname'C,"nefs 7","nefs 8", "sector", "sector 13")
	replace `varname'C="" if wholesector==1
	gen lenC=strlen(`varname'C)
	gsort - lenC

end
