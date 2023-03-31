
#library(ROracle)
library(RODBC)
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
require(DBI)

##  Things to do - ID non-market trades (permit banks, NEFS 4, etc)

################
## set directory
################

directory="/run/user/1878/gvfs/sftp:host=some.host.at.noaa.gov,user=your-user/net/"

################
################

uid1="your_user_id"
pwd1="your_pwd"
schema1="sole"
schema2="nova"
o<-odbcConnect(schema1, uid=uid1, pwd=pwd1,believeNRows=FALSE)



#### CORRECT THIS CODE WHEN THE DATABASE INCLUDES THE MOONCUSSER SECTOR  #####

get_out_data<-function(){
  out_1<-sqlQuery(o,"select b.year, b.transfer_number, b.from_sector_id, b.to_sector_id, a.stock, a.live_pounds, b.status, 
                   b.compensation, b.transfer_date       
                  from sector.transfers b, sector.transfer_stock a
                  where b.transfer_number = a.transfer_number and b.status = 'C'")
  out_1<-sqldf("select * from out_1 where from_sector_id is not null")
  out_1$YEAR<-ifelse(out_1$TRANSFER_NUMBER==6379, 2018, out_1$YEAR)
  out_1<-subset(out_1, !(TRANSFER_NUMBER %in% c(6380,6381)))
  out_1<<-out_1
  out_2<-sqlQuery(o,"select unique(a.sector) as sector_name, a.sector_id, a.year from sector.sector_mri a")
  makeup<-as.data.frame(t(c("Sustainable Harvest Sector 3",22,2010)))
  colnames(makeup)<-c("SECTOR_NAME","SECTOR_ID","YEAR")
  out_2<<-rbind(out_2, makeup)
}

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
  
  colnames(i)<-tolower(colnames(i))  # Make sftp://cdemarest@sole.some.place.at.noaa.gov/net/home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/column names lower case
  
  # Add columns for month, year, quarter
  i$date1 <- as.Date(i$transfer_date)
  i$month <- months.Date(i$date1)
  i$qtr <- substr(quarters.Date(i$date1),2,2)
  i$year <- year(i$date1)  
  terminal_fy<-ifelse(i$month >=1 & i$month <=4, unique(max(i$year))-1, unique(max(i$year)))
  terminal_fy<<-unique(terminal_fy)

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
  w$compensation <- ifelse((w$compensation < 3 & !(w$z4>0|w$z5>0|w$z12>0|w$z13>0) & w$total_lbs > 9), w$compensation * w$total_lbs, w$compensation) 
  
  # turn presumed marginal prices into total compensation
  #w <- subset(w, compensation > 5 & total_lbs > 50)  # eliminate small transactions with implicit prices less than $0.10
  w <- subset(w, avg_price == 0 | avg_price > 0.0045)  # eliminate prices less than half a penny
  w <- subset(w, avg_price < 5)  # eliminate nominal prices >$5/lbs 'cause that shit ain't real
  
  #w$z4<-0  # leaving haddock in...this and the next would eliminate gb haddock from the model, but after a lot of investigating I think it's better to leave it in
  #w$z5<-0
  
  #w$z18 <- ifelse(w$from_sector_name=="Maine Permit Bank"|w$from_sector_name=="NEFS 4",w$total_lbs,0)  # set z18 as the lease-only sector variable, soaking up the fact that these sectors exist to lease at below-market rates
  w_out <<- w
}


####################################RUN THE FUNCTIONS###################################

get_out_data()
process_inter_data()
process_final()

w_out<-unique(w_out)  ##eliminate duplicates, for whatever reason
#w_out$compensation<-ifelse(w_out$fy>=2019, jitter(w_out$compensation), w_out$compensation)

