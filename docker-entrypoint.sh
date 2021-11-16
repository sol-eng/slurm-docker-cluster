#!/bin/bash
set -ex

if [ "$1" = "slurmdbd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    #gosu munge /usr/sbin/munged
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

    exec gosu slurm /usr/sbin/slurmdbd -Dvvv
    #/usr/sbin/slurmdbd -Dvvv

fi

if [ "$1" = "slurmctld" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    #gosu munge /usr/sbin/munged
    /etc/init.d/munge start 

    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."

    until 2>/dev/null >/dev/tcp/slurmdbd/6819
    do
        echo "-- slurmdbd is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmdbd is now active ..."

    echo "---> Starting the Slurm Controller Daemon (slurmctld) ..."

    sed -i '/^Cache/ s/./#&/' /etc/slurm/slurm.conf           
    sed -i '/^Fast/ s/./#&/' /etc/slurm/slurm.conf 
    sed -i '/^AccountingStorageLoc/ s/./#&/' /etc/slurm/slurm.conf
    grep Storage /etc/slurm/slurm.conf
    exec gosu slurm /usr/sbin/slurmctld -Dvvv

    # R Studio integration 
    sed -i "s/CALLBACKHOST/`hostname`/" /etc/rstudio/rserver.conf

    systemctl restart rstudio-server
    systemctl restart rstudio-launcher
fi

if [ "$1" = "slurmd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    #gosu munge /usr/sbin/munged
    /etc/init.d/munge start 

    echo "---> Waiting for slurmctld to become active before starting slurmd..."

    until 2>/dev/null >/dev/tcp/slurmctld/6817
    do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmctld is now active ..."

    echo "---> Starting the Slurm Node Daemon (slurmd) ..."
    exec /usr/sbin/slurmd -Dvvv
fi

exec "$@"
