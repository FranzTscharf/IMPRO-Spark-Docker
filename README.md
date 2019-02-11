# IMPRO-Spark-Docker: Monitoring runtime engine statistics for Spark and Docker swarm
Over the last years, stream data processing has been gaining attention both in industry and in academia due to its wide range of applications. To fulfill the need for scalable and efficient stream analytics, numerous open source stream data processing systems have been developed, with high throughput and low latency being their key performance targets. Apache Spark is one of the stream processing systems used both in industry and in academia [1]. Docker is an open platform for developers and sysadmins to build, ship, and run distributed applications, whether on laptops, data center VMs, or the cloud [2]. The goal of this project is to integrate docker with Spark Streaming and expose Docker- and Spark-specific statistics to a common history server and visualize them. For example, Docker provides network related statistics and Spark provides JVM related statistics.

## Includes
The build process of this repo automaticly deployes a Docker Swarm with Apache Spark.
Also it creats a virtual machine for visualisation of the regarding Docker and Spark metrics.
For the visualisation it uses Grafana as time series analytics platform and Graphite as a historie server for storing the data.
For collecting the statistics it uses CollecD.

# Getting Started
## Deploy Enviroment:

```
cd IMPRO-Spark-Docker
sh ./sh/build.sh
```
follow instructions of the script.
At the end you can look into your IaaS provider ther should be multible vms deployed.

## Deploy Apache Spark Example Streaming Application:
```
cd IMPRO-Spark-Docker
sh ./sh/deploy-app-streaming.sh
```
Wait until the app is ready.
afterwards you can lauch the source thought the following commands.
```
cd IMPRO-Spark-Docker
sh ./sh/deploy-app-source.sh
```
## Access Web UI:
-Grafana on ip of node-v and port 80
-Graphit on ip of node-v and port 81
-Apache Spark Web UI on ip of node-1 and port 8080

# Dependencies
## Runtime metrics
-CollecD
-Native Spark config sink with file in ./pkg/metrics.properties

## License
Not sure probably Apache 2.0

