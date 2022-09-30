#!/bin/bash

if [ "$1" = "slurmdbd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    /etc/init.d/munge start  

    echo "---> Starting the Slurm Database Daemon (slurmdbd) ..."
    {
        . /etc/slurm/slurmdbd.conf
        until echo "SELECT 1" | mysql -h $StorageHost -u$StorageUser -p$StoragePass 2>&1 > /dev/null
        do
            echo "-- Waiting for database to become active ..."
            sleep 2
        done
    }
    echo "-- Database is now active ..."

    chmod 0600 /etc/slurm/slurmdbd.conf
    chown slurm /etc/slurm/slurmdbd.conf

    exec gosu slurm /usr/sbin/slurmdbd -D

fi

if [ "$1" = "slurmctld" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    /etc/init.d/munge start 

    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."
    until 2>/dev/null >/dev/tcp/slurmdbd/6819
    do
        echo "-- slurmdbd is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmdbd is now active ..."

    echo "---> Starting the Slurm Controller Daemon (slurmctld) ..."
    /usr/sbin/slurmctld -D & 

    echo "---> Activating the RSW License ..."
    /usr/lib/rstudio-server/bin/license-manager activate $RSP_LICENSE

    echo "---> Waiting for the Postgres DB to become available ..."
    until 2>/dev/null >/dev/tcp/postgres/5432
    do
        echo "-- postgres is not available.  Sleeping ..."
        sleep 2
    done

    echo "---> Starting RSW (launcher + server) ..."
    rstudio-launcher start
    rstudio-server start

    sleep 5 
     
    rstudio-server reset-cluster

    rstudio-server stop
    rstudio-server start

    while true 
    do
        sleep 20
    done

fi


if [ "$1" = "slurmd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    #gosu munge /usr/sbin/munged
    /etc/init.d/munge start 

    echo "---> Waiting for slurmctld to become active before starting slurmd..."

    until 2>/dev/null >/dev/tcp/slurmctld1/6817
    do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmctld is now active ..."

    echo "---> Starting the Slurm Node Daemon (slurmd) ..."
    exec /usr/sbin/slurmd -D
fi

exec "$@"
