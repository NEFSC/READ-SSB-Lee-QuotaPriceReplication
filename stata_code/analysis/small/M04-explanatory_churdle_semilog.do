
	
/*
1. The market price for quota fits perfectly into the "corner solution" setup described by Wooldridge. This is just Walras law of zero valued excess demand. 

	If all the individual demand functions x(p,w) are continuous, then we have the excess demand function:
	
	z(p)=sum x_i(p,w)-\omega_i
for any price vector p, we must have p*z(p) \equiv 0.

We therefore have --- if prices are non-zero, then we have Q_s=Q_d
If there is excess supply, then the price must be zero.  


Even if stock $i$ is often caught along with stock $j$ and catching $j$ is highly profitable, the fact that there there is no excess demand implies that only the amount of quota available matters.

We might have many ways to 

	
On one hand, I have a big enough n (16/17) and t(44ish). But perhaps I don't because it's 16 x 11.
	The "invidvidual-ness", resets itself every year, because it isn't an actual individual, but a market outcome.
	so, perhaps I have 
		t=4
		and n~stock*year (17*17)
	
	Note that the x(p,w) is an input demand equation, so it also depends on costs of fishing
	

*/



#delimit cr
version 15.1
pause on
clear all
spmatrix clear
global common_seed 06240628
cap log close

local mylogfile "${my_results}/M04-churdleA_semilog.smcl" 
log using `mylogfile', replace
local stock_concentration ${data_main}/quarterly_stock_concentration_index_${vintage_string}.dta
local fishery_concentration ${data_main}/fishery_concentration_index_${vintage_string}.dta
local stock_concentration_noex ${data_main}/quarterly_stock_concentration_index_no_ex_${vintage_string}.dta

local stock_disjoint ${data_main}/quarterly_stock_disjoint_index_${vintage_string}.dta

local spset_key "${data_main}/spset_id_keyfile_${vintage_string}.dta"
local spset_key2 "${data_main}/truncated_spset_id_keyfile_${vintage_string}.dta"
local spatial_lags ${data_main}/spatial_lags_${vintage_string}.dta
local spatial_lagsT ${data_main}/spatial_lags_${vintage_string}.dta

local prices "${data_main}/quarterly_ols_coefs_from_R_${vintage_string}.dta"
local  constraining ${data_main}/most_constraining_${vintage_string}.dta


global bootreps 500

/* read in the spmatrices previously created */
do "${processing_code}/K_spatial/K09T_readin_trunc_stswm.do"


use `prices'
/* drop the interaction and constant */

merge 1:1 stockcode dateq using `constraining'

drop if inlist(stockcode,1818,9999,101,102,103,104,105)
drop if inlist(fishing_year,2009,2020,2021)
drop if _merge==2
drop _merge

/* drop  2020  and 2021
drop 2009 because we already have lags.
2020, we can't add survey data, so we won't use to estimate 
*/

merge 1:1 stockcode dateq using `spatial_lagsT'
*drop if stockcode==17 & fishing_year<2012
assert _merge==3
*bysort _ID: assert _n==1
drop _merge

/* merge in quarterly "stock available indices" */
/* rename dateq to facilitate merges */
rename dateq quarterly 

merge 1:1 stockcode quarterly using `stock_concentration'
drop if _merge==2
assert _merge==3
drop _merge

merge 1:1 stockcode quarterly using `stock_concentration_noex'
drop if _merge==2
assert _merge==3
drop _merge

merge 1:1 stockcode quarterly using `stock_disjoint'
drop if _merge==2
assert _merge==3
drop _merge

/* merge in quarterly "fishery available indices" this is a m:1 merge */

merge m:1 quarterly using `fishery_concentration'
drop if _merge==2
assert _merge==3
drop _merge


rename  quarterly dateq


gen badj_GDP=badj/fGDP
gen ihs_badj_GDP=asinh(badj_GDP)

gen del=live_priceGDP-badj_GDP
gen ihs_del=asinh(del)


xi i.q_fy


/* if you want to adjust the spatial lags, here is where you do it 
something like


gen t=live_priceGDP
replace t=0 if stockcode==17 & fishing_year<=2012
spgenerate Wrev_livep=Wi2S_rev*t
drop t


*/
/* construct a variable representing the revenue from the other */
gen otherR=live_priceGDP*quota_remaining_BOQ
gen ihs_otherR=asinh(otherR)
gen ln_otherR=ln(otherR)




