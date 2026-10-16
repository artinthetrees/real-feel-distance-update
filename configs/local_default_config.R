city_string <- "Chicago"
county_string <- "Cook"
state_strin <- "IL"
year_num <- 2020
output_dir <- "data"

streetnet_datetime <- "2026-06-16T00:00:00Z"
osm_overpass_api_timeout <- 60
osm_overpass_api_endpoint <- "https://overpass-api.de/api/interpreter"

year_string <- as.character(year_num)
prism_dir <- "raw_prism_data"
prism_vars <- list("tmax","tdmean")

real_feel_model_label <- "prism_heatindex"
real_feel_vars_base <- list("temp from prism_tmax","dewpointtemp from prism_tdmean","")
real_feel_vars_to_calculate <-list("heatindex from temp dewpointtemp","") 
