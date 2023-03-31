# delimit ;
use "${data_intermediate}/ace_step2_${vintage_string}.dta", replace;




/* it's probably best to do this "last" --it's a little counterintuitive to have negative values for z and compensation */
/* Dyads -- see Stata tip 71 */
/* to facilitate, I will do this:

The "lower" sector id always becomes partyA
the higher sectorid always becomes partyB

We'll code transfers as flowing from party A to party B.
So, if the from matches partyA, then we do nothing
if the from_sector_id matches partyB, then we need to multiply all the z and compensation variables by -1 
Don't multiply the total_lbs variable by 1*/ 

assert from_sector_id~=to_sector_id;
gen partyA=min(from_sector_id,to_sector_id);
gen partyB=max(from_sector_id, to_sector_id);


gen partyAname=cond(from_sector_id<to_sector_id,from_sector_name,to_sector_name);
gen partyBname=cond(from_sector_id<to_sector_id,to_sector_name,from_sector_name);

foreach var of varlist z1-z17 compensation{;
replace `var'=-1*`var' if from_sector_id==partyB;
};
order partyA partyB partyAname partyBname from_sector_id to_sector_id from_sector_name to_sector_name compensation;

egen id=group(partyA partyB), lname(myl);
order id;


/* identifying swaps, swap+cash, and "refusals" to enter a price 
Chad considers compensation==0 and same date trades as possible swaps.

Potential groups: Same id, same day?  Same id and consecutive transfer_nums on the same day? (could be more than 2 transfer nums)


	zero dollars and quota flowing both ways.
	At least 1 has zero dollars and quota flows both ways?
*/

/* here is one way : 
same date; at least one of the linked does not include cash  compensation */
sort id transfer_num transfer_date ;
gen td2=dofc(transfer_date) ;
format td2 %td ;
order td2 ;
order transfer_date, last; 
egen potential_linked=group(id td2);
order potential;
order compens, after(transfer_number);
bysort potential: gen num_linked=_N;
order num_linked;
gen comp_check=abs(compensation)>0;
order comp_check;


bysort potential: egen tc=total(comp_check);

/*potentials with cash compensation in all of their rows are not swaps */
replace potential=0 if tc==num_linked;

/* single transfers in a day cannot be a swap by definition */
bysort potential: replace potential=0 if _N==1;

/* there's different kinds of "linked" 
browse if num_linked==16 illustrates one: All trades in one direction were entered separately, then all trades in the other direction were entered.

browse if num_linked==8 illustrates another 
	the offsets were entered together for one set. 
	
	two cash for ace were entered
	Then  two sets of swaps were entered
	There was a little break in between in the transfer_nums.

	
*/
tab num_linked if potential~=0;



/* 

 num_linked |      Freq.     Percent        Cum.
------------+-----------------------------------
          2 |        836       64.81       64.81
          3 |        228       17.67       82.48
          4 |        108        8.37       90.85
          5 |         60        4.65       95.50
          6 |         12        0.93       96.43
          7 |         14        1.09       97.52
          8 |         16        1.24       98.76
         16 |         16        1.24      100.00
------------+-----------------------------------
      Total |      1,290      100.00
*/






