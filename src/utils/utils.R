#library(tidyverse)

#tidycensus::census_api_key(my_census_api_key)

`%>%` <- magrittr::`%>%`

get_city_year_output_filename <- function(city_string,year_num,save_file_type="Rdata"){
  fname <- paste0(city_string,"_",as.character(year_num),".",save_file_type)
  return(fname)
}

get_city_output_filename <- function(city_string,save_file_type="Rdata"){
  fname <- paste0(city_string,".",save_file_type)
  return(fname)
}

get_obj_from_rdata <- function(rdata_file_path,obj_name=NULL){
  attach(rdata_file_path)
  obj <- obj_name
  detach()
  return(obj)
}