/* classify as nearshore 25nm, intermediate 25-75nm, and far over 75nm from land. This gives us 4 stocks in the nearshore, 8 in the intermediate, and 4 that are offshore).  
This is intended to help me capture cost differences - fuel is related to cost, but so is distance*/
gen stock_distance_type=0
replace stock_distance_type=1 if inlist(stockcode,5,9,11,12,13,15,16,17)
replace stock_distance_type=2 if inlist(stockcode,2,4,6,7)
label define stock_dist 0 "nearshore" 1 "intermediate" 2 "far" 
label values stock_distance_type stock_dist



/* create a "yearly quota variable from the quota_remaining_BOQ in _Iq*=1*/
sort stockcode fishing_year _Iq*
gen sectorACL=quota_remaining_BOQ if q_fy==1
bysort stockcode fishing_year (_Iq*): replace sectorACL=sectorACL[1] if sectorACL==.
gen recip_ACL=1/sectorACL
gen lnACL=ln(sectorACL)
/* need to add controls for quarter of the FY */

/* live price is endog, use 4th lag as IV */



gen bpos=badj_GDP>0 
replace bpos=. if badj_GDP==.
gen lnfp=ln(DDFUEL_R)

egen clustvar=group(stockcode fishing_year)

/*Experiment with the "selection" equation */


probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ  _Iq*
/******************************************************************/
/******************************************************************/
/******************************************************************/
/* so far, this is my favorite specification */
/******************************************************************/
/******************************************************************/
/******************************************************************/

/* The 2nd RHS variable is the 'fraction remaining' but this makes 'margining' a bit easier because a 1 unit or 1% increase in quota remaing must change the fraction remaining.*/
probit badj_GDP c.ln_quota_remaining_BOQ lnACL _Iq*, vce( cluster clustvar)
est store probit1
mat probit_b=e(b)





/* control function for possible endogeneity of quota_remaining */
gen es=e(sample)

regress ln_quota_remaining_BOQ  lnACL lag1Q_ln_quota_remaining_BOQ   _Iq*  if es
predict q_res1, residual

regress ln_quota_remaining_BOQ  lnACL lag1Q_ln_quota_remaining_BOQ  lag4Q_ln_quota_remaining_BOQ  _Iq*  if es
predict q_res14, residual

regress ln_quota_remaining_BOQ  lnACL lag4Q_ln_quota_remaining_BOQ  _Iq*  if es
predict q_res4, residual

probit badj_GDP c.ln_quota_remaining_BOQ lnACL _Iq* q_res1, vce( cluster clustvar)

probit badj_GDP c.ln_quota_remaining_BOQ lnACL _Iq* q_res14, vce( cluster clustvar)
probit badj_GDP c.ln_quota_remaining_BOQ lnACL _Iq* q_res4, vce( cluster clustvar)


/* HERE */


/*Not exactly sure the best way to let quota remaining enter in logs but also include the fraction of quota remaining in levels. */
/* setup for cluster bootstrap */
tsset, clear
egen stock_year_id=group(stockcode fishing_year)

cap drop q_res14
cap program drop boot_probit_cf14
program boot_probit_cf14, rclass
regress ln_quota_remaining_BOQ  lnACL lag1Q_ln_quota_remaining_BOQ  lag4Q_ln_quota_remaining_BOQ  _Iq*  if es
	predict q_res14, residual
 
probit badj_GDP c.ln_quota_remaining_BOQ fraction_remaining_BOQ _Iq* q_res14
	drop q_res14
		
end program


/* plain old bootstrap */
bootstrap, reps($bootreps) seed($common_seed): boot_probit_cf14
est store probit14

/* clustered on stock-year */
bootstrap, cluster(stock_year_id) seed($common_seed) reps($bootreps): boot_probit_cf14

est store probit14C


/************************************************************************/
/*Takeways: 
probit1 looks good.  The post-estimation breakdown looks good. 
	The Hsomer-Lemeshow test does not love it though.  Reject the model if we have 10 groups at the 5% level. Area under the ROC curve is pretty good.
*/
/******************************************************************/

est restore probit1

estat gof, group(10)table
estat classification
lroc
lsens

/* second stages */
gen lny=ln(badj_GDP)

regress lny c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R Wswt_quota_remaining_BOQ, vce(cluster clustvar) 
mat b=e(b)

mat starts=[b,probit_b]

truncreg badj_GDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R, vce(cluster clustvar) ll(0)


