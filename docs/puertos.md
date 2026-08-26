# Puertos principales

Los requisitos exactos dependen de la topología, CNI y componentes
habilitados.

Puertos principales utilizados por una plataforma RKE2:

| Puerto | Protocolo | Uso |
| --- | --- | --- |
| 22 | TCP | Administración SSH desde el nodo de control |
| 9345 | TCP | Registro y comunicación de nodos RKE2 |
| 6443 | TCP | Kubernetes API |
| 2379-2380 | TCP | etcd entre RKE2 Servers |
| 10250 | TCP | kubelet |
| 8472 | UDP | VXLAN cuando se utiliza Canal/Flannel |
| 80 | TCP | HTTP / ingress cuando corresponda |
| 443 | TCP | HTTPS / ingress / Rancher cuando corresponda |

El preflight del proyecto realiza comprobaciones de conectividad y detecta
posibles conflictos antes del despliegue.

Esta tabla resume únicamente los puertos principales. Antes de desplegar en
producción debe validarse la matriz completa de comunicaciones requerida por
la versión de RKE2, el CNI seleccionado y las políticas de red de la
organización.