write.csv(w_out,file=paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/w_out.csv")) 


########################################################################################


##########################################################
## LEAST SQUARES REGRESSION WITH ROBUST STANDARD ERRORS ##
##########################################################

# ## this is just for testing
# i=2019
# j=1
# ##

regress_qtr_out<-function() {
  d<-subset(w_out, fy==i&q_fy==j)
  
  # if the subset has observations
  if(dim(d)[1] != 0) {
    # remove predictors with four or fewer data points to avoid singular fits
    d <- d[,colSums(d>0) >= 5]

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
      e <- subset(e, cooks_d < cooks_max)           # remove weird ones (super-high cooks distance), noting that this is less important w/ robust standard errors
      ee <- e %>% distinct(cooks_d, date1)          # Remove duplicates, or it gives an error in rlm()
      e <- merge(ee,e,by=c("cooks_d","date1"),all.x=TRUE)
      
      ## some data fell out at the cooks filter, so need to re-evaluate formula for rlm
      e <- e[,colSums(e>0) >= 5]
      pred.rlm<-grep("^[z]",names(e),value=TRUE)        # build regression formula from remaining predictors
      x.rlm <- paste(pred.rlm, collapse="+")
      ols.rlm <- paste("compensation ~ ",x.rlm,sep="")      # regression from remaining predictors (will need to add lease_only for inter trades)
      ols.rlm <- as.formula(ols.rlm)                        # set OLS as formula for rlm

      nrow<-nrow(e)
      add_vector<-round(runif(nrow,0,1),3)
      av_df<-as.data.frame(add_vector)
      e$compensation<-e$compensation+av_df
      colnames(e[,c(7)])<-c("compensation")

      o1.rlm <- rlm(ols.rlm, data=e, maxit=600)         # won't converge at 20 so 600'll do      
                                                        # IGNORE error: #,    setting="KS2014" ...if you get it.
      
      a <- coefficients(summary(o1.rlm))            #returns a matrix
      
      a<-as.data.frame(a)
      a$var<-rownames(a)
      a$q_fy<-j
      a$fy<-i
      return(a)
    }
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
  sn<-read.csv(paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/var_stock_name_link.csv"))
  
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
  
  #write.csv(fy_out1,file="results/out_post_process_qtr.csv")
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
  sn <- read.csv(paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/var_stock_name_link.csv"))
  
  years <- c(2010:terminal_fy)
  zees <- sprintf("z%d",seq(1:17))
  comb <- expand.grid(fy=years,var=zees)                      # 'var' is not a good name for a column
  comb <- merge(comb,sn)  # add stock names
  comb <- merge(comb,fy,by=c("fy","var"),all=TRUE) 
  
  #fy[fy==0]<-NA                                               # Differentiate between NA and 0 results?
  
  fy_out2<<-comb
  #write.csv(fy_out2,file="results/out_post_process_yr.csv", row.names=FALSE)
}




cooks_max <- 2                                            # set cooks distancec max value at 2, which is pretty damned high, but not too important
fy_out1_list <- list()                                    # list that will hold quarterly data frames
fy_out2_list <- list()
k=1

##################

for (i in 2010:terminal_fy) {
  max_qtr<-max(unique(w_out$q_fy[w_out$fy==i]))
  for (j in 1:max_qtr) {
    
    a_out1 <- regress_qtr_out()
    
    if(!exists("a_out1")) { 
      #print("No data for this quarter.")
      next
    }   
    fy_out1_list[[k]] <- a_out1
    k <- k+1    
  }
}
  

print(paste("The terminal_fy is",terminal_fy))

##########################
##########################
##########################


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

save(fy_out2, file=paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/inter_prices_FY.Rda"))

############################################################################

# add in FY2010 Q3 values for Q1 and Q2
f<-subset(fy_out1,fy==2010&q_fy==3)
f1<-subset(fy_out1, fy==2010&q_fy %in% c(1))
f2<-subset(fy_out1, fy==2010&q_fy %in% c(2))
f3<-f
f4<-subset(fy_out1,fy==2010&q_fy==4)

#f1[,c(5,6,7,8,10)]<-f[,c(5,6,7,8,10)]
#f2[,c(5,6,7,8,10)]<-f[,c(5,6,7,8,10)]
f1<-f
f1$q_fy<-1
f2<-f
f2$q_fy<-2

f5<-rbind(f1,f2,f3,f4)

fall<-subset(fy_out1, fy!=2010)

fy_out1<-rbind(f5, fall)

save(fy_out1, file=paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/inter_prices.Rda"))
write.csv(fy_out1,file=paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/inter_prices.csv", row.names=FALSE)

##########################################################################

## THIS IS NOT A GOOD PLOT ##
ggplot(fy_out1, aes(x=as.factor(date),y=price))+theme_tufte(base_size=18,ticks=F)+
  geom_bar(width=.5,fill="red",stat="identity")+theme(axis.title=element_blank())+
  scale_y_continuous(breaks=seq(0,5,1))+geom_hline(yintercept=seq(0,5,1),col="white",lwd=1)+
  geom_vline(xintercept=seq(1,42,4),col="lightgrey",lwd=.25,linetype="dashed")+
  geom_hline(yintercept=seq(0,5,1),col="lightgrey",lwd=.25,linetype="dashed")+
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size=10))+
  theme(axis.text.y = element_text(size=10))+
  facet_wrap(~stock_name,nrow=7,strip.position="top")

ggplot(fy_out2, aes(x=as.factor(date),y=price))+theme_tufte(base_size=18,ticks=F)+
  geom_bar(width=.5,fill="red",stat="identity")+theme(axis.title=element_blank())+
  scale_y_continuous(breaks=seq(0,5,1))+geom_hline(yintercept=seq(0,5,1),col="white",lwd=1)+
  geom_vline(xintercept=seq(1,42,4),col="lightgrey",lwd=.25,linetype="dashed")+
  geom_hline(yintercept=seq(0,5,1),col="lightgrey",lwd=.25,linetype="dashed")+
  theme(text = element_text(size=12), axis.text.x = element_text(angle = 90, hjust = 1))+
  facet_wrap(~stock_name,nrow=3,strip.position="top")

## THIS SHIT WORKS BUT IT'S STILL SHIT
for (j in 1:17){
  varvar<-paste("z",j,sep="")
  plot(fy_out1$price[fy_out1$var==varvar]~fy_out1$date[fy_out1$var==varvar], type="l", main=unique(fy_out1$stock_name[fy_out1$var==varvar]), axes=FALSE, family='serif', ylab="Price", xlab="")
  axis(1,at=fy_out1$date[fy_out1$var==varvar], lab=fy_out1$date[fy_out1$var==varvar], tick=F, las=1, family="serif", cex=0.9, las=2)
  axis(2,at=fy_out1$date[fy_out1$var==varvar], lab=fy_out1$date[fy_out1$var==varvar], tick=F, las=1, family="serif", cex=0.9, las=2)
}

for (j in 6:17){
  varvar<-paste("z",j,sep="")
  plot(fy_out1$price[fy_out1$var==varvar]~fy_out1$date[fy_out1$var==varvar], type="l", main=unique(fy_out1$stock_name[fy_out1$var==varvar]))
}


############################################################################
############################################################################
############################################################################
# Build table for QCM cost  #



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
  
  qcm2<-qcm[,c(3,8,9,7,1)]
  qcm2[is.na(qcm2)]<-0
  qcm2<<-qcm2
}


create_qcm_table(2019)



qcm1  #copy this directly to the SAS program

save(qcm2,file=paste0(directory,"/home7/cdemarest/R/groundfish/QCM/model/files/quota_prices_fy",fy_in,".rda"))




















##########################################################

##  BULLSHIT

#################



















a<-(read.sas7bdat(paste0(directory,"home7/cdemarest/SAS/Sectors/sector_trades/hedonic_data_only/hedonic_data.sas7bdat")))
a$z4<-0
a$z5<-0
a$lease_only<-ifelse(a$lease_only<1,0,1)
a$lease_only[is.na(a$lease_only)]<-0
a<-subset(a,nominal_value>0|total_pounds>0)
a$bq<-a$total_pounds*a$basket
a$sq<-a$total_pounds*a$swap
a$lq<-a$total_pounds*a$lease_only

aaa<-by(a$nominal_value, a$fish_year,sum)
aaa<-as.data.frame(aaa)

#if stock = 'CC/GOM_Yellowtail_Flounder  ' then z1 = live_pounds;
#if stock = 'GB_Cod_East                 ' then z2 = live_pounds;
#if stock = 'GB_Cod_West                 ' then z3 = live_pounds;
#if stock = 'GB_Haddock_East             ' then z4 = live_pounds;
#if stock = 'GB_Haddock_West             ' then z5 = live_pounds;
#if stock = 'GB_Winter_Flounder          ' then z6 = live_pounds;
#if stock = 'GB_Yellowtail_Flounder      ' then z7 = live_pounds;
#if stock = 'GOM_Cod                     ' then z8 = live_pounds;
#if stock = 'GOM_Haddock                 ' then z9 = live_pounds;
#if stock = 'GOM_Winter_Flounder         ' then z10 = live_pounds;
#if stock = 'Plaice                      ' then z11 = live_pounds;
#if stock = 'Pollock                     ' then z12 = live_pounds;
#if stock = 'Redfish                     ' then z13 = live_pounds;
#if stock = 'SNE/MA_Yellowtail_Flounder  ' then z14 = live_pounds;
#if stock = 'White_Hake                  ' then z15 = live_pounds;
#if stock = 'Witch_Flounder              ' then z16 = live_pounds;
#if stock = 'SNE/MA_Winter_Flounder      ' then z17 = live_pounds;

#LIST OF ALL OLS OUTPUTS
require(nlme)
res<-lmList(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq|fish_year, data=a, pool=FALSE)
frame<-as.data.frame(coef(summary(res[[7]])))

#EXPLORING YEARS HERE)) %>% filter(n > 1)
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
  e <- subset(e, cooks_d < cooks_max)          (dim(d)[1] != 0){
    # remove predictors with four or fewer data points to avoid singular fits
    d <- d[,colSums(d>0) >= 5]
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
      e <- subset(e, cooks_d < cooks_max)           # remove weird ones (super-high cooks distance), noting that this is less important w/ robust standard errors
      ee <- e %>% distinct(cooks_d, date1)          # Remove duplicates, or it gives an error in rlm()
      e <- merge(ee,e,by=c("cooks_d","date1"),all.x=TRUE)
      
      # identical q and p trades in 2019 are resulting in singular fits....gotta fix it somehow
      nrow<-nrow(e)
      add_vector<-round(runif(nrow,0,1),2)
      av_df<-as.data.frame(add_vector)
      e$compensation<-e$compensation+av_df
      colnames(e[,c(7)])<-c("compensation")
      
      o1.rlm <- rlm(ols, data=e, maxit=600)         #won't converge at 20 so 200'll do      IGNORE=  "#,    setting="KS2014""
      
      a <- coefficients(summary(o1.rlm))            #returns a matrix
      
      a<-as.data.frame(a)
      a$var<-rownames(a)
      a$q_fy<-j
      a$fy<-i
      return(a)
    }
    # remove weird ones (super-high cooks distance), noting that this is less important w/ robust standard errors
    ee <- e %>% distinct(cooks_d, date1)          # Remove duplicates, or it gives an error in rlm()
    e <- merge(ee,e,by=c("cooks_d","date1"),all.x=TRUE)
    
    # identical q and p trades in 2019 are resulting in singular fits....gotta fix it somehow
    nrow<-nrow(e)
    add_vector<-round(runif(nrow,0,1),2)
    av_df<-as.data.frame(add_vector)
    e$compensation<-e$compensation+av_df
    colnames(e[,c(7)])<-c("compensation")
    
    o1.rlm <- rlm(ols, data=e, maxit=600)         #won't converge at 20 so 200'll do      IGNORE=  "#,    setting="KS2014""
    
    a <- coefficients(summary(o1.rlm))            #returns a matrix
    
    a<-as.data.frame(a)
    a$var<-rownames(a)
    a$q_fy<-j
    a$fy<-i
    return(a)
  }
}
}

