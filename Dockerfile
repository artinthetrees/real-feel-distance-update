# Use the official rocker geospatial image as a base
# Includes R, RStudio, tidyverse, GDAL, PROJ, GEOS, and key spatial packages
FROM rocker/geospatial:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Disable renv cache to force physical installation inside the image
ENV RENV_CONFIG_USE_CACHE=false

# Install additional system dependencies if needed (e.g., for specialized R packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libnetcdf-dev \
    curl \
    libcurl4-openssl-dev \
    libabsl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install GNU Make and compiler utilities 
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install specific R packages for spatial analysis
RUN install2.r --error \
    sf \
    terra \
    raster \
    stars \
    leaflet \
    mapview \
    rayshader \
    spatial \
    spatstat \
    gstat \
    tidyverse \
    renv \
    && rm -rf /tmp/downloaded_packages

# Default RStudio username/password is set by the rocker base image
# (usually rstudio / password in the console)