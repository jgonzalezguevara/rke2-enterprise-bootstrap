#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ask() {
  local value=""

  while [[ -z "$value" ]]; do
    read -r -p "$1: " value
  done

  printf '%s' "$value"
}

def() {
  local value=""

  read -r -p "$1 [$2]: " value

  printf '%s' "${value:-$2}"
}

ask_integer() {
  local prompt="$1"
  local example="$2"
  local minimum="${3:-0}"
  local value

  while true; do
    value="$(def "$prompt" "$example")"

    if [[ "$value" =~ ^[0-9]+$ ]] && (( value >= minimum )); then
      printf '%s' "$value"
      return
    fi

    echo "Valor no válido. Debe ser un número >= ${minimum}." >&2
  done
}

ask_ip() {
  local value

  while true; do
    value="$(ask "$1")"

    if python3 -c \
      'import ipaddress,sys; ipaddress.ip_address(sys.argv[1])' \
      "$value" 2>/dev/null
    then
      printf '%s' "$value"
      return
    fi

    echo "IP no válida." >&2
  done
}

ask_hostname() {
  local value

  while true; do
    value="$(ask "$1")"

    if python3 - "$value" <<'PYVALIDATE'
import ipaddress
import re
import sys

value = sys.argv[1].strip()

try:
    ipaddress.ip_address(value)
    sys.exit(1)
except ValueError:
    pass

pattern = re.compile(
    r"^(?=.{1,253}$)"
    r"(?!-)"
    r"[A-Za-z0-9]"
    r"(?:[A-Za-z0-9.-]*[A-Za-z0-9])?$"
)

sys.exit(0 if pattern.fullmatch(value) else 1)
PYVALIDATE
    then
      printf '%s' "$value"
      return
    fi

    echo "Hostname no válido. Ejemplo: rke2-server-01" >&2
  done
}

ask_dns() {
  local value

  while true; do
    value="$(ask "$1")"

    if python3 - "$value" <<'PYVALIDATE'
import ipaddress
import re
import sys

value = sys.argv[1].strip().lower()

try:
    ipaddress.ip_address(value)
    sys.exit(1)
except ValueError:
    pass

if "." not in value:
    sys.exit(1)

labels = value.rstrip(".").split(".")

valid = all(
    1 <= len(label) <= 63
    and re.fullmatch(
        r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
        label
    )
    for label in labels
)

sys.exit(0 if valid else 1)
PYVALIDATE
    then
      printf '%s' "${value,,}"
      return
    fi

    echo "DNS no válido. Ejemplo: api.lab.example" >&2
  done
}

ask_rke2_version() {
  local value

  while true; do
    value="$(ask "$1")"

    if [[ "$value" =~ ^v[0-9]+\.[0-9]+\.[0-9]+\+rke2r[0-9]+$ ]]; then
      printf '%s' "$value"
      return
    fi

    echo "Formato incorrecto. Ejemplo: v1.34.10+rke2r1" >&2
  done
}

echo
echo "RKE2 Enterprise Bootstrap"
echo "========================="
echo

name="$(ask 'Nombre corto del entorno (example: production)')"
name="${name,,}"

if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "ERROR: usa minúsculas, números y guiones." >&2
  exit 1
fi

dir="$ROOT/inventories/$name"

if [[ -e "$dir" ]]; then
  echo "ERROR: ya existe $dir" >&2
  exit 1
fi

cluster="$(def 'Nombre del clúster' "$name")"
user="$(def 'Usuario SSH' 'root')"
port="$(def 'Puerto SSH' '22')"
key="$(def 'Clave privada SSH' "$HOME/.ssh/id_ed25519")"

echo
echo "Cluster topology"
echo "----------------"
echo
echo "Selecciona la topología de despliegue:"
echo
echo "  1) Single-node / laboratorio"
echo "     Un único RKE2 Server. Sin alta disponibilidad."
echo
echo "  2) HA"
echo "     Tres o más RKE2 Servers, siempre en número impar."
echo