##################

for (i in 2010:terminal_fy) {
  max_qtr<-max(unique(w_out$q_fy[w_out$fy==i]))
  for (j in 1:max_qtr) {
    
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

save(fy_out2, file=paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/inter_prices_FY.Rda"))

############################################################################

# add in FY2010 Q3 values for Q1 and Q2
f<-subset(fy_out1,fy==2010&q_fy==3)
f1<-subset(fy_out1, fy==2010&q_fy %in% c(1))
f2<-subset(fy_out1, fy==2010&q_fy %in% c(2))
f3<-f
f4<-subset(fy_out1,fy==2010&q_fy==4)

#f1[,c(5,6,7,8,10)]<-f[,c(5,6,7,8,10)]
#f2[,c(5,6,7,8,10)]<-f[,c(5,6,7,8,10)]
f1<-f
f1$q_fy<-1
f2<-f
f2$q_fy<-2

f5<-rbind(f1,f2,f3,f4)

fall<-subset(fy_out1, fy!=2010)

fy_out1<-rbind(f5, fall)

save(fy_out1, file=paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/inter_prices.Rda"))
write.csv(fy_out1,file=paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/inter_prices.csv"), row.names=FALSE)

##########################################################################

## THIS IS NOT A GOOD PLOT ##
ggplot(fy_out1, aes(x=as.factor(date),y=price))+theme_tufte(base_size=18,ticks=F)+
  geom_bar(width=.5,fill="red",stat="identity")+theme(axis.title=element_blank())+
  scale_y_continuous(breaks=seq(0,5,1))+geom_hline(yintercept=seq(0,5,1),col="white",lwd=1)+
  geom_vline(xintercept=seq(1,42,4),col="lightgrey",lwd=.25,linetype="dashed")+
  geom_hline(yintercept=seq(0,5,1),col="lightgrey",lwd=.25,linetype="dashed")+
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size=10))+
  theme(axis.text.y = element_text(size=10))+
  facet_wrap(~stock_name,nrow=7,strip.position="top")

ggplot(fy_out2, aes(x=as.factor(date),y=price))+theme_tufte(base_size=18,ticks=F)+
  geom_bar(width=.5,fill="red",stat="identity")+theme(axis.title=element_blank())+
  scale_y_continuous(breaks=seq(0,5,1))+geom_hline(yintercept=seq(0,5,1),col="white",lwd=1)+
  geom_vline(xintercept=seq(1,42,4),col="lightgrey",lwd=.25,linetype="dashed")+
  geom_hline(yintercept=seq(0,5,1),col="lightgrey",lwd=.25,linetype="dashed")+
  theme(text = element_text(size=12), axis.text.x = element_text(angle = 90, hjust = 1))+
  facet_wrap(~stock_name,nrow=3,strip.position="top")

## THIS SHIT WORKS BUT IT'S STILL SHIT
for (j in 1:17){
  varvar<-paste("z",j,sep="")
  fy_out1[is.na(fy_out1)]<-0
  fy_out1<-subset(fy_out1, date <= '2020 Q2')
  plot(fy_out1$price[fy_out1$var==varvar]~fy_out1$date[fy_out1$var==varvar], type="l", main=unique(fy_out1$stock_name[fy_out1$var==varvar]), axes=FALSE, family='serif', ylab="Price", xlab="")
  axis(1,at=fy_out1$date[fy_out1$var==varvar], lab=fy_out1$date[fy_out1$var==varvar], tick=F, las=1, family="serif", cex=0.9, las=2)
  axis(2,at=seq(0,max(fy_out1$price[fy_out1$var==varvar]),0.25), lab=paste0("$",seq(0,max(fy_out1$price[fy_out1$var==varvar]),0.25)), tick=F, las=1, family="serif", cex=0.9, las=2)
}

exclude_stocks<-c('GB_Haddock_East','GB_Haddock_West','Pollock','Redfish','GOM_Winter_Flounder')
fy_out1<-subset(fy_out1, date <= '2020 Q2' & !stock_name %in% exclude_stocks)
ggplot(data=fy_out1, aes(x=date, y=price))+
  #geom_vline(xintercept=10, color = "red") +
  geom_line(color="#084594")+
  labs(title="", y="")+
  theme(text=element_text(family="serif"),
        panel.background = element_rect(fill = 'white'),
        axis.text.x = element_text(angle = 90, hjust=1))+
  facet_wrap(~stock_name,  nrow=4)   #scales="free_y",

  for (j in 6:17){
  varvar<-paste("z",j,sep="")
  plot(fy_out1$price[fy_out1$var==varvar]~fy_out1$date[fy_out1$var==varvar], type="l", main=unique(fy_out1$stock_name[fy_out1$var==varvar]))
}


############################################################################
############################################################################
############################################################################
# Build table for QCM cost  #



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
  qcm$spec<-ifelse(qcm$ stock_name=='GB_Yellowtail_Flounder','yt_flounder',qcm$spec)
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
  
  qcm2<-qcm[,c(3,8,9,7,1)]
  qcm2[is.na(qcm2)]<-0
  qcm2<<-qcm2
}


create_qcm_table(2020)

qcm1  #copy this directly to the SAS program
fy_in=2020
save(qcm2,file=paste0(directory,"/home7/cdemarest/R/groundfish/QCM/model/files/quota_prices_fy",fy_in,".rda"))




















##########################################################

##  BULLSHIT

#################



















a<-(read.sas7bdat(paste0(directory,"home7/cdemarest/SAS/Sectors/sector_trades/hedonic_data_only/hedonic_data.sas7bdat")))
a$z4<-0
a$z5<-0
a$lease_only<-ifelse(a$lease_only<1,0,1)
a$lease_only[is.na(a$lease_only)]<-0
a<-subset(a,nominal_value>0|total_pounds>0)
a$bq<-a$total_pounds*a$basket
a$sq<-a$total_pounds*a$swap
a$lq<-a$total_pounds*a$lease_only

aaa<-by(a$nominal_value, a$fish_year,sum)
aaa<-as.data.frame(aaa)

#if stock = 'CC/GOM_Yellowtail_Flounder  ' then z1 = live_pounds;
#if stock = 'GB_Cod_East                 ' then z2 = live_pounds;
#if stock = 'GB_Cod_West                 ' then z3 = live_pounds;
#if stock = 'GB_Haddock_East             ' then z4 = live_pounds;
#if stock = 'GB_Haddock_West             ' then z5 = live_pounds;
#if stock = 'GB_Winter_Flounder          ' then z6 = live_pounds;
#if stock = 'GB_Yellowtail_Flounder      ' then z7 = live_pounds;
#if stock = 'GOM_Cod                     ' then z8 = live_pounds;
#if stock = 'GOM_Haddock                 ' then z9 = live_pounds;
#if stock = 'GOM_Winter_Flounder         ' then z10 = live_pounds;
#if stock = 'Plaice                      ' then z11 = live_pounds;
#if stock = 'Pollock                     ' then z12 = live_pounds;
#if stock = 'Redfish                     ' then z13 = live_pounds;
#if stock = 'SNE/MA_Yellowtail_Flounder  ' then z14 = live_pounds;
#if stock = 'White_Hake                  ' then z15 = live_pounds;
#if stock = 'Witch_Flounder              ' then z16 = live_pounds;
#if stock = 'SNE/MA_Winter_Flounder      ' then z17 = live_pounds;

#LIST OF ALL OLS OUTPUTS
require(nlme)
res<-lmList(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq|fish_year, data=a, pool=FALSE)
frame<-as.data.frame(coef(summary(res[[7]])))

#EXPLORING YEARS HERE
a_16<-a[a$fish_year==2016,]
ols16<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_16)
plot(ols16, las=1)


a_13<-a[a$fish_year==2013,]
a_13$cr_nom_val<-a_13$nominal_value^(1/3)
ols13<-lm(cr_nom_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13)
summary(ols13)
plot(ols13, las=1)

ols13c<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13)
summary(ols13c)
plot(ols13c, las=1)

