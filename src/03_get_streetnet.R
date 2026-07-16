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
    streetnet_datetime <- commandArgs(trailingOnly=TRUE)[[8]]
    osm_overpass_api_timeout <- as.numeric(commandArgs(trailingOnly=TRUE)[[9]])
    osm_overpass_api_endpoint <- commandArgs(trailingOnly=TRUE)[[10]]
    message("city is: ", city_string)
    message("county is: ", county_string)
    message("state is: ", state_string)
    message("year is: ", year_num)
    message("crs datum is: ", crs_datum)
    message("output dir is: ", output_dir)
    message("census api key is: ", census_api_key)
    message("streetnet datetime: ", streetnet_datetime)
    message("osm overpass api timeout: ", osm_overpass_api_timeout)
    message("osm overpass api endpoint: ", osm_overpass_api_endpoint)
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
source("./src/utils/utils_get_streetnet.R")

#################################################################
# create output file path specific to this script

city_year_fname_streetnet <- paste0(city_year_output_fname_base,"_streetnet.parquet")
output_path_streetnet <- Gmisc::pathJoin(output_dir,"street_network",city_year_fname_streetnet)
print(output_path_streetnet)

# output_path <- Gmisc::pathJoin(output_dir,"street_network",city_year_output_fname)
# print(output_path)

#################################################################
# pull in objs needed from previous parts of pipeline for this step

crs_utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_utm)
crs_lonlat <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_lonlat)

print(crs_utm)
print(crs_lonlat)

boundary.utm <- 
  get_obj_from_rdata(
    rdata_file_path = Gmisc::pathJoin(output_dir,"boundary_maps",city_year_output_fname),
    obj_name = city.2km.buffer.utm
    )

#################################################################
# work for this step

boundary.lonlat <- boundary.utm %>% sf::st_transform(crs=crs_lonlat)

# create bounding box vector of coordinates from boundary lonlat sf - named vector in xmin, ymin, xmax, ymax order
sf_bb <- sf::st_bbox(boundary.lonlat)

# convert bounding box vector of coordinates to sf >> input to ohsome streetnet fx
#sf_bb_to_sf <- bbox_coords_to_sf(bbox_coords = sf_bb,crs=crs_lonlat)
# ggplot2::ggplot() + ggplot2::geom_sf(data=sf_bb_to_sf) + ggplot2::geom_sf(data=boundary.lonlat)

# convert bounding box vector of coordinates to osmdata bounding box matrix format >> input to dodgr streetnet fx
sf_bb_to_osmdata_bb <- bbox_coords_to_osmdata_bb(bbox_coords = sf_bb)

# streetnet_query_date <- Sys.Date()
# streetnet_sf.lonlat <- get_streetnet_sf_dodgr(osmdata_bb = sf_bb_to_osmdata_bb, expand = 0)

###############################################

api_endpoint <- osmdata::get_overpass_url()
osmdata::set_overpass_url(osm_overpass_api_endpoint)
api_endpoint <- osmdata::get_overpass_url()

###############################################

bb <- sf_bb_to_osmdata_bb

queue <- split_bbox (bb)
result <- list ()

while (length (queue) > 0) {
  
  print (queue [[1]])
  
  opres <- NULL
  opres <- try ({
    osmdata::opq (bbox = queue [[1]], datetime = streetnet_datetime, timeout = osm_overpass_api_timeout) |>
      osmdata::add_osm_feature (key = "highway") |>
      osmdata::osmdata_sf (quiet = FALSE)
  })
  
  if (class (opres) [1] != "try-error") {
    result <- append (result, list (opres))
    queue <- queue [-1]
  } else {
    message("splitting..")
    message("queue length before splitting: ",length(queue))
    bboxnew <- split_bbox (queue [[1]])
    queue <- append (bboxnew, queue [-1])
    message("queue length after splitting, removing problematic bbox, adding splits of problematic bbox: ",length(queue))
    
  }
}

rm(list = setdiff(ls(), c("result","output_path_streetnet")))
#save(result, file = "my_data_result.Rdata")

result_final = list()
for (i in 1:length(result)) {
  print(i)
  print(nrow(result[[i]]$osm_lines))
  interim <- osmdata::osm_poly2line(result[[i]])
  print(nrow(interim$osm_lines))
  result_final[[i]] <- interim$osm_lines
}
rm(list = setdiff(ls(), c("result_final","output_path_streetnet")))

result_sf_with_dup <- dplyr::bind_rows(result_final)
print(nrow(result_sf_with_dup))

result_sf_without_dup <- result_sf_with_dup |> dplyr::distinct()
print(nrow(result_sf_without_dup))

#save(result_sf_without_dup, file = "my_data_result_sf_without_dup.RData")

################################################################################
# save 1 for this step as parquet
sfarrow::st_write_parquet(obj = result_sf_without_dup, dsn = output_path_streetnet)
#hi <- sfarrow::st_read_parquet("./my_data_result_sf_without_dup_parquet.parquet")

# #################################################################
# # additional work
# rm(list = setdiff(ls(), c("result_sf_without_dup","output_path")))
# streetnet_weighted <- dodgr::weight_streetnet(result_sf_without_dup, wt_profile = "foot")

# streetnet_vertices <- dodgr::dodgr_vertices (streetnet_weighted)

# #################################################################
# # save 2 for this step as Rdata

# save(
#   streetnet_weighted,
#   streetnet_vertices,
#   file = output_path
# )

#################################################################
# save for this step

# save(
#   sf_bb,
#   sf_bb_to_sf,
#   sf_bb_to_osmdata_bb,
#   streetnet_query_date,
#   streetnet_sf.lonlat,
#   file = output_path
# )

#################################################################
# clean up workspace - remove any objs created during this step
if(interactive()){
  rm(list = ls())
  source("./local_default_config.R")
}
  
#################################################################


