#Install packages if necessary
if(!require(RODBC)) {  
  install.packages("RODBC")
  require(RODBC)}
if(!require(DBI)) {  
  install.packages("DBI")
  require(DBI)}
if(!require(foreign)) {  
  install.packages("foreign")
  require(foreign)}
if(!require(gdata)) {  
  install.packages("gdata")
  require(gdata)}

if(!require(lubridate)) {  
  install.packages("lubridate")
  require(lubridate)}
if(!require(caret)) {  
  install.packages("caret")
  require(caret)}
if(!require(MASS)) {  
  install.packages("MASS")
  require(MASS)}
if(!require(reshape2)) {  
  install.packages("reshape2")
  require(reshape2)}
if(!require(broom)) {  
  install.packages("broom")
  require(broom)}

if(!require(robustbase)) {  
  install.packages("robustbase")
  require(robustbase)}
if(!require(zoo)) {  
  install.packages("zoo")
  require(zoo)}
if(!require(ggthemes)) {  
  install.packages("ggthemes")
  require(ggthemes)}
if(!require(sqldf)) {  
  install.packages("sqldf")
  require(sqldf)}
if(!require(dplyr)) {  
  install.packages("dplyr")
  require(dplyr)}
if(!require(sas7bdat)) {  
  install.packages("sas7bdat")
  require(sas7bdat)}
if(!require(sandwich)) {  
  install.packages("sandwich")
  require(sandwich)}

if(!require(lmtest)) {  
  install.packages("lmtest")
  require(lmtest)}


# if(!require(ROracle)) {  
#   install.packages("ROracle")
#   require(ROracle)}


my_codedir<-file.path(my_projdir,"R_code")
                    
extraction_code<-file.path(my_projdir,"data_extraction_processing")
analysis_code <-file.path(my_codedir, "analysis")
R_codedir <-file.path(my_projdir, "R_code")
my_adopath <-file.path(my_codedir, "aceprice_ado")


# setup data folder
my_datadir <-file.path(my_projdir, "data_folder")
data_raw <-file.path(my_datadir, "raw")

data_internal <-file.path(my_datadir, "internal")
data_external<-file.path(my_datadir, "external")

data_main <-file.path(my_datadir, "main")
data_intermediate <-file.path(my_datadir, "intermediate")


spacepanels <- "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_11182019"


# setup results folders 
  
my_results <-file.path(my_projdir, "results")
hedonicR_results <-file.path(my_results, "hedonicR")

# setup images folders 

my_images <-file.path(my_projdir, "images")
exploratory <-file.path(my_images, "exploratory")

vintage_string<-Sys.Date()
vintage_string<-gsub("-","_",vintage_string)
