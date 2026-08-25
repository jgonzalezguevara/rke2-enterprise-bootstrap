# RKE2 Enterprise Bootstrap

Automatización reproducible para validar, preparar y desplegar clústeres RKE2 con Rancher sobre infraestructura Linux compatible.

El proyecto está diseñado para partir de hosts existentes sin asumir una distribución Linux concreta. Antes de realizar cambios, ejecuta un preflight que descubre las capacidades de cada nodo, comprueba requisitos técnicos, analiza red y estado previo y genera un informe de compatibilidad.

## Objetivo

Convertir el despliegue inicial de una plataforma RKE2 en un proceso:

- reproducible;
- parametrizable;
- validable;
- auditable;
- independiente de una distribución Linux concreta;
- preparado para crecer hacia operación Day-2.

La herramienta no necesita saber previamente si los hosts utilizan Ubuntu, SLES, Debian, Rocky Linux u otra distribución.

Comprueba qué capacidades proporciona realmente cada sistema y determina si cumple los requisitos necesarios para RKE2.

## Flujo

```text
CREATE ENVIRONMENT
        |
        v
VALIDATE
        |
        v
PREFLIGHT
  |
  +-- host discovery
  +-- network discovery
  +-- host state
  +-- online connectivity
  +-- evaluation
  +-- report
  +-- enforcement
        |
        v
OS PREPARATION
        |
        v
RKE2 SERVERS
        |
        v
RKE2 AGENTS
        |
        v
CERT-MANAGER
        |
        v
RANCHER
        |
        v
VALIDATION
```

## Características actuales

### Topología dinámica

El asistente soporta dos modelos de despliegue:

#### Single-node

Pensado para laboratorio, validación y entornos no HA.

- 1 nodo RKE2 Server.
- 0 o más nodos RKE2 Agent.
- Sin alta disponibilidad del control plane ni de etcd.

#### High Availability

Pensado para plataformas con etcd embebido distribuido.

- Mínimo de 3 nodos RKE2 Server.
- El número de servers debe ser impar.
- 0 o más nodos RKE2 Agent.

Además, el asistente permite definir:

- endpoint estable para RKE2;
- VIP o dirección del balanceador;
- redes de pods y servicios;
- DNS interno de Kubernetes;
- versiones de RKE2, Rancher y cert-manager.

La topología elegida se almacena en el inventario mediante
`deployment_topology`.

El comportamiento del endpoint depende de la topología:

- En `single`, `rke2_endpoint_ip` corresponde a la IP del único RKE2 Server,
  no se requiere `load_balancer_ip` y Rancher utiliza una réplica.
- En `ha`, `rke2_endpoint_ip` corresponde a la VIP o dirección del balanceador,
  `load_balancer_ip` es obligatorio y Rancher utiliza tres réplicas.
- `rke2_api_hostname` se mantiene como nombre estable del endpoint RKE2 en
  ambos modelos.
- Los TLS SAN de los servidores incluyen el hostname del API y el endpoint IP
  efectivo de la topología.

La validación local comprueba antes del despliegue:

- que exista al menos un RKE2 Server;
- que una topología `single` tenga exactamente un server;
- que una topología `ha` tenga al menos tres servers y un número impar;
- que exista exactamente un nodo bootstrap con `rke2_first_server=true`;
- que los contadores `expected_rke2_servers`, `expected_rke2_agents` y
  `expected_cluster_nodes` coincidan con el inventario real;
- que estén presentes las variables obligatorias del entorno.

### Preflight basado en capacidades

Antes del despliegue se comprueban, entre otros:

- sistema Linux;
- arquitectura;
- CPU y memoria;
- systemd;
- cgroups;
- módulos overlay y br_netfilter;
- swap;
- espacio disponible;
- DNS;
- interfaz, gateway y MTU;
- conectividad entre nodos;
- conflictos con los CIDR de Kubernetes;
- puertos utilizados por RKE2;
- instalaciones RKE2 previas;
- firewall;
- SELinux;
- AppArmor;
- proxy;
- Docker y containerd existentes;
- acceso al instalador RKE2;
- acceso a los repositorios Helm necesarios.

Los checks se clasifican como PASS, WARN o FAIL.

El informe se muestra antes de bloquear una instalación incompatible.

### Convergencia y protección de versiones

El bootstrap está diseñado para poder converger sobre hosts ya preparados sin
reinstalar componentes innecesariamente.

Durante una ejecución:

- la preparación del sistema utiliza módulos declarativos de Ansible;
- los parámetros `sysctl` se mantienen en `/etc/sysctl.d/90-rke2.conf`;
- RKE2 no se reinstala cuando ya está presente con la versión solicitada;
- la configuración de RKE2 solo provoca un reinicio cuando cambia;
- cert-manager y Rancher se gestionan mediante módulos Helm de Ansible;
- las releases existentes se inspeccionan antes de modificarlas;
- los cambios de versión de RKE2, cert-manager o Rancher se bloquean durante
  el bootstrap y deben realizarse mediante un procedimiento Day-2 explícito.

