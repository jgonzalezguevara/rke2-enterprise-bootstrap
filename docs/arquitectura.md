# Arquitectura

RKE2 Enterprise Bootstrap automatiza el ciclo inicial de validación,
despliegue y evaluación de una plataforma RKE2 sobre hosts Linux existentes.

## Nodo de control

La automatización se ejecuta desde un host Linux con Ansible.

El nodo de control:

- mantiene los inventarios;
- ejecuta las validaciones locales;
- realiza el preflight remoto;
- prepara los sistemas operativos;
- despliega RKE2;
- instala cert-manager y Rancher;
- ejecuta las validaciones posteriores;
- genera evidencias operativas locales.

Los entornos reales y sus secretos no forman parte del repositorio.

## Topologías

Se soportan dos topologías.

### Single-node

- exactamente 1 RKE2 Server;
- 0 o más RKE2 Agents;
- Rancher con una réplica;
- sin alta disponibilidad del control plane ni de etcd.

### High Availability

- mínimo 3 RKE2 Servers;
- número impar de servidores;
- etcd embebido distribuido;
- 0 o más RKE2 Agents;
- endpoint estable mediante VIP o balanceador;
- Rancher con tres réplicas.

## RKE2 Servers

El primer servidor, identificado mediante `rke2_first_server=true`,
inicializa el clúster.

Los servidores restantes se incorporan secuencialmente utilizando el endpoint
estable de RKE2.

El bootstrap valida la versión RKE2 existente antes de modificar la
configuración. Un cambio de versión requiere un procedimiento Day-2 explícito.

## RKE2 Agents

Los RKE2 Agents se incorporan mediante el endpoint estable de registro.

El número de agents es configurable y puede ser cero.

## Endpoint estable

RKE2 utiliza principalmente:

- TCP 9345 para registro y comunicación entre nodos;
- TCP 6443 para Kubernetes API.

En topología `single`, el endpoint corresponde al RKE2 Server.

En topología `ha`, la infraestructura debe proporcionar una VIP, balanceador
u otro mecanismo equivalente.

## cert-manager y Rancher

Después de que todos los nodos esperados estén disponibles, cert-manager y
Rancher se gestionan mediante Helm desde Ansible.

Las releases existentes se inspeccionan antes de realizar cambios.

El bootstrap no realiza upgrades implícitos de cert-manager ni Rancher.

## Validación

Después del despliegue puede ejecutarse:

`./rke2-deploy health ENVIRONMENT`

La validación comprueba, entre otros:

- Kubernetes API;
- estado de nodos y workloads;
- etcd;
- cert-manager;
- Rancher;
- conectividad entre nodos;
- CoreDNS;
- resolución DNS interna;
- servicio interno de Kubernetes.

## Estado observado y drift

`./rke2-deploy status ENVIRONMENT`

recoge el estado observado de la plataforma y lo compara con el estado
declarado.

La evaluación incluye:

- versiones RKE2 por nodo;
- número de nodos;
- miembros y salud de etcd;
- versiones de Rancher y cert-manager;
- desviaciones entre estado deseado y observado.

La operación es de solo lectura.

## Seguridad y Zero Trust

`./rke2-deploy security ENVIRONMENT`

realiza una evaluación de seguridad de solo lectura sobre hosts y Kubernetes.

Los controles incluyen:

- SSH y autenticación;
- firewall;
- SELinux y AppArmor;
- permisos de configuración;
- identidad y RBAC;
- NetworkPolicy;
- Pod Security Admission;
- workloads privilegiados;
- exposición de servicios;
- audit logging;
- cifrado de Secrets en reposo;
- hardening declarado de RKE2.

## Flujo

    Control node
         |
         v
    Environment
      validation
         |
         v
      Preflight
         |
         v
    OS preparation
         |
         v
    RKE2 servers
         |
         v
    RKE2 agents
         |
         v
    cert-manager
         |
         v
       Rancher
         |
         v
     Validation
         |
      +--+--+
      |     |
      v     v
    Status Security
      |     |
      +--+--+
         |
         v
    Local evidence
