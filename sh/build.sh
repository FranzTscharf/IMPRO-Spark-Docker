#!/bin/bash
echo "Please enter the Apikey of DigitalOcean:"
read apikey
echo "Destroy priviose VM's"
docker-machine rm node-1 node-2 node-3 node-v -y --force

echo "Create the Visualisation VM..."
docker-machine create \
    --driver digitalocean \
    --digitalocean-region "nyc1" \
    --digitalocean-size "4gb" \
    --digitalocean-access-token $apikey \
    node-v;
docker-machine ssh node-v "docker run -d -p 80:80 -p 81:81 -p 8000:8000 -p 2003:2003 -p 8125:8125 -p 8126:8126 kamon/grafana_graphite"

echo "Create the Apache Spark Cluster VMS..."
for i in 1 2 3; do
  docker-machine create \
    --driver digitalocean \
    --digitalocean-region "nyc1" \
    --digitalocean-size "4gb" \
    --digitalocean-access-token $apikey \
    node-$i;
done

echo "Initializing Swarm mode..."
docker-machine ssh node-1 -- docker swarm init --advertise-addr $(docker-machine ip node-1)
docker-machine ssh node-1 -- docker node update --availability drain node-1

echo "Adding the nodes to the Swarm..."
TOKEN=`docker-machine ssh node-1 docker swarm join-token worker | grep token | awk '{ print $5 }'`
docker-machine ssh node-2 "docker swarm join --token ${TOKEN} $(docker-machine ip node-1):2377"
docker-machine ssh node-3 "docker swarm join --token ${TOKEN} $(docker-machine ip node-1):2377"

echo "Deploying Spark..."
eval $(docker-machine env node-1)
export EXTERNAL_IP=$(docker-machine ip node-2)
basename="$(dirname $(dirname $0))"
docker stack deploy --compose-file="$basename"/docker-compose.yml spark
docker service scale spark_worker=2

echo "Add the host ip of the visualisation node to the config file of node-1(spark master)"
echo "Getting container ID of the Spark master..."
eval $(docker-machine env node-1)
NODE=$(docker service ps --format "{{.Node}}" spark_master)
eval $(docker-machine env $NODE)
CONTAINER_ID=$(docker ps --filter name=master --format "{{.ID}}")
echo "Navigate to the Spark master..."
docker exec -it $CONTAINER_ID bash -c "echo "*.sink.graphite.host=$(docker-machine ip node-v)" >> /usr/spark-2.3.1/conf/metrics.properties"

echo "Get metrics..."
eval $(docker-machine env node-1)
NODE=$(docker service ps --format "{{.Node}}" spark_master)
docker-machine ip $NODE
echo "Get address of spark master..."
echo "$(docker-machine ip node-1)"