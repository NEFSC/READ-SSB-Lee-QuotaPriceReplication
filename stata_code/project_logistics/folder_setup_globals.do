/* Set up global macros to point to folders */

version 15.1

#delimit ;


/*One of these
global user minyang; 
global user minyangWin; 
*/


if strmatch("$user","minyang"){;
global my_projdir "/home/mlee/Documents/projects/aceprice";
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";
};

/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){;
global my_projdir "C:/Users/Min-Yang.Lee/Documents/READ-SSB-Lee-QuotaPriceReplication";
global oracle_cxn " $mysole_conn" ;

};


global my_codedir "${my_projdir}/stata_code";
global extract_process "${my_codedir}/data_extraction_processing";
global extraction_code "${extract_process}/extraction";
global processing_code "${extract_process}/processing";
global analysis_code "${my_codedir}/analysis";
global R_code "${my_projdir}/R_code";
global my_adopath "${my_codedir}/aceprice_ado";


/* setup data folder */
global my_datadir "${my_projdir}/data_folder";
global data_raw "${my_datadir}/raw";
global memberids ${data_raw}/memberids;

global data_internal "${my_datadir}/internal";
global data_external"${my_datadir}/external";

global data_main "${my_datadir}/main";

global data_intermediate "${my_datadir}/intermediate";
global data_traders "${data_intermediate}/traders";

global trade_clean "${data_intermediate}/intra_clean";
global spacepanels "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_11182019";


/* setup results folders */
global intermediate_results "${my_projdir}/intermediate_results";
global my_results "${my_projdir}/results";



global hedonicR_results "${my_results}/hedonicR";

/* setup images folders */

global my_images "${my_projdir}/images";
global exploratory "${my_images}/exploratory";

/* setup table folders */
global my_tables "${my_projdir}/tables" ;

/* add the programs in mobility_ado to the adopath*/
adopath + $my_adopath ;


global BLS_folder "C:\Users\Min-Yang.Lee\Documents\READ-SSB-Lee-labor-and-wages"; 




/*set the date field */
local date: display %td_CCYY_NN_DD date(c(current_date), "DMY");
global today_date_string = subinstr(trim("`date'"), " " , "_", .);
global vintage_string $today_date_string;
di "$vintage_string";
vintage_lookup_and_reset;
