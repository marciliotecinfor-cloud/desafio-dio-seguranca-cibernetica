#!/usr/bin/env bash
# Verificação básica de conectividade/portas para o laboratório autorizado.
# Uso: ./scripts/precheck.sh 192.168.56.102
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 IP_DO_ALVO_DO_LAB"
  exit 1
fi

TARGET="$1"
echo "[+] Alvo informado: $TARGET"
echo "[+] Confirme que este IP pertence à sua VM isolada antes de continuar."
ping -c 2 "$TARGET" || true
nmap -sV -p 21,80,139,445 "$TARGET"
