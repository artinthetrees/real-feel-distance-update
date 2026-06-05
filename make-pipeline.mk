
# Set a default if no file is passed
CONFIG_FILE ?= configs/defaultconfig.mk

# Dynamically include the configuration file
include $(CONFIG_FILE)

include vars.mk
include .env

.PHONY: configtest

# 02 get boundary maps

# 01 get crs
$(OUTPUT_DIR)/crs/$(CITY_YEAR_OUTPUT_FILENAME): src/01_get_crs.R src/utils/utils_get_crs.R 
	mkdir -p $(OUTPUT_DIR)/crs
	$(R_SCRIPT) $< $(COUNTY) $(STATE) $(YEAR) $(CRS_DATUM) $(OUTPUT_DIR) $(CITY_YEAR_OUTPUT_FILENAME) $(CENSUS_API_KEY)

configtest:
	@echo "Running with configuration from $(CONFIG_FILE)"

