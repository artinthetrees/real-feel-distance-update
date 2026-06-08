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

#################################################################
# source utils specific to this script

#################################################################
# create output file path specific to this script

output_path <- Gmisc::pathJoin(output_dir,"street_network_products",city_year_output_fname)
print(output_path)

#################################################################
# pull in objs needed from previous parts of pipeline for this step

streetnet_sf.lonlat <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"street_network",city_year_output_fname),obj_name = streetnet_sf.lonlat)

#################################################################
# work for this step

graph <- dodgr::weight_streetnet (streetnet_sf.lonlat, wt_profile = "foot")

v <- dodgr::dodgr_vertices (graph)

#################################################################
# save for this step

save(
  graph,
  v,
  file = output_path
)

#################################################################
# clean up workspace - remove any objs created during this step
if(interactive()){
  rm(list = setdiff(ls(),ws_objs))
}
  
#################################################################


# streetnet_ohsome_latest <- get_streetnet_sf_ohsome(boundary_map = sf_bb_to_sf)
# save(
#   streetnet_ohsome_latest,
#   file = "./2025-refactor/chicago_streetnet_ohsome_latest.Rdata"
# )

# streetnet_dodgr_latest <- get_streetnet_sf_dodgr(osmdata_bb = sf_bb_to_osmdata_bb, expand = 0)
# save(
#   streetnet_dodgr_latest,
#   file = "./2025-refactor/chicago_streetnet_dodgr_latest.Rdata"
# )
# 
# streetnet_ohsome_latest_mini <- 
#   process_streetnet_ohsome(streetnet_sf = streetnet_ohsome_latest) %>%
#   select(osm_id,name,highway,geometry) %>%
#   get_geom_type_col()
# 
# streetnet_dodgr_latest_mini <- 
#   streetnet_dodgr_latest %>%
#   select(osm_id,name,highway,geometry) %>%
#   get_geom_type_col()
# 
# dodgr_ids <- streetnet_dodgr_latest_mini$osm_id
# ohsome_ids <- streetnet_ohsome_latest_mini$osm_id
#   
# only_dodgr_ids <- setdiff(dodgr_ids,ohsome_ids)
# only_ohsome_ids <- setdiff(ohsome_ids,dodgr_ids)
# 
# ohsome_only <-
#   streetnet_ohsome_latest_mini %>% sf::st_drop_geometry() %>%
#   anti_join(streetnet_dodgr_latest_mini %>% sf::st_drop_geometry(), by = join_by(osm_id))
# 
# dodgr_only <-
#   streetnet_dodgr_latest_mini %>% sf::st_drop_geometry() %>%
#   anti_join(streetnet_ohsome_latest_mini %>% sf::st_drop_geometry(), by = join_by(osm_id))
