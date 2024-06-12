#!/bin/bash
# setting up an empty computers with a k8s installation

set -e

token=TOKEN
host=HOST
port=6443
hash=HASH

sudo apt update
sudo apt install ufw -y
sudo ufw enable

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

if [[ $(sysctl net.ipv4.ip_forward) == "net.ipv4.ip_forward = 1" ]]; then
    echo "IP forwarding is enabled."
else
    echo "IP forwarding is not enabled."
    exit 1
fi

echo -e "Opening node ports"

# node ports
ufw allow 10250/tcp
ufw allow 10256/tcp
ufw allow 30000:32767/tcp

kubeadm join --token $token $host:$port --discovery-token-ca-cert-hash sha256:$hash
