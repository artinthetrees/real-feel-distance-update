# https://www.evan-soil.io/blog/ode-to-gnu-make/

# Define the image name and a hidden tracking file
IMAGE_NAME = rstudio-spatial
CONTAINER_NAME = rstudio-spatial-instance
BUILD_STAMP = .docker_build_stamp
RSTUDIO_PW = rstudiopw

.PHONY: all run stop clean

# Default target
all: run

# 1. Rebuild the image ONLY if the Dockerfile has changed
$(BUILD_STAMP): Dockerfile
	@echo "Dockerfile changed! Rebuilding image..."
	docker build -t $(IMAGE_NAME) .
	@touch $(BUILD_STAMP)

# 2. Re-create and run the container if the image was updated
run: $(BUILD_STAMP)
	@echo "Checking container status..."
	@if [ $$(docker ps -aq -f name=^$(CONTAINER_NAME)$$) ]; then \
		echo "Stopping and removing old container..."; \
		docker stop $(CONTAINER_NAME); \
		docker rm $(CONTAINER_NAME); \
	fi
	docker run -d --rm --name $(CONTAINER_NAME) -p 8787:8787 -e PASSWORD=$(RSTUDIO_PW) -v %cd%:/home/rstudio/project $(IMAGE_NAME)

# Helper target to manually stop the container
stop:
	@if [ $$(docker ps -aq -f name=^$(CONTAINER_NAME)$$) ]; then \
		docker stop $(CONTAINER_NAME); \
	fi

# Helper target to wipe out the stamp and container
clean: stop
	@if [ $$(docker ps -aq -f name=^$(CONTAINER_NAME)$$) ]; then \
		docker rm $(CONTAINER_NAME); \
	fi
	rm -f $(BUILD_STAMP)



