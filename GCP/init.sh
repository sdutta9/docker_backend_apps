#!/bin/bash

sudo apt-get update

# Install necessary Linux Packages
sudo apt install -y curl wget procps bash bash-completion net-tools vim tree openssl jq

# Install Docker
sudo apt-get install -y docker.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create a all needed directories
cd $HOME
mkdir -p backend/nginx/conf.d


# Download nginx config file
cd backend/nginx/conf.d
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/GCP/nginx/conf.d/insecure-web.shouvik.dev.conf
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/GCP/nginx/conf.d/secure-web.shouvik.dev.conf
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/GCP/nginx/conf.d/insecure-api.shouvik.dev.conf
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/GCP/nginx/conf.d/secure-api.shouvik.dev.conf
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/GCP/nginx/conf.d/upstreams.conf

# Download docker compose file
cd ../..
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/GCP/docker-compose.yaml

# Login to private registry to fetch the nginx plus container
# sudo docker login private-registry.nginx.com --username=$MY_JWT --password=none

# Run docker compose to create the containers
sudo docker-compose up -d