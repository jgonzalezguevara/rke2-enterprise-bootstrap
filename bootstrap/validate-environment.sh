#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="${1:?Indica entorno}"

I="$ROOT/inventories/$E/hosts.yml"
V="$ROOT/inventories/$E/group_vars/all.yml"
VAULT="$ROOT/inventories/$E/group_vars/vault.yml"

[[ -f "$I" ]] || {
  echo "ERROR: falta $I" >&2
  exit 1
}

[[ -f "$V" ]] || {
  echo "ERROR: falta $V" >&2
  exit 1
}

[[ -f "$VAULT" ]] || {
  echo "ERROR: falta $VAULT" >&2
  exit 1
}

echo
echo "Environment Validation"
echo "======================"
echo
echo "Environment : $E"
echo

TMP_INVENTORY="$(mktemp)"
trap 'rm -f "$TMP_INVENTORY"' EXIT

ansible-inventory \
  -i "$I" \
  --list \
  > "$TMP_INVENTORY"

python3 - "$TMP_INVENTORY" <<'PY'
import json
import sys

inventory_file = sys.argv[1]

with open(inventory_file) as f:
    data = json.load(f)

required_groups = (
    "rke2_cluster",
    "rke2_servers",
)

for group in required_groups:
    if group not in data:
        raise SystemExit(
            f"ERROR: missing required inventory group: {group}"
        )

servers = data["rke2_servers"].get("hosts", [])

# Ansible may omit empty groups from --list output.
# An environment with zero agents is valid.
agents = data.get("rke2_agents", {}).get("hosts", [])

server_count = len(servers)
agent_count = len(agents)
node_count = server_count + agent_count

if server_count < 1:
    raise SystemExit(
        "ERROR: at least one RKE2 server is required"
    )

hostvars = data.get("_meta", {}).get("hostvars", {})

first_server = servers[0]

vars_data = hostvars.get(first_server, {})

required_variables = (
    "environment_name",
    "cluster_name",
    "deployment_topology",
    "expected_rke2_servers",
    "expected_rke2_agents",
    "expected_cluster_nodes",
    "rke2_version",
    "rancher_version",
    "cert_manager_version",
    "rke2_api_hostname",
    "rancher_hostname",
    "load_balancer_ip",
    "rke2_cluster_cidr",
    "rke2_service_cidr",
    "rke2_cluster_dns",
    "rke2_cni",
)

missing = [
    name
    for name in required_variables
    if name not in vars_data
]

if missing:
    raise SystemExit(
        "ERROR: missing required variables: "
        + ", ".join(missing)
    )

topology = str(
    vars_data["deployment_topology"]
).strip().lower()

if topology not in ("single", "ha"):
    raise SystemExit(
        "ERROR: deployment_topology must be 'single' or 'ha'"
    )

if topology == "single":
    if server_count != 1:
        raise SystemExit(
            "ERROR: single topology requires exactly "
            "one RKE2 server"
        )

elif topology == "ha":
    if server_count < 3:
        raise SystemExit(
            "ERROR: HA topology requires at least "
            "three RKE2 servers"
        )

    if server_count % 2 == 0:
        raise SystemExit(
            "ERROR: HA topology requires an odd "
            "number of RKE2 servers"
        )

expected_servers = int(
    vars_data["expected_rke2_servers"]
)

expected_agents = int(
    vars_data["expected_rke2_agents"]
)

expected_nodes = int(
    vars_data["expected_cluster_nodes"]
)

if expected_servers != server_count:
    raise SystemExit(
        "ERROR: expected_rke2_servers does not match "
        f"inventory ({expected_servers} != {server_count})"
    )

if expected_agents != agent_count:
    raise SystemExit(
        "ERROR: expected_rke2_agents does not match "
        f"inventory ({expected_agents} != {agent_count})"
    )

if expected_nodes != node_count:
    raise SystemExit(
        "ERROR: expected_cluster_nodes does not match "
        f"inventory ({expected_nodes} != {node_count})"
    )

first_servers = [
    host
    for host in servers
    if hostvars.get(host, {}).get(
        "rke2_first_server", False
    )
]

if len(first_servers) != 1:
    raise SystemExit(
        "ERROR: exactly one RKE2 server must have "
        "rke2_first_server=true"
    )

if first_servers[0] != first_server:
    raise SystemExit(
        "ERROR: the first server in inventory must be "
        "the RKE2 bootstrap server"
    )

print("Topology")
print("--------")
print(f"Mode        : {topology}")
print(f"Servers     : {server_count}")
print(f"Agents      : {agent_count}")
print(f"Total nodes : {node_count}")
print(f"Bootstrap   : {first_server}")
print()
print("Inventory topology: OK")
PY

echo
echo "Ansible syntax"
echo "--------------"

VAULT_ARGS=()

if [[ -n "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]]; then
  VAULT_ARGS=(
    --vault-password-file
    "$ANSIBLE_VAULT_PASSWORD_FILE"
  )
else
  VAULT_ARGS=(
    --ask-vault-pass
  )
fi

ansible-playbook \
  -i "$I" \
  "$ROOT/site.yml" \
  --syntax-check \
  "${VAULT_ARGS[@]}"

echo
echo "[OK] Environment validation completed"
echo

ansible-inventory \
  -i "$I" \
  --graph
