n=2
function start() {
    pushd ~
	for i in `seq 1 $n` 
	do
		mkdir -p env-$i
		rsync -av slurm-docker-cluster/ env-$i
		pushd env-$i
		SSH_PORT=$(( 1000+$i ))  PWB_PORT=$(( 8000+$i )) docker-compose up -d
		popd
	done	
    popd
}

function stop() {
    pushd ~
	for i in `seq $n`
	do
		pushd env-$i
		docker-compose down  
	docker volume ls | grep env-$i | awk '{print $2}' | xargs docker volume rm 
		popd
	done
    popd
} 