while true; do
  read -r -p "Topología [1/2] (default: 2): " topology_choice
  topology_choice="${topology_choice:-2}"

  case "$topology_choice" in
    1)
      deployment_topology="single"
      server_count=1
      break
      ;;
    2)
      deployment_topology="ha"

      while true; do
        server_count="$(ask_integer 'Número de RKE2 servers' '3' '3')"

        if (( server_count % 2 == 0 )); then
          echo "El número de RKE2 servers debe ser impar para una topología etcd HA." >&2
          continue
        fi

        break
      done

      break
      ;;
    *)
      echo "Opción no válida. Selecciona 1 o 2." >&2
      ;;
  esac
done

agent_count="$(ask_integer 'Número de RKE2 agents' '0' '0')"

declare -a server_hostnames
declare -a server_ips
declare -a agent_hostnames
declare -a agent_ips

echo
echo "RKE2 servers"
echo "------------"

for ((i=1; i<=server_count; i++)); do
  server_hostnames+=(
    "$(ask_hostname "Hostname server ${i} (example: rke2-server-$(printf '%02d' "$i"))")"
  )

  server_ips+=(
    "$(ask_ip "IP server ${i} (example: 192.168.10.$((10+i)))")"
  )
done

if (( agent_count > 0 )); then
  echo
  echo "RKE2 agents"
  echo "-----------"

  for ((i=1; i<=agent_count; i++)); do
    agent_hostnames+=(
      "$(ask_hostname "Hostname agent ${i} (example: rke2-agent-$(printf '%02d' "$i"))")"
    )

    agent_ips+=(
      "$(ask_ip "IP agent ${i} (example: 192.168.10.$((20+i)))")"
    )
  done
fi

echo
echo "Cluster endpoints"
echo "-----------------"

api="$(ask_dns 'DNS fijo API/registro RKE2 (example: api.cluster.example)')"
rancher="$(ask_dns 'DNS de Rancher (example: rancher.cluster.example)')"

if [[ "$deployment_topology" == "ha" ]]; then
  vip="$(ask_ip 'VIP/IP del balanceador (example: 192.168.10.10)')"
  rke2_endpoint_ip="$vip"
  rancher_replicas=3
else
  vip=""
  rke2_endpoint_ip="${server_ips[0]}"
  rancher_replicas=1
fi

echo
echo "Kubernetes networks"
echo "-------------------"

pods="$(def 'CIDR pods' '10.42.0.0/16')"
services="$(def 'CIDR servicios' '10.43.0.0/16')"
dns="$(def 'DNS Kubernetes' '10.43.0.10')"

echo
echo "Versions"
echo "--------"

rke2="$(ask_rke2_version 'Versión RKE2 (example: v1.34.10+rke2r1)')"
rancherv="$(ask 'Versión chart Rancher (example: 2.14.3)')"
cm="$(ask 'Versión cert-manager (example: v1.18.2)')"

all_hostnames=(
  "${server_hostnames[@]}"
  "${agent_hostnames[@]}"
)

all_ips=(
  "${server_ips[@]}"
  "${agent_ips[@]}"
)

if [[ "$(printf '%s\n' "${all_hostnames[@]}" | sort -u | wc -l)" -ne "${#all_hostnames[@]}" ]]; then
  echo "ERROR: hay hostnames duplicados." >&2
  exit 1
fi

if [[ "$(printf '%s\n' "${all_ips[@]}" | sort -u | wc -l)" -ne "${#all_ips[@]}" ]]; then
  echo "ERROR: hay direcciones IP duplicadas." >&2
  exit 1
fi

if [[ "$deployment_topology" == "ha" ]]; then
  for node_ip in "${all_ips[@]}"; do
    if [[ "$vip" == "$node_ip" ]]; then
      echo "ERROR: la VIP no puede coincidir con la IP de un nodo." >&2
      exit 1
    fi
  done
fi

echo
echo "============================================================"
echo "SUMMARY"
echo "============================================================"
echo "Environment : $name"
echo "Cluster     : $cluster"
echo "Topology    : $deployment_topology"
echo
echo "RKE2 servers: $server_count"

