
# Set a default if no file is passed
CONFIG_FILE ?= configs/defaultconfig.mk

# Dynamically include the configuration file
include $(CONFIG_FILE)

include vars.mk
include .env

.PHONY: all \
        raw_prism \
		acs \
		crs \
		boundary_maps \
		boundary_map_plots \
		processed_prism \
		grocery \
		streetnet \
		streetnet_products\
		distance_to_grocery\
		collect_data \
		check-missing \
		check-names \
		configtest

all: configtest real_feel acs boundary_map_plots

real_feel: $(OUTPUT_DIR)/real_feel_distance_to_grocery/$(CITY_FILE_SAFE)_$(YEAR)/$(REAL_FEEL_MODEL_LABEL)_$(CITY_YEAR_OUTPUT_FILENAME)
collect_data: $(OUTPUT_DIR)/collected_data/$(CITY_FILE_SAFE)_$(YEAR)/$(REAL_FEEL_MODEL_LABEL)_$(CITY_YEAR_OUTPUT_FILENAME)
distance_to_grocery: $(OUTPUT_DIR)/distance_to_grocery/$(CITY_YEAR_OUTPUT_FILENAME)
streetnet_products: $(OUTPUT_DIR)/street_network_products/$(CITY_YEAR_OUTPUT_FILENAME)
streetnet: $(OUTPUT_DIR)/street_network/$(CITY_YEAR_OUTPUT_STREETNET_PARQUET) 
grocery: $(OUTPUT_DIR)/grocery/$(CITY_YEAR_OUTPUT_FILENAME)
processed_prism: $(ALL_PROCESSED_PRISM_FILE_PATHS)
boundary_map_plots: $(OUTPUT_DIR)/boundary_map_plots/$(CITY_YEAR_OUTPUT_FILENAME)
boundary_maps: $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME)
crs: $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME)
acs: $(OUTPUT_DIR)/acs_data/$(YEAR_OUTPUT_ACS_CODEBOOK_PARQUET) $(OUTPUT_DIR)/acs_data/$(STATE_YEAR_OUTPUT_ACS_PARQUET) $(OUTPUT_DIR)/acs_data/$(STATE_YEAR_OUTPUT_ACS_ESTIMATES_PARQUET)
raw_prism: $(ALL_RAW_PRISM_FILE_PATHS)

# 06 calculate real feel distance 
# file dependencies: collected data
$(OUTPUT_DIR)/real_feel_distance_to_grocery/$(CITY_FILE_SAFE)_$(YEAR)/$(REAL_FEEL_MODEL_LABEL)_$(CITY_YEAR_OUTPUT_FILENAME): src/06_get_real_feel_distance_to_grocery.R src/utils/utils.R $(OUTPUT_DIR)/collected_data/$(CITY_FILE_SAFE)_$(YEAR)/$(REAL_FEEL_MODEL_LABEL)_$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/real_feel_distance_to_grocery/$(CITY_FILE_SAFE)_$(YEAR)
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(OUTPUT_DIR) $(REAL_FEEL_MODEL_LABEL)

# 05 collect distance to grocery and base environmental data that are directly used in real feel calc or used to calculate calculated environmental data that are used in real feel calc 
# file dependencies: distance to grocery, processed prism data (if/when other sources added this should be changed to all processed environmental data)
$(OUTPUT_DIR)/collected_data/$(CITY_FILE_SAFE)_$(YEAR)/$(REAL_FEEL_MODEL_LABEL)_$(CITY_YEAR_OUTPUT_FILENAME): src/05_get_collected_data.R src/utils/utils_get_collected.R src/utils/utils.R $(OUTPUT_DIR)/distance_to_grocery/$(CITY_YEAR_OUTPUT_FILENAME) $(ALL_PROCESSED_PRISM_FILE_PATHS)
	mkdir -p $(OUTPUT_DIR)/collected_data/$(CITY_FILE_SAFE)_$(YEAR)
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(OUTPUT_DIR) "$(REAL_FEEL_VARS_BASE)" "$(REAL_FEEL_VARS_TO_CALCULATE)" $(REAL_FEEL_MODEL_LABEL)

# 04 get distance to grocery
$(OUTPUT_DIR)/distance_to_grocery/$(CITY_YEAR_OUTPUT_FILENAME): src/04_get_distance_to_grocery.R src/utils/utils_get_distance.R src/utils/utils.R $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/grocery/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/street_network_products/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/distance_to_grocery
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)

