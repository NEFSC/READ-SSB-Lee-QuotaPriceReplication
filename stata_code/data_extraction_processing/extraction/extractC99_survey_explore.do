/* This is just some sample code to extract data from SVDBS and see what it looks like. */



#delimit ;

cap mkdir "${data_raw}/svdbs";

/* vessels on cruises */

	odbc load,  exec(" select * from master_cruise_details where purpose_code in (10,11) and cruise6>=200100 order by cruise6;") $mysole_conn;

/* Vessel names*/

odbc load,  exec("select * from svdbs.sv_vessel;") $mysole_conn;


/* Bigelow starts in 2009  -- Gloria Michelle and Pisces do the MA DMF inshore bottom trawl survey (11).*/

/*FSCS starts in with cruise6=200102 */

clear;

	odbc load,  exec("select distinct cruise6, svvessel from fscs_svsta where  cruise6 in 
    (select distinct cruise6 from svdbs_cruises where purpose_code in (10,11))
order by cruise6;") $mysole_conn;


/*UNION_FSCS has "everything" dating to the 1948s (1963 for real though)*/

clear;

	odbc load,  exec("select distinct cruise6, svvessel from union_fscs_svsta where  cruise6 in 
    (select distinct cruise6 from svdbs_cruises where purpose_code in (10,11))
order by cruise6;") $mysole_conn;


/* Length-weight coefficients, but svspp and sex. There is a SVLWCOEFF and an SVLWEXP.  Have to match on svspp and sex */
	odbc load,  exec("select * from SVDBS.SVGFSPP;") $mysole_conn;
 
 
 /* Length and weigths of individual fish */

	odbc load,  exec("select * from FSCS_SVBIO where cruise6>=200900;") $mysole_conn;

