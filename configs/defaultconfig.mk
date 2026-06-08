###########################################
STATE:= IL
COUNTY:= Cook
CITY:= Chicago
YEAR:=  2020
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


