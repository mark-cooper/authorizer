#!/bin/bash

mkdir -p plugins/
git clone git@github.com:lyrasis/aspace-importer.git plugins/aspace-importer || true

mkdir -p /tmp/aspace/import
mkdir -p /tmp/aspace/json

docker network create aspace || true

# mysql
if [ ! "$(docker ps -q -f name=mysql)" ]; then
  if [ "$(docker ps -aq -f status=exited -f name=mysql)" ]; then
      docker rm mysql
  fi

  docker run -d \
    --name db \
    --network=aspace \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=123456 \
    -e MYSQL_DATABASE=archivesspace \
    -e MYSQL_USER=archivesspace \
    -e MYSQL_PASSWORD=archivesspace \
    mysql:5.7 \
    --character-set-server=utf8 \
    --collation-server=utf8_unicode_ci \
    --innodb_buffer_pool_size=4G \
    --innodb_buffer_pool_instances=4

  echo "Waiting for MySQL to bootstrap"
  while ! mysqladmin ping -h 127.0.0.1 --silent; do
      sleep 1
  done
fi

# archivesspace
if [ ! "$(docker ps -q -f name=archivesspace)" ]; then
  if [ "$(docker ps -aq -f status=exited -f name=archivesspace)" ]; then
      docker rm archivesspace
  fi

  docker run -d \
    --name archivesspace \
    --network=aspace \
    -p 8080:8080 \
    -p 8081:8081 \
    -p 8089:8089 \
    -p 8090:8090 \
    -e JAVA_OPTS="-Xms2g -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+AggressiveOpts -XX:+UseFastAccessorMethods -XX:+UseBiasedLocking -XX:+UseCompressedOops -server" \
    -e ASPACE_JAVA_XMX="-Xmx2g" \
    -e APPCONFIG_DB_URL='jdbc:mysql://db:3306/archivesspace?useUnicode=true&characterEncoding=UTF-8&user=archivesspace&password=archivesspace' \
    -v $(pwd)/config:/archivesspace/config \
    -v $(pwd)/plugins:/archivesspace/plugins \
    -v /tmp/aspace:/tmp/aspace \
    archivesspace/archivesspace:latest
fi

docker logs -f archivesspace
