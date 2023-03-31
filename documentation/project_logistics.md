# Overview
In general, I'm trying to keep code, raw data, processed data, results, and images separate.  I have soft coded these directories; and only two files needs to be changed (the ones in project_logistics) to change the project directories and subdirectories.

Smaller bits of analysis that are related (or depend on previous) are collected together in a wrapper.

# Cloning from Github and other setup
Min-Yang is using Rstudio to write Rmd and it's git version controling to commit/push/pull from github. It works reasonably well.  So does github desktop.  You will also need git installed.

The easist thing to do is create a new repository using this as a template. [Here's a starting guide](https://cfss.uchicago.edu/setup/git-with-rstudio/).  Don't put spaces in the name.  This will set up many, but not all of the folders.

# Stata Users 

## Running code

1. Open up stata and the stata do file called "/stata_code/project_logistics/folder_setup_globals.do"
2. Change the line:

```
global myprojdir U:/this_project_directory
```
to your project directory. 

Here are two ways to be ready to run the project.

### Automatic
1.  Modify or create your profile.do file that stata automatically runs on startup.  I've put mine in c:/ado/profile.do.  
add the following 2 lines

```
global user minyangWin
global aceprice full\path\to\folder_setup_globals.do 
```
2. Restart stata
3. type  "do $aceprice"

Everything is set up and ready to go.

### By hand
Every time you want to work on the project in stata do this:
```
global user <your_user_name>
do "/stata_code/project_logistics/folder_setup_globals.do"
```
you will have to type in the full path for the second line.




## user written code stata code
As far as I can tell, we need these user written stata commands
<!---
1. renvarlab
1. egenmore
1. tabcount
1. ineqdeco, ineqdec0
1. vioplot
1. renvars
1. mdesc
--->

# R users

If you are using Rstudio, as long as you use the "Project" feature, you shouldn't have to do much. All you need to do is open  `R_paths_libraries.R`  and change this line of code.

```
my_projdir<-"path/to/project/directory"
```

# Description of the folders

## project_logistics
A pair of small do files to set up folders and then make stata aware of folders.

## data_extraction_processing
There is sample code in "data_extraction_processing" that you can use to get deflators.  This can be done with "/data_extraction_processing/wrapper_external.do".  You'll need an API key to import fred.  Extracting OES and QCEW data is really slow. 

## summary stats

The code in here will do a bunch of data exploration.  Violin plots take a while to run.  

## Sub-projects
Code for smaller pieces of the project are all in their individual folders in "stata_code". For the most part, they produce datasets or tables in  "/results/" and images in "/images/"
