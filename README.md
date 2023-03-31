# Project Template

A small repository that will help you set up an organized project. There is also a tiny bit of sample code about how to get data off the NEFSC oracle servers.  

1. A folder structure and some utilities that will (hopefully) help you keep things organized
1. Getting Data
    1. Sample code for extracting data from oracle using stata.
    1. Sample code for extracting data from oracle using R with ROracle and RODBC.
    1. Sample code for extracting data from the St. Louis Fed using stata. 
    1. If you need to extract data from oracle on one of the NEFSC servers, look [here](https://github.com/NEFSC/READ-SSB-LEE-On-the-servers)
1. a class file (ajae_mod.csl) and a latex preamble (preamble-latex.tex) that might make your life easier if you are using markdown to make pdfs.

# How to use

1.  Create a [new repository](/images/new_repository.jpg) using this as a [template](/images/from_template.jpg).
2.  Clone it the new repository locally, using Github Desktop, Rstudio, or something else.
3.  Delete the parts of this readme that are no longer needed.
4.  If R and Rstudio is part of your workflow, associate the directory with a project. File--> New Project--> Existing Directory.

# Overview and Folder structure

This is mostly borrowed from the world bank's EDB. https://dimewiki.worldbank.org/wiki/Stata_Coding_Practices
Please use forward slashes (that is C:/path/to/your/folder) instead of backslashes for unix/mac compatability. I'm forgetful about this. 

I keep each project in a separate folder.  A stata do file containing folder names get stored as a macro in stata's startup profile.do.  This lets me start working on any of my projects by opening stata and typing: 
```
do $my_project_name
```
Rstudio users using projects don't have to do this step.  But it is convenient to read paths into variables by using the "R_paths_libraries.R" file.


# On passwords and other confidential information

Basically, you will want to store them in a place that does not get uploaded to github. 

For stata users, there is a description [here](/documentation/project_logistics.md). 

For R users, try storing it in .Renviron. Or copy the general approach from stata.

# NOAA Requirements
This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an ‘as is’ basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.”


1. who worked on this project:  Min-Yang Lee
1. when this project was created: Jan, 2021 
1. what the project does: Helps people get organized.  Shows how to get data from NEFSC oracle 
1. why the project is useful:  Helps people get organized.  Shows how to get data from NEFSC oracle 
1. how users can get started with the project: Download and follow the readme
1. where users can get help with your project:  email me or open an issue
1. who maintains and contributes to the project. Min-Yang

# License file
See here for the [license file](License.txt)