regress live_priceGDP lag1Q_live_priceGDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL _Iq* i.stock_distance_type#c.DDFUEL_R
predict pres1, residual
regress live_priceGDP lag4Q_live_priceGDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL _Iq* i.stock_distance_type#c.DDFUEL_R
predict pres4, residual




regress live_priceGDP lag1Q_live_priceGDP lag4Q_live_priceGDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL _Iq* i.stock_distance_type#c.DDFUEL_R
predict pres14, residual

clonevar price_res=pres14

truncreg badj_GDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R pres14, vce(cluster clustvar) ll(0)


regress quota_remaining_BOQ lag1Q_quota_remaining_BOQ lag4Q_quota_remaining_BOQ c.recip_ACL _Iq* i.stock_distance_type#c.DDFUEL_R
predict qrresid14, residual

cap drop pres14
cap drop qresid14
cap drop pres1
cap drop qrresid1

cap program drop boot_trunc_cf14
program boot_trunc_cf14, rclass
	regress live_priceGDP lag1Q_live_priceGDP lag4Q_live_priceGDP c.c.recip_ACL _Iq* i.stock_distance_type#c.DDFUEL_R
	predict pres14, residual
 
 regress quota_remaining_BOQ lag1Q_quota_remaining_BOQ lag4Q_quota_remaining_BOQ c.recip_ACL _Iq* i.stock_distance_type#c.DDFUEL_R
	predict qrresid14, residual

truncreg badj_GDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R qrresid14 pres14, ll(0)
	drop pres14 qrresid14
		
end program



/* plain old bootstrap */
bootstrap, reps($bootreps) seed($common_seed): boot_trunc_cf14
est store trunc14

/* clustered on stock-year */
bootstrap, cluster(stock_year_id) seed($common_seed) reps($bootreps): boot_trunc_cf14

est store trunc14c

/* Both suggest that live prices are not endogenous. This is a little surprising at first, but I can sort of believe it. This is basically saying that there is nothing in the */



cap drop pres14
cap drop qresid14
cap drop pres1
cap drop qrresid1

cap program drop boot_trunc_cf1
program boot_trunc_cf1, rclass
	regress live_priceGDP lag1Q_live_priceGDP c.c.recip_ACL _Iq* i.stock_distance_type#c.DDFUEL_R
	predict pres1, residual
 
 regress quota_remaining_BOQ lag1Q_quota_remaining_BOQ c.recip_ACL _Iq* i.stock_distance_type#c.DDFUEL_R
	predict qrresid1, residual

truncreg badj_GDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R qrresid1 pres1, ll(0)
	drop pres1 qrresid1
		
end program



/* plain old bootstrap */
bootstrap, reps($bootreps) seed($common_seed): boot_trunc_cf1
est store trunc1

/* clustered on stock-year */
bootstrap, cluster(stock_year_id) seed($common_seed) reps($bootreps): boot_trunc_cf1

est store trunc1c



/*fuelXdistance doesn't seem to matter much.  Lets drop these and see what happens */




cap drop pres14
cap drop qresid14
cap drop pres1
cap drop qrresid1

cap program drop boot_trunc_cf1
program boot_trunc_cf1, rclass
	regress live_priceGDP lag1Q_live_priceGDP lag4Q_live_priceGDP c.recip_ACL _Iq*
	predict pres1, residual
 
 regress quota_remaining_BOQ lag1Q_quota_remaining_BOQ lag4Q_quota_remaining_BOQ c.recip_ACL _Iq* 
	predict qrresid1, residual

truncreg badj_GDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* qrresid1 pres1, ll(0)
	drop pres1 qrresid1
		
end program


/* plain old bootstrap */
bootstrap, reps($bootreps) seed($common_seed): boot_trunc_cf1
est store trunc14a

/* clustered on stock-year */
bootstrap, cluster(stock_year_id) seed($common_seed) reps($bootreps): boot_trunc_cf1

est store trunc14ac


/* things to do 
Lets try out the probit with logs on the RHS
lets try out the truncreg with logs on the RHS

*/







churdle exponential badj_GDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R Wswt_quota_remaining_BOQ price_res, select( c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R) vce(cluster clustvar) ll(0)



/* I'm having problems due to the quota_remaining_BOQ variable 
it happens even if I do something very simple:

churdle linear badj_GDP  quota_remaining_BOQ, select(quota_remaining_BOQ) ll(0)

/* these all work, so it feels like a scaling problem */
churdle linear badj_GDP  _Iq*, select(quota_remaining_BOQ _Iq*) ll(0)
churdle linear badj_GDP  fraction_remaining_BOQ _Iq*, select(quota_remaining_BOQ _Iq*) ll(0)

