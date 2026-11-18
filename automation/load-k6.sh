#!/usr/bin/env bash
# Q239-Q241 : test de charge k6. Le code de sortie est non nul si un seuil est depasse (=> pipeline en echec).
# usage : load-k6.sh <dev|staging|prod|http://...> [dossier-de-sortie]
# P95_MS (defaut 1500) : seuil de latence p95 en millisecondes.
set -euo pipefail
cd "$(dirname "$0")/.."
URL=$(bash automation/url-cible.sh "${1:?env ou url}")
OUT=${2:-k6-out}; mkdir -p "$OUT"; chmod 777 "$OUT"
echo "== k6 sur $URL (seuil p95 : ${P95_MS:-1500} ms)"
docker run --rm --network host -v "$PWD/tests/load:/scripts:ro" -v "$PWD/$OUT:/out:rw" \
  -e BASE_URL="$URL" -e P95_MS="${P95_MS:-1500}" "${K6_IMAGE:-grafana/k6:latest}" \
  run --summary-export=/out/summary.json /scripts/smoke.js
