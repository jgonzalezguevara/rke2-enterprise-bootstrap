# Puertos principales

- TCP 22: SSH.
- TCP 9345: registro RKE2.
- TCP 6443: Kubernetes API.
- TCP 2379-2380: etcd entre masters.
- TCP 10250: kubelet.
- UDP 8472: VXLAN para Canal/Flannel.
- TCP 80/443: ingress y Rancher.

Confirma la matriz completa con el equipo de red del cliente.