a_13$ln_val<-log(a_13$nominal_value+1)
ols13d<-lm(ln_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13)
summary(ols13d)
coef<-exp(coefficients(ols13d))
View(coef)

plot(ols13d, las=1)

#compare single stock trade means to single stock modeled estimates

a_13a<-a_13[a_13$single==1,]
ols13a<-lm(cr_nom_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13a)
plot(ols13a, las=1)
summary(ols13a)
coef<-coefficients(ols13a)*1000
View(coef)

ols13b<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13a)
plot(ols13b, las=1)
summary(ols13b)
coef<-coefficients(ols13b)
View(coef)

ols13d<-lm(ln_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13a)
plot(ols13d, las=1)
summary(ols13d)
coef<-exp(coefficients(ols13d))*1000
View(coef)

ols13d<-lm(ln_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13a)
plot(ols13d, las=1)
summary(ols13d)
coef<-exp(coefficients(ols13d))*1000
View(coef)


gam13a<-gam(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13a, family = gaussian)
summary(gam13a)

glm13b<-glm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13a, family = poisson)
summary(glm13b)

require(mgcv)
a_13a$nominal_value<-ifelse(a_13a$nominal_value==0,1,a_13a$nominal_value)
a_13a$ln_nv<-log(a_13a$nominal_value)
gam13b<-gam(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13a, family = poisson(link="log"))
ols13b<-lm(ln_nv~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13a)
summary(gam13b)
summary(ols13b)
plot(ols13b, las=1)