Esto evita convertir una segunda ejecución del bootstrap en un upgrade
implícito de la plataforma.

La contraseña de Ansible Vault se solicita una sola vez durante `install` y se
reutiliza únicamente durante esa ejecución mediante un fichero temporal con
permisos restrictivos, eliminado automáticamente al finalizar.

> La convergencia está implementada por diseño y validada mediante análisis
> estático y comprobaciones de sintaxis. La idempotencia completa debe
> verificarse también mediante ejecuciones repetidas sobre un clúster de
> integración real.

### Estado observado y detección de drift

Consultar el estado observado de una plataforma desplegada:

```bash
./rke2-deploy status ENVIRONMENT
```

`status` es una operación de solo lectura y no requiere Ansible Vault.

Recoge y compara:

- versión RKE2 instalada en cada nodo;
- versión RKE2 declarada;
- número de nodos observado y esperado;
- miembros y salud de etcd;
- release de Rancher;
- release de cert-manager;
- topología declarada;
- desviaciones entre estado deseado y observado.

El comando informa del drift sin modificar la plataforma ni bloquear la
consulta.

Cada ejecución conserva una evidencia local en:

```text
artifacts/status/<environment>/
```

### Seguridad de configuración

Los entornos reales se generan localmente dentro de:

```text
inventories/<environment>/
```

y están excluidos de Git.

Las credenciales se almacenan en un fichero protegido mediante Ansible Vault.

El repositorio público contiene únicamente:

```text
inventories/example/
```

con nombres y direcciones reservados para documentación.

### Instalación

El proceso instala y configura:

- RKE2 Server;
- RKE2 Agent;
- etcd embebido en topologías HA;
- Helm;
- cert-manager;
- SUSE Rancher.

Los nodos se incorporan secuencialmente al clúster.

## Uso

Crear un entorno:

```bash
./rke2-deploy create
```

Validar su configuración:

```bash
./rke2-deploy validate ENVIRONMENT
```

Comprobar conectividad Ansible:

```bash
./rke2-deploy ping ENVIRONMENT
```

Ejecutar el preflight:

```bash
./rke2-deploy preflight ENVIRONMENT
```

Mostrar el inventario:

```bash
./rke2-deploy inventory ENVIRONMENT
```

Desplegar:

```bash
./rke2-deploy install ENVIRONMENT
```

Validar la salud de una plataforma desplegada:

```bash
./rke2-deploy health ENVIRONMENT
```

El health check valida Kubernetes, estado de nodos y workloads, etcd,
cert-manager, Rancher, conectividad TCP entre nodos, CoreDNS,
resolución DNS interna y el servicio interno de Kubernetes.

Las evidencias se almacenan localmente en:

```text
artifacts/validation/<environment>/
```

Listar entornos:

```bash
./rke2-deploy list
```

## Requisitos del nodo de control

- Linux.
- Ansible.
- Python 3.
- OpenSSH client.
- OpenSSL.
- Acceso SSH a los hosts destino.

Instala las colecciones de Ansible requeridas con:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Arquitectura

Consulta:

- docs/arquitectura.md
- docs/puertos.md
- docs/operacion.md

## Estructura principal

```text
rke2-enterprise-bootstrap/
|-- bootstrap/
|-- docs/
|-- inventories/
|   `-- example/
|-- playbooks/
|-- roles/
|   |-- os_prepare/
|   |-- preflight/
|   |-- rancher/
|   |-- rke2/
|   `-- validation/
|-- artifacts/
|-- rke2-deploy
|-- site.yml
|-- requirements.yml
`-- ansible.cfg
```

## Roadmap

Capacidades previstas:

- validación avanzada de networking y puertos;
- instalación air-gap;
- private registries;
- backup y restore de etcd;
- upgrades controlados de RKE2;
- upgrades de Rancher;
- hardening;
- almacenamiento;
- observabilidad;
- reporting;
- validaciones Day-2;
- GitOps y Fleet.

## Estado

PoC funcional en desarrollo activo.

No debe utilizarse directamente en producción sin revisar previamente requisitos, versiones soportadas, networking, seguridad, almacenamiento y políticas específicas del entorno.

## Autor

Jose Gonzalez

Systems & Platform Engineer

Linux · Kubernetes · RKE2 · SUSE · Automation

Más contenido técnico:

- https://desdeelservidor.es
- https://desdeelservidor.es/proyectos.html
- https://github.com/jgonzalezguevara
