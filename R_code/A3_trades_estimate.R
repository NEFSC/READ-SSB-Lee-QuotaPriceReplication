# This is Min-Yang's modification of Chad Demarests's code to estimate the quarterly average price (dollars per pound) of quota.
# This needs an input Rdataset. It cleans/recode, estimate and test various models
# This code gets exports the estimated coefficients to a table.


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
    # Changed from > to != to account for swaps.
    # this may drop out the "compensation" column if there are few cash trades (and a couple swaps).
    
    colpick<-colSums(d!=0) >= 5
    colpick[c("compensation")]<-TRUE
    d <- d[,colpick]
    
    # if any predictors are left   
    if(length(grep("^[z]",names(d),value=TRUE)) != 0) {
      pred<-grep("^[z]",names(d),value=TRUE)        # build regression formula from remaining predictors
      # print(paste("pred is ",pred))
      x <- paste(pred, collapse="+")
      
      
      # reconstruct the interaction variable using only the retained z columns. But check for the lease_only variable 
      lease_only_exists<-length(grep("lease_only",colnames(d)))
      
      # Use absolute values of the pounds, just in case there is quota transferred both ways. There shouldn't be, but just in case.
      if(lease_only_exists>0){
      d$inter2<-rowSums(abs(d[,c(pred)]))*d$lease_only
      
      # Check that there's enough lease-only >0 and add it to the RHS equation
      include<-sum(d['inter2']>0)
        if(include>=5){
          x<-paste(x,"+inter2")
        }
     }
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
      
      colpick<-colSums(e!=0) >= 5
      colpick[c("compensation")]<-TRUE
      e <- e[,colpick]
      
      pred.rlm<-grep("^[z]",names(e),value=TRUE)        # build regression formula from remaining predictors

      x.rlm <- paste(pred.rlm, collapse="+")
  
      # reconstruct the interaction variable using only the retained z columns. But check for the lease_only variable 
      lease_only_exists<-length(grep("lease_only",colnames(e)))
      
      #I used abs() here just in case any lease-only transactions are swaps.
      if(lease_only_exists>0){
        e$inter2<-rowSums(abs(e[,c(pred.rlm)]))*e$lease_only
        
      # Check that there's enough lease-only >0 and add it to the RHS equation
          include<-sum(e['inter2']!=0)
          if(include>=5){
            x.rlm<-paste(x.rlm,"+inter2")
          }
        }
        
    
      
      
      ols.rlm <- paste("compensation ~ ",x.rlm,sep="")      # regression from remaining predictors (will need to add lease_only for inter trades)
      ols.rlm <- as.formula(ols.rlm)                        # set OLS as formula for rlm
      
      ols.rlm2 <- paste("compensation2 ~ ",x.rlm,sep="")      # regression from remaining predictors (will need to add lease_only for inter trades)
      ols.rlm2 <- as.formula(ols.rlm2)                        # set OLS as formula for rlm
      
      
      nrow<-nrow(e)
      add_vector<-round(runif(nrow,0,1),3)
      e$compensation2<-e$compensation+add_vector
      #colnames(e[,c(7)])<-c("compensation")
      
      
      #Estimate again by OLS, tack on White standard errors
      o2.lm <- lm(ols.rlm, data=e)         
      a <- coefficients(summary(o2.lm))            #returns a matrix
      r2<-summary(o2.lm)$r.squared
      n<-nrow(e)
      a<-cbind(a,r2,n)
      
      vce<-vcovHC(o2.lm, type = "HC0")
      eye<-as.matrix(sqrt(diag(vce)))
      colnames(eye)<-"WhiteSE"
      a<-cbind(a,eye)
      
      # An M estimator 
      o1.rlm <- rlm(ols.rlm2, data=e, maxit=600)         # won't converge at 20 so 600'll do      
      # IGNORE error: #,    setting="KS2014" ...if you get it.
      
      b <- coefficients(summary(o1.rlm))            #returns a matrix
      rlm.names<-colnames(b)
      rlm.names<-paste0("rlm",rlm.names)
      colnames(b)<-rlm.names
      rlm_r2<-summary(o2.lm)$r.squared
      rlm_n<-nrow(e)
      b<-cbind(b,rlm_r2,rlm_n)
      
      
      
      #stick the two sets of results together
      a<-cbind(a,b)
      a<-as.data.frame(a)
      a$var<-rownames(a)
      a$q_fy<-j
      a$fy<-i
      coefs_and_data<-list(a,e)
      return(coefs_and_data)
    }
  } 
} 

