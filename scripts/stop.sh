#!/bin/bash

# quick wrapper to sanitize the environment 

docker-compose down
docker volume  ls | grep slurm | awk '{print $2}' | xargs docker volume rm

