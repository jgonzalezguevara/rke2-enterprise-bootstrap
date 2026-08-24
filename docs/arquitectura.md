# Arquitectura

RKE2 Enterprise Bootstrap utiliza una topología configurable.

## Nodo de control

La automatización se ejecuta desde un host Linux con Ansible.

## RKE2 Servers

El número de nodos RKE2 Server es configurable.

Para topologías HA con etcd embebido, el asistente exige:

- Un mínimo de 3 servidores.
- Un número impar de servidores.

El primer servidor inicializa el clúster y los servidores restantes se incorporan secuencialmente utilizando el endpoint estable de RKE2.

## RKE2 Agents

El número de nodos RKE2 Agent es configurable y puede ser cero.

Los agents se incorporan al clúster mediante el endpoint estable de registro RKE2.

## Endpoint estable

La infraestructura debe proporcionar un endpoint estable para:

- TCP 9345: registro y comunicación de nodos RKE2.
- TCP 6443: Kubernetes API.

El endpoint puede implementarse mediante un balanceador, VIP u otra solución equivalente.

## Rancher

Rancher se instala sobre el clúster mediante Helm después de validar que todos los nodos esperados están en estado Ready.

El número de réplicas de Rancher es configurable.

## Flujo

```text
Ansible control node
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

```

