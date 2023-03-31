/* code to construct spatial weights matrices from the distance datasets..

This code constructs a "truncated" version of the weights matrices, where we drop out SNEMA Winter in FY 2010, 2011, and 2012 because it was not allocated.

OBJECTIVE: I really need a block diagonal matrix

	W1 0 0 0 0 ... 0
	0 W2 0 0 0 ....
W=[ .	.	.	.	. ]
	.	.	.	.	.
	0	0	0	0	WT
	
Where W1, W2, .... WT are the nxn distance matrices for each quarter.

After the Final tidy ups, the data starts is "long".  It's not a perfect dyad, since there are no obs where stock1==stock2
stock1, stock1, fishing_year, Ru*
n=17 (stocks)
T=12 (years)

There are a few observations less than the full set of spatial weights matrices.
*/


#delimit cr
version 15.1
pause off
clear all
set maxvar 20000
timer clear
spmatrix clear

cap mkdir ${data_main}/spatial_weight_matrices

/* this has prices and all the relevant RHS variables */
local overlap_dataset "${data_main}/overlap_indices_${vintage_string}.dta"
local overlap_survey1_dataset "${data_main}/overlap_indices_survey_nofilter_${vintage_string}.dta"
local spset_key1 "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local spset_key2 "${data_main}/truncated_spset_id_keyfile_${vintage_string}.dta"


local spset_key2big "${data_main}/truncated_spset_id_keyfileBIG_${vintage_string}.dta"


use `overlap_dataset', clear

label define stockcode 999 "Non-Groundfish", modify
merge 1:1 stock1 stock2 fishing_year using `overlap_survey1_dataset'
/* note: the fishing based overlaps have data for 2007-2020. The survey has 2009-2019. Survey also doesn't have non-groundfish yet. So we expect _merge==1 <--> fy 2007 or fy2008  */

assert _merge==1 if inlist(fishing_year,2007,2008)



/* final tidy ups */
/* 1.  drop the non-allocated stocks*/
drop if inlist(stock1,101,102,103,104,105,999)
drop if inlist(stock2,101,102,103,104,105,999)

/* drop out Ru_discard */
drop Ru_discard
keep fishing_year stock1 stock2 Ru_*
/* just FYs 2010 to 2019 */
keep if fishing_year>=2010 & fishing_year<=2019

/* for testing purposes 
keep if fishing_year==2012|fishing_year==2013
*/
/* variable rename */
rename Ru_pounds land
rename Ru_revenue rev
rename Ru_charged catch
rename Ru_surveywt swt
rename Ru_surveynum snum

/*********************************************************************/
/*********************************************************************/
/* When I constructed the data, I did not construct Ru for stock1==stock2*/
/* the Ru distances range from 0 to 1, where 0 is stock1=stock2, and 1 is zero overlap between the two stocks */
/* We need to create an extra observation and fill it stock1=stock2 and Ru*=99 */

count if stock1==stock2
assert r(N)==0



bysort fishing_year stock1: gen marker=_n==1
expand 2 if marker==1, gen(mymark)
foreach var of varlist  land rev catch swt snum{
	replace `var'=0 if mymark==1
}
replace stock2=stock1 if mymark==1

foreach var of varlist  land rev catch swt snum{
	assert `var'==0 if mymark==1
}
drop marker mymark
/*********************************************************************/


/*********************************************************************/
/*********************************************************************/

/* drop out the non-groundfish, we just need the allocated groundfish stock1<=17 and stock2<=17 */
keep if stock1<=17 & stock2<=17
keep stock1 stock2 fishing_year land rev catch swt snum




/*Construct nearest neighbors*/

