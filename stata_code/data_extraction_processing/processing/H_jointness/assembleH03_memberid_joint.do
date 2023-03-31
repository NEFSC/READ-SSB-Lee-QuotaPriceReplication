/* The goal of this is to construct a linking table.
It will allow me to link the ACE trading data to the DMIS data.*/



use "${data_intermediate}\inbound_process_memberids_${vintage_string}.dta", clear

merge m:m fy sectorid memberid using "${data_intermediate}\sector_memberids_cleaned_${vintage_string}.dta"
drop if _merge==2
drop _merge

/* merge=2 is NBD -these didn't trade 
merge=1 means I couldn't look up the memberid from teh rosters. That's not good
but many are SECTOR_ID + 00 
AND I should fill those with the "whole sector" anyway. */


/* I'll use a joinby on sectorid and FY to associate mris that don't match */
joinby sectorid fy using "${data_intermediate}\sector_mri_roster_${vintage_string}.dta", 

replace mri=all_mris if mri==.
drop all_mris
duplicates drop
/* sometimes there are multiple mri-years. Make sure that each transfernum-stock has no duplicated mris  */

bysort sectorname fy transfernumber sectorid stockcode stock_id stock clean_date memberid mri: keep if _n==1
bysort transfernum stockcode mri: gen dup_mark=_N>=2

gen monthly_date=mofd(clean_date)

save "${data_intermediate}\transfers_with_mris_${vintage_string}.dta", replace


/* the dup_mark flags those transfernumber-stockcode that have the same mri attached more than 1 time.*/



/* what do I want to 'get' from DMIS? 
right now, let's get the yearly landings and landings-exclusive of that stock 

*/
use $data_intermediate/mri_monthly_$vintage_string.dta, clear
keep fy mri stockcode tland tland_ex
collapse (sum) tland tland_ex, by(fy mri stockcode)
tempfile dmis_4merge
save `dmis_4merge'


use "${data_intermediate}\transfers_with_mris_${vintage_string}.dta", replace
merge m:1 fy mri stockcode using `dmis_4merge'
drop if _merge==2
collapse (sum) tland tland_ex, by(sectorname fy transfernumber sectorid stockcode stock_id stock)



 gen conversion_ratio=tland_ex/(tland-tland_ex)
/* there's lots of merge==1; an MRI in the transaction didn't fish for a particular stock 
not super suprising, many mris are in cph. (pull that along)?
But what if a member bought ace but never fished it?  That's kind of wierd.
*/
