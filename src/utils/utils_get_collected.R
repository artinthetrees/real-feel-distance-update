source("./src/utils/utils.R")
library(tidyverse)

collect_environmental_data_var <- function(base_var,source_var,summary_distances_df,collect_data_df,year_string,output_dir,city_year_output_fname_base){

    # collect the data for each base var only if not already collected
    if ((!is.null(collect_data_df)) && (base_var %in% names(collect_data_df))){
      message("base var ",base_var," already collected, skipping collection..")
    } else {
      message("base var ",base_var," not already collected, collecting..")

      source_var_parse <- stringr::str_split(source_var, "_", n = 2)[[1]]
      source_var_source_string <- source_var_parse[[1]]

      # pull in data for base var needed for calculated var
      source_var_fname <- Gmisc::pathJoin(output_dir,"environmental_data",city_year_output_fname_base,paste0(source_var,"_",city_year_output_fname_base,".Rdata"))
      if (source_var_source_string == "prism"){
        by_tract <- get_obj_from_rdata(rdata_file_path = source_var_fname,obj_name = prism_by_boundary.aw_mean.df)
      } 
      
      by_tract$tract_id <- as.integer(rownames(by_tract))
      by_tract <- by_tract %>% select(tract_id,everything())
      by_tract_long <- pivot_longer(by_tract, cols = starts_with(year_string), names_to = "date", values_to = base_var)

      if (is.null(collect_data_df)){
      
        collect_data_df <- 
          summary_distances_df %>%
          right_join(.,
                    by_tract_long,
                    by = c("tract_id" = "tract_id")) 
        
      } else {
        
        collect_data_df <- 
          collect_data_df %>%
          left_join(.,
                    by_tract_long,
                    by = c("tract_id" = "tract_id","date" = "date")) 
        
      }
    }

    return(collect_data_df)

}

calculate_environmental_data_var_heatindex <- function(collect_df,temp_var="temp",dewpointtemp_var="dewpointtemp",temp_measured_in="celsius",...){
    collect_data_df <- 
    collect_data_df %>%
    mutate(heatindex = weathermetrics::heat.index(t = .data[[temp_var]],
                                                    dp = .data[[dewpointtemp_var]], 
                                                    temperature.metric = "celsius", 
                                                    output.metric = "celsius"),
            temp_f = weathermetrics::celsius.to.fahrenheit(.data[[temp_var]], round = 2),
            dewpointtemp_f = weathermetrics::celsius.to.fahrenheit(.data[[dewpointtemp_var]], round = 2),
            heatindex_f = weathermetrics::heat.index(t = temp_f,
                                                    dp = dewpointtemp_f, 
                                                    temperature.metric = "fahrenheit", 
                                                    output.metric = "fahrenheit"),
            heatindex_invalid = ifelse(.data[[temp_var]] < 27 | .data[[dewpointtemp_var]] < 12,1,0)
            )
    
    return(collect_data_df)

}