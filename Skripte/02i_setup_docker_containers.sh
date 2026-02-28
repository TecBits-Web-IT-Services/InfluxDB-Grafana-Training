#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

#Setup influxDB v3 Explorer
mkdir -p /docker/influxdb3-explorer/db
mkdir -p /docker/influxdb3-explorer/config

docker run --detach \
--name influxdb3-explorer \
--pull always \
--network=host \
--publish 8888:80 \
--volume /docker/influxdb3-explorer/db:/db:rw \
--volume /docker/influxdb3-explorer/config:/app-root/config:ro \
--env SESSION_SECRET_KEY=$(openssl rand -hex 32) \
--restart unless-stopped \
influxdata/influxdb3-ui:1.6.2 \
--mode=admin