#!/bin/bash

echo 'alias k=kubectl' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s - server --node-ip 192.168.56.110
K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo $K3S_TOKEN > /vagrant/k3s_token
