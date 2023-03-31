# Lifted from Chad's code, with a few tweaks.
# This code reads in a set of excel files that have been put into a standard format.  It cleans them up a bit and stacks them into two csvs.
require(gdata)
require(lubridate)
require(caret)
require(MASS)
require(reshape2)
require(dplyr)
require(broom)
require(robustbase)
require(zoo)
require(ggthemes)
library("readxl")

library("sqldf")

start_yr = 2011
end_yr = 2017

################
## set directory
## These data are confidential under MSA
## the 2017 date fields are a bit funky, you manually opened the excel file and set the format to MM/DD/YY (2 digit year) 
################

#directory <- "/run/user/1878/gvfs/sftp:host=sole.nefsc.noaa.gov,user=cdemarest/"
#directory<-"net.nefsc.noaa.gov\home7\cdemarest\R\groundfish\quota_trades\intra_sector_data"
# This works for min-yang in windows
#directory="//net.nefsc.noaa.gov/home7/cdemarest/R/groundfish/quota_trades/intra_sector_data"


file_old <-"trades11_13.csv"
file_recent <-"trades14_17.csv" 



################
################
################

#read_excel is pulling in 2015 dates as POSIXct, 2016 as chr, 2017 as "num"

get_in_data<-function(){
  #LOAD THE DATA, FY14 AND 15 PROCESSED BY ME AND FY11-13 PROCESSED BY DENISE (GARFO) AND FINN (HOLLINGS '14)
  v11<-read_excel(file.path(data_raw,"master_reg_2011.xls"))
  v12<-read_excel(file.path(data_raw,"master_reg_2012.xls"))
  v13<-read_excel(file.path(data_raw,"master_reg_2013.xls"))
  v14<-read_excel(file.path(data_raw,"master_intra_trades_2014.xls"))
  v15<-read_excel(file.path(data_raw,"master_intra_trades_2015.xls"))
  v16<-read_excel(file.path(data_raw,"master_intra_trades_2016.xls"))
  v17<-read_excel(file.path(data_raw,"master_intra_trades_2017b.xls"))
  
  v11$fy<-2011
  v12$fy<-2012
  v13$fy<-2013
  v15$id<-NULL
  v14$fy<-2014
  v15$fy<-2015
  v16$fy<-2016
  v17$fy<-2017
  
  #Tidy up the 11-13 column names by substituting a period for slashes and spaces(?!)
  names<-colnames(v11)
  names<-gsub("/", ".", names)
  names<-gsub(" ", ".", names)
  colnames(v11)<-names
  
  names<-colnames(v12)
  names<-gsub("/", ".", names)
  names<-gsub(" ", ".", names)
  colnames(v12)<-names
  
  names<-colnames(v13)
  names<-gsub("/", ".", names)
  names<-gsub(" ", ".", names)
  colnames(v13)<-names
  
  
  # Tidy up the date columns and drop the sector_id column
  v14$date<-as.Date(v14$date) 
  v15$date<-as.Date(v15$date) 
  v16$date<-as.Date(v16$date, format="%m/%d/%Y") 
  v17$date<-as.Date(v17$date, format="%Y-%m-/%d") 
  
  keepcols<-colnames(v14)
  
  v15<-v15[,keepcols]
  v16<-v16[,keepcols]
  v17<-v17[,keepcols]
  
  
  v11<<-v11
  v12<<-v12
  v13<<-v13
  v14<<-v14
  v15<<-v15
  v16<<-v16
  v17<<-v17
}






