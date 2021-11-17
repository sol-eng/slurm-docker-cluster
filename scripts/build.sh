#!/bin/bash

# build commands 

docker build --platform linux/amd64 --build-arg SLURM_TAG="slurm-19-05-2-1" -t slurm-docker-cluster:19.05.2 -f Dockerfile.compile .
docker build --platform linux/amd64 --build-arg SLURM_TAG="slurm-20-11-8-1" -t slurm-docker-cluster:20.11.8 -f Dockerfile.compile .
docker build --platform linux/amd64 --build-arg SLURM_TAG="slurm-21-08-3-1" -t slurm-docker-cluster:21.08.3 -f Dockerfile.compile .
