## Kubernetes Bare Metal Playground


- After running `install-k8s.sh` you need to
  - create a user with kubeadm as noted within `install.sh`
  - install metallb in order to have a cluster loadbalancer
  - REMEMBER TO ADD PROXY PROTOCOL TO NGINX CONTROLLER