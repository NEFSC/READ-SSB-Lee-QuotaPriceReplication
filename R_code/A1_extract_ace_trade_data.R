
#library(ROracle)

if(!require(RODBC)) {  
  install.packages("RODBC")
  require(RODBC)}

if(!require(sqldf)) {  
  install.packages("sqldf")
  require(sqldf)}

##   This is the data-extraction step from "inter_trades_QTR_final_CD.R" from Chad Feb 22,2021

o<-odbcConnect("sole.nefsc.noaa.gov", uid=id, pwd=solepw, believeNRows=FALSE)



get_out_data<-function(){
  out_1<-sqlQuery(o,"select b.year, b.transfer_number, b.from_sector_id, b.to_sector_id, a.stock, a.live_pounds, b.status, 
                   b.compensation, b.transfer_date       
                  from sector.transfers@garfo_nefsc b, sector.transfer_stock@garfo_nefsc a
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

get_out_data()
savefile<-file.path(data_internal,paste0("ACE_data_",vintage_string,".Rdata"))
close(o)
save.image(savefile)

write.dta(out_1,file.path(data_internal,paste0("ACE_data_",vintage_string,".dta")), version=10, convert.dates=TRUE)  


