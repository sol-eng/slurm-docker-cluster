FROM ubuntu:20.04

LABEL org.opencontainers.image.source="https://github.com/michaelmayer2/slurm-docker-cluster" \
      org.opencontainers.image.title="slurm-docker-cluster" \
      org.opencontainers.image.description="Slurm Docker cluster on Ububtu 20.04 LTS" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      maintainer="Michael Mayer"

ARG SLURM_TAG=slurm-19-05-2-1
ARG GOSU_VERSION=1.11
ARG R_VERSIONS="3.6.3 4.0.5 4.1.2"
ARG RSWB_VERSION="2021.09.0-351.pro6"
ARG PROXY

RUN if test -n $PROXY; then echo "Acquire::http { Proxy \"http://$PROXY:3142\"; };" >> /etc/apt/apt.conf.d/01proxy; fi

## Install R and RStudio Workbench

COPY rstudio/create.R /tmp/create.R 

RUN apt-get update -y && \
	apt-get install -y gdebi-core curl && \ 
	IFS=" "; for R_VERSION in $R_VERSIONS ; \
	do \
		curl -O https://cdn.rstudio.com/r/ubuntu-2004/pkgs/r-${R_VERSION}_1_amd64.deb && \
		gdebi -n r-${R_VERSION}_1_amd64.deb && \
		rm -f r-${R_VERSION}_1_amd64.deb && \
		/opt/R/$R_VERSION/bin/Rscript /tmp/create.R ;\
	done && \
	curl -O https://download2.rstudio.org/server/bionic/amd64/rstudio-workbench-${RSWB_VERSION}-amd64.deb && \
	gdebi -n rstudio-workbench-${RSWB_VERSION}-amd64.deb && \
	rm -f rstudio-workbench-${RSWB_VERSION}-amd64.deb && \
    	apt clean all && \
    	rm -rf /var/cache/apt

COPY rstudio/launcher.conf /etc/rstudio/launcher.conf
COPY rstudio/launcher.slurm.conf /etc/rstudio/launcher.slurm.conf
COPY rstudio/launcher.slurm.profiles.conf /etc/rstudio/launcher.slurm.profiles.conf
COPY rstudio/rserver.conf /etc/rstudio/rserver.conf

## Install SLURM

### Populate directories and set permissions 
 
RUN /bin/bash -c "set -x \
    && groupadd -r --gid=995 slurm \
    && useradd -r -s /bin/bash -g slurm --uid=995 slurm \
    && mkdir -p /home/slurm && chown slurm /home/slurm \
    && mkdir -p /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmdbd \
        /var/lib/slurmd \
        /var/log/slurm \
        /data \
    && touch /var/lib/slurmd/node_state \
        /var/lib/slurmd/front_end_state \
        /var/lib/slurmd/job_state \
        /var/lib/slurmd/resv_state \
        /var/lib/slurmd/trigger_state \
        /var/lib/slurmd/assoc_mgr_state \
        /var/lib/slurmd/assoc_usage \
        /var/lib/slurmd/qos_usage \
        /var/lib/slurmd/fed_mgr_state \
    && ln -s /etc/slurm-llnl /etc/slurm \
    && chown -R slurm:slurm /var/*/slurm* " 


### Install slurm packages and db dependencies 

RUN set -ex \
    && apt-get update \
    && apt-get -y install \
       slurmd slurmdbd slurmctld slurm-client \
       mariadb-server \
       mariadb-client \
       libmariadbd-dev \
       psmisc \
       bash-completion \
    && apt clean all \
    && rm -rf /var/cache/apt

RUN umask 0022 && echo "export TZ=Europe/Paris" > /etc/profile.d/timezone.sh

### Copy slurm.conf and slurmdbd.conf 

COPY slurm.conf /etc/slurm/slurm.conf
COPY slurmdbd.conf /etc/slurm/slurmdbd.conf
RUN chmod 0600 /etc/slurm/slurmdbd.conf



## Configure a mail client and add a couple of nice to have tools

RUN mkdir -p /etc/postfix

COPY rstudio/main.cf /etc/postfix/main.cf
ENV DEBIAN_FRONTEND=noninteractive

RUN set -ex \
    && apt-get update \
    && apt-get -y install \
       wget gpg vim net-tools iputils-ping postfix mailutils \
    && apt clean all \
    && rm -rf /var/cache/apt


## Install gosu

RUN set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true



COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]
