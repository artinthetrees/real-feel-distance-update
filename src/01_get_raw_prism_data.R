#################################################################
# list all objs in workspace at start

if(interactive()){
    ws_objs <- ls()
}

#################################################################
# source common utils 
source("./src/utils/utils.R")

#################################################################
if(!interactive()){
    # source("./src/utils/utils_shell.R")
    # get_config_vars_from_shell()
    year_string <- commandArgs(trailingOnly=TRUE)[[1]]
    prism_dir <- commandArgs(trailingOnly=TRUE)[[2]]
    prism_vars_raw <- commandArgs(trailingOnly=TRUE)[[3]]
    prism_vars <- as.list(strsplit(prism_vars_raw,"\\s+")[[1]])
    message("year is: ", year_string)
    message("prism dir is: ", prism_dir)
    message("prism vars raw are: ", prism_vars_raw)
    message("prism vars are: ", prism_vars)
}

#################################################################
# create common output fnames

#################################################################
# source utils specific to this script

#################################################################
# create output file path specific to this script

#################################################################
# pull in objs needed from previous parts of pipeline for this step

#################################################################
# work for this step

prism::prism_set_dl_dir(prism_dir)

for (prism_var in prism_vars){

    prism::get_prism_dailys(
        type = prism_var, 
        minDate = paste0(year_string,"-01-01"), 
        maxDate = paste0(year_string,"-12-31"), 
        resolution = "800m",
        keepZip = FALSE,
        check = "httr" # if file already downloaded, will not download again
    )
        

}


#################################################################
# clean up workspace - remove any objs created during this step
if(interactive()){
    rm(list = setdiff(ls(),ws_objs))
}
  
#################################################################








