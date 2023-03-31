/*
Syntax

No_arguments
*/
program getIC, rclass

	version 15.1

qui estat ic
mat IC=r(S)
mat AIC=IC[1,5]


mat BIC=IC[1,6]



end