for ((i=0; i<server_count; i++)); do
  printf '  %-30s %s\n' \
    "${server_hostnames[$i]}" \
    "${server_ips[$i]}"
done

echo
echo "RKE2 agents : $agent_count"

for ((i=0; i<agent_count; i++)); do
  printf '  %-30s %s\n' \
    "${agent_hostnames[$i]}" \
    "${agent_ips[$i]}"
done

echo
echo "API endpoint : $api"
echo "Endpoint IP  : $rke2_endpoint_ip"
echo "Rancher      : $rancher"

if [[ "$deployment_topology" == "ha" ]]; then
  echo "Load balancer: $vip"
else
  echo "Load balancer: not required (single-node)"
fi
echo
echo "RKE2         : $rke2"
echo "Rancher      : $rancherv"
echo "cert-manager : $cm"
echo "============================================================"
echo

read -r -p "¿Los datos son correctos? [s/N]: " confirmation

case "${confirmation,,}" in
  s|si|sí|y|yes)
    ;;
  *)
    echo "Operación cancelada. No se ha creado el entorno."
    exit 0
    ;;
esac

read -r -s -p "Token RKE2 (vacío = generar): " token
echo

if [[ -z "$token" ]]; then
  token="$(openssl rand -hex 32)"
fi

read -r -s -p "Contraseña bootstrap Rancher: " rancherpass
echo

if [[ -z "$rancherpass" ]]; then
  echo "ERROR: contraseña obligatoria." >&2
  exit 1
fi

mkdir -p "$dir/group_vars"

{
  echo "---"
  echo "all:"
  echo "  children:"
  echo "    rke2_cluster:"
  echo "      children:"
  echo "        rke2_servers:"
  echo "          hosts:"

  for ((i=0; i<server_count; i++)); do
    echo "            ${server_hostnames[$i]}:"
    echo "              ansible_host: ${server_ips[$i]}"

    if (( i == 0 )); then
      echo "              rke2_first_server: true"
    fi
  done

  echo "        rke2_agents:"

  if (( agent_count > 0 )); then
    echo "          hosts:"

    for ((i=0; i<agent_count; i++)); do
      echo "            ${agent_hostnames[$i]}:"
      echo "              ansible_host: ${agent_ips[$i]}"
    done
  else
    echo "          hosts: {}"
  fi

  echo "  vars:"
  echo "    ansible_user: $user"
  echo "    ansible_port: $port"
  echo "    ansible_ssh_private_key_file: $key"
  echo "    ansible_python_interpreter: /usr/bin/python3"

} > "$dir/hosts.yml"

cat > "$dir/group_vars/all.yml" <<EOF_VARS
---
environment_name: "$name"
cluster_name: "$cluster"

deployment_topology: "$deployment_topology"

minimum_vcpus: 4
minimum_memory_mb: 7800

expected_rke2_servers: $server_count
expected_rke2_agents: $agent_count
expected_cluster_nodes: $((server_count + agent_count))

rke2_api_hostname: "$api"
rke2_endpoint_ip: "$rke2_endpoint_ip"
rancher_hostname: "$rancher"
load_balancer_ip: "$vip"

rke2_cluster_cidr: "$pods"
rke2_service_cidr: "$services"
rke2_cluster_dns: "$dns"
rke2_cni: "canal"

rke2_version: "$rke2"
rancher_version: "$rancherv"
cert_manager_version: "$cm"

rancher_replicas: $rancher_replicas
rancher_tls_source: "rancher"
EOF_VARS

cat > "$dir/group_vars/vault.yml" <<EOF_VAULT
---
vault_rke2_token: "$token"
vault_rancher_bootstrap_password: "$rancherpass"
EOF_VAULT

chmod 600 "$dir/group_vars/vault.yml"

ansible-vault encrypt "$dir/group_vars/vault.yml"

echo
echo "Entorno creado:"
echo "  $dir"
echo
echo "Siguiente paso:"
echo "  ./rke2-deploy validate $name"
echo
