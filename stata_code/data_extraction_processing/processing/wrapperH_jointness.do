

#delimit cr
version 15.1
pause off

global foldersearch sectors_refiled
clear

global jointness ${processing_code}/H_jointness



/* Code to assemble data to construct jointness of groundfish at the mri level */
do "${jointness}/assembleH01_mri_joint.do"


/* Code to merge the sector-year-memberids into a transaction */
do "${jointness}/assembleH02_memberid_dmis_join_clean.do"




/* Code to assemble data to construct jointness of groundfish at the adjusted memberid level */
do "${jointness}/assembleH03_memberid_joint.do"

