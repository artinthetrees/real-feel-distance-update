
# Set a default if no file is passed
CONFIG_FILE ?= configs/defaultconfig.mk

# Dynamically include the configuration file
include $(CONFIG_FILE)

include vars.mk
include .env

.PHONY: all boundary boundaryplots grocery configtest

all: configtest crs boundary_maps boundary_map_plots grocery streetnet

streetnet: $(OUTPUT_DIR)/street_network/$(CITY_YEAR_OUTPUT_STREETNET_PARQUET) $(OUTPUT_DIR)/street_network/$(CITY_YEAR_OUTPUT_FILENAME)
#distance_to_grocery: $(OUTPUT_DIR)/distance_to_grocery/$(CITY_YEAR_OUTPUT_FILENAME)
grocery: $(OUTPUT_DIR)/grocery/$(CITY_YEAR_OUTPUT_FILENAME)
boundary_map_plots: $(OUTPUT_DIR)/boundary_map_plots/$(CITY_YEAR_OUTPUT_FILENAME)
boundary_maps: $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME)
crs: $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME)

# 03 get streetnet
$(OUTPUT_DIR)/street_network/$(CITY_YEAR_OUTPUT_STREETNET_PARQUET) $(OUTPUT_DIR)/street_network/$(CITY_YEAR_OUTPUT_FILENAME): src/03_get_streetnet.R src/utils/utils_get_streetnet.R src/utils/utils.R $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME) 
	mkdir -p $(OUTPUT_DIR)/street_network
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY) $(STREETNET_DATETIME) $(OSM_OVERPASS_API_TIMEOUT) $(OSM_OVERPASS_API_ENDPOINT)
# 	mkdir -p $(OUTPUT_DIR)/street_network/street_network_created
# 	touch -a $(OUTPUT_DIR)/street_network/street_network_created/$(CITY_FILE_SAFE)_streetnetwork_created.txt

# # 04 get distance to grocery
# $(OUTPUT_DIR)/distance_to_grocery/$(CITY_YEAR_OUTPUT_FILENAME): src/04_get_distance_to_grocery.R src/utils/utils_get_streetnet.R src/utils/utils_get_distance.R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/grocery/$(CITY_YEAR_OUTPUT_FILENAME)
# 	mkdir -p $(OUTPUT_DIR)/distance_to_grocery
# 	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)

# 03 get grocery
$(OUTPUT_DIR)/grocery/$(CITY_YEAR_OUTPUT_FILENAME): src/03_process_raw_grocery_data/process_raw_grocery_$(CITY_FILE_SAFE)_$(YEAR).R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/grocery
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)

# 02b get boundary map plots
$(OUTPUT_DIR)/boundary_map_plots/$(CITY_YEAR_OUTPUT_FILENAME): src/02b_get_boundary_map_plots.R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/boundary_map_plots
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY) 

# 02 get boundary maps
$(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME): src/02_get_boundary_maps.R src/utils/utils_get_boundary_maps.R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/boundary_maps
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)
# 	mkdir -p $(OUTPUT_DIR)/boundary_maps/boundary_maps_created
# 	touch -a $(OUTPUT_DIR)/boundary_maps/boundary_maps_created/$(CITY_FILE_SAFE)_boundary_maps_created.txt

# 01 get crs
$(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME): src/01_get_crs.R src/utils/utils_get_crs.R src/utils/utils_shell.R src/utils/utils.R 
	mkdir -p $(OUTPUT_DIR)/crs
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)
# 	mkdir -p $(OUTPUT_DIR)/crs/crs_created
# 	touch -a $(OUTPUT_DIR)/crs/crs_created/$(CITY_FILE_SAFE)_crs_created.txt

configtest:
	@echo "Running with configuration from $(CONFIG_FILE)"

