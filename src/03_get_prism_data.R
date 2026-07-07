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
    prism_dir <- commandArgs(trailingOnly=TRUE)[[6]]
    prism_vars_raw <- commandArgs(trailingOnly=TRUE)[[7]]
    prism_vars <- as.list(strsplit(prism_vars_raw,"\\s+")[[1]])
    message("city is: ", city_string)
    message("county is: ", county_string)
    message("state is: ", state_string)
    message("year num is: ", year_num)
    message("year string is: ", year_string)
    message("output dir is: ", output_dir)
    message("prism dir is: ", prism_dir)
    message("prism vars raw are: ", prism_vars_raw)
    message("prism vars are: ", prism_vars)
}

#################################################################
# create common output fnames

city_year_output_fname <- get_city_year_output_filename(city_string=city_string,year_num=year_num,save_file_type="Rdata")
message("city year output file name is: ", city_year_output_fname)

city_output_fname <- get_city_output_filename(city_string=city_string,save_file_type="Rdata")
message("city output file name is: ", city_output_fname)

#################################################################
# source utils specific to this script
#source("./src/utils/utils_get_streetnet.R")
source("./src/utils/utils_get_prism_data.R")

#################################################################
# create output file path specific to this script
output_folder_parent <- Gmisc::pathJoin(output_dir,"environmental_data")
output_folder <- Gmisc::pathJoin(output_folder_parent,paste0(city_string,"_",year_string))
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
# pull in objs needed from previous parts of pipeline for this step

crs_utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_utm)
print(crs_utm)

tracts.within.city.utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"boundary_maps",city_year_output_fname),obj_name = tracts.within.city.utm)

#################################################################
# work for this step

message("Setting prism archive directory to ",prism_dir)
prism::prism_set_dl_dir(prism_dir)

for (prism_var in prism_vars){
  
  message("Processing ",prism_var)
    
  # output_folder_subdir <- Gmisc::pathJoin(output_folder,paste0("prism_",prism_var))
  # if (!dir.exists(output_folder_subdir)) {
  #     dir.create(output_folder_subdir)
  # }
  output_path <- Gmisc::pathJoin(output_folder,paste0("prism_",prism_var,"_",city_year_output_fname))
  message("Data for this prism var will be saved to ",output_path)

  prism_file_list <- prism::pd_to_file(
    prism::prism_archive_subset(
      prism_var, 
      "daily", 
      minDate = paste0(year_string,"-01-01"), 
      maxDate = paste0(year_string,"-12-31"),
      resolution = "800m"
    )
  )
  
  print(prism_file_list[1:25])
  if (length(prism_file_list) == 0){
    message("no prism files found for ",prism_var," for year ",year_string,"...skipping getting prism per boundary for this condition...")
    next
  }

  get_prism_per_boundary(
    prism_file_list=prism_file_list,
    boundary_map=tracts.within.city.utm,
    return_type="verbose",
    output_path=output_path
  )

}

#################################################################
# save for this step

# save(
#   file = output_path
# )

#################################################################
# clean up workspace - remove any objs created during this step

if (interactive()){
  rm(list = setdiff(ls(),ws_objs))

}


#################################################################

