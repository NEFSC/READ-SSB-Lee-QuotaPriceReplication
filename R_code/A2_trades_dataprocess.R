# This is Min-Yang's modification of Chad Demarest's code to estimate the quarterly average price (dollars per pound) of quota.
# This needs an input Rdataset. It cleans/recode, estimate and test various models
# This code gets exports the estimated coefficients to a table.



##  Things to do - ID non-market trades (permit banks, NEFS 4, etc)

my_datafile<-file.path(data_internal,paste0("ACE_data_",vintage_string,".Rdata"))



process_inter_data<-function(){
  
  # Add to_sector_name and from_sector_name to dataset
  i11<-sqldf("select b.sector_name as from_sector_name, transfer_number, transfer_date
             from out_1 a, out_2 b
             where a.from_sector_id=b.sector_id and a.year = b.year")  
  i12<-sqldf("select b.sector_name as to_sector_name, transfer_number, transfer_date
             from out_1 a, out_2 b
             where a.to_sector_id=b.sector_id and a.year = b.year")
  i1<-merge(out_1,i11,by=c("TRANSFER_NUMBER","TRANSFER_DATE"))
  i2<-merge(i1,i12,by=c("TRANSFER_NUMBER","TRANSFER_DATE"))
  i<-unique(i2)
  
  colnames(i)<-tolower(colnames(i))  # Make names lower case
  
  # Add columns for month, year, quarter
  i$date1 <- as.Date(i$transfer_date)
  i$month <- months.Date(i$date1)
  i$qtr <- substr(quarters.Date(i$date1),2,2)
  i$year <- year(i$date1)  
  
  i$fy <- with(i, ifelse(month(date1) < 5, year-1, year))
  
  i$compensation <- as.numeric(i$compensation)
  i[is.na(i)] <- 0
  
  # Convert to array of z's
  i$z1 <- ifelse(i$stock=="CC/GOM_Yellowtail_Flounder"|i$stock=="CC/GOM Yellowtail Flounder",i$live_pounds,0)
  i$z2 <- ifelse(i$stock=="GB_Cod_East"|i$stock=="GB Cod East",i$live_pounds,0)
  i$z3 <- ifelse(i$stock=="GB_Cod_West"|i$stock=="GB Cod West",i$live_pounds,0)
  i$z4 <- ifelse(i$stock=="GB_Haddock_East"|i$stock=="GB Haddock East",i$live_pounds,0)
  i$z5 <- ifelse(i$stock=="GB_Haddock_West"|i$stock=="GB Haddock West",i$live_pounds,0)
  i$z6 <- ifelse(i$stock=="GB_Winter_Flounder"|i$stock=="GB Winter Flounder",i$live_pounds,0)
  i$z7 <- ifelse(i$stock=="GB_Yellowtail_Flounder"|i$stock=="GB Yellowtail Flounder",i$live_pounds,0)
  i$z8 <- ifelse(i$stock=="GOM_Cod"|i$stock=="GOM Cod",i$live_pounds,0)
  i$z9 <- ifelse(i$stock=="GOM_Haddock"|i$stock=="GOM Haddock",i$live_pounds,0)
  i$z10 <- ifelse(i$stock=="GOM_Winter_Flounder"|i$stock=="GOM Winter Flounder",i$live_pounds,0)
  i$z11 <- ifelse(i$stock=="Plaice",i$live_pounds,0)
  i$z12 <- ifelse(i$stock=="Pollock",i$live_pounds,0)
  i$z13 <- ifelse(i$stock=="Redfish",i$live_pounds,0)
  i$z14 <- ifelse(i$stock=="SNE/MA_Yellowtail_Flounder"|i$stock=="SNE/MA Yellowtail Flounder",i$live_pounds,0)
  i$z15 <- ifelse(i$stock=="White_Hake"|i$stock=="White Hake",i$live_pounds,0)
  i$z16 <- ifelse(i$stock=="Witch_Flounder"|i$stock=="Witch Flounder",i$live_pounds,0)
  i$z17 <- ifelse(i$stock=="SNE/MA_Winter_Flounder"|i$stock=="SNE/MA Winter Flounder",i$live_pounds,0)
  
  i_e1<-sqldf("select fy, date1, transfer_date, qtr, transfer_number, from_sector_name, to_sector_name, avg(compensation) as compensation,
              sum(z1) as z1, sum(z2) as z2, sum(z3) as z3, sum(z4) as z4, sum(z5) as z5, sum(z6) as z6, sum(z7) as z7, sum(z8) as z8, sum(z9) as z9,
              sum(z10) as z10, sum(z11) as z11, sum(z12) as z12, sum(z13) as z13, sum(z14) as z14, sum(z15) as z15, sum(z16) as z16, sum(z17) as z17
              from i group by fy, date1, transfer_date, qtr, from_sector_name, to_sector_name")
  
  i_zero<<-subset(i_e1,compensation==0)  # potential swaps
  i_e1<-i_e1[!i_e1$compensation==0,]  # drop all zero compensation trades
  i_e1$transfer_number<-NULL
  i_e1$transfer_date<-NULL
  
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

process_final<-function(){
  w <- out    
  
  # Change calendar year quarter to fy quarter
  w$q_fy <- 10
  w$q_fy <- ifelse(months.Date(w$date1) %in% c("May","June","July"), 1, w$q_fy)
  w$q_fy <- ifelse(months.Date(w$date1) %in% c("August","September","October"), 2, w$q_fy)
  w$q_fy <- ifelse(months.Date(w$date1) %in% c("November","December","January"), 3, w$q_fy)
  w$q_fy <- ifelse(months.Date(w$date1) %in% c("February","March","April"), 4, w$q_fy)
  
  
  # when we compute total pounds, it should be based on absolute values: some of these are negative because of swap-returns

  
  w$abs_z1<-abs(w$z1)
  w$abs_z2<-abs(w$z2)
  w$abs_z3<-abs(w$z3)
  w$abs_z4<-abs(w$z4)
  w$abs_z5<-abs(w$z5)
  w$abs_z6<-abs(w$z6)
  w$abs_z7<-abs(w$z7)
  w$abs_z8<-abs(w$z8)
  w$abs_z9<-abs(w$z9)
  w$abs_z10<-abs(w$z10)
  w$abs_z11<-abs(w$z11)
  w$abs_z12<-abs(w$z12)
  w$abs_z13<-abs(w$z13)
  w$abs_z14<-abs(w$z14)
  w$abs_z15<-abs(w$z15)
  w$abs_z16<-abs(w$z16)
  w$abs_z17<-abs(w$z17)
  
  
  w$total_lbs <- with(w, abs_z1+abs_z2+abs_z3+abs_z4+abs_z5+abs_z6+abs_z7+abs_z8+abs_z9+abs_z10+abs_z11+abs_z12+abs_z13+abs_z14+abs_z15+abs_z16+abs_z17)
  w$avg_price <- w$compensation/w$total_lbs
  w$compensation <- ifelse((w$compensation < 3 & !(w$abs_z4>0|w$abs_z5>0|w$abs_z12>0|w$abs_z13>0) & w$total_lbs > 9), w$compensation * w$total_lbs, w$compensation) 
  
  
  drops <- c("abs_z1","abs_z2","abs_z3","abs_z4" , "abs_z5" , "abs_z6" , "abs_z7" , "abs_z8" , "abs_z9" , "abs_z10" , "abs_z11" , "abs_z12" , "abs_z13" , "abs_z14" , "abs_z15" , "abs_z16" , "abs_z17")
  w<-w[ , !(names(w) %in% drops)]
  write.dta(w,file.path(data_intermediate,paste0("nodrop_quota_",vintage_string,".dta")), version=10, convert.dates=TRUE)  
  
  # turn presumed marginal prices into total compensation
  #w <- subset(w, compensation > 5 & total_lbs > 50)  # eliminate small transactions with implicit prices less than $0.10
  w <- subset(w, avg_price == 0 | avg_price > 0.0045)  # eliminate prices less than half a penny
  w <- subset(w, avg_price < 6)  # eliminate nominal prices >$6/lbs 'cause that shit ain't real
  
  #w$z4<-0  # leaving haddock in...this and the next would eliminate gb haddock from the model, but after a lot of investigating I think it's better to leave it in
  #w$z5<-0
  w$lease_only <- ifelse(w$from_sector_name=="Maine Permit Bank"|w$from_sector_name=="NEFS 4",1,0)  # set lease_only to 1 for the lease only sectors
  
  w$interaction <- ifelse(w$from_sector_name=="Maine Permit Bank"|w$from_sector_name=="NEFS 4",w$total_lbs,0)  # set interaction as the lease-only sector variable, soaking up the fact that these sectors exist to lease at below-market rates
  
  terminal_fy<<-max(w$fy) 
  w_out <<- w
  w_out<<-unique(w_out)  ##eliminate duplicates, for whatever reason
  write.csv(w_out,file=file.path(data_intermediate,paste0("cleaned_quota_",vintage_string,".csv"))) 
  write.dta(w_out,file.path(data_intermediate,paste0("cleaned_quota_",vintage_string,".dta")), version=10, convert.dates=TRUE)  
  
  
}






####################################RUN THE FUNCTIONS###################################
#get_out_data()

load(my_datafile)

process_inter_data()
process_final()

