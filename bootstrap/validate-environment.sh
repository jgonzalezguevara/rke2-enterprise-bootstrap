#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="${1:?Indica entorno}"
I="$ROOT/inventories/$E/hosts.yml"
V="$ROOT/inventories/$E/group_vars/all.yml"

[[ -f "$I" && -f "$V" ]] || { echo "ERROR: inventario incompleto" >&2; exit 1; }

ansible-inventory -i "$I" --list >/dev/null
ansible-playbook -i "$I" "$ROOT/site.yml" --syntax-check --ask-vault-pass

for x in rke2_version rancher_version cert_manager_version rke2_api_hostname rancher_hostname load_balancer_ip; do
  grep -Eq "^${x}: *\"?[^\"]+" "$V" || { echo "ERROR: falta $x" >&2; exit 1; }
done

echo "[OK] Validación local completada"
ansible-inventory -i "$I" --graph
