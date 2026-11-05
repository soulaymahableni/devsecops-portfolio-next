#!/usr/bin/env bash
# Q135 : supprime toute la plateforme (ressources Terraform, conteneurs, volumes).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
START=$(date +%s)

echo "[1/2] Terraform : destruction des ressources"
if [ -d terraform/envs/platform/.terraform ]; then (cd terraform/envs/platform && terraform destroy -auto-approve -input=false | tail -3); else echo "(rien à détruire)"; fi

echo "[2/2] Docker : suppression des conteneurs et des volumes"
docker compose down -v
rm -rf automation/generated

echo "Suppression terminée en $(( $(date +%s) - START )) secondes."
