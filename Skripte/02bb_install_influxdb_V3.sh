#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key

gpg --show-keys --with-fingerprint --with-colons ./influxdata-archive.key 2>&1 \
| grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$' \
&& cat influxdata-archive.key \
| gpg --dearmor \
| sudo tee /usr/share/keyrings/influxdata-archive.gpg > /dev/null \
&& echo 'deb [signed-by=/usr/share/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
| sudo tee /etc/apt/sources.list.d/influxdata.list

sudo apt-get update && sudo apt-get install influxdb3-core

systemctl start influxdb3-core

influxdb3 create token --admin > /home/student/Schreibtisch/admin-token.txt
chown student:student /home/student/Schreibtisch/admin-token.txt