# 03b get streetnet products
$(OUTPUT_DIR)/street_network_products/$(CITY_YEAR_OUTPUT_FILENAME): src/03b_get_streetnet_products.R src/utils/utils.R $(OUTPUT_DIR)/street_network/$(CITY_YEAR_OUTPUT_STREETNET_PARQUET) 
	mkdir -p $(OUTPUT_DIR)/street_network_products
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY) 

# 03 get streetnet - file dependencies: crs, boundary maps
$(OUTPUT_DIR)/street_network/$(CITY_YEAR_OUTPUT_STREETNET_PARQUET): src/03_get_streetnet.R src/utils/utils_get_streetnet.R src/utils/utils.R $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME) 
	mkdir -p $(OUTPUT_DIR)/street_network
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY) $(STREETNET_DATETIME) $(OSM_OVERPASS_API_TIMEOUT) $(OSM_OVERPASS_API_ENDPOINT)
# 	mkdir -p $(OUTPUT_DIR)/street_network/street_network_created
# 	touch -a $(OUTPUT_DIR)/street_network/street_network_created/$(CITY_FILE_SAFE)_streetnetwork_created.txt

# 03 get grocery - file dependencies: crs, boundary maps (not currently using boundary maps dependency but if generalized it will)
$(OUTPUT_DIR)/grocery/$(CITY_YEAR_OUTPUT_FILENAME): src/03_process_raw_grocery_data/process_raw_grocery_$(CITY_FILE_SAFE)_$(YEAR).R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/grocery
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)

# 03 get processed prism - file dependencies: crs, boundary maps, raw prism data
ifneq ($(PRISM_VARS),)

$(ALL_PROCESSED_PRISM_FILE_PATHS): src/03_get_prism_data.R src/utils/utils_get_prism_data.R src/utils/utils.R $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME) $(ALL_RAW_PRISM_FILE_PATHS)
	mkdir -p $(OUTPUT_DIR)/environmental_data/$(CITY_FILE_SAFE)_$(YEAR)
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(OUTPUT_DIR) $(PRISM_DIR) "$(PRISM_VARS)"

endif

# 02b get boundary map plots
$(OUTPUT_DIR)/boundary_map_plots/$(CITY_YEAR_OUTPUT_FILENAME): src/02b_get_boundary_map_plots.R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/boundary_map_plots
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY) 

# 02 get boundary maps - file dependencies: crs
$(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME): src/02_get_boundary_maps.R src/utils/utils_get_boundary_maps.R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/boundary_maps
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)
# 	mkdir -p $(OUTPUT_DIR)/boundary_maps/boundary_maps_created
# 	touch -a $(OUTPUT_DIR)/boundary_maps/boundary_maps_created/$(CITY_FILE_SAFE)_boundary_maps_created.txt

# 01 get crs - no file dependencies
$(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME): src/01_get_crs.R src/utils/utils_get_crs.R src/utils/utils_shell.R src/utils/utils.R 
	mkdir -p $(OUTPUT_DIR)/crs
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)
# 	mkdir -p $(OUTPUT_DIR)/crs/crs_created
# 	touch -a $(OUTPUT_DIR)/crs/crs_created/$(CITY_FILE_SAFE)_crs_created.txt

# 01 get acs data - no file dependencies
$(OUTPUT_DIR)/acs_data/$(YEAR_OUTPUT_ACS_CODEBOOK_PARQUET) $(OUTPUT_DIR)/acs_data/$(STATE_YEAR_OUTPUT_ACS_PARQUET) $(OUTPUT_DIR)/acs_data/$(STATE_YEAR_OUTPUT_ACS_ESTIMATES_PARQUET): src/01_get_acs_data.R src/utils/utils.R 
	mkdir -p $(OUTPUT_DIR)/acs_data/$(STATE)_$(YEAR)
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(OUTPUT_DIR) $(CENSUS_API_KEY)

# 01 get raw prism data, only if prism vars is a non-empty list - no file dependencies
ifneq ($(PRISM_VARS),)

$(ALL_RAW_PRISM_FILE_PATHS): src/01_get_raw_prism_data.R src/utils/utils.R 
	mkdir -p $(PRISM_DIR)
	$(R_SCRIPT) $< $(YEAR) $(PRISM_DIR) "$(PRISM_VARS)"

endif

check-missing:
	@echo "Checking for missing files..."
	@echo "Missing targets: $(filter-out $(wildcard $(ALL_RAW_PRISM_FILE_PATHS)),$(ALL_RAW_PRISM_FILE_PATHS))"

check-names:
	@echo "Checking for processed prism file names..."
	@echo "File names: $(ALL_PROCESSED_PRISM_FILE_PATHS)"

configtest:
	@echo "Running with configuration from $(CONFIG_FILE)"

