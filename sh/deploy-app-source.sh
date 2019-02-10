#!/bin/sh
COMMAND="while true; do echo 'example Welcome and the Welcome to Welcome Welcome to the example of this project IMPRO';done | nc -l -v -k -p 8380"
docker-machine ssh node-s "echo '$COMMAND' > loop.sh"
docker-machine ssh node-s "chmod +x loop.sh"
docker-machine ssh node-s "sh loop.sh"