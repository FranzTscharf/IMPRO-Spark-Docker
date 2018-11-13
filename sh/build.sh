#!/bin/bash
echo "Create the VMS..."
for i in 1 2; do
	docker-machine create --driver virtualbox --engine-opt experimental --engine-opt metrics-addr=0.0.0.0:4999 node-$i;
done

echo "Initializing Swarm mode..."
docker-machine ssh node-1 -- docker swarm init --advertise-addr $(docker-machine ip node-1)
docker-machine ssh node-1 -- docker node update --availability drain node-1

echo "Adding the nodes to the Swarm..."
TOKEN=`docker-machine ssh node-1 docker swarm join-token worker | grep token | awk '{ print $5 }'`
docker-machine ssh node-2 "docker swarm join --token ${TOKEN} $(docker-machine ip node-1):2377"

echo "Deploying Spark..."
eval $(docker-machine env node-1)
export EXTERNAL_IP=$(docker-machine ip node-2)
basename="$(dirname $(dirname $0))"
docker stack deploy --compose-file="$basename"/docker-compose.yml spark
docker service scale spark_worker=1

echo "Get address..."
NODE=$(docker service ps --format "{{.Node}}" spark_master)
docker-machine ip $NODE
echo "Get address..."
echo "curl http://$(docker-machine ip node-1):4999/metrics"
echo "curl http://$(docker-machine ip node-2):4999/metrics"