b<-(read.sas7bdat("/net/home7/cdemarest/SAS/Sectors/sector_trades/hedonic_data_only/trades_with_basket_swap.sas7bdat"))
b[is.na(b)]<-0
b_13a<-sqldf("select transfer_number, stock, (compensation/live_pounds) as price from b 

a_16<-a[a$fish_year==2016,]
ols16<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_16)
plot(ols16, las=1)


a_13<-a[a$fish_year==2013,]
a_13$cr_nom_val<-a_13$nominal_value^(1/3)
ols13<-lm(cr_nom_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13)
summary(ols13)
plot(ols13, las=1)

ols13c<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13)
summary(ols13c)
plot(ols13c, las=1)

a_13$ln_val<-log(a_13$nominal_value+1)
ols13d<-lm(ln_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13)
summary(ols13d)
coef<-exp(coefficients(ols13d))
View(coef)

plot(ols13d, las=1)

#compare single stock trade means to single stock modeled estimates

a_13a<-a_13[a_13$single==1,]
ols13a<-lm(cr_nom_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13a)
plot(ols13a, las=1)
summary(ols13a)
coef<-coefficients(ols13a)*1000
View(coef)

ols13b<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13a)
plot(ols13b, las=1)
summary(ols13b)
coef<-coefficients(ols13b)
View(coef)

