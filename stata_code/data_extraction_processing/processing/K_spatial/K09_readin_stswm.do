spmatrix clear
/* Readin spatial weights matrices */
foreach metric in land rev catch swt snum{
	spmatrix use W000_`metric' using ${data_main}/spatial_weight_matrices/W000_`metric'.stswm, replace
	
	spmatrix use W00S_`metric' using ${data_main}/spatial_weight_matrices/W00S_`metric'.stswm, replace

	spmatrix use Wii0_`metric' using ${data_main}/spatial_weight_matrices/Wii0_`metric'.stswm, replace

	spmatrix use WiiS_`metric' using ${data_main}/spatial_weight_matrices/WiiS_`metric'.stswm, replace
	spmatrix use Wi2S_`metric' using ${data_main}/spatial_weight_matrices/Wi2S_`metric'.stswm, replace

	spmatrix use WiiR_`metric' using ${data_main}/spatial_weight_matrices/WiiR_`metric'.stswm, replace
	
	spmatrix use WiiJ_`metric' using ${data_main}/spatial_weight_matrices/WiiJ_`metric'.stswm, replace
	spmatrix use W00J_`metric' using ${data_main}/spatial_weight_matrices/W00J_`metric'.stswm, replace

}


/*2 nearest neighbor spatial weights matrices */

foreach metric in N1_land N1_rev N1_catch N1_swt N1_snum N2_land N2_rev N2_catch N2_swt N2_snum {
	spmatrix use W00_`metric' using ${data_main}/spatial_weight_matrices/W00_`metric'.stswm, replace
	spmatrix use W0S_`metric' using ${data_main}/spatial_weight_matrices/W0S_`metric'.stswm, replace
	

	
}


foreach metric in N1A_land N1A_rev N1A_catch N1A_swt N1A_snum N2A_land N2A_rev N2A_catch N2A_swt N2A_snum{
	spmatrix use WA0_`metric' using ${data_main}/spatial_weight_matrices/WA0_`metric'.stswm, replace
	spmatrix use WAS_`metric' using ${data_main}/spatial_weight_matrices/WAS_`metric'.stswm, replace
}



