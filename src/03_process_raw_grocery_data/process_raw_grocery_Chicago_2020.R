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
library(dplyr)

#################################################################
# create output file path specific to this script

output_folder <- Gmisc::pathJoin(output_dir,"grocery")
output_path <- Gmisc::pathJoin(output_dir,"grocery",city_year_output_fname)
print(output_path)

if (!dir.exists(output_folder)) {
  dir.create(output_folder)
}

#################################################################
# pull in objs needed from previous parts of pipeline for this step

crs_utm <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_utm)
crs_lonlat <- get_obj_from_rdata(rdata_file_path = Gmisc::pathJoin(output_dir,"crs",city_year_output_fname),obj_name = crs_lonlat)

print(crs_utm)
print(crs_lonlat)

#################################################################
# work for this step

city_year_file_safe <- get_city_year_output_filename(city_string=city_string,year_num=year_num,save_file_type=NULL)
message("city year file safe string is: ", city_year_file_safe)

raw_data_folder_path <- Gmisc::pathJoin("raw_grocery_data",city_year_file_safe)
message("raw data folder path is: ", raw_data_folder_path)

if (dir.exists(raw_data_folder_path)) {

  # Bring in points
  grocery_1.df <- read.csv(Gmisc::pathJoin(raw_data_folder_path,"Grocery_Store_Status.csv"), stringsAsFactors = FALSE)
  grocery_1.df$Longitude <- as.numeric(sapply(grocery_1.df$Location, function(x) strsplit(strsplit(x," ")[[1]][2],"\\(")[[1]][2]))
  grocery_1.df$Latitude <- as.numeric(sapply(grocery_1.df$Location, function(x) strsplit(strsplit(x," ")[[1]][3],"\\)")[[1]][1]))

  grocery_2.df <- read.csv(Gmisc::pathJoin(raw_data_folder_path,"Nearby_Cook_County_Grocery_Store_Chains.csv"), stringsAsFactors = FALSE)
  grocery_2.df$Address <- sapply(grocery_2.df$LOCATION, function(x) stringr::str_trim(strsplit(x,"\\(")[[1]][1]))
  grocery_2.df$LongLat <- sapply(grocery_2.df$LOCATION, function(x) strsplit(x,"\\(")[[1]][2])
  grocery_2.df$Longitude <- as.numeric(sapply(grocery_2.df$LongLat, function(x) strsplit(strsplit(x," ")[[1]][2],"\\)")[[1]][1]))
  grocery_2.df$Latitude <- as.numeric(sapply(grocery_2.df$LongLat, function(x) strsplit(x,",")[[1]][1]))

  grocery_3.df <- read.csv(Gmisc::pathJoin(raw_data_folder_path,"Nearby_Independent_Cook_County_Grocery_Stores.csv"), stringsAsFactors = FALSE)
  grocery_3.df$Longitude <- as.numeric(sapply(grocery_3.df$LOCATION, function(x) strsplit(strsplit(x," ")[[1]][2],"\\)")[[1]][1]))
  grocery_3.df$Latitude <- as.numeric(sapply(grocery_3.df$LOCATION, function(x) strsplit(strsplit(x,",")[[1]][1],"\\(")[[1]][2]))

  grocery.df <-
    rbind(grocery_1.df %>% dplyr::select(Longitude,Latitude) %>% mutate(group = "chicago"),
          grocery_2.df %>% dplyr::select(Longitude,Latitude) %>% mutate(group = "cook"),
          grocery_3.df %>% dplyr::select(Longitude,Latitude) %>% mutate(group = "cook"))

  # check to make sure that the as.numeric didn't actually round the lat/longs
  # print(grocery.df$Longitude, digits = 20)

  # clean any points without long/lat
  grocery.df <- grocery.df %>% filter(!is.na(Longitude))

  # "+proj=utm +zone=16N +datum=WGS84"

  # set a crs for the grocery lat/long coordinates
  grocery.sf.lonlat <- 
    sf::st_as_sf(grocery.df, coords = c("Longitude", "Latitude"), crs = crs_lonlat)

  # check that the crs was set and check the units (will be null for longlat projection)
  sf::st_crs(grocery.sf.lonlat)$proj4string
  sf::st_crs(grocery.sf.lonlat)$units

  # convert crs to use utm which measures distance in meters, use zone 16N for chicago
  grocery.sf.utm <- 
    sf::st_transform(grocery.sf.lonlat,
                crs = crs_utm) 

  # check that the crs was set and check the units (will be meters for utm projection)
  sf::st_crs(grocery.sf.utm)$proj4string
  sf::st_crs(grocery.sf.utm)$units

  #################################################################
  # save for this step

  save(
    grocery.df,
    grocery.sf.lonlat,
    grocery.sf.utm,
    file = output_path
  )

} else {
  print("the raw data folder for this city year does not exist: ")
  print(raw_data_folder_path)
  print("exiting..")
}



#################################################################
# clean up workspace - remove any objs created during this step
if(interactive()){
  rm(list = setdiff(ls(),ws_objs))
}