ols13d<-lm(ln_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13a)
plot(ols13d, las=1)
summary(ols13d)
coef<-exp(coefficients(ols13d))*1000
View(coef)

ols13d<-lm(ln_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+bq+sq+lq, data=a_13a)
plot(ols13d, las=1)
summary(ols13d)
coef<-exp(coefficients(ols13d))*1000
View(coef)


gam13a<-gam(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13a, family = gaussian)
summary(gam13a)

glm13b<-glm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13a, family = poisson)
summary(glm13b)

require(mgcv)
a_13a$nominal_value<-ifelse(a_13a$nominal_value==0,1,a_13a$nominal_value)
a_13a$ln_nv<-log(a_13a$nominal_value)
gam13b<-gam(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13a, family = poisson(link="log"))
ols13b<-lm(ln_nv~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_13a)
summary(gam13b)
summary(ols13b)
plot(ols13b, las=1)

b<-(read.sas7bdat("/net/home7/cdemarest/SAS/Sectors/sector_trades/hedonic_data_only/trades_with_basket_swap.sas7bdat"))
b[is.na(b)]<-0
b_13a<-sqldf("select transfer_number, stock, (compensation/live_pounds) as price from b 
where valid_value = 1 and basket = 0 and swap = 0 and lease_only = 0 and fish_year = 2013")
b_13a1<-sqldf ("select stock, avg(price) as avg_price from b_13a group by stock")


#FY15

a_15<-a[a$fish_year==2015,]
a_15$cr_nom_val<-a_15$nominal_value^(1/3)

ols15a<-lm(cr_nom_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_15)
summary(ols15a)
plot(ols15a, las=1)

ols15b<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_15)
summary(ols15b)
plot(ols15b, las=1)

