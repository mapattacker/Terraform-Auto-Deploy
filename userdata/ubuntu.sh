#!/bin/bash

echo "==============================="
echo "[INFO] Installing Docker..."
# https://docs.docker.com/engine/install/ubuntu/
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker --version
docker compose version


echo "==============================="
echo "[INFO] Installing aws-cliv2..."
# jq required to parse outputs from aws-cli
sudo apt-get update
sudo apt-get install -y jq unzip
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install
sudo rm -f awscliv2.zip
sudo rm -rf aws


echo "==============================="
echo "[INFO] Installing Ansible..."
sudo apt-get update -y
sudo apt-get install -y ansible
ansible --version


echo "==============================="
echo "[INFO] Create dotenv..."
AWS_ACCOUNT=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .accountId)
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
echo AWS_ACCOUNT=${AWS_ACCOUNT} > .env
echo AWS_REGION=${AWS_REGION} >> .env
echo ECR=${{ECR}} >> .env
