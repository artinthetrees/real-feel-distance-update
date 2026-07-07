###########################################
STATE:= IL
COUNTY:= Cook
CITY:= Chicago
YEAR:=  2020
###########################################

###########################################
PRISM_VARS:= tmax tdmean
PRISM_DIR:= raw_prism_data
#ALL_PRISM_FILE_TYPES:= bil bil.aux.xml hdr info.txt prj stx xml
ALL_PRISM_FILE_TYPES:= bil 
###########################################

###########################################
STREETNET_DATETIME:= 2026-06-16T00:00:00Z
#STREETNET_DATETIME:= $(YEAR)-06-15T00:00:00Z
OSM_OVERPASS_API_TIMEOUT:= 60
OSM_OVERPASS_API_ENDPOINT:= https://overpass-api.de/api/interpreter
###########################################

###########################################
# other option is NAD83; use WGS84 when using dodgr
CRS_DATUM:= WGS84 
###########################################

###########################################
OUTPUT_DIR:= data
###########################################

###########################################
OUTPUT_FILE_EXT:= Rdata
###########################################

underscore:= _
empty:=
space:= $(empty) $(empty)

CITY_FILE_SAFE:= $(subst $(space),$(underscore),$(CITY))
COUNTY_FILE_SAFE:= $(subst $(space),$(underscore),$(COUNTY))

$(info    city_file_safe is $(CITY_FILE_SAFE))
$(info    county_file_safe is $(COUNTY_FILE_SAFE))

CITY_YEAR_OUTPUT_FILENAME:= $(CITY_FILE_SAFE)_$(YEAR).$(OUTPUT_FILE_EXT)
CITY_OUTPUT_FILENAME:= $(CITY_FILE_SAFE).$(OUTPUT_FILE_EXT)

# CITY_YEAR_OUTPUT_FILENAME_PARQUET:= $(CITY_FILE_SAFE)_$(YEAR).parquet
# CITY_OUTPUT_FILENAME_PARQUET:= $(CITY_FILE_SAFE).parquet

CITY_YEAR_OUTPUT_STREETNET_PARQUET:= $(CITY_FILE_SAFE)_$(YEAR)_streetnet.parquet

YEAR_OUTPUT_ACS_CODEBOOK_PARQUET:= $(YEAR)_acs5_codebook.parquet
STATE_YEAR_OUTPUT_ACS_PARQUET:= $(STATE)_$(YEAR)/$(STATE)_$(YEAR)_acs5.parquet
STATE_YEAR_OUTPUT_ACS_ESTIMATES_PARQUET:= $(STATE)_$(YEAR)/$(STATE)_$(YEAR)_acs5_estimates.parquet


ifneq ($(PRISM_VARS),)
# Generates dates dynamically from jan 1 to dec 31 of the year specified
ALL_DATES:= $(shell seq 1 366 | xargs -I {} date -d "$(YEAR)-01-01 + {} days - 1 day" "+%Y%m%d" 2>/dev/null | grep "^$(YEAR)")

# Nested foreach
ALL_RAW_PRISM_FILE_PATHS:= $(foreach prism_var,$(PRISM_VARS), \
              $(foreach date,$(ALL_DATES), \
			      $(foreach file_type,$(ALL_PRISM_FILE_TYPES), \
                    $(PRISM_DIR)/prism_$(prism_var)_us_30s_$(date)/prism_$(prism_var)_us_30s_$(date).$(file_type) \
				  ) \
              ) \
            )

# Nested foreach
ALL_PROCESSED_PRISM_FILE_PATHS:= $(foreach prism_var,$(PRISM_VARS),$(OUTPUT_DIR)/environmental_data/$(CITY_FILE_SAFE)_$(YEAR)/prism_$(prism_var)_$(CITY_YEAR_OUTPUT_FILENAME))				 
              
            

$(info    prism_vars is $(PRISM_VARS))
#$(info    all_raw_prism_file_paths is $(ALL_RAW_PRISM_FILE_PATHS))

# Set N (e.g., print the first 3 items)
N := 25
# Prints the list elements to the console during execution
$(info First $(N) items of all_raw_prism_file_paths: $(wordlist 1, $(N), $(ALL_RAW_PRISM_FILE_PATHS)))
$(info all_processed_prism_file_paths: $(ALL_PROCESSED_PRISM_FILE_PATHS))
$(info city year output filename: $(CITY_YEAR_OUTPUT_FILENAME))
endif