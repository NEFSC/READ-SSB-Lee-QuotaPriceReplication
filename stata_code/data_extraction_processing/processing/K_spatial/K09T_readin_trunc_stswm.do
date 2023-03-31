spmatrix clear
/* Readin spatial weights matrices */
foreach metric in land rev catch swt snum{
	spmatrix use W000_`metric' using ${data_main}/spatial_weight_matrices/W000T_`metric'.stswm, replace
	spmatrix use W00S_`metric' using ${data_main}/spatial_weight_matrices/W00ST_`metric'.stswm, replace

	spmatrix use Wii0_`metric' using ${data_main}/spatial_weight_matrices/Wii0T_`metric'.stswm, replace

	spmatrix use WiiS_`metric' using ${data_main}/spatial_weight_matrices/WiiST_`metric'.stswm, replace
	spmatrix use Wi2S_`metric' using ${data_main}/spatial_weight_matrices/Wi2ST_`metric'.stswm, replace

	spmatrix use WiiR_`metric' using ${data_main}/spatial_weight_matrices/WiiRT_`metric'.stswm, replace
	
	
	spmatrix use WiiJ_`metric' using ${data_main}/spatial_weight_matrices/WiiJT_`metric'.stswm, replace
	spmatrix use W00J_`metric' using ${data_main}/spatial_weight_matrices/W00JT_`metric'.stswm, replace

}



foreach metric in N1A_land N1A_rev N1A_catch N1A_swt N1A_snum N2A_land N2A_rev N2A_catch N2A_swt N2A_snum{
	spmatrix use WA0_`metric' using ${data_main}/spatial_weight_matrices/WA0T_`metric'.stswm, replace
	spmatrix use WAS_`metric' using ${data_main}/spatial_weight_matrices/WAST_`metric'.stswm, replace
}




