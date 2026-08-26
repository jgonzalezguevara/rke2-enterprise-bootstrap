#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="${1:?Indica entorno}"
I="$ROOT/inventories/$E/hosts.yml"
SECURITYDIR="$ROOT/artifacts/security/$E"

[[ -f "$I" ]] || {
  echo "ERROR: falta $I" >&2
  exit 1
}

mkdir -p "$SECURITYDIR"

REPORT="$SECURITYDIR/security-$(date +%Y%m%d-%H%M%S).txt"

echo
echo "Platform security assessment"
echo "============================"
echo "Environment : $E"
echo "Report      : $REPORT"
echo

ansible-playbook \
  -i "$I" \
  "$ROOT/playbooks/security.yml" |
tee "$REPORT"

echo
echo "Security evidence stored in:"
echo "$REPORT"