a_15a<-a_15[a_15$single==1,]
dollars<-a_15a$nominal_value[a_15a$z8>0]
pounds<-a_15a$z8[a_15a$z8>0]
lm.cod<-lm(dollars~pounds)
plot(dollars~pounds)
abline(lm.cod, col="red")
summary(lm.cod)

ols15c<-lm(cr_nom_val~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_15a)
summary(ols15c)
plot(ols15c, las=1)

ols15d<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+lq, data=a_15a)
summary(ols15d)
plot(ols15d, las=1)

#a_15a1<-unique(a_15a)
a_15a2<-sqldf("select * from a_15a where swap = 0")







a_15a2$zz1<-jitter(a_15a2$z1, .01)
a_15a2$zz2<-jitter(a_15a2$z2, .01)
a_15a2$zz3<-jitter(a_15a2$z3, .01)
a_15a2$zz4<-jitter(a_15a2$z4, .01)
a_15a2$zz5<-jitter(a_15a2$z5, .01)
a_15a2$zz6<-jitter(a_15a2$z6, .01)
a_15a2$zz7<-jitter(a_15a2$z7, .01)
a_15a2$zz8<-jitter(a_15a2$z8, .01)
a_15a2$zz9<-jitter(a_15a2$z9, .01)
a_15a2$zz10<-jitter(a_15a2$z10, .01)
a_15a2$zz11<-jitter(a_15a2$z11, .01)
a_15a2$zz12<-jitter(a_15a2$z12, .01)
a_15a2$zz13<-jitter(a_15a2$z13, .01)
a_15a2$zz14<-jitter(a_15a2$z14, .01)
a_15a2$zz15<-jitter(a_15a2$z15, .01)
a_15a2$zz16<-jitter(a_15a2$z16, .01)
a_15a2$zz17<-jitter(a_15a2$z17, .01)

rols15d<-rlm((nominal_value/10000)~zz1+zz2+zz3+zz4+zz5+zz6+zz7+zz8+zz9+zz10+zz11+zz12+zz13+zz14+zz15+zz16+zz17+lq, data=a_15a2, maxit=20)
summary(rols15d)
plot(rols15d)

rols15da<-rlm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17, data=a_15a2)
summary(rols15da)

rols15da<-rlm(nominal_value~z8+z2+z3+z1+z6+z7, data=a_15a2)
summary(rols15da)

#require(robustbase)
#rols15d<-lmrob(nominal_value~zz1+zz2+zz3+zz4+zz5+zz6+zz7+zz8+zz9+zz10+zz11+zz12+zz13+zz14+zz15+zz16+zz17+lq, data=a_15a2)

#a_15a2$z8j<-rnorm(a_15a2$z8)
#a_15a2$z8ji<-jitter(a_15a2$z8, .01)

#a_13[c(301),]

#d1<-cooks.distance(ols13)
#r1<-stdres(ols13)
#a1<-cbind(a_13)



