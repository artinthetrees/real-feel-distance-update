
get_config_vars_from_shell <- function(){
  city_string <- commandArgs(trailingOnly=TRUE)[[1]]
  county_string <- paste0(commandArgs(trailingOnly=TRUE)[[2]]," County")
  state_string <- commandArgs(trailingOnly=TRUE)[[3]]
  year_num <- as.numeric(commandArgs(trailingOnly=TRUE)[[4]])
  crs_datum <- commandArgs(trailingOnly=TRUE)[[5]]
  output_dir <- commandArgs(trailingOnly=TRUE)[[6]]
  census_api_key <- commandArgs(trailingOnly=TRUE)[[7]]
  message("city is: ", county_string)
  message("county is: ", county_string)
  message("state is: ", state_string)
  message("year is: ", year_num)
  message("crs datum is: ", crs_datum)
  message("output dir is: ", output_dir)
  message("census api key is: ", census_api_key)
}