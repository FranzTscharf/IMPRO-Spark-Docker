#!/bin/sh
echo "\033[1mPlease enter the Apikey of DigitalOcean:\033[0m"
read apikey
echo "Generating Node-s Txt Streaming Service..."
eval $(docker-machine env -u)
#delete current node-s
docker-machine rm node-s -y --force
#create new node-s 
docker-machine create \
    --driver digitalocean \
    --digitalocean-region "nyc1" \
    --digitalocean-size "4gb" \
    --digitalocean-access-token $apikey \
node-s;
docker-machine ssh node-s "while true; do echo 'Welcome and Welcome to the example';done | netcat --broker --listen -l -v -k -p 8380 &";
SIMULATION_IP=$(docker-machine ip node-s)

echo "Getting Container ID Spark Master..."
eval $(docker-machine env node-1)
NODE=$(docker service ps --format "{{.Node}}" spark_master)
eval $(docker-machine env $NODE)
CONTAINER_ID=$(docker ps --filter name=master --format "{{.ID}}")

echo "Copying NetworkWordCount.py app to the Spark master..."
basename="$(dirname $(dirname $0))"
docker cp "$basename"/app/NetworkWordCount.py $CONTAINER_ID:/tmp

echo "Running Spark Streaming Job..."
docker exec $CONTAINER_ID \
  bin/spark-submit \
    --files=/usr/spark-2.3.1/conf/metrics.properties \
    --conf spark.metrics.conf=/usr/spark-2.3.1/conf/metrics.properties \
    --master spark://master:7077 \
    --class endpoint \
    /tmp/NetworkWordCount.py $SIMULATION_IP 8380
