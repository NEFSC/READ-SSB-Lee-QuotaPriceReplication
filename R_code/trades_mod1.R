# This is Min-Yang's modification of Chad Demarests's code to estimate the quarterly average price (dollars per pound) of quota.
# This needs an input Rdataset. It cleans/recode, estimate and test various models
# This code gets exports the estimated coefficients to a table.



##  Things to do - ID non-market trades (permit banks, NEFS 4, etc)

## You're dumbass RODBC isn't working on your local computer. And you're having major problems with lubridate on the Venus server

my_datafile<-"ACE_data2.Rdata"



process_inter_data<-function(){
  
  # Add to_sector_name and from_sector_name to dataset
  i11<-sqldf("select b.sector_name as from_sector_name
             from out_1 a, out_2 b
             where a.from_sector_id=b.sector_id")  
  i12<-sqldf("select b.sector_name as to_sector_name
             from out_1 a, out_2 b
             where a.to_sector_id=b.sector_id")
  
  i<-cbind(out_1,i11,i12)
  
  colnames(i)<-tolower(colnames(i))  # Make column names lower case
  
  # Add columns for month, year, quarter
  i$date1 <- as.Date(i$transfer_date)
  i$month <- months.Date(i$date1)
  i$qtr <- substr(quarters.Date(i$date1),2,2)
  i$year <- year(i$date1)  
  terminal_fy <<- max(i$year)
  terminal_fy <<- 2019
  
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
  
  w$total_lbs <- with(w, z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17)
  w$avg_price <- w$compensation/w$total_lbs
  w$compensation <- ifelse((w$compensation<3&!(w$z4>0|w$z5>0|w$z12>0|w$z13>0)&w$total_lbs>9), w$compensation*w$total_lbs, w$compensation) 
  # turn presumed marginal prices into total compensation
  w <- subset(w, compensation>5&total_lbs>50)  # eliminate small transactions with implicit prices less than $0.10
  w <- subset(w, avg_price>0.0045)  # eliminate prices less than half a penny
  w <- subset(w, avg_price<5)  # eliminate nominal prices >$5/lbs 'cause that shit ain't real
  #w$z4<-0  # leaving haddock in...this and the next would eliminate gb haddock from the model, but after a lot of investigating I think it's better to leave it in
  #w$z5<-0
  w$z18 <- ifelse(w$from_sector_name=="Maine Permit Bank"|w$from_sector_name=="NEFS 4",w$total_lbs,0)  # set z18 as the lease-only sector variable, soaking up the fact that these sectors exist to lease at below-market rates
  w_out <<- w
  
  write.csv(w_out,file=file.path(data_intermediate,"cleaned_quota.csv")) 
  write.dta(w_out,file.path(data_intermediate,"cleaned_quota.dta"), version=10, convert.dates=TRUE)  
  
}






































##########################################################
## LEAST SQUARES REGRESSION WITH ROBUST STANDARD ERRORS ##
##########################################################
# This is breaking in q1 of 2019 because there was only 1 trade in that quarter that had z4, z7, z14, and z17.
regress_qtr_out<-function(){
  #print(paste("Year: ",i," Quarter: ",j)) 
  d<-subset(w_out, fy==i&q_fy==j)
  
  # if the subset has observations
  if(dim(d)[1] != 0){
    # remove predictors with four or fewer data points to avoid singular fits
    d <- d[,colSums(d>0) >= 5]
    d_out<<-d                                 # Purpose?
    # if any predictors are left   
    if(length(grep("^[z]",names(d),value=TRUE)) != 0) {
      pred<-grep("^[z]",names(d),value=TRUE)        # build regression formula from remaining predictors
      # print(paste("pred is ",pred))
      x <- paste(pred, collapse="+")
      ols <- paste("compensation ~ ",x,sep="")      # regression from remaining predictors (will need to add lease_only for inter trades)
      ols <- as.formula(ols)                        # set OLS as formula for rlm
      o1.lm <- lm(ols, data=d)                      # compute OLS to idenify severe and influential outliers
      o1 <- as.data.frame(cooks.distance(o1.lm))    # get cooks distance to id influential weird ones
      e <- cbind(o1,d)
      names(e)[1] <- "cooks_d"
      e <- subset(e, cooks_d<cooks_max)             # remove weird ones (super-high cooks distance), noting that this is less important w/ robust standard errors
      e <- unique(e)                                # Remove duplicates, or it gives an error in rlm()
      
      o1.rlm <- rlm(ols, data=e, maxit=600)         #won't converge at 20 so 200'll do      IGNORE=  "#,    setting="KS2014""
      
      a <- coefficients(summary(o1.rlm))            #returns a matrix
      
      a<-as.data.frame(a)
      a$var<-rownames(a)
      a$q_fy<-j
      a$fy<-i
      return(a)
    }
  } else {
    #print("No observations this quarter")    
  }  
}

regress_yr_out<-function(){
  
  d <- subset(w_out, fy==i)  
  d <- d[,colSums(d>0) >= 5]                         # remove predictors with four or fewer data points to avoid singular fits
  
  pred <- grep("^[z]",names(d),value=TRUE)           # build regression formula from remaining predictors
  x <- paste(pred, collapse="+")
  ols <- paste("compensation ~ ",x,sep="")           # regression from remaining predictors (will need to add lease_only for inter trades)
  ols <- as.formula(ols)                             # set OLS as formula for rlm
  o1.lm <- lm(ols, data=d)                           # compute OLS to idenify severe and influential outliers
  o1 <- as.data.frame(cooks.distance(o1.lm))         # get cooks distance to id influential weird ones
  e <- cbind(o1,d)
  names(e)[1] <- "cooks_d"
  e <- subset(e, cooks_d<cooks_max)                  # remove weird ones (super-high cooks distance), noting that this is less important w/ robust standard errors
  o1.rlm <- rlm(ols, data=e, maxit=200)              # Won't converge at 20 so 200'll do      IGNORE= "#,    setting="KS2014""
  o1.rlm <<- o1.rlm
  a <- coefficients(summary(o1.rlm))
  a <- as.data.frame(a)
  a$var <- rownames(a)  
  a$fy <- i
  return(a)
  
}


post_process_qtr<-function(){
  fy <- fy_out1
  fy <- sqldf("select * from fy where var <> '(Intercept)'")  # filtering out low t-value (not sig) prices
  names(fy)[names(fy) == 't value'] <- 't_value'  # Rename column 't value'
  
  fy$price <- 99
  lease_only <<- sqldf("select * from fy where var='z18'")  # set aside lease-only values for inspection
  fy<-sqldf("select * from fy where var <> 'z18'")  # drop lease-only values for reporting purposes
  
  fy$price <- ifelse((abs(fy$t_value)>1.5 ),fy$Value,0)                  
  fy$price <- ifelse(fy$t_value<0,0,fy$price)                                  # negative prices to zero...because....don't ask
  fy$price <- ifelse((fy$var=="z4"|fy$var=="z5")&fy$Value>1,0,fy$price)        # jeez, haddock fucks with everything...
  fy$price <- ifelse((fy$var=="z12"|fy$var=="z2")&fy$Value>2.85,0,fy$price)    # bizzaro pollock and a GB cod east that's apparently in error
  fy$price <- ifelse(fy$var=="z13"&fy$Value>1&fy$fy<2017,0,fy$price)           # bizzaro redfish
  
  fy$price<-ifelse(fy$Value>6,0,fy$price)
  
  # TODO : Part of the following can be taken out into a separate function
  
  #############CREATE TIMEVAR DATASET WITH YEARS AND QUARTERS AND STOCK NAMES##################
  sn<-read.csv(file.path(data_master,"var_stock_name_link.csv"))
  years <- c(2010:terminal_fy)
  qrts <- c(1:4)
  zees <- sprintf("z%d",seq(1:17))
  comb <- expand.grid(fy=years, q_fy=qrts, var=zees)  # 'var' is not a good name for a column
  comb <- merge(comb,sn)                              # add stock names
  
  comb <- merge(comb,fy,by=c("fy","q_fy","var"),all=TRUE)
  fy <- comb
  fy$date <- as.yearqtr(paste(fy$fy,fy$q_fy,sep="q"))
  
  #fy[fy==0] <- NA #WHY???
  
  fy$price_out <- fy$price
  fy_out1 <<- fy
  
  write.csv(fy_out1,file=file.path(hedonicR_results,"hedonic_quarterlyR.csv"), row.names=FALSE)
  write.dta(fy_out1,file.path(hedonicR_results,"hedonic_quarterlyR.dta"), version=10, convert.dates=TRUE)  
  
}

post_process_yr<-function(){
  
  fy<-fy_out2
  fy<-sqldf("select * from fy where var <> '(Intercept)'")                    # filtering out low t-value (not sig) prices
  names(fy)[names(fy) == 't value'] <- 't_value'                              # Rename column 't value'
  
  #LEASE-ONLY
  lease_only <<- sqldf("select * from fy where var='z18'")                    # set aside lease-only values for inspection
  fy <- sqldf("select * from fy where var <> 'z18'")                          # drop lease-only values for reporting purposes
  
  #PRICE
  fy$price <- 99
  fy$price <- ifelse((abs(fy$t_value)>1.5 ),fy$Value,0)                  
  fy$price <- ifelse(fy$t_value<0,0,fy$price)                                  # negative prices to zeros (hi Anna)
  fy$price <- ifelse((fy$var=="z4"|fy$var=="z5")&fy$Value>1,0,fy$price)        # jeez, haddock fucks with everything...
  fy$price <- ifelse((fy$var=="z12"|fy$var=="z13"|fy$var=="z2")&fy$Value>2.85,0,fy$price)  # bizzaro pollock
  
  fy$price <- ifelse(fy$Value>6,0,fy$price)
  
  #############CREATE TIMEVAR DATASET WITH YEARS AND QUARTERS AND STOCK NAMES##################
  sn <- read.csv(file.path(data_master,"var_stock_name_link.csv"))
  
  years <- c(2010:terminal_fy)
  zees <- sprintf("z%d",seq(1:17))
  comb <- expand.grid(fy=years,var=zees)                      # 'var' is not a good name for a column
  comb <- merge(comb,sn)  # add stock names
  comb <- merge(comb,fy,by=c("fy","var"),all=TRUE) 
  
  #fy[fy==0]<-NA                                              # Differentiate between NA and 0 results?
  
  fy_out2<<-comb


  write.csv(fy_out2,file=file.path(hedonicR_results,"hedonic_yearlyR.csv"), row.names=FALSE)
  write.dta(fy_out2,file.path(hedonicR_results,"hedonic_yearlyR.dta"), version=10, convert.dates=TRUE)  
  
}
#END OF DEFINING FUNCTIONS 






####################################RUN THE FUNCTIONS###################################
#get_out_data()

load(file.path(data_internal,my_datafile))

process_inter_data()
process_final()

cooks_max <- 2                                            # set cooks distancec max value at 2, which is pretty damned high, but not too important
fy_out2_list <- list()
fy_out1_list <- list()                                    # list that will hold quarterly data frames

#print(paste("The terminal_fy is",terminal_fy))

###################################### QUARTERLY #######################################
k <- 1
for (i in 2010:terminal_fy) {
  for (j in 1:4) {
    
    a_out1 <- regress_qtr_out()
    
    if(!exists("a_out1")) { 
      #print("No data for this quarter.")
      next
    }   
    fy_out1_list[[k]] <- a_out1
    k <- k+1    
  }
}
# Combine all dataframes from the list
fy_out1 <- do.call(rbind,c(fy_out1_list, make.row.names=FALSE))

###################################### YEARLY #########################################

m <- 1
for (i in 2010:(terminal_fy)) {
  a_out2 <- regress_yr_out()
  fy_out2_list[[m]] <- a_out2   
  m <- m+1
}

# Combine all dataframes from the list
fy_out2 <- do.call(rbind,c(fy_out2_list, make.row.names=FALSE))

post_process_qtr()
post_process_yr()



############################################################################
# 
# ## THIS IS NOT A GOOD PLOT ##
# ggplot(fy_out1, aes(x=as.factor(date),y=price))+theme_tufte(base_size=18,ticks=F)+
#   geom_bar(width=.25,fill="red",stat="identity")+theme(axis.title=element_blank())+
#   scale_y_continuous(breaks=seq(0,5,1))+geom_hline(yintercept=seq(0,5,1),col="white",lwd=1)+
#   geom_vline(xintercept=seq(1,42,4),col="lightgrey",lwd=.5,linetype="dashed")+
#   geom_hline(yintercept=seq(0,5,1),col="lightgrey",lwd=.5,linetype="dashed")+
#   theme(axis.text.x = element_text(angle = 90, hjust = 1))+
#   facet_wrap(~stock_name,nrow=3,strip.position="top")
# 
# ggplot(fy_out2, aes(x=as.factor(date),y=price))+theme_tufte(base_size=18,ticks=F)+
#   geom_bar(width=.25,fill="red",stat="identity")+theme(axis.title=element_blank())+
#   scale_y_continuous(breaks=seq(0,5,1))+geom_hline(yintercept=seq(0,5,1),col="white",lwd=1)+
#   geom_vline(xintercept=seq(1,42,4),col="lightgrey",lwd=.5,linetype="dashed")+
#   geom_hline(yintercept=seq(0,5,1),col="lightgrey",lwd=.5,linetype="dashed")+
#   theme(axis.text.x = element_text(angle = 90, hjust = 1))+
#   facet_wrap(~stock_name,nrow=3,strip.position="top")

## THIS SHIT WORKS BUT IT'S STILL SHIT
# for (j in 1:3){
#   varvar<-paste("z",j,sep="")
#   plot(fy_out1$price[fy_out1$var==varvar]~fy_out1$date[fy_out1$var==varvar], type="l", main=unique(fy_out1$stock_name[fy_out1$var==varvar]))
# }
# 
# for (j in 6:17){
#   varvar<-paste("z",j,sep="")
#   plot(fy_out1$price[fy_out1$var==varvar]~fy_out1$date[fy_out1$var==varvar], type="l", main=unique(fy_out1$stock_name[fy_out1$var==varvar]))
# }


############################################################################
############################################################################
############################################################################
# Build table for QCM cost  #

# 
# 
create_qcm_table <- function(fy_in){
  qcm<-subset(fy_out2, fy==fy_in)
  qcm$spec<-'none'
  qcm$spec<-ifelse(qcm$stock_name=='Plaice','am_plaice',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GB_Cod_East','cod',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GB_Cod_West','cod',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GOM_Cod','cod',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GB_Haddock_East','haddock',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GB_Haddock_West','haddock',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GOM_Haddock','haddock',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='Pollock','pollock',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='Redfish','redfish',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='White_Hake','wh_hake',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GB_Winter_Flounder','winter_fl',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GOM_Winter_Flounder','winter_fl',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='SNE/MA_Winter_Flounder','winter_fl',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='Witch_Flounder','witch',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='CC/GOM_Yellowtail_Flounder','yt_flounder',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='GB_Yellowtail_Flounder','yt_flounder',qcm$spec)
  qcm$spec<-ifelse(qcm$stock_name=='SNE/MA_Yellowtail_Flounder','yt_flounder',qcm$spec)

  qcm$stock<-'none'
  qcm$stock<-ifelse(qcm$stock_name=='Plaice','all',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GB_Cod_East','gb_east',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GB_Cod_West','gb_west',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GOM_Cod','gom',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GB_Haddock_East','gb_east',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GB_Haddock_West','gb_west',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GOM_Haddock','gom',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='Pollock','all',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='Redfish','all',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='White_Hake','all',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GB_Winter_Flounder','gb',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GOM_Winter_Flounder','gom',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='SNE/MA_Winter_Flounder','sne_ma',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='Witch_Flounder','all',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='CC/GOM_Yellowtail_Flounder','cc_gom',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='GB_Yellowtail_Flounder','gb',qcm$stock)
  qcm$stock<-ifelse(qcm$stock_name=='SNE/MA_Yellowtail_Flounder','sne',qcm$stock)

  qcm1<-qcm[,c(8,9,7,1)]
  qcm1[is.na(qcm1)]<-0
  qcm1<<-qcm1
}


#create_qcm_table(2018)
#create_qcm_table(2010)



#qcm1 
