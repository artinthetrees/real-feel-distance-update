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
    city_string <- commandArgs(trailingOnly=TRUE)[[1]]
    county_string <- paste0(commandArgs(trailingOnly=TRUE)[[2]]," County")
    state_string <- commandArgs(trailingOnly=TRUE)[[3]]
    year_num <- as.numeric(commandArgs(trailingOnly=TRUE)[[4]])
    crs_datum <- commandArgs(trailingOnly=TRUE)[[5]]
    output_dir <- commandArgs(trailingOnly=TRUE)[[6]]
    census_api_key <- commandArgs(trailingOnly=TRUE)[[7]]
    message("city is: ", city_string)
    message("county is: ", county_string)
    message("state is: ", state_string)
    message("year is: ", year_num)
    message("crs datum is: ", crs_datum)
    message("output dir is: ", output_dir)
    message("census api key is: ", census_api_key)
}

#################################################################
# create common output fnames

city_year_output_fname <- get_city_year_output_filename(city_string=city_string,year_num=year_num,save_file_type="Rdata")
message("city year output file name is: ", city_year_output_fname)

city_output_fname <- get_city_output_filename(city_string=city_string,save_file_type="Rdata")
message("city output file name is: ", city_output_fname)

#################################################################
# source utils specific to this script
source("./src/utils/utils_get_crs.R")

#################################################################
# create output file path specific to this script

output_path <- Gmisc::pathJoin(output_dir,"crs",city_year_output_fname)
print(output_path)

#################################################################
# pull in objs needed from previous parts of pipeline for this step

print("no objects from previous part of pipeline pulled in")

#################################################################
# work for this step

get_crs(
    county_string = county_string,
    state_string = state_string,
    year_num = year_num,
    crs_datum = crs_datum,
    census_api_key = census_api_key,
    output_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname)
)

#################################################################
# clean up workspace - remove any objs created during this step
if(interactive()){
    rm(list = setdiff(ls(),ws_objs))
}
  
#################################################################








