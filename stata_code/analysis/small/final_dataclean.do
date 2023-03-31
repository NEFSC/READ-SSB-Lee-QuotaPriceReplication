/* this is the last bit of datacleaning that I do before estimating */


cap drop qtr

order z1-z17, after(to_sector_name)

drop if fy>=2020

gen lease_only_sector=inlist(from_sector_name,"NEFS 4", "Maine Sector/MPBS")


gen fyq=yq(fy,q_fy)

/* there's only a few obs in Q1 of FY2010 and Q2 of FY2010. I'm pooling them into Q3 of 2010. */

replace fyq=yq(2010,3) if fyq==yq(2010,1) | fyq==yq(2010,2)
cap drop q_fy
gen q_fy=quarter(dofq(fyq))

gen cons=1
gen qtr1 = q_fy==1
gen qtr2 = q_fy==2
gen qtr3 = q_fy==3
gen qtr4 = q_fy==4


gen end=mdy(5,1,fy+1)
gen begin=mdy(5,1,fy)
gen season_remain=(end-date1)/(end-begin)

gen season_elapsed=1-season_remain

/* Data cleaning step: */
/*  (3786 is a transfer of 2014 quota, probably to balance)*/

foreach var of varlist date1  {
replace `var'=td(30apr2015) if transfer_number==3786
}
replace fy=2014 if inlist(transfer_number,3786)
replace q_fy=4 if inlist(transfer_number,3786)
replace fyq=yq(2014,4) if inlist(transfer_number,3786)
/* */

/* some data corrections based on comdt_desc*/
/*3841 and 3842 references a trade between 20 and 16 that was supposed to be dabs 
This refers to transfer 3823.  We need to adjust CCGOM YTF=0 and Place=25000 in transfer_number 3823
and then drop 3841 3842
*/
replace z11=z1 if transfer_number==3823
replace z1=0 if transfer_number==3823

drop if inlist(transfer_number,3841, 3842)

/* 3992 references a double trade between 12 and 7 that was un-done.*/
drop if inlist(transfer_number,3990,3992)
Zdelabel


gen nstocks=0

foreach var of varlist CCGOM_yellowtail- SNEMA_winter{
	replace nstocks=nstocks+1 if `var'>0
}
/**/


/* define constraints 
                */
constraint define 1 CCGOM_yellowtail=0
constraint define 2 GBE_cod=0
constraint define 3 GBW_cod=0
constraint define 4 GBE_haddock=0
constraint define 5 GBW_haddock=0
constraint define 6 GB_winter=0
constraint define 7 GB_yellowtail=0
constraint define 8 GOM_cod=0
constraint define 9 GOM_haddock=0
constraint define 10 GOM_winter=0
constraint define 11 plaice=0
constraint define 12 pollock=0
constraint define 13 redfish=0
constraint define 14 SNEMA_yellowtail=0
constraint define 15 white_hake=0
constraint define 16 witch_flounder=0
constraint define 17 SNEMA_winter=0




/* bring in deflators and construct real compensation */

preserve
use  "$data_external/deflatorsQ_${vintage_string}.dta", clear
keep dateq  fGDPDEF_2010Q1 fPCU483483 fPCU31173117_2010Q1

rename fGDPDEF_2010Q1 fGDP
rename fPCU483483 fwater_transport
rename fPCU31173117_2010Q1 fseafoodproductpreparation

notes fGDP: Implicit price deflator
notes fwater: Industry PPI for water transport services
notes fseafood: Industry PPI for seafood product prep and packaging
tempfile deflators
save `deflators'
restore

gen dateq=qofd(date1)
format dateq %tq
merge m:1 dateq using `deflators', keep(1 3)
assert _merge==3
drop _merge


gen compensationR_GDPDEF=compensation/fGDP

gen compensationR_water=compensation/fwater_transport
gen compensationR_seafood=compensation/fseafoodproductpreparation





 /* set up interaction variable */
gen lease_only_pounds=lease_only_sector*total_lbs

clonevar totalpounds2=total_lbs
clonevar lease_only_pounds2=lease_only_pounds

















