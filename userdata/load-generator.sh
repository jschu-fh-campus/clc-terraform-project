#!/bin/bash

# script to install docker and run the load generator 
# see also https://gist.github.com/janoszen/7ced227c54d1c9e86a9c1cbd93a451f2

set -e

export DEBIAN_FRONTEND=noninteractive

# region Install Docker (https://docs.docker.com/engine/install/ubuntu/)
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
# endregion

# region Launch containers

# Run the load generator (https://github.com/janoszen/http-load-generator)
docker run -d \
  --restart=always \
  -p 8080:8080 \
  janoszen/http-load-generator:1.0.1
  
# endregion