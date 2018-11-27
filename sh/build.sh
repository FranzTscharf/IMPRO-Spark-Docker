#!/bin/bash
echo -e "\033[1mWhich IssA provider do you want to use?\033[0m"
echo -e "\033[1;34m0: DigitalOcean\033[0m"
echo -e "\033[1;34m1: Amazon Web Services\033[0m"
echo -e "\033[1;34m2: Google Cloud Platform\033[0m"
echo -e "\033[1;34m3: Local\033[0m"
echo -e "\033[1;34m4: Nothing\033[0m"
echo -e "\033[1mPlease enter the Number of the desired platform:\033[0m"
read issa

case "$issa" in
    "0")
            echo -e "\033[1mPlease enter the Apikey of DigitalOcean:\033[0m"
            read apikey
            echo -e "\033[1mDestroy priviose VM's\033[0m"
            docker-machine rm node-1 node-2 node-3 node-v -y --force

            echo -e "\033[1mCreate the Visualisation VM...\033[0m"
            docker-machine create \
                --driver digitalocean \
                --digitalocean-region "nyc1" \
                --digitalocean-size "4gb" \
                --digitalocean-access-token $apikey \
                node-v;
            docker-machine ssh node-v "docker run -d -p 80:80 -p 81:81 -p 8000:8000 -p 2003:2003 -p 8125:8125/udp -p 8126:8126 --name kamon-grafana-dashboard kamon/grafana_graphite"

            echo -e "\033[1mCreate the Apache Spark Cluster VMS...\033[0m"
            for i in 1 2 3; do
              docker-machine create \
                --driver digitalocean \
                --digitalocean-region "nyc1" \
                --digitalocean-size "4gb" \
                --digitalocean-access-token $apikey \
                node-$i;
            done
            ;;
    "1")
            echo -e "\033[1mPlease enter the AWS_ACCESS_KEY_ID:\033[0m"
            read ACCESS_KEY_ID
            export AWS_ACCESS_KEY_ID=ACCESS_KEY_ID
            echo -e "\033[1mPlease enter the AWS_SECRET_ACCESS_KEY:\033[0m"
            read MY-SECRET-KEY
            export AWS_SECRET_ACCESS_KEY=MY-SECRET-KEY
            echo -e "\033[1mDestroy priviose VM's\033[0m"
            docker-machine rm node-1 node-2 node-3 node-v -y --force
            echo -e "\033[1mCreate the Visualisation VM...\033[0m"
            docker-machine create -d amazonec2 \
                --amazonec2-region us-west-2 \
                --amazonec2-instance-type "t2.medium" \
                --amazonec2-ssh-keypath ~/.ssh/ssh_key \
            node-v;
            docker-machine ssh node-v "docker run -d -p 80:80 -p 81:81 -p 8000:8000 -p 2003:2003 -p 8125:8125 -p 8126:8126 kamon/grafana_graphite"
            echo -e "\033[1mCreate the Apache Spark Cluster VMS...\033[0m"
            for i in 1 2 3; do
                docker-machine create -d amazonec2 \
                    --amazonec2-region us-west-2 \
                    --amazonec2-instance-type "t2.medium" \
                    --amazonec2-ssh-keypath ~/.ssh/ssh_key \
                node-$i;
            done
            ;;
    "2")    
            echo -e "\033[1mPlease enter the Absolute Path of GOOGLE APPLICATION CREDENTIALS(.../gce-credentials.json):\033[0m"
            read gce-credentials
            export GOOGLE_APPLICATION_CREDENTIALS=gce-credentials
            echo -e "\033[1mPlease enter the Project ID of Google Cloud Project where the VM's should be added to:\033[0m"
            read projectID
            echo -e "\033[1mDestroy priviose VM's\033[0m"
            docker-machine rm node-1 node-2 node-3 node-v -y --force
            echo -e "\033[1mCreate the Visualisation VM...\033[0m"
            docker-machine create --driver google \
                --google-project $projectID \
                --google-zone us-central1-f \
                --google-machine-type n1-standard-1 \
                --google-disk-size "500" \
            node-v;
            docker-machine ssh node-v "docker run -d -p 80:80 -p 81:81 -p 8000:8000 -p 2003:2003 -p 8125:8125 -p 8126:8126 kamon/grafana_graphite"
            echo -e "\033[1mCreate the Apache Spark Cluster VMS...\033[0m"
            for i in 1 2 3; do
                docker-machine create --driver google \
                    --google-project $projectID \
                    --google-zone us-central1-f \
                    --google-machine-type n1-standard-1 \
                    --google-disk-size "500" \
                node-$i;
            done
            ;;
    "4")      
            echo -e "\033[1mNothing\033[0m"
            ;;
    *)
            echo -e "\033[1mDefault\033[0m"
            ;;
            
esac
echo -e "\033[1mInitializing Swarm mode...\033[0m"
docker-machine ssh node-1 -- docker swarm init --advertise-addr $(docker-machine ip node-1)
docker-machine ssh node-1 -- docker node update --availability drain node-1

echo -e "\033[1mAdding the nodes to the Swarm...\033[0m"
TOKEN=`docker-machine ssh node-1 docker swarm join-token worker | grep token | awk '{ print $5 }'`
docker-machine ssh node-2 "docker swarm join --token ${TOKEN} $(docker-machine ip node-1):2377"
docker-machine ssh node-3 "docker swarm join --token ${TOKEN} $(docker-machine ip node-1):2377"

echo -e "\033[1mDeploying Spark...\033[0m"
eval $(docker-machine env node-1)
export EXTERNAL_IP=$(docker-machine ip node-2)
basename="$(dirname $(dirname $0))"
docker stack deploy --compose-file="$basename"/docker-compose.yml spark
docker service scale spark_worker=2

echo -e "\033[1mAdd the host ip of the visualisation node to the config file of all nodes\033[0m"
for i in 1 2 3; do
    eval $(docker-machine env node-$i)
    for container in $(docker ps --format "{{.ID}}");do
        docker exec -it $container bash -c "echo "*.sink.graphite.host=$(docker-machine ip node-v)" >> /usr/spark-2.3.1/conf/metrics.properties"
    done
done

echo "Get address of spark master..."
eval $(docker-machine env node-1)
NODE=$(docker service ps --format "{{.Node}}" spark_master)
docker-machine ip $NODE