regress_yr_out<-function(){
  
  d <- subset(w_out, fy==i)  
  
  colpick<-colSums(d!=0) >= 5
  colpick[c("compensation")]<-TRUE
  d <- d[,colpick]     # remove predictors with four or fewer data points to avoid singular fits
  
  pred<-grep("^[z]",names(d),value=TRUE)        # build regression formula from remaining predictors
  # print(paste("pred is ",pred))
  x <- paste(pred, collapse="+")
  
  
  # reconstruct the interaction variable using only the retained z columns. But check for the lease_only variable 
  lease_only_exists<-length(grep("lease_only",colnames(d)))
  
  if(lease_only_exists>0){
    d$inter2<-rowSums(abs(d[,c(pred)]))*d$lease_only
    
    # Check that there's enough lease-only >0 and add it to the RHS equation
    include<-sum(d['inter2']!=0)
    if(include>=5){
      x<-paste(x,"+inter2")
    }
  }
  
  

  
  

  
  
  
  
  
  ols <- paste("compensation ~ ",x,sep="")           # regression from remaining predictors (will need to add lease_only for inter trades)
  ols <- as.formula(ols)                             # set OLS as formula for rlm
  o1.lm <- lm(ols, data=d)                           # compute OLS to idenify severe and influential outliers
  o1 <- as.data.frame(cooks.distance(o1.lm))         # get cooks distance to id influential weird ones
  e <- cbind(o1,d)
  names(e)[1] <- "cooks_d"
  e <- subset(e, cooks_d<cooks_max)    # remove weird ones (super-high cooks distance), noting that this is less important w/ robust standard errors
 
  
  
  
  #Estimate again by OLS, tack on White standard errors
  o2.lm <- lm(ols, data=e)         
  a <- coefficients(summary(o2.lm))            #returns a matrix
  r2<-summary(o2.lm)$r.squared
  n<-nrow(e)
  a<-cbind(a,r2,n)
  
  vce<-vcovHC(o2.lm, type = "HC0")
  eye<-as.matrix(sqrt(diag(vce)))
  colnames(eye)<-"WhiteSE"
  a<-cbind(a,eye)
  
  
  
  
  # An M estimator 
  
   o1.rlm <- rlm(ols, data=e, maxit=200)              # Won't converge at 20 so 200'll do      IGNORE= "#,    setting="KS2014""
  o1.rlm <<- o1.rlm
  b <- coefficients(summary(o1.rlm))            #returns a matrix
  rlm.names<-colnames(b)
  rlm.names<-paste0("rlm",rlm.names)
  colnames(b)<-rlm.names
  rlm_r2<-summary(o2.lm)$r.squared
  rlm_n<-nrow(e)
  b<-cbind(b,rlm_r2,rlm_n)

  
  #stick the two sets of results together
  a<-cbind(a,b)
  a<-as.data.frame(a)
  a$var<-rownames(a)
  a$q_fy<-j
  a$fy<-i
  coefs_and_dataY<-list(a,e)
  return(coefs_and_dataY)
  

}


