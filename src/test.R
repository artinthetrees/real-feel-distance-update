output_dir <- "data"
city_year_output_fname <- "Chicago_2020.Rdata"

source("src/utils/utils.R")
source("./src/utils/utils_get_streetnet.R")

tracts.within.city.utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"boundary_maps",city_year_output_fname),obj_name = tracts.within.city.utm)
#ggplot2::ggplot() + ggplot2::geom_sf(data=tracts.within.city.utm)

crs_utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_utm)
crs_lonlat <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_lonlat)

print(crs_utm)
print(crs_lonlat)

my_tract.utm <- 
  tracts.within.city.utm %>%
  dplyr::filter(NAME==1604)
#ggplot2::ggplot() + ggplot2::geom_sf(data=tracts.within.city.utm) + ggplot2::geom_sf(data=my_tract.utm,fill="red")

my_tract.2km.buffer.utm <- 
  sf::st_buffer(my_tract.utm, dist = 2000)
#ggplot2::ggplot() + ggplot2::geom_sf(data=my_tract.2km.buffer.utm) + ggplot2::geom_sf(data=my_tract.utm,fill="red")

boundary.utm <- my_tract.2km.buffer.utm
#################################################################
# work for this step

boundary.lonlat <- boundary.utm %>% sf::st_transform(crs=crs_lonlat)

# create bounding box vector of coordinates from boundary lonlat sf - named vector in xmin, ymin, xmax, ymax order
sf_bb <- sf::st_bbox(boundary.lonlat)

# convert bounding box vector of coordinates to sf >> input to ohsome streetnet fx
sf_bb_to_sf <- bbox_coords_to_sf(bbox_coords = sf_bb,crs=crs_lonlat)

# ggplot2::ggplot() + ggplot2::geom_sf(data=sf_bb_to_sf) + ggplot2::geom_sf(data=boundary.lonlat)

# convert bounding box vector of coordinates to osmdata bounding box matrix format >> input to dodgr streetnet fx
sf_bb_to_osmdata_bb <- bbox_coords_to_osmdata_bb(bbox_coords = sf_bb)

streetnet_query_date <- Sys.Date()
streetnet_sf.lonlat <- get_streetnet_sf_dodgr(osmdata_bb = sf_bb_to_osmdata_bb, expand = 0)

graph <- dodgr::weight_streetnet (streetnet_sf.lonlat, wt_profile = "foot")

v <- dodgr::dodgr_vertices (graph)

# https://urbananalyst.github.io/dodgr/articles/dodgr.html

# https://urbananalyst.github.io/dodgr/reference/write_dodgr_wt_profile.html
dodgr::write_dodgr_wt_profile(file = "configs/dodgr_weights.json")
