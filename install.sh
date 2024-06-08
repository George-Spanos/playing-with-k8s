#!/bin/bash
# setting up an empty computers with a k8s installation

set -e

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

containerdVersion="1.7.18"
containerdURL="https://github.com/containerd/containerd/releases/download/v$containerdVersion/containerd-$containerdVersion-linux-amd64.tar.gz"
containerdFilename="containerd-$containerdVersion-linux-amd64.tar.gz"

runcVersion="1.1.12"
runcURL="https://github.com/opencontainers/runc/releases/download/v$runcVersion/runc.amd64"
runcFilename="runc.amd64"

cniVersion="1.5.0"
cniURL="https://github.com/containernetworking/plugins/releases/download/v$cniVersion/cni-plugins-linux-amd64-v$cniVersion.tgz"
cniFilename="cni-plugins-linux-amd64-v$cniVersion.tgz"

echo "\nInstalling containerd...\n"

curl -LO $containerdURL

tar Cxzvf /usr/local $containerdFilename

mkdir -p /usr/local/lib/systemd/system
cat << EOF > /usr/local/lib/systemd/system/containerd.service
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now containerd

mkdir /etc/containerd

containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd

rm $containerdFilename

echo "\nContainerd installed succesfully\n"
# Install runc

echo "\nInstalling runc...\n"

curl -LO $runcURL

install -m 755 $runcFilename /usr/local/sbin/runc
rm $runcFilename

echo "\nRunc installed\n"

#install cni plugin

echo "\nInstalling CNI plugin...\n"

mkdir -p /opt/cni/bin

curl -LO $cniURL

tar Cxzvf /opt/cni/bin $cniFilename

rm $cniFilename

echo -e "\nCNI plugin installed succesfully"

echo -e "Opening ports for k8s..."

ufw allow ssh
ufw allow 6443/tcp
ufw allow 2379/tcp
ufw allow 2380/tcp
ufw allow 10250/tcp
ufw allow 10259/tcp
ufw allow 10257/tcp

# node ports
ufw allow 10250/tcp
ufw allow 10256/tcp
ufw allow 30000:32767/tcp

echo -e "Installing kubeadm kubectl and kubelet..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

echo -e "starting cluster"

kubeadm init --pod-network-cidr=10.244.0.0/16

export KUBECONFIG=/etc/kubernetes/admin.conf

echo -e "Installing flannel"

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo -e "remove taint of no nodes on control plane node"
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo -e "Generating users"

cat << EOF > user.yml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: "kubernetes"
controlPlaneEndpoint: "188.34.185.207:6443"
certificatesDir: "/etc/kubernetes/pki"
EOF

kubeadm kubeconfig user --config user.yml --org moby --client-name gspanos > gspanos.yml

echo -e "Give admin permissions"

cat << EOF > cluster-admin.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-binding
subjects:
- kind: User
  name: gspanos
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
kubectl apply -f cluster-admin.yml

echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> .bashrc
source .bashrc