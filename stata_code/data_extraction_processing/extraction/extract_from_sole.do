/* here is a piece of code that shows how to extract data from sole */
#delimit;

clear;
odbc load,  exec("select * from cfspp;") $mysole_conn;
save $data_internal/cfspp_test_$vintage_string.dta, replace;


/* here is code that shows how to loop and append in stata*/
global firstyr 2012;
global lastyr 2016;
quietly forvalues yr=$firstyr/$lastyr{ ;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load, exec("select sum(s.qtykept) as qtykept, s.sppcode, s. dealnum, t.state1, t.portlnd1, t. permit, t.port, t.tripid, trunc(nvl(s.datesold, t.datelnd1)) as datesell from vtr.veslog`yr's s, vtr.veslog`yr't t 
		where t.tripid= s.tripid and (t.tripcatg=1 or t.tripcatg=4)
			and s.dealnum not in ('99998', '1', '2', '5', '7', '8')  and s.qtykept>=1 and s.qtykept is not null
			and sppcode not in ('WHAK','HAKNS','RHAK','WHAK','SHAK','HAKOS','WHB','CAT','RED')
			group by s.sppcode, t.state1, t.portlnd1, s.dealnum, t. permit, t.port, t.tripid, trunc(nvl(s.datesold, t.datelnd1));")  $mysole_conn;                    
	gen dbyear= `yr';
	quietly save `new', emptyok;
};
	clear;
	append using `NEWfiles';
	renvarlab, lower;
	destring, replace;
	compress;
cap drop emptyds;