post_process_qtr<-function(){
  fy <- fy_out1
  #fy <- sqldf("select * from fy where var <> '(Intercept)'")  # filtering out low t-value (not sig) prices
  names(fy)[names(fy) == 't value'] <- 't_value'  # Rename column 't value'
  names(fy)[names(fy) == 'rlmt value'] <- 'rlmt_value'  # Rename column 't value'
  names(fy)[names(fy) == 'Pr(>|t|)'] <- 'pval'  # Rename column 't value'
  names(fy)[names(fy) == 'Std. Error'] <- 'std_error'  # Rename column 't value'
  names(fy)[names(fy) == 'rlmStd. Error'] <- 'rlmstd_error'  # Rename column 't value'
  
  #lease_only <<- sqldf("select * from fy where var='z18'")  # set aside lease-only values for inspection
  #fy<-sqldf("select * from fy where var <> 'z18'")  # drop lease-only values for reporting purposes
  
  # fy$price <- ifelse((abs(fy$t_value)>1.5 ),fy$Value,0)                  
  # fy$price <- ifelse(fy$t_value<0,0,fy$price)                                  # negative prices to zero...because....don't ask
  # fy$price <- ifelse((fy$var=="z4"|fy$var=="z5")&fy$Value>1,0,fy$price)        # jeez, haddock fucks with everything...
  # fy$price <- ifelse((fy$var=="z12"|fy$var=="z2")&fy$Value>2.85,0,fy$price)    # bizzaro pollock and a GB cod east that's apparently in error
  # fy$price <- ifelse(fy$var=="z13"&fy$Value>1&fy$fy<2017,0,fy$price)           # bizzaro redfish
  # 
  # fy$price<-ifelse(fy$Value>6,0,fy$price)
  
  # TODO : Part of the following can be taken out into a separate function
  
  #############CREATE TIMEVAR DATASET WITH YEARS AND QUARTERS AND STOCK NAMES##################
  sn_link<-file.path(data_main,"var_stock_name_link.csv")
  sn<-read.csv(sn_link)
  
  #sn<-read.csv(paste0(directory,"home7/cdemarest/R/groundfish/quota_trades/ace_lease_price_model/var_stock_name_link.csv"))
  
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
  #fy<-sqldf("select * from fy where var <> '(Intercept)'")                    # filtering out low t-value (not sig) prices
  names(fy)[names(fy) == 't value'] <- 't_value'                              # Rename column 't value'
  
  #LEASE-ONLY
  lease_only <<- sqldf("select * from fy where var='inter2'")                    # set aside lease-only values for inspection
  fy <- sqldf("select * from fy where var <> 'inter2'")                          # drop lease-only values for reporting purposes
  
  #PRICE
  # fy$price <- 99
  # fy$price <- ifelse((abs(fy$t_value)>1.5 ),fy$Value,0)                  
  # fy$price <- ifelse(fy$t_value<0,0,fy$price)                                  # negative prices to zeros (hi Anna)
  # fy$price <- ifelse((fy$var=="z4"|fy$var=="z5")&fy$Value>1,0,fy$price)        # jeez, haddock fucks with everything...
  # fy$price <- ifelse((fy$var=="z12"|fy$var=="z13"|fy$var=="z2")&fy$Value>2.85,0,fy$price)  # bizzaro pollock
  # 
  # fy$price <- ifelse(fy$Value>6,0,fy$price)
  
  #############CREATE TIMEVAR DATASET WITH YEARS AND QUARTERS AND STOCK NAMES##################
  sn_link<-file.path(data_main,"var_stock_name_link.csv")
  sn<-read.csv(sn_link)
  
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

# Should put in a line here that loads in the data 
#temporarily bin the early trades of 2010 into Q3
w_out$q_fy[w_out$q_fy<=2 & w_out$fy==2010]<-3


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

coefs<-list()
estimation_dataset<-list()

for (k in 1:length(fy_out1_list)) {
coefs[[k]]<-fy_out1_list[[k]][[1]]
estimation_dataset[[k]]<-fy_out1_list[[k]][[2]]
}



print(paste("The terminal_fy is",terminal_fy))

##########################
##########################
##########################


# Combine all dataframes from the list
fy_out1 <- do.call(rbind,c(coefs, make.row.names=FALSE))

#estimation_dataset <- do.call(rbind,c(estimation_dataset, make.row.names=FALSE))
# Some of the dataframes in the estimation dataset list have different columns. So we use dplyr's bind_rows instead of do.call(rbind)
estimation_dataset <- dplyr::bind_rows(estimation_dataset)


###################################### YEARLY #########################################


coefsY<-list()
estimation_datasetY<-list()



m <- 1
for (i in 2010:(terminal_fy)) {
  a_out2 <- regress_yr_out()
  fy_out2_list[[m]] <- a_out2   
  m <- m+1
}


for (k in 1:length(fy_out2_list)) {
  coefsY[[k]]<-fy_out2_list[[k]][[1]]
  estimation_datasetY[[k]]<-fy_out2_list[[k]][[2]]
}



# Combine all dataframes from the list
fy_out2 <- do.call(rbind,c(coefs, make.row.names=FALSE))
estimation_datasetY <- dplyr::bind_rows(estimation_datasetY)

post_process_qtr()
post_process_yr()

Rda_out<-paste0("inter_prices_FY_",vintage_string,".Rda")
csv_out<-paste0("inter_prices_FY_",vintage_string,".csv")
save(fy_out2, file=file.path(data_main,Rda_out)) 

############################################################################

# There are no prices for Q1 and Q2 of FY 2010.  
#This section of code replaces those missing prices with prices for Q3 of FY 2010.
#We don't want to do this for an analysis of quarterly quota prices.

# f<-subset(fy_out1,fy==2010&q_fy==3)
# f1<-subset(fy_out1, fy==2010&q_fy %in% c(1))
# f2<-subset(fy_out1, fy==2010&q_fy %in% c(2))
# f3<-f
# f4<-subset(fy_out1,fy==2010&q_fy==4)
# 
# #f1[,c(5,6,7,8,10)]<-f[,c(5,6,7,8,10)]
# #f2[,c(5,6,7,8,10)]<-f[,c(5,6,7,8,10)]
# f1<-f
# f1$q_fy<-1
# f2<-f
# f2$q_fy<-2
# 
# f5<-rbind(f1,f2,f3,f4)
# 
# fall<-subset(fy_out1, fy!=2010)
# 
# fy_out1<-rbind(f5, fall)


Rda_out<-paste0("inter_prices_qtr_",vintage_string,".Rda")
csv_out<-paste0("inter_prices_qtr_",vintage_string,".csv")
dta_out<-paste0("inter_prices_qtr_",vintage_string,".dta")


# Save the quarterly coefficients as a Rda, csv, and dta
save(fy_out1, file=file.path(data_main,Rda_out)) 
write.csv(fy_out1,file=file.path(data_main,csv_out), row.names=FALSE)
write.dta(fy_out1,file.path(data_main,dta_out) , version=10, convert.dates=TRUE)  


# Save the quarterly coefficients and data, yearly coefficients and data all together an RData 
save_out<-paste0("quarterly_estimation_results_",vintage_string,".RData")
save_out<-file.path(data_main,save_out)
save(estimation_dataset,estimation_datasetY,w_out,fy_out1,fy_out2, file=save_out)


# Save the quarterly data and yearly data as a stata dta 
# Even though you saved this data, be careful using it.  It marks things as "NA" when excluded from the estimating equation. 

write.dta(estimation_dataset,file.path(data_main,paste0("quarterly_estimation_dataset_",vintage_string,".dta")), version=10, convert.dates=TRUE)  
write.dta(estimation_datasetY,file.path(data_main,paste0("yearly_estimation_dataset_",vintage_string,".dta")), version=10, convert.dates=TRUE)  


