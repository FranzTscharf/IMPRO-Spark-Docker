#!/bin/sh

echo "Getting container ID of the Spark master..."

eval $(docker-machine env node-1)
NODE=$(docker service ps --format "{{.Node}}" spark_master)
eval $(docker-machine env $NODE)
CONTAINER_ID=$(docker ps --filter name=master --format "{{.ID}}")


echo "Copying letter-count.py app to the Spark master..."
basename="$(dirname $(dirname $0))"
docker cp "$basename"/app/letter-count.py $CONTAINER_ID:/tmp


echo "Running Spark Job..."
docker exec $CONTAINER_ID \
  bin/spark-submit \
    --master spark://master:7077 \
    --class endpoint \
    /tmp/letter-count.py