#CANT DO THIS WITH BQ/SQ/LQ BECAUSE INFLATED ZEROS, MAY NEED TO INTERACT EACH WITH EACH OR GLM OR SOMETHING ELSE
#WHAT IF I CUBE ROOTED THE WHOLE DAMN THING

#http://stats.idre.ucla.edu/r/dae/robust-regression/
#http://www2.warwick.ac.uk/fac/soc/economics/staff/vetroeger/teaching/po906_week8910.pdf


#if stock = 'CC/GOM_Yellowtail_Flounder  ' then z1 = live_pounds;
#if stock = 'GB_Cod_East                 ' then z2 = live_pounds;
#if stock = 'GB_Cod_West                 ' then z3 = live_pounds;
#if stock = 'GB_Haddock_East             ' then z4 = live_pounds;
#if stock = 'GB_Haddock_West             ' then z5 = live_pounds;
#if stock = 'GB_Winter_Flounder          ' then z6 = live_pounds;
#if stock = 'GB_Yellowtail_Flounder      ' then z7 = live_pounds;
#if stock = 'GOM_Cod                     ' then z8 = live_pounds;
#if stock = 'GOM_Haddock                 ' then z9 = live_pounds;
#if stock = 'GOM_Winter_Flounder         ' then z10 = live_pounds;
#if stock = 'Plaice                      ' then z11 = live_pounds;
#if stock = 'Pollock                     ' then z12 = live_pounds;
#if stock = 'Redfish                     ' then z13 = live_pounds;
#if stock = 'SNE/MA_Yellowtail_Flounder  ' then z14 = live_pounds;
#if stock = 'White_Hake                  ' then z15 = live_pounds;
#if stock = 'Witch_Flounder              ' then z16 = live_pounds;
#if stock = 'SNE/MA_Winter_Flounder      ' then z17 = live_pounds;




#res<-lm(nominal_value~z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+basket+swap+lease_only, data=a)
#http://stackoverflow.com/questions/28029922/linear-regression-and-storing-results-in-data-frame
#for (i in 2010:2011) {
#}

#for (i in 2010:2016) {
#  ai<-a[a$fish_year==i,]
#  lmi<-lm(nominal_value~(z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+basket+swap+lease_only),data=ai)
#  return(summary(lmi)$coef)
#  lmii<-coefficients(lmi)
#  assign(paste("coef",i,sep="_"), (lmii))
#}
#intra<-as.data.frame(rbind(lm_2010,lm_2011,lm_2012,lm_2013,lm_2014,lm_2015,lm_2016))
#summary(lm_2010)
#lm_2010

#lm_i<-lm(nominal_value~(z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17),data=ai)
#assign(paste("lm",[i],sep="_"), lm_i(files[i],header=NULL))

#t_lm2<-lm(nominal_value~(z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17))
#summary(t_lm2)

#summary(lmi)
#lmiii<-as.data.frame(summary(lmi))
#lmii



#attach(a)
#t_lm<-lm(log(nominal_value)~(z1+z2+z3+z4+z5+z6+z7+z8+z9+z10+z11+z12+z13+z14+z15+z16+z17+basket+swap+lease_only))
#summary(t_lm)
#detach(a)

#b<-(read.sas7bdat("/net/home7/cdemarest/SAS/Sectors/sector_trades/hedonic_data_only/trades_with_basket_swap.sas7bdat"))
#c<-(read.sas7bdat("/net/home7/cdemarest/SAS/Sectors/sector_trades/hedonic_data_only/sixteen.sas7bdat"))



#################################
#################################
###############################
### Deleted this chunk of commented code on 9/17/2020

##
#e10<-e[,c("cooks_d","compensation")]
#e11<-e10[duplicated(e10)|duplicated(e10, fromLast=TRUE),]
#if (length(e11) > 0) {
#  e12<-merge(e11,e,by=c("cooks_d","compensation"),all.x = TRUE)
#  e12<-distinct(e12)
#  nrow<-nrow(e12)
#  add_vector<-round(runif(nrow,0,1),2)
#  av_df<-as.data.frame(add_vector)
#  e12$compensation<-e12$compensation+av_df
#  
#  e13<-anti_join(e,e12,by=c("cooks_d","to_sector_name","from_sector_name","date1"), rownames=FALSE)

#  e14<-
#library(data.table)
#e12<-as.data.frame(as.data.table(e12))
#e13<-as.data.frame(as.data.table(e13))
# colnames(e12[,c(2)])<-c("compensation")
#  e<-bind_rows(e12,e13)
# e<-e13
# }