#11-13 DATA FIRST
process_1113<-function(){
  
  
  v_e<-rbind(v11,v12,v13)
  
  v_e$q_fy<-ifelse(v_e$Day_of_FY>0&v_e$Day_of_FY<=92,1,0)
  v_e$q_fy<-ifelse(v_e$Day_of_FY>92&v_e$Day_of_FY<=184,2,v_e$q_fy)
  v_e$q_fy<-ifelse(v_e$Day_of_FY>184&v_e$Day_of_FY<=276,3,v_e$q_fy)
  v_e$q_fy<-ifelse(v_e$Day_of_FY>276&v_e$Day_of_FY<=366,4,v_e$q_fy)
  
  v_e$z1<-v_e$CC.GOM.Yellowtail.Flounder
  v_e$z2<-v_e$GB.Cod.East
  v_e$z3<-v_e$GB.Cod.West
  v_e$z4<-v_e$GB.Haddock.East
  v_e$z5<-v_e$GB.Haddock.West
  v_e$z6<-v_e$GB.Winter.Flounder
  v_e$z7<-v_e$GB.Yellowtail.Flounder
  v_e$z8<-v_e$GOM.Cod
  v_e$z9<-v_e$GOM.Haddock
  v_e$z10<-v_e$GOM.Winter.Flounder
  v_e$z11<-v_e$Plaice
  v_e$z12<-v_e$Pollock
  v_e$z13<-v_e$Redfish
  v_e$z14<-v_e$SNE.MA.Yellowtail.Flounder
  v_e$z15<-v_e$White.Hake
  v_e$z16<-v_e$Witch.Flounder
  v_e$z17<-v_e$SNE.MA.Winter.Flounder
  
  v_e2<-sqldf("select fy, q_fy, sector_name, from_member_id, to_member_id, Day_of_FY,total_compensation as compensation, 
  z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17 from v_e")
  
  names(v_e2)<-tolower(names(v_e2))
  v_e2[is.na(v_e2)]<-0
  v_e3<<-v_e2
  
  ###########################PROCESS AND RETURN SWAPS###################################
  s1<-subset(v_e3,compensation==0)
  
  s1<-s1 %>% group_by(fy,q_fy,sector_name) %>% mutate(lag.to = lag(to_member_id, 1))
  s1<-s1 %>% group_by(fy,q_fy,sector_name) %>% mutate(lead.to = lead(to_member_id, 1))
  s1<-s1 %>% group_by(fy,q_fy,sector_name) %>% mutate(lag.from = lag(from_member_id, 1))
  s1<-s1 %>% group_by(fy,q_fy,sector_name) %>% mutate(lead.from = lead(from_member_id, 1))
  s1$swap_side<-0
  s1$swap_side<-ifelse(s1$to_member_id==s1$lead.from&s1$from_member_id==s1$lead.to,1,s1$swap_side)
  s1$swap_side<-ifelse(s1$from_member_id==s1$lag.to&s1$to_member_id==s1$lag.from,2,s1$swap_side)
  s1<-subset(s1,swap_side!=0)
  s1<-s1 %>% group_by(fy,q_fy,sector_name) %>% mutate(lead.swap_side = lead(swap_side, 1))
  s1<-s1 %>% group_by(fy,q_fy,sector_name) %>% mutate(lag.swap_side = lag(swap_side, 1))
  s1$swap<-ifelse(s1$swap_side==1&s1$lead.swap_side==2,1,0)
  s1$swap<-ifelse(s1$swap_side==2&s1$lag.swap_side==1,1,s1$swap)
  s1<-subset(s1,swap==1)
  s2<-sqldf("select fy, q_fy, sector_name, from_member_id, to_member_id, compensation, Day_of_FY, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17, swap, swap_side from s1 where swap_side = 2 and 
           (z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17)>0")
  s3<-sqldf("select fy, q_fy, sector_name, from_member_id, to_member_id, compensation, Day_of_FY, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17, swap, swap_side from s1 where swap_side = 1 and 
           (z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17)>0")
  s2$id<-as.numeric(rownames(s2))
  s3$id<-as.numeric(rownames(s3))
  s4<-sqldf("select a.fy, a.q_fy, a.Day_of_FY,a.id, a.sector_name, a.from_member_id, a.to_member_id, a.compensation, (a.z1-b.z1) as z1, (a.z2-b.z2) as z2, (a.z3-b.z3) as z3, (a.z4-b.z4) as z4, (a.z5-b.z5) as z5,
           (a.z6-b.z6) as z6, (a.z7-b.z7) as z7, (a.z8-b.z8) as z8, (a.z9-b.z9) as z9, (a.z10-b.z10) as z10, (a.z11-b.z11) as z11, (a.z12-b.z12) as z12, (a.z13-b.z13) as z13, (a.z14-b.z14) as z14,
           (a.z15-b.z15) as z15, (a.z16-b.z16) as z16, (a.z17-b.z17) as z17 from s2 a, s3 b where a.id=b.id and a.fy=b.fy and a.q_fy=b.q_fy and a.sector_name=b.sector_name")
  s4<-sqldf("select fy, q_fy, Day_of_FY, sector_name, from_member_id, to_member_id, compensation, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17 from s4")
  s4$type<-"swap"
  v_e2<-subset(v_e2, compensation!=0)
  v_e2$type<-"regular"
  # save the swap and trade data frames
  swap11_13<<-s4
  trades11_13<<-v_e2
}





#14 ONWARD DATA



 



format_stock_names<-function(){
  
  v<-rbind(v14, v15, v16, v17)
  
  correct_stocks<-as.data.frame(c("CC/GOM_Yellowtail_Flounder","GB_Cod_East","GB_Cod_West","GB_Haddock_East","GB_Haddock_West","GB_Winter_Flounder","GB_Yellowtail_Flounder","GOM_Cod","GOM_Haddock","GOM_Winter_Flounder","Plaice","Pollock","Redfish","SNE/MA_Yellowtail_Flounder","White_Hake","Witch_Flounder","SNE/MA_Winter_Flounder"))
  colnames(correct_stocks)<-c("stock")
  
  stocks<-as.data.frame(unique(v$stock))
  colnames(stocks)<-c("stock")
  
  stocks1<-as.vector(sqldf("select * from stocks where (stock LIKE '%ell%' OR stock LIKE '%ELL%' OR stock LIKE '%YEL%' OR stock LIKE '%yel%' OR stock LIKE '%yt%' OR stock LIKE '%YT%') AND (stock LIKE '%cc%' OR stock LIKE '%CC%' OR stock LIKE '%GOM%' OR stock LIKE '%gom%') AND (stock NOT LIKE '%GB%' OR stock NOT LIKE '%gb%')"))
  stocks2<-as.vector(sqldf("select * from stocks where (stock LIKE '%Cod%' OR stock LIKE '%cod%' OR stock LIKE '%COD%') AND (stock LIKE '%gb%' OR stock LIKE '%GB%' OR stock LIKE '%Geor%') AND (stock LIKE '%E%' OR stock LIKE '%e%') AND (stock NOT LIKE '%West%' OR stock NOT LIKE '%west%')"))
  stocks3<-as.vector(sqldf("select * from stocks where (stock LIKE '%Cod%' OR stock LIKE '%cod%' OR stock LIKE '%COD%') AND (stock LIKE '%gb%' OR stock LIKE '%GB%' OR stock LIKE '%Geor%') AND (stock LIKE '%W%' OR stock LIKE '%w%') AND (stock NOT LIKE '%East%' OR stock NOT LIKE '%east%')"))
  stocks4<-as.vector(sqldf("select * from stocks where (stock LIKE '%add%' OR stock LIKE '%ADD%') AND (stock LIKE '%gb%' OR stock LIKE '%GB%' OR stock LIKE '%Geor%') AND (stock LIKE '%E%' OR stock LIKE '%e%') AND (stock NOT LIKE '%West%' OR stock NOT LIKE '%west%')"))
  stocks5<-as.vector(sqldf("select * from stocks where (stock LIKE '%add%' OR stock LIKE '%ADD%') AND (stock LIKE '%gb%' OR stock LIKE '%GB%' OR stock LIKE '%Geor%') AND (stock LIKE '%W%' OR stock LIKE '%w%') AND (stock NOT LIKE '%East%' OR stock NOT LIKE '%east%')"))
  stocks6<-as.vector(sqldf("select * from stocks where (stock LIKE '%int%' OR stock LIKE '%INT%' OR stock LIKE '%Flound%') AND (stock LIKE '%gb%' OR stock LIKE '%GB%' OR stock LIKE '%eorge%') AND (stock NOT LIKE '%ell%' OR stock NOT LIKE '%ELL%')"))
  stocks7<-as.vector(sqldf("select * from stocks where (stock LIKE '%ell%' OR stock LIKE '%ELL%' OR stock LIKE '%yt%' OR stock LIKE '%YT%') AND (stock LIKE '%gb%' OR stock LIKE '%GB%')"))
  stocks8<-as.vector(sqldf("select * from stocks where (stock LIKE '%Cod%' OR stock LIKE '%cod%' OR stock LIKE '%COD%' OR stock LIKE '%cog%') AND (stock LIKE '%om%' OR stock LIKE '%OM%' OR stock LIKE '%GMSS%' OR stock LIKE '%gmss%' OR stock LIKE '%Gulf%')"))
  stocks9<-as.vector(sqldf("select * from stocks where (stock LIKE '%add%' OR stock LIKE '%ADD%' OR stock LIKE '%ADGM%') AND (stock LIKE '%om%' OR stock LIKE '%OM%' OR stock LIKE '%GMSS%' OR stock LIKE '%gmss%' OR stock LIKE '%GM%' OR stock LIKE '%gm%' OR stock LIKE '%Gulf%')"))
  stocks10<-as.vector(sqldf("select * from stocks where (stock LIKE '%int%' OR stock LIKE '%INT%' OR stock LIKE '%M fl%' OR stock LIKE '%om fl%') AND (stock LIKE '%om%' OR stock LIKE '%OM%')"))
  stocks11<-as.vector(sqldf("select * from stocks where (stock LIKE '%lai%' OR stock LIKE '%LAI%' OR stock LIKE '%DAB%' OR stock LIKE '%dab%' OR stock LIKE '%Dab%' OR stock LIKE '%PLAG%')"))
  stocks12<-as.vector(sqldf("select * from stocks where (stock LIKE '%oll%' OR stock LIKE '%OLL %')"))
  stocks13<-as.vector(sqldf("select * from stocks where (stock LIKE '%edf%' OR stock LIKE '%EDF%' OR stock LIKE '%Red%' OR stock LIKE '%RED%' OR stock LIKE '%red%') "))
  stocks14<-as.vector(sqldf("select * from stocks where (stock LIKE '%ell%' OR stock LIKE '%ELL%' OR stock LIKE '%yt%' OR stock LIKE '%YT%') AND (stock LIKE '%sn%' OR stock LIKE '%SN%' OR stock LIKE '%Sn%')"))
  stocks15<-as.vector(sqldf("select * from stocks where (stock LIKE '%hak%' OR stock LIKE '%HAK%' OR stock LIKE '%Hak%') "))
  stocks16<-as.vector(sqldf("select * from stocks where (stock LIKE '%itc%' OR stock LIKE '%ITC%' OR stock LIKE '%sole%' OR stock LIKE '%SOLE%' OR stock LIKE '%WITG%') "))
  stocks17<-as.vector(sqldf("select * from stocks where (stock LIKE '%int%' OR stock LIKE '%INT%' OR stock LIKE '%lackb%' OR stock LIKE '%ne flo%' OR stock LIKE '%ne/ma fl%') AND (stock LIKE '%sne%' OR stock LIKE '%SNE%' OR stock LIKE '%MA%' OR stock LIKE '%ma%') AND (stock NOT LIKE '%mai%' OR stock NOT LIKE '%MAI%' OR stock NOT LIKE '%GB%' OR stock NOT LIKE '%gb%')"))
  
  v1<-data.frame()
  for (i in 1:17) {
    stockstock<-correct_stocks[c(i),]
    v2<-sqldf(paste0("select a.date, a.from_member_id, a.to_member_id, a.transfer_lbs, a.compensation_type, a.commodity_desc, a.compensation, a.sector_name, a.fy from v a, stocks",i," b where a.stock=b.stock"))
    v2$stock<-stockstock
    v1<-rbind(v1,v2)
  }
  v<<-v1
}






process_14_plus<-function(){


  v<-sqldf("select * from v where date is not null")
  v$compensation<-as.numeric(v$compensation)
  v[is.na(v)]<-0
  
  
  v$z1<-as.numeric(as.character(ifelse(v$stock=="CC/GOM_Yellowtail_Flounder",v$transfer_lbs,0)))
  v$z2<-as.numeric(as.character(ifelse(v$stock=="GB_Cod_East",v$transfer_lbs,0)))
  v$z3<-as.numeric(as.character(ifelse(v$stock=="GB_Cod_West",v$transfer_lbs,0)))
  v$z4<-as.numeric(as.character(ifelse(v$stock=="GB_Haddock_East",v$transfer_lbs,0)))
  v$z5<-as.numeric(as.character(ifelse(v$stock=="GB_Haddock_West",v$transfer_lbs,0)))
  v$z6<-as.numeric(as.character(ifelse(v$stock=="GB_Winter_Flounder",v$transfer_lbs,0)))
  v$z7<-as.numeric(as.character(ifelse(v$stock=="GB_Yellowtail_Flounder",v$transfer_lbs,0)))
  v$z8<-as.numeric(as.character(ifelse(v$stock=="GOM_Cod",v$transfer_lbs,0)))
  v$z9<-as.numeric(as.character(ifelse(v$stock=="GOM_Haddock",v$transfer_lbs,0)))
  v$z10<-as.numeric(as.character(ifelse(v$stock=="GOM_Winter_Flounder",v$transfer_lbs,0)))
  v$z11<-as.numeric(as.character(ifelse(v$stock=="Plaice",v$transfer_lbs,0)))
  v$z12<-as.numeric(as.character(ifelse(v$stock=="Pollock",v$transfer_lbs,0)))
  v$z13<-as.numeric(as.character(ifelse(v$stock=="Redfish",v$transfer_lbs,0)))
  v$z14<-as.numeric(as.character(ifelse(v$stock=="SNE/MA_Yellowtail_Flounder",v$transfer_lbs,0)))
  v$z15<-as.numeric(as.character(ifelse(v$stock=="White_Hake",v$transfer_lbs,0)))
  v$z16<-as.numeric(as.character(ifelse(v$stock=="Witch_Flounder",v$transfer_lbs,0)))
  v$z17<-as.numeric(as.character(ifelse(v$stock=="SNE/MA_Winter_Flounder",v$transfer_lbs,0)))
  
  v_e1<-sqldf("select fy, date, sector_name, from_member_id, to_member_id, avg(compensation) as avg_compensation, sum(compensation) as sum_compensation, compensation as first_compensation, 
 sum(z1) as z1, sum(z2) as z2, sum(z3) as z3, sum(z4) as z4, sum(z5) as z5, sum(z6) as z6, sum(z7) as z7, sum(z8) as z8, sum(z9) as z9,
 sum(z10) as z10, sum(z11) as z11, sum(z12) as z12, sum(z13) as z13, sum(z14) as z14, sum(z15) as z15, sum(z16) as z16, sum(z17) as z17 
 from v group by fy, date, sector_name, from_member_id, to_member_id")
  
  v_e1$avg_compensation<-round(v_e1$avg_compensation,0)
  v_e1$first_compensation<-round(v_e1$first_compensation,0)
  v_e1$compensation<-ifelse(v_e1$avg_compensation==v_e1$first_compensation, v_e1$avg_compensation, v_e1$sum_compensation)
  v_e1$avg_compensation<-NULL
  v_e1$sum_compensation<-NULL
  v_e1$first_compensation<-NULL
  v_zero<<-subset(v_e1,compensation==0)
  v_e1<-v_e1[!v_e1$compensation==0,]                                                   #drop all zero compensation trades
  #v_e1$date<-NULL
  
  ###########################PROCESS AND RETURN SWAPS###################################
  s11<-subset(v_zero,compensation==0)
  
  s11<-s11 %>% group_by(fy,date,sector_name) %>% mutate(lag.to = lag(to_member_id, 1))
  s11<-s11 %>% group_by(fy,date,sector_name) %>% mutate(lead.to = lead(to_member_id, 1))
  s11<-s11 %>% group_by(fy,date,sector_name) %>% mutate(lag.from = lag(from_member_id, 1))
  s11<-s11 %>% group_by(fy,date,sector_name) %>% mutate(lead.from = lead(from_member_id, 1))
  s11$swap_side<-0
  s11$swap_side<-ifelse(s11$to_member_id==s11$lead.from&s11$from_member_id==s11$lead.to,1,s11$swap_side)
  s11$swap_side<-ifelse(s11$from_member_id==s11$lag.to&s11$to_member_id==s11$lag.from,2,s11$swap_side)
  s11<-subset(s11,swap_side!=0)
  s11<-s11 %>% group_by(fy,date,sector_name) %>% mutate(lead.swap_side = lead(swap_side, 1))
  s11<-s11 %>% group_by(fy,date,sector_name) %>% mutate(lag.swap_side = lag(swap_side, 1))
  s11$swap<-ifelse(s11$swap_side==1&s11$lead.swap_side==2,1,0)
  s11$swap<-ifelse(s11$swap_side==2&s11$lag.swap_side==1,1,s11$swap)
  s11<-subset(s11,swap==1)
  s12<-sqldf("select fy, date, sector_name, from_member_id, to_member_id, compensation, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17, swap, swap_side from s11 where swap_side = 2 and 
           (z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17)>0")
  s13<-sqldf("select fy, date, sector_name, from_member_id, to_member_id, compensation, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17, swap, swap_side from s11 where swap_side = 1 and 
           (z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17)>0")
  s14<-sqldf("select a.fy, a.date, a.sector_name, a.from_member_id, a.to_member_id, a.compensation, (a.z1-b.z1) as z1, (a.z2-b.z2) as z2, (a.z3-b.z3) as z3, (a.z4-b.z4) as z4, (a.z5-b.z5) as z5,
           (a.z6-b.z6) as z6, (a.z7-b.z7) as z7, (a.z8-b.z8) as z8, (a.z9-b.z9) as z9, (a.z10-b.z10) as z10, (a.z11-b.z11) as z11, (a.z12-b.z12) as z12, (a.z13-b.z13) as z13, (a.z14-b.z14) as z14,
           (a.z15-b.z15) as z15, (a.z16-b.z16) as z16, (a.z17-b.z17) as z17 from s12 a, s13 b where a.date=b.date and a.fy=b.fy and a.sector_name=b.sector_name")
  s14<-sqldf("select fy, date, sector_name, from_member_id, to_member_id, compensation, z1,z2,z3,z4,z5,z6,z7,z8,z9,z10,z11,z12,z13,z14,z15,z16,z17 from s14")
  
  
  s14$month<-as.yearmon(s14$date)
  s14$month<-format(s14$month, "%m")
  s14$q_fy<-ifelse(s14$month=="05"|s14$month=="06"|s14$month=="07",1,0)                   #change calendar year quarter to fy quarter
  s14$q_fy<-ifelse(s14$month=="08"|s14$month=="09"|s14$month=="10",2,s14$q_fy)
  s14$q_fy<-ifelse(s14$month=="11"|s14$month=="12"|s14$month=="01",3,s14$q_fy)
  s14$q_fy<-ifelse(s14$month=="02"|s14$month=="03"|s14$month=="04",4,s14$q_fy)
  
  
  v_e1$month<-as.yearmon(v_e1$date)
  v_e1$month<-format(v_e1$month, "%m")
  v_e1$q_fy<-ifelse(v_e1$month=="05"|v_e1$month=="06"|v_e1$month=="07",1,0)                   #change calendar year quarter to fy quarter
  v_e1$q_fy<-ifelse(v_e1$month=="08"|v_e1$month=="09"|v_e1$month=="10",2,v_e1$q_fy)
  v_e1$q_fy<-ifelse(v_e1$month=="11"|v_e1$month=="12"|v_e1$month=="01",3,v_e1$q_fy)
  v_e1$q_fy<-ifelse(v_e1$month=="02"|v_e1$month=="03"|v_e1$month=="04",4,v_e1$q_fy)
  
  
  v_e1$type<-"regular"
  s14$type<-"swap"
  
  swap14_17<<-s14
  trades14_17<<-v_e1
  
}

#COMBINE THE DATASETS AND PROCESS THE HEDONIC DATA
process_all<-function(){
  w<-rbind(v_in1,v_in2)                                 #v_e1 is 2014 and 2015 processed data, v_e2 is 2011-2013 processed data
  attach(w)
  w$total_lbs<-z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17
  detach(w)
  w$avg_price<-w$compensation/w$total_lbs
  w$compensation<-ifelse((w$compensation<3&!(w$z4>0|w$z5>0|w$z12>0|w$z13>0)&w$total_lbs>9),w$compensation*w$total_lbs,w$compensation)  
                                                      #turn presumed marginal prices into total compensation
  w<-subset(w, compensation>5&total_lbs>50)           #eliminate small transactions with implicit prices less than $0.10
  w<-subset(w, avg_price>0.0045)                      #eliminate prices less than half a penny
  w<-subset(w, avg_price<5)                           #eliminate nominal prices >$5/lbs 'cause that shit ain't real
  #w$z4<-0                                            #leaving haddock in...this and the next would eliminate gb haddock from the model, but after a lot of investigating I think it's better to leave it in
  #w$z5<-0
  w_in<<-w
  write.csv(w_in,file=paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/w_in.csv") ) 
}

##############################################################RUN THE FUNCTIONS###############################################################
get_in_data()
process_1113()
format_stock_names()
process_14_plus()                                        #don't sweat the Warning...it's two dates that failed to parse with LUBRIDATE...both datum are dropped
#process_all()                                         #combine both the 11-13 and 14-> datasets and process them
##############################################################################################################################################

trades11_13<-rbind(swap11_13,trades11_13)
trades14_17<-rbind(swap14_17,trades14_17)

write.csv(trades11_13,file=file.path(data_internal, file_old) ) 
write.csv(trades14_17,file=file.path(data_internal, file_recent) ) 




