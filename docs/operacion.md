# Operación

RKE2 Enterprise Bootstrap proporciona una interfaz única mediante
`rke2-deploy`.

## Crear un entorno

    ./rke2-deploy create

El asistente genera localmente el inventario y la configuración necesaria.

## Validar configuración

    ./rke2-deploy validate ENVIRONMENT

Comprueba la coherencia del inventario y de la topología antes de contactar
con los nodos.

## Comprobar acceso Ansible

    ./rke2-deploy ping ENVIRONMENT

Valida la conectividad SSH y la ejecución remota mediante Ansible.

## Ejecutar preflight

    ./rke2-deploy preflight ENVIRONMENT

Descubre y evalúa las capacidades de los hosts y de la red antes del
despliegue.

Los resultados se clasifican como PASS, WARN o FAIL.

## Desplegar

    ./rke2-deploy install ENVIRONMENT

El proceso valida el entorno, comprueba conectividad y solicita confirmación
antes de ejecutar la instalación completa.

La contraseña de Ansible Vault se solicita una sola vez durante la ejecución.

## Validar salud

    ./rke2-deploy health ENVIRONMENT

Comprueba el funcionamiento posterior al despliegue.

Las evidencias se almacenan en:

    artifacts/validation/<environment>/

## Consultar estado y drift

    ./rke2-deploy status ENVIRONMENT

Compara el estado observado de la plataforma con las versiones y topología
declaradas.

Es una operación de solo lectura y no requiere Ansible Vault.

Las evidencias se almacenan en:

    artifacts/status/<environment>/

## Evaluar seguridad

    ./rke2-deploy security ENVIRONMENT

Ejecuta la evaluación de postura de seguridad y Zero Trust.

Es una operación de solo lectura y no aplica remediaciones automáticas.

Las evidencias se almacenan en:

    artifacts/security/<environment>/

## Consultar inventario

    ./rke2-deploy inventory ENVIRONMENT

Muestra la estructura del inventario Ansible.

## Listar entornos

    ./rke2-deploy list

## Protección de versiones

El bootstrap no debe utilizarse como mecanismo implícito de upgrade.

Si RKE2, cert-manager o Rancher ya existen con una versión distinta de la
declarada, la ejecución se detiene.

Los upgrades deben realizarse mediante procedimientos Day-2 explícitos.

## Producción

Antes de utilizar la herramienta en producción deben revisarse:

- compatibilidad de versiones;
- networking;
- balanceadores y VIP;
- almacenamiento;
- seguridad;
- backup y recuperación;
- políticas corporativas;
- procedimientos Day-2.
