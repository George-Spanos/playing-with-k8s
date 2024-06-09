## Kubernetes Bare Metal Playground


- After running `install-k8s.sh` you need to
  - create a user with kubeadm as noted within `install.sh`
  - install metallb in order to have a cluster loadbalancer
  - REMEMBER TO ADD PROXY PROTOCOL TO NGINX CONTROLLER

Ingress Notes

- Do the issuers need to be on the same namespace? **Yes**
- Does the ingress need? `acme.cert-manager.io/http01-edit-in-place: "true", nginx.ingress.kubernetes.io/force-ssl-redirect: "false"`
  - **Only `acme.cert-manager.io/http01-edit-in-place: "true"` is needed**
- does the app service need to be cluster ip? Is it better to be load balancer? It can be load balancer as well
  - the idea is that the load balancer is intended for services you expose outside of the cluster. Cluster IP is fine for internal services

## Next Steps

- Add a database. Easy
- Have it have persistent cloud storage/volume. Easy with [hetzner csi](https://github.com/hetznercloud/csi-driver/blob/main/docs/kubernetes/README.md#getting-started)
- Configure Continuous Delivery on PR create.