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
    
    real_feel_model_label <- commandArgs(trailingOnly=TRUE)[[6]]
    
    message("city is: ", city_string)
    message("county is: ", county_string)
    message("state is: ", state_string)
    message("year num is: ", year_num)
    message("year string is: ", year_string)
    message("output dir is: ", output_dir)

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

#################################################################
# create output file path specific to this script
output_folder_parent <- Gmisc::pathJoin(output_dir,"real_feel_distance_to_grocery")
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

collect_data_df <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"collected_data",city_year_output_fname_base,paste0(real_feel_model_label,"_",city_year_output_fname)),obj_name = collect_data_df)

#################################################################
# work for this step

age_dummy <- 1
age_dummy_young <- 0
# https://www.healthline.com/health/exercise-fitness/average-walking-speed#average-speed-by-age
age_penalty <- 0.15

# if temp is above ideal environmental temp for humans (70F) then set this dummy to 1
temp_ref_f <- 70
temp_abv70F_dummy <- quote(ifelse(temp >= weathermetrics::fahrenheit.to.celsius(temp_ref_f, round = 2),1,0))
temp_abv70F_penalty <- 0.0056 
temp_abv70F_penalty_young <- 0.0035 
# 5% decrease in aerobic capacity for every 10 degrees celsius >> 0.5% increase in 'distance' for every 1 degree celsius

dewpointtemp_ref_f <- 55
dewpointtemp_abv55F_dummy <- quote(ifelse(dewpointtemp >= weathermetrics::fahrenheit.to.celsius(dewpointtemp_ref_f, round = 2),1,0)) 
dewpointtemp_abv55F_penalty <- 0.055
dewpointtemp_abv55F_penalty_young <- 0.0077

# https://www.sciencedirect.com/science/article/pii/S0160412021004591
# https://www.sciencedirect.com/science/article/pii/S0160412021004591
# https://ehjournal.biomedcentral.com/articles/10.1186/s12940-016-0167-3
# https://ieeexplore.ieee.org/abstract/document/8254354
# https://www.sciencedirect.com/science/article/pii/S1555415506008889?casa_token=0wRrFTicIZUAAAAA:0hqN1TNm9DyCY-dDsIZkLKtrN2mV9T5gsPsv65QkZrMEPiqvWjjhaVqorG6GRCDvrdhBDsloGg
# https://www.scielo.br/j/aabc/a/TPZpmfGmztHbBjJVnqJLNBv/?lang=en
# https://repositorio-aberto.up.pt/bitstream/10216/114841/1/MonteiroCarvalho2013.pdf
heatindex_ref_f <- 80
heatindex_abv80F_dummy <- quote(ifelse(heatindex >= weathermetrics::fahrenheit.to.celsius(heatindex_ref_f, round = 2),1,0)) 
heatindex_abv80F_penalty <- 0.075
heatindex_abv80F_penalty_young <- 0.025

# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3377942/
walking_dist <- 1000


