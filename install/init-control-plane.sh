#!/bin/bash
set -e

clusterName="kubernetes-test"
clusterIP="49.12.111.118"
username="gpanos-test"

ufw allow ssh

echo -e "Opening ports for k8s..."

# control plane ports
ufw allow 6443/tcp
ufw allow 2379/tcp
ufw allow 2380/tcp
ufw allow 10250/tcp
ufw allow 10259/tcp
ufw allow 10257/tcp

# node ports. uncomment block if control plane should also have pods

# ufw allow 10250/tcp
# ufw allow 10256/tcp
# ufw allow 30000:32767/tcp

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

# uncomment block if control plane is also a worker 
# echo -e "remove taint of no nodes on control plane node"
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-
# modprobe br_netfilter # need this if core dns is on the same node as a pod

echo -e "Generating users"

cat << EOF > user.yml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: $clusterName
controlPlaneEndpoint: "$clusterIP:6443"
certificatesDir: "/etc/kubernetes/pki"
EOF

kubeadm kubeconfig user --config user.yml --org moby --client-name $username > $username.yml

echo -e "Give admin permissions"

cat << EOF > cluster-admin.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-binding
subjects:
- kind: User
  name: $username
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
kubectl apply -f cluster-admin.yml

echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> .bashrc
source .bashrc