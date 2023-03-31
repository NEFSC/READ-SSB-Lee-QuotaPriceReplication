# Codings
The pounds in a trade are coded Z1 through Z17. This is the table that decodes.

Code | Species | Stockarea | DMIS stock_id | statistical areas | svspp
----| ----------| -----| -----| -----|  -----| 
z1 | Yellowtail Flounder | CCGOM| YELCCGM | 511-521| 105
z2 | Cod | GB-East| CODGBE | 561, 562 |73 
z3 | Cod | GB-West | CODGBW | 521-639 minus (561, 562) | 73
z4 | Haddock | GB-East | HADGBE | 561, 562 | 74
z5 | Haddock | GB-West | HADGBW |  521-639 minus (561, 562)| 74
z6 | Winter Flounder | GB | FLWGB | 522, 525, 542, 543, 561, 562 | 106
z7 | Yellowtail | GB | YELGB | 522,525, 542,543, 561, 562 |105
z8 | Cod | GOM | CODGMSS | 511-515 | 73
z9 | Haddock | GOM | HADGM | 511-515 | 74
z10 | Winter Flounder | GOM | FLWGMSS | 511-515| 106
z11 | Plaice | Unit | PLAGMMA |511-639 | 102
z12 | Pollock | Unit | POKGMASS | 511-639 | 75
z13 | Redfish | Unit | REDGMGBSS | 511-639 | 155
z14 | Yellowtail Flounder | SNEMA | YELSNE |526, 533-541, 611-639 | 105
z15 | White_Hake | Unit | HKWGMMA | 511-639 | 76
z16 | Witch Flounder | Unit | WITGMMA | 511-639 | 107
z17 | Winter Flounder | SNEMA | FLWSNEMA |521, 526, 533-541, 611-639 | 106


z18 is an interaction of "lease_only==1" and total_lbs. "lease_only"  is not in the dataset.  
Winter Flounder SNEMA (FLWSNEMA) first had a sector subACL in 2013. 




The following stocks do not have allocated quota:

Code | Species | Stockarea | DMIS stock_id | statistical areas
----| ----------| -----| -----|  -----|
z101 | Halibut | UNIT| HALGMMA | 511-515, 521,522, 525,526, 551, 552,561,562
z102 | Ocean Pout | UNIT| OPTGMMA |511-623
z103 | Windowpane | Northern| FLGMGBSS |511-515,521,522,525,542,543,551, 552,561,562,465,464
z104 | Windowpane |Southern| FLDSNEMA | 526, 533,534, 537,538, 539, 541, 511-639
z105 | Wolffish | UNIT| WOLGMMA | 512,513,514,515,521,522,525,526,537
z999 | Other | UNIT | OTHER | All
Everything else has been binned into "other"
# Quota holding requirements in order to fish.
An operator needs to have quota for anything they can catch/charge. This means that the prices of quota are linked together.  This gets enforced on the stock area level (which differs slightly by species).  This is useful info, but not directly used.  Each "stock area" has different costs of fishing in it. 

Code | Stock| Requirements
--| --------- | --------------
1 | Yellowtail CCGOM  | 8,9,10,11,12,13,15, 16     
2 | Cod GB-East | 4,6,7, 11,12,13,15,16      
3 | Cod GB-West | 5,6,7,11,12,13,15,16       
4 | Haddock GB-East | 2,6,7, 11,12,13,15,16      
5 | Haddock GB-West | 3,6,7,11,12,13,15,16       
6 | Winter Flounder GB |  2,3,4,5,7,11,12,13,15,16   
7 | Yellowtail Flounder GB | Look up. similar to 5 or 6 though.
8 | Cod GOM | 1,8,9,10,11,12,14,15       
9 | GOM haddock |  1,7,9,10,11,12,14,15       
10 |GOM Winter | 1,7,8,10,11,12,14,15       
10 | Plaice  |
11 | Pollock |
12 | Redfish | 
13 | Yellowtail Flounder SNEMA |  3,5,6,7,10,11,12,14,15,16   
14 | White hake | 
15 | Witch flounder | 
16 | Winter Flounder SNEMA | 3,5,13, 10,11,12,14,15   

This table is not exactly right. For example, to fish for CCGOM Yellowtail, you will need to hold all the unit stocks. If you fish in 521, you'll also need GBW haddock, GBW cod, and SNEMA Winter.  But if you fish in the GOM, you'll need GOM haddock, GOM cod, and GOM winter.

Maybe a better way to think about it is:
1. Fish in the Gulf of Maine (511-515): GOM cod, GOM haddock, GOM winter, CCGOM Yellowtail, plus unit stocks
1. Fish in CC (521): CCGOM yellowtail, GBW cod, GBW haddock, SNEMA Winter
1. Fish on Georges Bank (east of Nantucket): GBW/E cod, GBW/E haddock, GB Winter, GB Yellowtail
1. Fish southwest of Nantucket: GBW cod, GBW haddock, SNEMA Winter, SNEMA Yellowtail


# Georges East and West is a bit funky

GARFO's quota monitoring reports contains Catches, Landings, Discards, and ACLs for GBE Cod and GBE Haddock and GB Cod, GB Haddock. These can be used to deduce GBW Cod and GBW haddock. 

GB Cod East and GB Haddock East are the portion of the overall stock that is allowed to be fished in the Eastern U.S./Canada Area.
GB Haddock East reflects re-allocations of the overall stock, based on Sectors converting GB haddock to be fished outside the Eastern Area.

The East allocations will change throughout the year is worth noting--no other allocations do. 

But also the very basic fact that the tables include ACL and catch for all GB cod/haddock, and East GB cod/haddock....but never West GB cod/haddock alone.

The quota allocations are not All and East, they're West and East.

All Catch=East Catch+West Catch 
All ACL=East ACL+West ACL

If a sector wants to convert it's GBE to GBW, it fills out a sector ACE transfer form. This is the same form that is used to transfer ACE between sectors. But I don't think these are stored in the same database, because I've yet to see a transfer that had the same "to_sector" and "from_sector"

 ## PSC


>In the table showing PSC as a percentage, each permit has a GB cod PSC and a GB haddock PSC. However, in the table showing PSC in pounds, each permit has an Eastern amount and a Western amount for GB cod and GB haddock."

https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports//Sectors/PSC/psc_description.html 
Despite GARFO's writing, they are not actually doing this in the poundage allocations.   


> We do not assign an individual permit separate PSCs for the Eastern GB cod or Eastern GB haddock; instead, we assign each permit a PSC for the GB cod stock and GB haddock stock. Each sector's GB cod and GB haddock allocations are then divided into an Eastern ACE and a Western ACE, based on each sector's percentage of the GB cod and GB haddock ACLs. For example, if a sector is allocated 4 percent of the GB cod ACL and 6 percent of the GB haddock ACL, the sector is allocated 4 percent of the commercial Eastern U.S./Canada Area GB cod total allowable catch (TAC) and 6 percent of the commercial Eastern U.S./Canada Area GB haddock TAC as its Eastern GB cod and haddock annual catch entitlements (ACEs). These amounts are then subtracted from the sector's overall GB cod and haddock allocations to determine its Western GB cod and haddock ACEs. 

This describes how to do this. If a sector has X percentage of the GB cod; they have the same percentage of the GBE cod. Then you get GBW by subtracting GBE from GB.


Torey Adler is the person who knows about this at APSD.
