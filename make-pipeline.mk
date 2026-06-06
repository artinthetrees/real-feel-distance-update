
# Set a default if no file is passed
CONFIG_FILE ?= configs/defaultconfig.mk

# Dynamically include the configuration file
include $(CONFIG_FILE)

include vars.mk
include .env

.PHONY: configtest

# 02b get boundary map plots
$(OUTPUT_DIR)/boundary_map_plots/$(CITY_YEAR_OUTPUT_FILENAME): src/02b_get_boundary_map_plots.R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME) $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/boundary_map_plots
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY) 

# 02 get boundary maps
$(OUTPUT_DIR)/boundary_maps/$(CITY_YEAR_OUTPUT_FILENAME): src/02_get_boundary_maps.R src/utils/utils_get_boundary_maps.R src/utils/utils_shell.R src/utils/utils.R $(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME)
	mkdir -p $(OUTPUT_DIR)/boundary_maps
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)

# 01 get crs
$(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME): src/01_get_crs.R src/utils/utils_get_crs.R src/utils/utils_shell.R src/utils/utils.R 
	mkdir -p $(OUTPUT_DIR)/crs
	$(R_SCRIPT) $< $(CITY) $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CENSUS_API_KEY)

configtest:
	@echo "Running with configuration from $(CONFIG_FILE)"