churdle linear badj_GDP  ln_quota_remaining_BOQ, select(ln_quota_remaining_BOQ) ll(0)

*/

churdle linear badj_GDP c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R , select(c.quota_remaining_BOQ c.quota_remaining_BOQ#c.recip_ACL live_priceGDP _Iq* i.stock_distance_type#c.DDFUEL_R) vce(cluster clustvar) ll(0) 


*churdle linear badj_GDP c.fraction_remaining_BOQ c.quota_remaining_BOQ live_priceGDP, select( c.fraction_remaining_BOQ c.quota_remaining_BOQ live_priceGDP _Iq* i.stock_distance_type#c.lnfp) ll(0)


/******************************************************************/
/******************************************************************/
/******************************************************************/
/* These models aren't so good, for one reason or another*/
/******************************************************************/
/******************************************************************/
/******************************************************************/

/* we lose a bit of explanatory power when we drop 
exclude fraction_remaining_BOQ or 
exclude a squared term
It seems to be that "both" fraction remaining and quota remaining are affecting the probabilty of a price, but that does make the margins difficult. 

I could probably make a new variable (1/TotalQ) and then we estimate c.quota_remaining c.quota_remaining#c.recip_totalQ
*/

probit badj_GDP c.fraction_remaining_BOQ c.ln_quota_remaining_BOQ ln_live_priceGDP _Iq* i.stock_distance_type#c.lnfp, cluster(clustvar)
probit badj_GDP c.fraction_remaining_BOQ  ln_live_priceGDP _Iq* i.stock_distance_type#c.lnfp, cluster(clustvar)
probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ ln_live_priceGDP _Iq* i.stock_distance_type#c.lnfp, cluster(clustvar)

/*fuel prices are not significant by themselves*/

probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ DDFUEL_R  _Iq*
probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp _Iq*
probit badj_GDP c.ln_live_priceGDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp _Iq* 


/* proportion observed doesn't explain anything. neither does the total target level */
probit badj_GDP c.fraction_remaining_BOQ c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ ln_live_priceGDP _Iq* i.stock_distance_type#c.lnfp proportion_observed , cluster(clustvar)
probit badj_GDP c.fraction_remaining_BOQ c.quota_remaining_BOQ live_priceGDP _Iq* i.stock_distance_type#c.lnfp, cluster(clustvar)

/* Compared to the preferred specification, adding dummies for fishing year add to the model. All are individually insignificant and they just suck explanatory power from the other variables*/
probit badj_GDP c.fraction_remaining_BOQ c.quota_remaining_BOQ live_priceGDP _Iq* i.fishing_year i.stock_distance_type#c.lnfp, cluster(clustvar)



/* dummies for stocks*/
/* looking at these two models, if the stock goes back and forth from being zero to positive, then the model with dummies does poorly in one of the switching times.
That is, the stock dummies are conditioning out time-invariant unobservables. But, of course, they are not conditioning out the ones that vary over time systematically, in this case, the fact that each YEAR-stockcode has some "stuff."
So, we could treat each stock+fishing_year as $i$, and we'd have t=4.  This is a bit of a problem from a FE perspective.  Could do CREs. Or just leave out stock dummies. 
*/
probit badj_GDP c.fraction_remaining_BOQ c.quota_remaining_BOQ live_priceGDP _Iq* i.stock_distance_type#c.lnfp, cluster(clustvar)
estat gof, group(10)table
estat classification
lroc
lsens

probit badj_GDP c.fraction_remaining_BOQ c.quota_remaining_BOQ live_priceGDP _Iq* i.stock_distance_type#c.lnfp i.stockcode,  cluster(clustvar)
estat gof, group(10)table
estat classification
lroc
lsens

/*
probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp  i.stockcode _Iq*
probit badj_GDP c.ln_live_priceGDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp _Iq* 
probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp _Iq* ln_live_priceGDP i.fishing_year
probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp _Iq* ln_live_priceGDP i.fishing_year i.stockcode
*/


/*setup CREs */
bysort stockcode: egen ln_quota_bar=mean(ln_quota_remaining_BOQ)
bysort stockcode: egen ln_price_bar=mean(ln_live_priceGDP)
bysort stockcode: egen ln_fraction_bar=mean(ln_fraction_remaining_BOQ)

bysort stockcode: egen quota_bar=mean(quota_remaining_BOQ)
bysort stockcode: egen price_bar=mean(live_priceGDP)
bysort stockcode: egen fraction_bar=mean(fraction_remaining_BOQ)

/*setup stockcode and FY CREs */
bysort stockcode fishing_year: egen ln_quota_SYmean=mean(quota_remaining_BOQ)
bysort stockcode fishing_year: egen ln_price_SYmean=mean(live_priceGDP)
bysort stockcode fishing_year: egen ln_fraction_SYmean=mean(fraction_remaining_BOQ)

bysort stockcode fishing_year: egen quota_SYmean=mean(quota_remaining_BOQ)
bysort stockcode fishing_year: egen price_SYmean=mean(live_priceGDP)
bysort stockcode fishing_year: egen fraction_SYmean=mean(fraction_remaining_BOQ)



/*
probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp _Iq* ln_live_priceGDP i.fishing_year qr_bar pr_bar
probit badj_GDP c.fraction_remaining_BOQ##c.fraction_remaining_BOQ  _Iq*
truncreg badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ  ln_live_priceGDP _Iq*  i.stockcode, ll(0)
*/






/* here's some reasonable specifications */
/* set esample for the first stage*/
cap drop es
probit badj_GDP c.fraction_remaining_BOQ c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ ln_live_priceGDP _Iq*, robust
gen es=e(sample)

/* probit with dummies for each stock will drop out GBE haddock and GBE cod because there is no variation -- perfect prediction*/
probit badj_GDP c.fraction_remaining_BOQ c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ ln_live_priceGDP _Iq* i.stockcode, robust
gen es2=e(sample)


/* control function without stock dummies */

tsset stockcode dateq 
regress ln_quota_remaining_BOQ ln_live_priceGDP _Iq* l(4).ln_quota_remaining_BOQ  if es
predict res_qr1
regress c.fraction_remaining_BOQ ln_live_priceGDP _Iq* l(4).fraction_remaining_BOQ if es
predict res_fr1



probit badj_GDP c.fraction_remaining_BOQ c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ ln_live_priceGDP _Iq* res_qr1 res_fr1 , robust
predict pr1, pr
order pr1
graph box pr1, over(bpos)
browse if pr1<.4 & bpos==0


/* control function with stock dummies */

regress ln_quota_remaining_BOQ ln_live_priceGDP _Iq* l(4).ln_quota_remaining_BOQ i.stockcode if es2
predict res_qr2
regress c.fraction_remaining_BOQ ln_live_priceGDP _Iq* l(4).fraction_remaining_BOQ i.stockcode if es2
predict res_fr2


probit badj_GDP c.fraction_remaining_BOQ c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ ln_live_priceGDP _Iq* res_qr2 res_fr2 i.stockcode, robust
predict pr2, pr
order pr2
graph box pr2, over(bpos)
browse if pr2<.4 & bpos==1 
browse if pr2<.4 & bpos==1 & badj_GDP>.06







probit badj_GDP c.fraction_remaining_BOQ##c.fraction_remaining_BOQ DDFUEL_R  _Iq*
probit badj_GDP c.fraction_remaining_BOQ##c.fraction_remaining_BOQ lnfp _Iq*
probit badj_GDP c.fraction_remaining_BOQ##c.fraction_remaining_BOQ lnfp  i.stockcode _Iq*
probit badj_GDP c.ln_live_priceGDP c.fraction_remaining_BOQ##c.fraction_remaining_BOQ lnfp _Iq* 
probit badj_GDP c.fraction_remaining_BOQ##c.fraction_remaining_BOQ lnfp _Iq* ln_live_priceGDP i.fishing_year
probit badj_GDP c.fraction_remaining_BOQ##c.fraction_remaining_BOQ lnfp _Iq* ln_live_priceGDP i.fishing_year i.stockcode

probit badj_GDP c.fraction_remaining_BOQ##c.fraction_remaining_BOQ lnfp _Iq* ln_live_priceGDP i.fishing_year


probit badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ fraction_remaining_BOQ lnfp _Iq* i.fishing_year

/*


churdle exponential badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ  ln_live_priceGDP _Iq*  i.stockcode if inlist(stockcode,4,5)==0, ll(0) select(c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp _Iq*)

churdle exponential badj_GDP c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ  ln_live_priceGDP _Iq*  i.stockcode if inlist(stockcode,4,5)==0, ll(0) select(c.ln_quota_remaining_BOQ##c.ln_quota_remaining_BOQ lnfp _Iq*)
*/

log close
