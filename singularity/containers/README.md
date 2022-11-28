# Singularity Images 

In this folder you can store any Singularity images you may want to use with Workbench. 

To start with, you can use the `r-session-complete` images from dockerhub. 

```
apptainer build /opt/apptainer/containers/r-session-complete-2022.07.2-576.pro12.sif docker://rstudio/r-session-complete:bionic-2022.07.2-576.pro12

```

Please note that the conversion from docker to singularity/apptainer information is a very time-consuming and resource intensive process, so please make sure you have enough temporary storage available. 

If you wanted to use `r-session-complete` against a different version of Workbench (e.g. 2022.11.0-daily-206.pro5), please use 

```
export RSWB_VERSION="2022.11.0-daily-206.pro5"
apptainer build /opt/apptainer/containers/r-session-complete-${RSWB_VERSION}.sif docker://rstudio/r-session-complete:bionic-${RSWB_VERSION}
```
