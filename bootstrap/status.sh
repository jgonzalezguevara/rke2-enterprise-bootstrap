#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="${1:?Indica entorno}"
I="$ROOT/inventories/$E/hosts.yml"
STATUSDIR="$ROOT/artifacts/status/$E"

[[ -f "$I" ]] || {
  echo "ERROR: falta $I" >&2
  exit 1
}

mkdir -p "$STATUSDIR"

REPORT="$STATUSDIR/status-$(date +%Y%m%d-%H%M%S).txt"

echo
echo "Platform status report"
echo "======================"
echo "Environment : $E"
echo "Report      : $REPORT"
echo

ansible-playbook \
  -i "$I" \
  "$ROOT/playbooks/status.yml" |
tee "$REPORT"

echo
echo "Status evidence stored in:"
echo "$REPORT"