real_feel_distance_df <- 
  collect_data_df %>%
  mutate(temp_dummy = eval(temp_abv70F_dummy),
         dewpointtemp_dummy = eval(dewpointtemp_abv55F_dummy),
         heatindex_dummy = eval(heatindex_abv80F_dummy),
         
         # get the raw distance and calculate whether 
         raw_dist = dist_to_grocery,
         avoid_trip = ifelse(raw_dist > walking_dist,1,0),

         # older adult - calc the "penalty distance" due to each factor (age/environmental vars)
         age_dist = raw_dist*age_dummy*age_penalty,
         temp_dist = raw_dist*temp_dummy*temp_abv70F_penalty*(temp - weathermetrics::fahrenheit.to.celsius(temp_ref_f, round = 2)),
         dewpointtemp_dist = raw_dist*dewpointtemp_dummy*dewpointtemp_abv55F_penalty*(dewpointtemp - weathermetrics::fahrenheit.to.celsius(dewpointtemp_ref_f, round = 2)),
         heatindex_dist = raw_dist*heatindex_dummy*heatindex_abv80F_penalty*(heatindex - weathermetrics::fahrenheit.to.celsius(heatindex_ref_f, round = 2)),
         
         # healthy young adult - calc the "penalty distance" due to each factor (age/environmental vars) - age_dummy_young is 0 so "penalty distance" due to age is always 0 here
         age_dist_young = raw_dist*age_dummy_young*age_penalty, # 
         temp_dist_young = raw_dist*temp_dummy*temp_abv70F_penalty_young*(temp - weathermetrics::fahrenheit.to.celsius(temp_ref_f, round = 2)),
         dewpointtemp_dist_young = raw_dist*dewpointtemp_dummy*dewpointtemp_abv55F_penalty_young*(dewpointtemp - weathermetrics::fahrenheit.to.celsius(dewpointtemp_ref_f, round = 2)),
         heatindex_dist_young = raw_dist*heatindex_dummy*heatindex_abv80F_penalty_young*(heatindex - weathermetrics::fahrenheit.to.celsius(heatindex_ref_f, round = 2)),
         
         # older adults   
         real_feel_dist_age = 
           raw_dist + 
           age_dist,
         real_feel_dist_heatindex = 
           raw_dist + 
           heatindex_dist,
         real_feel_dist_age_heatindex = 
           raw_dist + 
           age_dist + 
           heatindex_dist,  
         real_feel_dist_temp_dewpointtemp_heatindex = 
           raw_dist + 
           temp_dist + 
           dewpointtemp_dist + 
           heatindex_dist,
         real_feel_dist_age_temp_dewpointtemp_heatindex = 
           raw_dist + 
           age_dist +
           temp_dist + 
           dewpointtemp_dist + 
           heatindex_dist,
         
         # health young adult - even though age "penalty distance" is included as a var in these calcs the values will always be zero bc the age penalty dummy for young adults is 0
         real_feel_dist_age_young = 
           raw_dist + 
           age_dist_young,
         real_feel_dist_heatindex_young = 
           raw_dist + 
           heatindex_dist_young,
         real_feel_dist_age_heatindex_young = 
           raw_dist + 
           age_dist_young + 
           heatindex_dist_young,
         real_feel_dist_temp_dewpointtemp_heatindex_young = 
           raw_dist + 
           temp_dist_young + 
           dewpointtemp_dist_young + 
           heatindex_dist_young,
         real_feel_dist_age_temp_dewpointtemp_heatindex_young = 
           raw_dist + 
           age_dist_young +
           temp_dist_young + 
           dewpointtemp_dist_young + 
           heatindex_dist_young,
         
         # older adult - impact on felt distance and on decision/likelihood of taking trip
         p_increase_age = real_feel_dist_age/raw_dist - 1,
         more_than_double_age = ifelse(p_increase_age > 1,1,0),
         newly_avoid_trip_age = ifelse(raw_dist <= walking_dist & real_feel_dist_age > walking_dist,1,0),
         avoid_trip_cat_age = case_when(
           raw_dist <= walking_dist & real_feel_dist_age <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_age > walking_dist ~ "newly avoid trip",
         ),
         p_increase_heatindex = real_feel_dist_heatindex/raw_dist - 1,
         more_than_double_heatindex = ifelse(p_increase_heatindex > 1,1,0),
         newly_avoid_trip_heatindex = ifelse(raw_dist <= walking_dist & real_feel_dist_heatindex > walking_dist,1,0),
         avoid_trip_cat_heatindex = case_when(
           raw_dist <= walking_dist & real_feel_dist_heatindex <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_heatindex > walking_dist ~ "newly avoid trip",
         ),
         p_increase_age_heatindex = real_feel_dist_age_heatindex/raw_dist - 1,
         more_than_double_age_heatindex = ifelse(p_increase_age_heatindex > 1,1,0),
         newly_avoid_trip_age_heatindex = ifelse(raw_dist <= walking_dist & real_feel_dist_age_heatindex > walking_dist,1,0),
         avoid_trip_cat_age_heatindex = case_when(
           raw_dist <= walking_dist & real_feel_dist_age_heatindex <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_age_heatindex > walking_dist ~ "newly avoid trip",
         ),
         p_increase_temp_dewpointtemp_heatindex = real_feel_dist_temp_dewpointtemp_heatindex/raw_dist - 1,
         more_than_double_temp_dewpointtemp_heatindex = ifelse(p_increase_temp_dewpointtemp_heatindex > 1,1,0),
         newly_avoid_trip_temp_dewpointtemp_heatindex = ifelse(raw_dist <= walking_dist & real_feel_dist_temp_dewpointtemp_heatindex > walking_dist,1,0),
         avoid_trip_cat_temp_dewpointtemp_heatindex = case_when(
           raw_dist <= walking_dist & real_feel_dist_temp_dewpointtemp_heatindex <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_temp_dewpointtemp_heatindex > walking_dist ~ "newly avoid trip",
         ),
         p_increase_age_temp_dewpointtemp_heatindex = real_feel_dist_age_temp_dewpointtemp_heatindex/raw_dist - 1,
         more_than_double_age_temp_dewpointtemp_heatindex = ifelse(p_increase_age_temp_dewpointtemp_heatindex > 1,1,0),
         newly_avoid_trip_age_temp_dewpointtemp_heatindex = ifelse(raw_dist <= walking_dist & real_feel_dist_age_temp_dewpointtemp_heatindex > walking_dist,1,0),
         avoid_trip_cat_age_temp_dewpointtemp_heatindex = case_when(
           raw_dist <= walking_dist & real_feel_dist_age_temp_dewpointtemp_heatindex <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_age_temp_dewpointtemp_heatindex > walking_dist ~ "newly avoid trip",
         ),
       
         # health young adult - impact on felt distance and on decision/likelihood of taking trip
         p_increase_age_young = real_feel_dist_age_young/raw_dist - 1,
         more_than_double_age_young = ifelse(p_increase_age_young > 1,1,0),
         newly_avoid_trip_age_young = ifelse(raw_dist <= walking_dist & real_feel_dist_age_young > walking_dist,1,0),
         avoid_trip_cat_age_young = case_when(
           raw_dist <= walking_dist & real_feel_dist_age_young <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_age_young > walking_dist ~ "newly avoid trip",
         ),
         p_increase_heatindex_young = real_feel_dist_heatindex_young/raw_dist - 1,
         more_than_double_heatindex_young = ifelse(p_increase_heatindex_young > 1,1,0),
         newly_avoid_trip_heatindex_young = ifelse(raw_dist <= walking_dist & real_feel_dist_heatindex_young > walking_dist,1,0),
         avoid_trip_cat_heatindex_young = case_when(
           raw_dist <= walking_dist & real_feel_dist_heatindex_young <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_heatindex_young > walking_dist ~ "newly avoid trip",
         ),
         p_increase_age_heatindex_young = real_feel_dist_age_heatindex_young/raw_dist - 1,
         more_than_double_age_heatindex_young = ifelse(p_increase_age_heatindex_young > 1,1,0),
         newly_avoid_trip_age_heatindex_young = ifelse(raw_dist <= walking_dist & real_feel_dist_age_heatindex_young > walking_dist,1,0),
         avoid_trip_cat_age_heatindex_young = case_when(
           raw_dist <= walking_dist & real_feel_dist_age_heatindex_young <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_age_heatindex_young > walking_dist ~ "newly avoid trip",
         ),
         p_increase_temp_dewpointtemp_heatindex_young = real_feel_dist_temp_dewpointtemp_heatindex_young/raw_dist - 1,
         more_than_double_temp_dewpointtemp_heatindex_young = ifelse(p_increase_temp_dewpointtemp_heatindex_young > 1,1,0),
         newly_avoid_trip_temp_dewpointtemp_heatindex_young = ifelse(raw_dist <= walking_dist & real_feel_dist_temp_dewpointtemp_heatindex_young > walking_dist,1,0),
         avoid_trip_cat_temp_dewpointtemp_heatindex_young = case_when(
           raw_dist <= walking_dist & real_feel_dist_temp_dewpointtemp_heatindex_young <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_temp_dewpointtemp_heatindex_young > walking_dist ~ "newly avoid trip",
         ),
         p_increase_age_temp_dewpointtemp_heatindex_young = real_feel_dist_age_temp_dewpointtemp_heatindex_young/raw_dist - 1,
         more_than_double_age_temp_dewpointtemp_heatindex_young = ifelse(p_increase_age_temp_dewpointtemp_heatindex_young > 1,1,0),
         newly_avoid_trip_age_temp_dewpointtemp_heatindex_young = ifelse(raw_dist <= walking_dist & real_feel_dist_age_temp_dewpointtemp_heatindex_young > walking_dist,1,0),
         avoid_trip_cat_age_temp_dewpointtemp_heatindex_young = case_when(
           raw_dist <= walking_dist & real_feel_dist_age_temp_dewpointtemp_heatindex_young <= walking_dist ~ "take trip",
           raw_dist > walking_dist ~ "avoid trip",
           raw_dist <= walking_dist & real_feel_dist_age_temp_dewpointtemp_heatindex_young > walking_dist ~ "newly avoid trip",
         ),
       
        )

#################################################################
# save for this step

save(
  real_feel_distance_df,
  file = output_path
)

#################################################################
# clean up workspace - remove any objs created during this step

if (interactive()){
  rm(list = setdiff(ls(),ws_objs))
}

#################################################################















