#!/bin/bash

# Script to install docker and run load generator + node exporter 
# See also https://gist.github.com/janoszen/7ced227c54d1c9e86a9c1cbd93a451f2

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

# Run the load generator (https://github.com/janoszen/http-load-generator)
docker run -d \
  --restart=always \
  -p 8080:8080 \
  quay.io/janoszen/http-load-generator:1.0.1
  
# Run the node exporter (Port 9100)
docker run -d \
  --restart=always \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter \
  --path.rootfs=/host