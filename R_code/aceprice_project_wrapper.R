# This decsribes how /what to run.

#### Set things up
my_projdir<- "/home/mlee/Documents/projects/READ-SSB-Lee-QuotaPriceReplication"
my_projdir<-"C:/Users/Min-Yang.Lee/Documents/READ-SSB-Lee-QuotaPriceReplication"

#this reads in paths and libraries
# Be careful, there's are a few masked objects (packages with commands with the same name)

source(file.path(my_projdir,"R_code","project_logistics","R_paths_libraries.R"))
# Reset the vintage_string
vintage_string<-"2024_01_19"
##############################################################
# this DOES NOT run. It is a lightly modified piece of R code from Chad that he uses to estimate prices of quota.
#source(file.path(R_codedir,"inter_trades_QTR_final.R"))
##############################################################


##############################################################
# source(file.path(R_codedir,"project_logistics","R_credentials.R"))

# A tiny bit of code to just extract the Ace trade data.
  source(file.path(R_codedir,"A1_extract_ace_trade_data.R"))
##############################################################

# Get data ready to estimate hedonic models

source(file.path(R_codedir,"A2_trades_dataprocess.R"))


# Estimate hedonic models by year and quarter.
source(file.path(R_codedir,"A3_trades_estimate.R"))


# Estimate hedonic models by year and quarter, but don't drop RHS variables 
#source(file.path(R_codedir,"A3_trades_estimate_nodrop.R"))

# source(file.path(R_codedir,"A4_intra_trades_process.R"))


