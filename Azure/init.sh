#!/bin/bash

sudo apt-get update

# Install Linux Networking Tools
sudo apt install -y net-tools

# Install Docker
sudo apt-get install -y docker.io

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create a all needed directories
cd $HOME
mkdir -p backend/nginx/conf.d
mkdir -p backend/nginx/ssl

# Download nginx config file
cd backend/nginx/conf.d
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/Azure/nginx/conf.d/juiceshop.shouvik.dev.conf
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/Azure/nginx/conf.d/insecure-api.shouvik.dev.conf
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/Azure/nginx/conf.d/secure-api.shouvik.dev.conf
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/Azure/nginx/conf.d/upstreams.conf
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/Azure/nginx/conf.d/dashboard.conf

# Download docker compose file
cd ../..
wget https://raw.githubusercontent.com/sdutta9/docker_backend_apps/main/Azure/docker-compose.yaml

# Login to private registry to fetch the nginx container
# sudo docker login private-registry.nginx.com --username=$MY_JWT --password=none

# Run docker compose to create the containers
# sudo docker-compose up -d