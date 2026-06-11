# RKE2 Enterprise Bootstrap

Repositorio orientado a despliegues base de RKE2 en entornos empresariales y laboratorios avanzados.

El objetivo de este proyecto es disponer de una estructura limpia, reproducible y fácilmente automatizable para desplegar clústeres Kubernetes basados en RKE2 siguiendo buenas prácticas habituales en entornos productivos.

Este repositorio no pretende ser un instalador cerrado, sino una base práctica para laboratorios, validaciones, automatización y despliegues reales inspirados en operación empresarial.

## Documentación relacionada

Más documentación técnica sobre Linux, Kubernetes, RKE2, automatización y operación empresarial en:

https://desdeelservidor.es

También puedes consultar la sección de proyectos:

https://desdeelservidor.es/proyectos.html


---

# Objetivos

* Simplificar despliegues iniciales de RKE2
* Mantener configuraciones reproducibles
* Facilitar troubleshooting y operación Day-2
* Servir como base para automatización futura
* Centralizar ejemplos de configuración y validaciones
* Mantener una estructura clara y reutilizable

---

# Tecnologías

* RKE2
* Kubernetes
* Linux
* systemd
* HA
* Networking
* Shell scripting

---

# Estructura del proyecto

```bash
rke2-enterprise-bootstrap/
├── README.md
├── scripts/
│   ├── install-server.sh
│   ├── install-agent.sh
│   ├── health-check.sh
│   ├── cleanup.sh
│
├── configs/
│   ├── config-server.yaml
│   ├── config-agent.yaml
│
├── docs/
│   ├── architecture.md
│   ├── troubleshooting.md
│   ├── day2-operations.md
│
├── manifests/
│   ├── example-nginx.yaml
│
├── .gitignore
```

---

# Características

* Instalación automatizada de nodos server y agent
* Ejemplos de configuración hardened
* Ejemplos de TLS SAN
* Configuración base enterprise-oriented
* Validaciones básicas de salud del clúster
* Scripts reutilizables
* Estructura preparada para automatización

---

# Escenarios previstos

* Laboratorios Kubernetes
* Entornos de pruebas
* Aprendizaje avanzado
* Bases para automatización
* Integración futura con:

  * Rancher
  * GitOps
  * Fleet
  * Longhorn
  * Monitorización
  * CI/CD

---

# Ejemplo de instalación server

```bash
curl -sfL https://get.rke2.io | sh -

mkdir -p /etc/rancher/rke2/

cp configs/config-server.yaml /etc/rancher/rke2/config.yaml

systemctl enable rke2-server.service
systemctl start rke2-server.service
```

---

# Ejemplo de instalación agent

```bash
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

mkdir -p /etc/rancher/rke2/

cp configs/config-agent.yaml /etc/rancher/rke2/config.yaml

systemctl enable rke2-agent.service
systemctl start rke2-agent.service
```

---

# Validaciones básicas

```bash
kubectl get nodes -o wide

kubectl get pods -A

systemctl status rke2-server

journalctl -u rke2-server -f
```

---

# Troubleshooting habitual

Algunos problemas típicos que suelen revisarse:

* problemas de etcd
* errores de networking
* TLS SAN incorrectos
* problemas de conectividad entre nodos
* errores de CNI
* conflictos firewall
* certificados expirados
* nodos NotReady

La documentación de troubleshooting irá ampliándose progresivamente.

---

# Roadmap

Pendiente de incorporar:

* HA con VIP
* integración Rancher
* ejemplos con Longhorn
* ejemplos GitOps
* ejemplos Fleet
* hardening adicional
* integración observabilidad
* integración con Terraform
* integración con Proxmox
* soporte edge/labs

---

# Importante

Este repositorio está orientado a:

* laboratorio
* aprendizaje
* automatización
* despliegues de referencia

No debe utilizarse directamente en producción sin revisión y adaptación previa a los requisitos de cada entorno.

---

# Autor

Jose Gonzalez

Linux Systems Engineer
Kubernetes | Linux | RKE2 | Observabilidad | Automatización


## Más recursos

📚 Biblioteca Linux y DevOps  
https://desdeelservidor.es/biblioteca-linux-devops.html

👨‍💻 Sobre el autor  
https://desdeelservidor.es/autor-jose-gonzalez.html

🎓 Formación Linux y Troubleshooting  
https://desdeelservidor.es/formacion.html

📰 Newsletter Linux y Sistemas  
https://desdeelservidor.es/newsletter.html
