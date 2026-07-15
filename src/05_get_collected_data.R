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
    city_string <- commandArgs(trailingOnly=TRUE)[[1]]
    county_string <- paste0(commandArgs(trailingOnly=TRUE)[[2]]," County")
    state_string <- commandArgs(trailingOnly=TRUE)[[3]]
    year_num <- as.numeric(commandArgs(trailingOnly=TRUE)[[4]])
    year_string <- commandArgs(trailingOnly=TRUE)[[4]]
    output_dir <- commandArgs(trailingOnly=TRUE)[[5]]
    
    real_feel_vars_base_raw <- commandArgs(trailingOnly=TRUE)[[6]]
    real_feel_vars_to_calculate_raw <- commandArgs(trailingOnly=TRUE)[[7]]
    real_feel_model_label <- commandArgs(trailingOnly=TRUE)[[8]]
    
    #real_feel_vars_base <- as.list(strsplit(real_feel_vars_base_raw,"\\s+")[[1]])
    real_feel_vars_base <- lapply(as.list(strsplit(real_feel_vars_base,",")[[1]]),trimws)
    real_feel_vars_to_calculate <- lapply(as.list(strsplit(real_feel_vars_to_calculate_raw,",")[[1]]),trimws)
    
  
    message("city is: ", city_string)
    message("county is: ", county_string)
    message("state is: ", state_string)
    message("year num is: ", year_num)
    message("year string is: ", year_string)
    message("output dir is: ", output_dir)

    message("real feel vars base raw are: ", real_feel_vars_base_raw)
    message("real feel vars base are: ", real_feel_vars_base)

    message("real feel vars to calculate raw are: ", real_feel_vars_to_calculate_raw)
    message("real feel vars to calculate are: ", real_feel_vars_to_calculate)

    message("real feel model label is: ", real_feel_model_label)
    
}

#################################################################
# create common output fnames

city_year_output_fname <- get_city_year_output_filename(city_string=city_string,year_num=year_num,save_file_type="Rdata")
message("city year output file name is: ", city_year_output_fname)

city_output_fname <- get_city_output_filename(city_string=city_string,save_file_type="Rdata")
message("city output file name is: ", city_output_fname)

city_year_output_fname_base <- get_city_year_output_filename(city_string=city_string,year_num=year_num,save_file_type=NULL)
message("city year output file base name is: ", city_year_output_fname_base)

#################################################################
# source utils specific to this script
library(tidyverse)
source("./src/utils/utils_get_collected.R")

#################################################################
# create output file path specific to this script
output_folder_parent <- Gmisc::pathJoin(output_dir,"collected_data")
output_folder <- Gmisc::pathJoin(output_folder_parent,city_year_output_fname_base)
print(output_folder)

if (interactive()) {
  if (!dir.exists(output_folder_parent)) {
    dir.create(output_folder_parent)
  }
}

if (interactive()) {
  if (!dir.exists(output_folder)) {
    dir.create(output_folder)
  }
}


#################################################################
# define outpath for this step

output_path <- Gmisc::pathJoin(output_folder,paste0(real_feel_model_label,"_",city_year_output_fname))
print(output_path)

#################################################################
# pull in objs needed from previous parts of pipeline for this step

summary_distances_df <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"distance_to_grocery",city_year_output_fname),obj_name = summary_distances_df)

#################################################################
# work for this step

collect_data_df <- NULL

# collect base environmental variables that are directly part of real feel calculation
if (length(real_feel_vars_base)==0){
  message("there are 0 base environmental variables needed for real feel calculation, skipping collection of base environmental variables...")
} else {
  message("there are ",length(real_feel_vars_base), " environmental variables needed for real feel calculation, starting collection of base environmental variables...")
  capture_base_vars_list <- list()
  capture_source_vars_list <- list()

  for (var_base_def in real_feel_vars_base){
    if (var_base_def == ""){
      message("base var is empty string, skipping collection process..")
      next
    }
    message("working on ",var_base_def)
    split_base_var_from_source_var <- lapply(as.list(strsplit(var_base_def,"from")[[1]]),trimws)

    base_var <- split_base_var_from_source_var[[1]]
    source_var <- split_base_var_from_source_var[[2]]

    capture_base_vars_list[[length(capture_base_vars_list) + 1]] <- base_var
    capture_source_vars_list[[length(capture_source_vars_list) + 1]] <- source_var

    collect_data_df <- collect_environmental_data_var(base_var,source_var,summary_distances_df,collect_data_df,year_string,output_dir,city_year_output_fname_base)

  }
}

# collect base environmental variables needed to calculate calculated environmental variables that are part of the real feel calculation
if (length(real_feel_vars_to_calculate)==0){
  message("there are 0 calculated environmental variables needed for real feel calculation, skipping collection of base environmental variables needed for calculated environmental variable calculation...")
} else {
  message("there are ",length(real_feel_vars_to_calculate), "calculated variables needed for real feel calculation, starting collection of base environmental variables needed for calculated environmental variables calculation...")
  calc_vars_list <- list()

  for (var_calc_def in real_feel_vars_to_calculate){
    if (var_calc_def == ""){
      message("calc var is empty string, skipping calculation process..")
      next
    }

    message("working on ",var_calc_def)
    split_calc_var_from_base_vars <- lapply(as.list(strsplit(var_calc_def,"from")[[1]]),trimws)
    
    calc_var <- split_calc_var_from_base_vars[[1]]
    message("calc var: ", calc_var)
    
    calc_vars_list[[length(calc_vars_list) + 1]] <- calc_var
    
    base_vars_raw <- split_calc_var_from_base_vars[[2]]
    base_vars <- lapply(as.list(strsplit(base_vars_raw,"\\s+")[[1]]),trimws)
    message("base vars: ", base_vars)

    # make sure all base vars required for calculation of calc var have already been collected
    if !all(unlist(base_vars) %in% names(collect_df)){
      message("not all base vars required to calculate ",calc_var," are available: ")
      print(base_vars)
      print(unlist(base_vars) %in% names(collect_df))
      message("skipping calculation..")
      next
    }
    
    my_calc_function_name <- paste0("calculate_environmental_data_var_",calc_var)

    my_calc_function <- tryCatch({
        match.fun(my_calc_function_name)
      }, error = function(e) {
        message("No function available to calculate ", calc_var)
        NULL
      })

    if (is.null(my_calc_function)){
      message("Skipping calculation of ",calc_var)
      next
    }
    
    collect_data_df <- 
    my_calc_function(
      collect_data_df,
      temp_var="temp",
      dewpointtemp_var="dewpointtemp",
      temp_measured_in="celsius",
      dist_measured_in="meter"
      )
  
}

collect_data_df <- 
  collect_data_df %>%
  mutate(dist_to_grocery = median_dist_to_grocery)

#################################################################
# save for this step

save(
  collect_data_df,
  file = output_path
)

#################################################################
# clean up workspace - remove any objs created during this step

if (interactive()){
  rm(list = setdiff(ls(),ws_objs))
}

#################################################################















