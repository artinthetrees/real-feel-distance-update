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
source("./src/utils/utils_get_streetnet.R")
source("./src/utils/utils_get_distance.R")

#################################################################
# create output file path specific to this script
if (interactive()) {
  output_folder <- Gmisc::pathJoin(output_dir,"distance_to_grocery")
  if (!dir.exists(output_folder)) {
    dir.create(output_folder)
  }
}

output_path <- Gmisc::pathJoin(output_dir,"distance_to_grocery",city_year_output_fname)
print(output_path)

#################################################################
# pull in objs needed from previous parts of pipeline for this step

crs_utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_utm)
print(crs_utm)
crs_lonlat <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_lonlat)
print(crs_lonlat)

# streetnet_vertices <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"intermediate","street_network_products",city_output_fname),obj_name = v)
# streetnet_graph <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"intermediate","street_network_products",city_output_fname),obj_name = graph)

grocery.utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"grocery",city_year_output_fname),obj_name = grocery.sf.utm)
tracts.within.city.utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"boundary_maps",city_year_output_fname),obj_name = tracts.within.city.utm)

print(names(sf::st_geometry(tracts.within.city.utm)))

# to test/debug just use the first n tracts
tracts.within.city.utm <- tracts.within.city.utm[1:5, ]

print("tracts: ")
print(names(tracts.within.city.utm))
print(names(sf::st_geometry(tracts.within.city.utm)))

#################################################################
# work for this step

distances_df_list <- list()
summary_distances_df_list <- list()

for (i in 1:nrow(tracts.within.city.utm)){
  one_tract.utm <- tracts.within.city.utm[i,]
  print("one tract: ")
  print(names(one_tract.utm))
  print(names(sf::st_geometry(one_tract.utm)))
  
  tract_id <- i
  print(tract_id)

  print("hi 0")
  ################################### get streetnet, graph,and vertices for this tract plus 2km buffer
  ### get 2km buffer boundary
  one_tract.2km.buffer.utm <- sf::st_buffer(one_tract.utm, dist = 2000)
  ###
  print("hi 1")
  ### get bbox params appropriately formatted for dodgr_streetnet fx
  boundary.utm <- one_tract.2km.buffer.utm
  print("hi 2")
  boundary.lonlat <- boundary.utm %>% sf::st_transform(crs=crs_lonlat)
  print("hi 3")
  # create bounding box vector of coordinates from boundary lonlat sf - named vector in xmin, ymin, xmax, ymax order
  sf_bb <- sf::st_bbox(boundary.lonlat)
  print("hi 4")
  # convert bounding box vector of coordinates to osmdata bounding box matrix format >> input to dodgr streetnet fx
  sf_bb_to_osmdata_bb <- bbox_coords_to_osmdata_bb(bbox_coords = sf_bb)
  print("hi 5")
  ###

  ### get dodgr streetnet, graph, and vertices objects
  streetnet_query_date <- Sys.Date()
  
  streetnet_sf.lonlat <- get_streetnet_sf_dodgr(osmdata_bb = sf_bb_to_osmdata_bb, expand = 0)
  streetnet_graph <- dodgr::weight_streetnet (streetnet_sf.lonlat, wt_profile = "foot")
  streetnet_vertices <- dodgr::dodgr_vertices (streetnet_graph)
  ###
  ###################################


  my_distances <- 
    get_distances_df(
      one_tract_sf.utm = one_tract.utm,
      grocery_sf.utm = grocery.utm, 
      streetnet_vertices = streetnet_vertices, 
      streetnet_graph = streetnet_graph, 
      crs_lonlat = crs_lonlat, 
      crs_utm = crs_utm
    )
  
  if (my_distances$no_distances){ # this will happen if there are no from or to points
    
    distances_df <- 
      data.frame(
        tract_name=character(),
        tract_geoid=character(),
        no_distances=integer()
        )
    
    distances_df[1, ] <- c(
      my_distances$tract_name,
      my_distances$tract_geoid,
      1
      )
    
    distances_df$tract_id <- tract_id
    distances_df <- distances_df %>% select(tract_id,tract_name,tract_geoid,no_distances)
    
    summary_distances_df <- 
      data.frame(
        tract_name=character(),
        tract_geoid=character(),
        no_distances=integer()
      )
    
    summary_distances_df[1, ] <- c(
      my_distances$tract_name,
      my_distances$tract_geoid,
      1
    )
    summary_distances_df$tract_id <- tract_id  
    summary_distances_df <- summary_distances_df %>% select(tract_id,tract_name,tract_geoid,no_distances)
    
  } else {
    
    distances_df <- my_distances$distances_df 
    distances_df$no_distances <- 0
    distances_df$tract_id <- tract_id
    distances_df <- distances_df %>% select(tract_id,tract_name,tract_geoid,no_distances,everything())
    
    summary_distances_df <- my_distances$summary_distances_df 
    summary_distances_df$no_distances <- 0
    summary_distances_df$tract_id <- tract_id  
    summary_distances_df <- summary_distances_df %>% select(tract_id,tract_name,tract_geoid,no_distances,everything())
    
  }
  
  
  distances_df_list[[i]] <- distances_df
  summary_distances_df_list[[i]] <- summary_distances_df
  
  
}


summary_distances_df <- 
  data.table::rbindlist(summary_distances_df_list, 
                        use.names = TRUE,
                        fill = TRUE)




#################################################################
# save for this step

save(
  summary_distances_df,
  distances_df_list,
  file = output_path
)

#################################################################
# clean up workspace - remove any objs created during this step

rm(list = setdiff(ls(),ws_objs))

#################################################################


