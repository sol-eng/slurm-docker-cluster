#!/bin/bash

exec > /var/log/user-data-install.log
exec 2>&1


while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   sleep 1
done

apt-get update

apt-get install -y snap git sshpass

sleep 60
snap install docker 

echo "ubuntu ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ubuntu

echo "Defaults:%sudo env_keep += \"RSP_LICENSE\"" | sudo tee -a /etc/sudoers

sudo -u ubuntu echo "export RSP_LICENSE=KAZG-PPFB-HH8S-SE8A-CP9J-F7GW-YWTA" >> /home/ubuntu/.bashrc

sudo -u ubuntu bash -l -c "cd /home/ubuntu && git clone https://github.com/sol-eng/slurm-docker-cluster.git && cd slurm-docker-cluster && git checkout build-battle"

sudo -u ubuntu echo "source /home/ubuntu/slurm-docker-cluster/code/script.sh" >> /home/ubuntu/.bashrc


