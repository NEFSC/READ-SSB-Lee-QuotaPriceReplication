# Quota Prices 
Code and Data to Replicate 

Lee, M and Demarest, C. 2023. "Groundfish Quota Prices." Fisheries Research 260:106605.  

https://doi.org/10.1016/j.fishres.2022.106605

https://repository.library.noaa.gov/view/noaa/48192

# Required stata packages

1. renvarlab
1. estout
1. outreg2
1. nehurdle

# Notes

The first stage data on quota transactions is confidential and cannot be shared. The second stage data, which includes estimates of prices obtained in the first stage, can be found in "/data_folder/main/quarterly_ols_coefs_from_R_2022_03_02.dta".  There are additional datasets in the "/data_folder/main" folder that contain other variables.

The two main .do files used to estimate the model are:
/stata_code/analysis/small/M09-churdle_spatial_compare2.do and 
/stata_code/analysis/small/M09B-exog_spatial_hurdle.do

Running these two files should allow you to reproduce the econometric results in the paper.

We have tried to leave out alot of the code that we used to estimate and test preliminary models. Some are silly. Some are distracting.  We may have removed too many of them.



# NOAA Requirements
This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an as is basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.


1. who worked on this project:  Min-Yang
1. when this project was created: Jan, 2021 
1. what the project does: Project to investigate ACE prices. 
1. why the project is useful:  Fisheries management in groundfish
1. how users can get started with the project: Download and follow the readme
1. where users can get help with your project:  email me or open an issue
1. who maintains and contributes to the project. Min-Yang

# License file
See here for the [license file](https://github.com/minyanglee/READ-SSB-Lee-aceprice/blob/main/license.md)
