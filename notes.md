## Kubernetes Bare Metal Playground


- After running `install-k8s.sh` you need to
  - create a user with kubeadm as noted within `install.sh`
  - install metallb in order to have a cluster loadbalancer
  - REMEMBER TO ADD PROXY PROTOCOL TO NGINX CONTROLLER

It seems that cert manager might not play well with nginx helm from nginx. Try [this helm](https://kubernetes.github.io/ingress-nginx/)

Made it work! Test the following:

- Do the issuers need to be on the same namespace?
- Does the ingress need? `acme.cert-manager.io/http01-edit-in-place: "true", nginx.ingress.kubernetes.io/force-ssl-redirect: "false"`
- does the app service need to be cluster ip? Is it better to be load balancer?