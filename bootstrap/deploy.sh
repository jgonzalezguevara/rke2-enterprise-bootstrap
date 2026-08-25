#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="${1:?Indica entorno}"
I="$ROOT/inventories/$E/hosts.yml"
V="$ROOT/inventories/$E/group_vars/all.yml"
VAULT="$ROOT/inventories/$E/group_vars/vault.yml"
LOGDIR="$ROOT/artifacts/logs/$E"

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

VAULT_PASSWORD_FILE=""

cleanup() {
  if [[ -n "$VAULT_PASSWORD_FILE" ]]; then
    rm -f "$VAULT_PASSWORD_FILE"
  fi
}

trap cleanup EXIT INT TERM

VAULT_PASSWORD_FILE="$(mktemp)"
chmod 600 "$VAULT_PASSWORD_FILE"

read -r -s -p "Vault password: " vault_password
echo

printf '%s\n' "$vault_password" > "$VAULT_PASSWORD_FILE"
unset vault_password

export ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_PASSWORD_FILE"

"$ROOT/bootstrap/validate-environment.sh" "$E"

ansible \
  -i "$I" \
  rke2_cluster \
  -m ansible.builtin.ping

read -r -p "¿Ejecutar instalación completa? [s/N]: " a
[[ "${a,,}" =~ ^(s|si|sí|y|yes)$ ]] || exit 0

mkdir -p "$LOGDIR"
LOG="$LOGDIR/deployment-$(date +%Y%m%d-%H%M%S).log"

ansible-playbook \
  -i "$I" \
  "$ROOT/site.yml" \
  --vault-password-file "$VAULT_PASSWORD_FILE" |
tee "$LOG"
