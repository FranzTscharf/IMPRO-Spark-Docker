#!/bin/sh
echo "\033[1mPlease enter the Apikey of DigitalOcean:\033[0m"
read apikey
echo "\033[1mGenerating Node-s Txt Streaming Service...\033[0m"
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
SIMULATION_IP=$(docker-machine ip node-s)

echo "\033[1mGetting Container ID Spark Master...\033[0m"
eval $(docker-machine env node-1)
NODE=$(docker service ps --format "{{.Node}}" spark_master)
eval $(docker-machine env $NODE)
CONTAINER_ID=$(docker ps --filter name=master --format "{{.ID}}")

echo "\033[1mCopying NetworkWordCount.py app to the Spark master...\033[0m"
basename="$(dirname $(dirname $0))"
docker cp "$basename"/app/NetworkWordCount.py $CONTAINER_ID:/tmp

echo "\033[1mRunning Spark Streaming Job...\033[0m"
docker exec $CONTAINER_ID \
  bin/spark-submit \
    --files=/usr/spark-2.3.1/conf/metrics.properties \
    --conf spark.metrics.conf=/usr/spark-2.3.1/conf/metrics.properties \
    --master spark://master:7077 \
    --class endpoint \
    /tmp/NetworkWordCount.py $SIMULATION_IP 8380