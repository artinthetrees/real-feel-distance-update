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

city_output_fname_base <- get_city_output_filename(city_string=city_string,save_file_type=NULL)
message("city output file name base is: ", city_output_fname_base)

city_year_output_fname_base <- get_city_year_output_filename(city_string=city_string,year_num=year_num,save_file_type=NULL)
message("city year output file name base is: ", city_year_output_fname_base)

#################################################################
# source utils specific to this script

#################################################################
# create output file path specific to this script

output_path <- Gmisc::pathJoin(output_dir,"street_network_products",city_year_output_fname)
print(output_path)

#################################################################
# pull in objs needed from previous parts of pipeline for this step

city_year_fname_streetnet <- paste0(city_year_output_fname_base,"_streetnet.parquet")

#streetnet_sf.lonlat <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"street_network",city_output_fname),obj_name = streetnet_sf.lonlat)
streetnet_sf.lonlat <- sfarrow::st_read_parquet(Gmisc::pathJoin(output_dir,"street_network",city_year_fname_streetnet))

#################################################################
# work for this step

streetnet_weighted <- dodgr::weight_streetnet (streetnet_sf.lonlat, wt_profile = "foot")

streetnet_vertices <- dodgr::dodgr_vertices (streetnet_weighted)

#################################################################
# save for this step

save(
  streetnet_weighted,
  streetnet_vertices,
  file = output_path
)

#################################################################
# clean up workspace - remove any objs created during this step
if(interactive()){
  rm(list = setdiff(ls(),ws_objs))
}
  
#################################################################


