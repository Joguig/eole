#!/bin/bash

docker network create ep_network
docker run -d --network ep_network \
	   -e MYSQL_ROOT_PASSWORD=password \
	   --name ep_mysql mariadb:10.4

docker run -d --network ep_network \
	   -e ETHERPAD_DB_HOST=ep_mysql \
	   -e ETHERPAD_DB_PASSWORD=password \
	   -p 9001:9001 \
      	   unihalle/etherpad-lite

