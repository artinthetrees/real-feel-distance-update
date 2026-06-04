if(!interactive()){
    county_string <- paste0(commandArgs(trailingOnly=TRUE)[[1]]," County")
    state_string <- commandArgs(trailingOnly=TRUE)[[2]]
    year_num <- as.numeric(commandArgs(trailingOnly=TRUE)[[3]])
    crs_datum <- commandArgs(trailingOnly=TRUE)[[4]]
    output_dir <- commandArgs(trailingOnly=TRUE)[[5]]
    city_year_output_fname <- commandArgs(trailingOnly=TRUE)[[6]]
    census_api_key <- commandArgs(trailingOnly=TRUE)[[7]]
    message("county is: ", county_string)
    message("state is: ", state_string)
    message("year is: ", year_num)
    message("crs datum is: ", crs_datum)
    message("output dir is: ", output_dir)
    message("city year output file name is: ", city_year_output_fname)
    message("census api key is: ", census_api_key)
}

source("./src/utils/load_pipe.R")
source("./src/utils/utils_get_crs.R")

get_crs(
    county_string = county_string,
    state_string = state_string,
    year_num = year_num,
    crs_datum = crs_datum,
    census_api_key = census_api_key,
    output_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname)
)
