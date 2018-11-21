#!/bin/bash
echo "Getting container ID of the Spark master..."
eval $(docker-machine env node-1)
NODE=$(docker service ps --format "{{.Node}}" spark_master)
eval $(docker-machine env $NODE)
CONTAINER_ID=$(docker ps --filter name=master --format "{{.ID}}")
echo "Navigate to the Spark master..."
docker exec -it $CONTAINER_ID /bin/bash