n=9
function start() {
    pushd ~
	for i in `seq 1 $n` 
	do
		mkdir -p env-$i
		rsync -av slurm-docker-cluster/ env-$i
		pushd env-$i
		sudo SSH_PORT=$(( 1000+$i ))  PWB_PORT=$(( 8000+$i )) docker-compose up -d
		popd
	done	
    popd
}

function stop() {
    pushd ~
	for i in `seq $n`
	do
		pushd env-$i
		sudo docker-compose down  
	    sudo docker volume ls | grep env-$i | awk '{print $2}' | xargs sudo docker volume rm 
		popd
	done
    popd
} 


function mess() {
    # disable rstudio-launcher on env 1
    sshpass -p BuildBattleMSP ssh -o StrictHostKeyChecking=no -p 1001 rstudio@localhost sudo killall /usr/lib/rstudio-server/bin/rstudio-launcher
    # remove session components on env 2
    sshpass -p BuildBattleMSP ssh -o StrictHostKeyChecking=no -p 1002 rstudio@localhost ssh -o StrictHostKeyChecking=no c1 sudo rm -rf /usr/lib/rstudio-server
    sshpass -p BuildBattleMSP ssh -o StrictHostKeyChecking=no -p 1002 rstudio@localhost ssh -o StrictHostKeyChecking=no c2 sudo rm -rf /usr/lib/rstudio-server

    # kill slurmctld
    sshpass -p BuildBattleMSP ssh -o StrictHostKeyChecking=no -p 1003 rstudio@localhost ssh -o StrictHostKeyChecking=no slurmctld sudo killall slurmctld

    # disable partition
    sshpass -p BuildBattleMSP ssh -o StrictHostKeyChecking=no -p 1004 rstudio@localhost sudo -u slurm scontrol update Partition=normal State=DOWN

    # remove session callback address
    pushd ~/env-5 && sed -i 's/^launcher-sessions-call.*//' rstudio/rserver.conf && sudo docker-compose up rstudio -d && popd
    }