###########################################
STATE = IL
COUNTY = Cook
CITY = Chicago
YEAR = 2019
###########################################

###########################################
# other option is NAD83; use WGS84 when using dodgr
CRS_DATUM = WGS84 
###########################################

###########################################
OUTPUT_DIR = ./data/
###########################################

###########################################
OUTPUT_FILE_EXT = Rdata
###########################################


CITY_YEAR_OUTPUT_FILENAME = $(CITY)_$(YEAR).$(OUTPUT_FILE_EXT)
CITY_OUTPUT_FILENAME = $(CITY).$(OUTPUT_FILE_EXT)


