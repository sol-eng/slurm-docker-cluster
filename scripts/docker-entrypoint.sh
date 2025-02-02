#!/bin/bash

if [ "$1" = "slurmdbd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    /etc/init.d/munge start  

    echo "---> Starting sshd ..."
    /etc/init.d/ssh start

    echo "rstudio ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/rstudio

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

    exec gosu slurm /usr/sbin/slurmdbd

    # Loop indefinitely
    while true; do sleep 20; done
fi

if [ "$1" = "slurmctld" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    /etc/init.d/munge start 

    echo "---> Starting sshd ..."
    /etc/init.d/ssh start

    echo "rstudio ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/rstudio

    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."
    until 2>/dev/null >/dev/tcp/slurmdbd/6819
    do
        echo "-- slurmdbd is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmdbd is now active ..."

    echo "---> Starting the Slurm Controller Daemon (slurmctld) ..."
    exec gosu slurm /usr/sbin/slurmctld

    # Loop indefinitely
    while true; do sleep 20; done
    
fi

if [ "$1" = "rstudio" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    /etc/init.d/munge start 

    echo "---> Starting sshd ..."
    /etc/init.d/ssh start

    # create ssh keys
    sudo -u rstudio bash -c "ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys"

    echo "rstudio ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/rstudio

    echo "---> Waiting for the Postgres DB to become available ..."
    until 2>/dev/null >/dev/tcp/postgres/5432
    do
        echo "-- postgres is not available.  Sleeping ..."
        sleep 2
    done

    echo "---> Adding dns entries for both slurmctld hosts ..."
    
    # https://stackoverflow.com/questions/33056385/increment-ip-address-in-a-shell-script

    nextip(){
    IP=$1
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
    }

    previp(){
    IP=$1
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX - 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
    }
    
    ip=`ifconfig eth0 | grep inet | awk '{print $2}'`
 
    #if [ `hostname` == "rstudio1" ]; then 
    #    echo "$(nextip $ip) rstudio2" >> /etc/hosts
    #fi

    #if [ `hostname` == "rstudio2" ]; then 
    #    echo "$(previp $ip) rstudio1" >> /etc/hosts
    #fi

    echo "---> Starting RSW (launcher + server) ..."

    until 2>/dev/null >/dev/tcp/slurmctld/6817
    do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done

    echo "---> Activating the RSW License ..."
    /usr/lib/rstudio-server/bin/license-manager activate $RSP_LICENSE

    echo "---> enabling debugging ..."
    echo -e "[*]\nlog-level=debug" > /etc/rstudio/logging.conf

    echo "---> starting RSW ..."
    /usr/bin/rstudio-launcher start
    sleep 4
    /usr/sbin/rstudio-server start
    sleep 4 

    # Loop indefinitely
    while true; do sleep 20; done

fi


if [ "$1" = "slurmd" ]
then
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    #gosu munge /usr/sbin/munged
    /etc/init.d/munge start 

    echo "---> Starting sshd ..."
    /etc/init.d/ssh start

    echo "rstudio ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/rstudio

    echo "---> Waiting for slurmctld to become active before starting slurmd..."

    until 2>/dev/null >/dev/tcp/slurmctld/6817
    do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmctld is now active ..."

    echo "---> Starting the Slurm Node Daemon (slurmd) ..."
    exec /usr/sbin/slurmd

    # Loop indefinitely
    while true; do sleep 20; done
fi

exec "$@"




#root@slurmctld1:/# if [ `hostname` == "slurmctld1" ]; then  echo "x"; fi

#root@slurmctld1:/# ip=`ifconfig eth0 | grep inet | awk '{print $2}'`
