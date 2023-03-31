

clonevar OG_nespp3=nespp3
/* deal with species that span multiple nespp3 groups 
We go with the "earliest" nespp3 -- the code that was first in the databases*/
replace nespp3=012 if nespp3==011
replace nespp3=147 if nespp3==148

replace nespp3=081 if nespp3==082
replace nespp3=120 if nespp3==119
replace nespp3=168 if nespp3==167
replace nespp3=153 if nespp3==154

replace nespp3=269 if nespp3==270


replace nespp3=748 if nespp3==751
