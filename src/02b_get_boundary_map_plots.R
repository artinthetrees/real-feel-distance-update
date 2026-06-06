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
# source utils & load libraries specific to this script
library(ggplot2)
library(patchwork)

#################################################################
# create output file path specific to this script

output_path <- Gmisc::pathJoin(output_dir,"boundary_map_plots",city_year_output_fname)
print(output_path)

#################################################################
# pull in objs needed from previous parts of pipeline for this step

crs_utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_utm)
print(crs_utm)

city.utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"boundary_maps",city_year_output_fname),obj_name = city.utm)
city.2km.buffer.utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"boundary_maps",city_year_output_fname),obj_name = city.2km.buffer.utm)

counties.within.city.2km.buffer.utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"boundary_maps",city_year_output_fname),obj_name = counties.within.city.2km.buffer.utm)
tracts.within.city.2km.buffer.utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"boundary_maps",city_year_output_fname),obj_name = tracts.within.city.2km.buffer.utm)

#################################################################
# work for this step

my_font_size = 10

# raw plots - counties overview
counties.within.city.2km.buffer.plot <- 
  ggplot() +
  geom_sf(data=counties.within.city.2km.buffer.utm, aes(fill=STUSPS)) +
  geom_sf_text(data=counties.within.city.2km.buffer.utm, aes(label=NAME),colour = "white",size=my_font_size/.pt) +
  coord_sf(datum=sf::st_crs(city.utm)) +
  theme_void() +
  theme(legend.position = "none")

counties.within.city.2km.buffer.plus.city.plot <- 
  ggplot() +
  geom_sf(data=counties.within.city.2km.buffer.utm, aes(fill=STUSPS)) +
  geom_sf(data=city.utm) +
  geom_sf_text(data=city.utm, aes(label=NAME),size=my_font_size/.pt) +
  coord_sf(datum=sf::st_crs(city.utm)) +
  theme_void() +
  labs(fill="State")

# raw plots - tracts overview
tracts.within.city.2km.buffer.plus.city.plot.0 <- 
  ggplot() +
  geom_sf(data=counties.within.city.2km.buffer.utm, fill=NA) +
  geom_sf(data=tracts.within.city.2km.buffer.utm, aes(fill=STUSPS)) +
  geom_sf(data=city.utm,alpha=0.5,color=NA) +
  geom_sf_text(data=city.utm, aes(label=NAME),size=my_font_size/.pt) +
  coord_sf(datum=sf::st_crs(city.utm)) +
  theme_void() +
  labs(fill="State")

tracts.within.city.2km.buffer.plus.city.plot.1 <- 
  ggplot() +
  geom_sf(data=tracts.within.city.2km.buffer.utm, aes(fill=STUSPS)) +
  geom_sf(data=city.2km.buffer.utm, fill=NA, color="blue") +
  geom_sf(data=city.utm,alpha=0.5,color=NA) +
  geom_sf_text(data=city.utm, aes(label=NAME),size=my_font_size/.pt) +
  coord_sf(datum=sf::st_crs(city.utm)) +
  theme_void() +
  labs(fill="State")

tracts.within.city.2km.buffer.plus.city.plot.2 <- 
  ggplot() +
  geom_sf(data=tracts.within.city.2km.buffer.utm, aes(fill=NAMELSADCO)) +
  geom_sf(data=city.2km.buffer.utm, fill=NA, color="blue") +
  geom_sf(data=city.utm,alpha=0.5,color=NA) +
  geom_sf_text(data=city.utm, aes(label=NAME),size=my_font_size/.pt) +
  coord_sf(datum=sf::st_crs(city.utm)) +
  theme_void() +
  labs(fill="County")

# final plots - counties overview
counties.overview.plot <- 
  counties.within.city.2km.buffer.plot +
  counties.within.city.2km.buffer.plus.city.plot +
  plot_annotation(
    tag_levels = "A"
  )

# final plots - tracts overview
tracts.overview.plot <- 
  tracts.within.city.2km.buffer.plus.city.plot.0 +
  tracts.within.city.2km.buffer.plus.city.plot.1 +
  tracts.within.city.2km.buffer.plus.city.plot.2 +
  plot_annotation(
    tag_levels = "A"
  )

#################################################################
# save for this step

save(
  counties.overview.plot,
  tracts.overview.plot,
  counties.within.city.2km.buffer.plot,
  counties.within.city.2km.buffer.plus.city.plot,
  tracts.within.city.2km.buffer.plus.city.plot.0,
  tracts.within.city.2km.buffer.plus.city.plot.1,
  tracts.within.city.2km.buffer.plus.city.plot.2,
  file = output_path
)

#################################################################
# clean up workspace - remove any objs created during this step
if(interactive()){
  rm(list = setdiff(ls(),ws_objs))
}
  
#################################################################








