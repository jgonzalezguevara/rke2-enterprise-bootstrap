#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="${1:?Indica entorno}"
I="$ROOT/inventories/$E/hosts.yml"
LOGDIR="$ROOT/artifacts/logs/$E"

"$ROOT/bootstrap/validate-environment.sh" "$E"
ansible -i "$I" rke2_cluster -m ansible.builtin.ping

read -r -p "¿Ejecutar instalación completa? [s/N]: " a
[[ "${a,,}" =~ ^(s|si|sí|y|yes)$ ]] || exit 0

mkdir -p "$LOGDIR"
LOG="$LOGDIR/deployment-$(date +%Y%m%d-%H%M%S).log"

ansible-playbook -i "$I" "$ROOT/site.yml" --ask-vault-pass | tee "$LOG"
