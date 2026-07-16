To run real-feel-distance pipeline in docker container

1. Make sure docker container is built correctly and up and running - this will check for if image already built and if any changes to Dockerfile since last build. 

- If image already built and no changes to Dockerfile, will run container from existing built image. 
- If image already built and changes to Dockerfile, will rebuild image, then check if container already running. If container is already running, will stop currently running container. Will run container from newly built image.
- If image not already built, will build image then run container from newly built image. 

```local-local shell 
make -f make-docker.mk 
```

2. Start interactive session in docker shell with working directory set to project directory using the w flag

```local-local shell
docker exec -it -w /home/rstudio/project container-name bash
```

3. Run pipeline make file with appropriate config file

```local-container shell
make -f make-pipeline.mk CONFIG_FILE=/home/rstudio/project/configs/configfilename
```

4. Exit docker container shell to return to local shell

```local-container shell
exit

```