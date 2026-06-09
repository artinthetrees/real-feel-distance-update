#library(tidyverse)

#tidycensus::census_api_key(my_census_api_key)

`%>%` <- magrittr::`%>%`

get_file_safe_string <- function(input_string){

  return(sub(" ","_",input_string))
}

get_city_year_output_filename <- function(city_string,year_num,save_file_type="Rdata"){
  if (!is.null(my_variable)) {
    fname <- paste0(get_file_safe_string(city_string),"_",as.character(year_num),".",save_file_type)
  } else {
    fname <- paste0(get_file_safe_string(city_string),"_",as.character(year_num))
  }
  
  return(fname)
}

get_city_output_filename <- function(city_string,save_file_type="Rdata"){
  fname <- paste0(get_file_safe_string(city_string),".",save_file_type)
  if (!is.null(my_variable)) {
    fname <- paste0(get_file_safe_string(city_string),".",save_file_type)
  } else {
    fname <- paste0(get_file_safe_string(city_string))
  }
  return(fname)
}

get_obj_from_rdata <- function(rdata_file_path,obj_name=NULL){
  attach(rdata_file_path)
  obj <- obj_name
  detach()
  return(obj)
}

