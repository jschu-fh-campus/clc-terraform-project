#!/bin/bash

# Script to install docker and run prometheus, the service discovery and grafana

# Exit immediatelly on failure
set -e

# Run in non-interactive mode -> apt will use default values and not ask questions
export DEBIAN_FRONTEND=noninteractive

# Install Docker (https://docs.docker.com/engine/install/ubuntu/)
# -y -> answer yes to everything
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# create docker network
docker network create monitoring

# create prometheus.yml on instance
echo """
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'runningInstances'
    file_sd_configs:
      - files:
          - ${config_directory}/config.json
        refresh_interval: 10s
""" >> /srv/prometheus.yml

# Run prometheus
docker run \
  -d \
  -p 9090:9090 \
  -v ${config_directory}:${config_directory} \
  -v /srv/prometheus.yml:/etc/prometheus/prometheus.yml \
  --name prometheus \
  --net=monitoring \
  prom/prometheus

# Run the service discovery 
docker run \
  -d \
  -e EXOSCALE_KEY=${exoscale_key} \
  -e EXOSCALE_SECRET=${exoscale_secret} \
  -e EXOSCALE_ZONE=${exoscale_zone} \
  -e EXOSCALE_INSTANCEPOOL_ID=${exoscale_instancepool_id} \
  -e TARGET_PORT=${target_port} \
  -v ${config_directory}:${config_directory} \
  --name service-discovery \
  --net=monitoring \
  jschu/exoscale_service_discovery

# create prometheus datasource for grafana on instance
echo """
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  orgId: 1
  url: http://prometheus:9090
  version: 1
  editable: false
""" >> /srv/datasource.yml

#Run Grafana
docker run \
  -d \
  -p 3000:3000 \
  -v /srv/datasource.yml:/etc/grafana/provisioning/datasources/datasource.yml \
  --name grafana \
  --net=monitoring \
  grafana/grafana