foreach var of varlist  land rev catch swt snum{
	bysort fishing_year stock1: egen `var'_rank=rank(`var')
	replace `var'_rank=. if stock1==stock2 /*something cannot be it's own nearest neighbor */
	
	bysort fishing_year stock1 (`var'_rank): gen N1_`var'=_n==1
	bysort fishing_year stock1 (`var'_rank): gen N2_`var'=_n<=2
	
	replace `var'_rank=. if stock2==17 & fishing_year>=2010 & fishing_year<=2012 /*SNEMA Winter during this time cannot be a neighbor to any stocks. It will have neighbors, but that is okay.*/

	
	/*replace `var'_rank=. if stock1==17 & fishing_year>=2010 & fishing_year<=2012 We DO NOT want to have this here -- it will zero out distances for the SNEMA winter row, which will then randomly let anything be its neighbor. */

	
	bysort fishing_year stock1 (`var'_rank): gen N1A_`var'=_n==1
	bysort fishing_year stock1 (`var'_rank): gen N2A_`var'=_n<=2

	drop `var'_rank
}

/* End of Final Tidy Ups */




pause



/*********************************************************************/
/*************Expand to quarterly data********************************/
expand 4
bysort fishing_year stock1 stock2: gen quarter=_n
order fishing_year quarter

gen dateq=yq(fishing_year, quarter)
format dateq %tq
drop quarter


/*Keep just a subset of the data for testing purposes
keep if dateq<=yq(2010,4)
keep if dateq>=yq(2012,3) & dateq<=yq(2013,2)
*/

/*

I need a (nT) by (nT) matrix 
I have 
nT*n right now. So I need (T) replicates.  This is basically just constructing the Zeros for the off diagonal terms in the block diagonal matrix.
*/

qui summ dateq
local first `r(min)'
local last `r(max)'
local distinct = `last'-`first'+1
expand `distinct'

sort dateq stock1 stock2
egen dateq2=seq(), from(`first') to(`last')
format dateq2 %tq
/* zero out if the dates are not the same */
foreach var of varlist land rev catch swt snum N1* N2* {
	replace `var'=0 if dateq~=dateq2
}


/*********************************************************************/
/*********************************************************************/
/*sort the data properly */
/* the id variable is the distinct stock1 and dateq variable
I want to stack the in blocks such that 
stockcode1, quarter1
stockcode2, quarter1...

stockcode17, quarter1
stockcode1, quarter2
stockcode2, quarter2....

stockcode1, quarterT
stockcode17, quarterT...

So, I want to sort by dateq, stock1,stock2*/
/*********************************************************************/


/*********************************************************************/
/*********************************************************************/
/* construct the ID variables */
/* this is crucial to make sure they spmatrix is joined properly to the data later on*/
sort dateq stock1 stock2
egen id1=group(dateq stock1 )


/* should I do this, or should I just 
clonevar id2=id1 NOPE */
sort dateq2 stock2 stock1
egen id2=group(dateq2 stock2)
sort id1 id2



/*********************************************************************/
/*********************************************************************/

/* do some checks We better we have the same number of groups.*/
summ id1
local firstid1 `r(min)'
local lastid1 `r(max)'
summ id2
local firstid2 `r(min)'
local lastid2 `r(max)'

assert `firstid1'==`firstid2'
assert `lastid1'==`lastid2'
xtset, clear

pause
/*Drop SNEMA Winter prior to 2012 */
drop if stock1==17 & dateq<=yq(2011,4) 
drop if stock2==17 & dateq2<=yq(2011,4) 


preserve
keep id1 id2 stock1 stock2 dateq dateq2
save `spset_key2big', replace
restore

drop stock2 dateq2


keep id1 id2 stock1 dateq land rev catch swt snum N1A_land N2A_land N1A_rev N2A_rev N1A_catch N2A_catch N1A_swt N2A_swt N1A_snum N2A_snum 

/*********************************************************************/
/* Convert my "long" data into matrices. */

/* this step takes a while: it takes the 65 seconds to reshape 1-2 vars,  79 seconds to reshape 5 variables, and about 2 minutes to do 15 (lots of variables though)*/
timer on 2
reshape wide land rev catch swt snum N1A_land N2A_land N1A_rev N2A_rev N1A_catch N2A_catch N1A_swt N2A_swt N1A_snum N2A_snum, i(id1) j(id2)
spset, clear
spset id1


order id1 stock1 dateq _ID land* rev*  catch* swt* snum* N1A_land* N2A_land* N1A_rev* N2A_rev* N1A_catch* N2A_catch* N1A_swt* N2A_swt* N1A_snum* N2A_snum* 



foreach metric in land rev catch swt snum{

	/* W for weighting matrix
	First+second characters - type (00 - raw; (i)nverse distance , (N)earest Neighbor and degree, (i)nverse distance ^2)
	third character - normalization (0,Spectral, Row) 
	suffix - what metric was used to construct this?
	*/



	/********************************************************/
	/********************************************************/
	/* Distance and direct matrices, spectral normed */
	/********************************************************/
	/********************************************************/

	/* Inverse Distance, spectral normalization (largest eigenvalue)
	Inverse distance is smart enough to set the elements=0 if the underlying value =0*/

	spmatrix fromdata WiiST_`metric'=`metric'`firstid1'-`metric'`lastid1', idistance normalize(spectral)
	spmatrix note WiiST_`metric' : spectral normalized inverse distance  matrix on `metric'
	spmatrix save WiiST_`metric' using ${data_main}/spatial_weight_matrices/WiiST_`metric'.stswm, replace








	
	/* Distance, spectral normalized */
	spmatrix fromdata W00ST_`metric'=`metric'`firstid1'-`metric'`lastid1', normalize(spectral)
	spmatrix note W00ST_`metric' : non-normalized distance  matrix on `metric'
	spmatrix save W00ST_`metric' using ${data_main}/spatial_weight_matrices/W00ST_`metric'.stswm, replace

	
	
	/********************************************************/
	/********************************************************/
	/* Distance and direct matrices, spectral normed */
	/********************************************************/
	/********************************************************/
	


	/* Distance, not normalized */
	spmatrix fromdata W000T_`metric'=`metric'`firstid1'-`metric'`lastid1', normalize(none)
	spmatrix note W000T_`metric' : non-normalized distance  matrix on `metric'
	spmatrix save W000T_`metric' using ${data_main}/spatial_weight_matrices/W000T_`metric'.stswm, replace
	
	/* put this D matrix into mata */
	spmatrix matafromsp D id =W000T_`metric'
	
	/* Inverse Distance, also not normalized
	Inverse distance is smart enough to set the elements=0 if the underlying value =0*/
	spmatrix fromdata Wii0T_`metric'=`metric'`firstid1'-`metric'`lastid1', idistance normalize(none)
	spmatrix note Wii0T_`metric' : non-normalized inverse distance  matrix on `metric'
	spmatrix save Wii0T_`metric' using ${data_main}/spatial_weight_matrices/Wii0T_`metric'.stswm, replace

	
	/* put this ID matrix into mata */
	spmatrix matafromsp W id = Wii0T_`metric'
    mata: W = W:^2
	/* construct the ID^2, spectral normalized */
	spmatrix spfrommata Wi2ST_`metric'=W id, normalize(spectral)
	spmatrix note Wi2ST_`metric' : spectral normalized inverse distance  matrix on `metric'
	spmatrix save Wi2ST_`metric' using ${data_main}/spatial_weight_matrices/Wi2ST_`metric'.stswm, replace

	
	/*extract the largest abs(eigenvalue) from the W and D matrices. Keep the largest one. */
	mata: De=symeigenvalues(D)
	mata: We=symeigenvalues(W)
	mata: De=abs(De)
	mata: We=abs(We)
	mata: st_numscalar("max_De", max(De))
	mata: st_numscalar("max_We", max(We))

	scalar myscale=max(max_De,max_We)
	mata: D2=D/st_numscalar("myscale")
	mata: W2=W/st_numscalar("myscale")
	
	
	spmatrix spfrommata WiiJT_`metric'=W2 id, normalize(none)
	spmatrix note WiiJT_`metric' : Joint spectral normalized inverse distance truncated matrix on `metric'
	spmatrix save WiiJT_`metric' using ${data_main}/spatial_weight_matrices/WiiJT_`metric'.stswm, replace

	
	spmatrix spfrommata W00JT_`metric'=D2 id, normalize(none)
	spmatrix note W00JT_`metric' : Joint spectral normalized distance truncated matrix on `metric'
	spmatrix save W00JT_`metric' using ${data_main}/spatial_weight_matrices/W00JT_`metric'.stswm, replace

	
	
	mata: mata drop W D id
	
	/* Inverse Distance, row normalization 
	Inverse distance is smart enough to set the elements=0 if the underlying value =0*/

	spmatrix fromdata WiiRT_`metric'=`metric'`firstid1'-`metric'`lastid1', idistance normalize(row)
	spmatrix note WiiRT_`metric' : row normalized inverse distance  matrix on `metric'
	spmatrix save WiiRT_`metric' using ${data_main}/spatial_weight_matrices/WiiRT_`metric'.stswm, replace
}

/*nearest neighbor spatial weights matrices */


/*nearest neighbor spatial weights matrices */
foreach metric in N1A_land N2A_land N1A_rev N2A_rev N1A_catch N2A_catch N1A_swt N2A_swt N1A_snum N2A_snum {
	spmatrix fromdata WN1A0T_`metric'=`metric'`firstid1'-`metric'`lastid1', normalize(none)
	spmatrix note WN1A0T_`metric' : Adjusted Nearest Neighbor matrix on `metric'
	spmatrix save WN1A0T_`metric' using ${data_main}/spatial_weight_matrices/WA0T_`metric'.stswm, replace
	
	spmatrix fromdata WN1AST_`metric'=`metric'`firstid1'-`metric'`lastid1', normalize(spectral)
	spmatrix note WN1AST_`metric' : spectral normalized Nearest Neighbor matrix on `metric'
	spmatrix save WN1AST_`metric' using ${data_main}/spatial_weight_matrices/WAST_`metric'.stswm, replace
}









/* truncated spatial weights matrix key */
preserve
keep id1 stock1 dateq _ID
rename stock1 stockcode

bysort stockcode dateq: assert _N==1
compress
save `spset_key2', replace
restore













