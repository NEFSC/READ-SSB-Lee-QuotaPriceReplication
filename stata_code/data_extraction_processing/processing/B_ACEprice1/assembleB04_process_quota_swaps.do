/* examine and process swaps? */
# delimit; 
/*
use "${data_internal}\potential_swaps.dta", replace;

  ########################### PROCESS AND RETURN SWAPS ###################################
  s1 <- subset(i_zero,compensation==0)
  
  s1 <- s1 %>% group_by(fy,qtr,date1) %>% mutate(lag.to = lag(to_sector_name, 1))
  s1 <- s1 %>% group_by(fy,qtr,date1) %>% mutate(lead.to = lead(to_sector_name, 1))
  s1 <- s1 %>% group_by(fy,qtr,date1) %>% mutate(lag.from = lag(from_sector_name, 1))
  s1 <- s1 %>% group_by(fy,qtr,date1) %>% mutate(lead.from = lead(from_sector_name, 1))
  s1$swap_side <- 0
  s1$swap_side <- ifelse(s1$to_sector_name==s1$lead.from&s1$from_sector_name==s1$lead.to,1,s1$swap_side)
  s1$swap_side <- ifelse(s1$from_sector_name==s1$lag.to&s1$to_sector_name==s1$lag.from,2,s1$swap_side)
  
  s1 <- subset(s1,swap_side!=0)
  s1 <- s1 %>% group_by(fy,qtr,date1) %>% mutate(lead.swap_side = lead(swap_side, 1))
  s1 <- s1 %>% group_by(fy,qtr,date1) %>% mutate(lag.swap_side = lag(swap_side, 1))
  s1$swap <- ifelse(s1$swap_side==1&s1$lead.swap_side==2,1,0)
  s1$swap <- ifelse(s1$swap_side==2&s1$lag.swap_side==1,1,s1$swap)
  
  s1 <- subset(s1,swap==1)
  s12 <- sqldf("select fy, qtr, date1, from_sector_name, to_sector_name, compensation, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17, swap, swap_side from s1 where swap_side = 2 and
               (z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17)>0")
  s13 <- sqldf("select fy, qtr, date1, from_sector_name, to_sector_name, compensation, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17, swap, swap_side from s1 where swap_side = 1 and
               (z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17)>0")
  s14 <- sqldf("select a.fy, a.qtr, a.date1, a.from_sector_name, a.to_sector_name, a.compensation, (a.z1-b.z1) as z1, (a.z2-b.z2) as z2, (a.z3-b.z3) as z3, (a.z4-b.z4) as z4, (a.z5-b.z5) as z5,
               (a.z6-b.z6) as z6, (a.z7-b.z7) as z7, (a.z8-b.z8) as z8, (a.z9-b.z9) as z9, (a.z10-b.z10) as z10, (a.z11-b.z11) as z11, (a.z12-b.z12) as z12, (a.z13-b.z13) as z13, (a.z14-b.z14) as z14,
               (a.z15-b.z15) as z15, (a.z16-b.z16) as z16, (a.z17-b.z17) as z17 from s12 a, s13 b where a.date1=b.date1 and a.fy=b.fy and a.qtr=b.qtr")
  s14 <- sqldf("select fy, qtr, date1, from_sector_name, to_sector_name, compensation, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17 from s14")
  i_e1 <- rbind(i_e1, s14)  
  out <<- i_e1
}

*/
