#!/bin/bash

# Script to install docker and run prometheus and a static service discovery

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

# create prometheus.yml on instance
echo """
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'localMonitoring'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
  - job_name: 'customServers'
    file_sd_configs:
      - files:
          - /service-discovery/custom_servers.json
        refresh_interval: 2s
""" >> /srv/prometheus.yml

# create json configuration for service discovery
mkdir /srv/service-discovery

echo """
[
  {
    \"targets\": [ \"1.2.3.4:9100\", \"1.2.3.4:9100\", \"1.2.3.4:9100\" ]
  }
]
""" >> /srv/service-discovery/custom_servers.json

# Run prometheus
docker run \
    --net="host" \
    -d \
    -p 9090:9090 \
    -v /srv/service-discovery/:/service-discovery/ \
    -v /srv/prometheus.yml:/etc/prometheus/prometheus.yml \
    -v /srv/service-discovery/:/service-discovery/ \
    prom/prometheus

# Run the node exporter
docker run -d \
  --restart=always \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter \
  --path.rootfs=/host
  