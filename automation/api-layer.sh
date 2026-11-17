#!/usr/bin/env bash
# API 1.2 = image 1.0 + code d'observabilite + prom-client (+ dependances).
# Utilise quand le miroir Alpine est injoignable (apk add impossible).
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")/../api"
BASE=localhost:8085/portfolio/devsecops-api:1.0
IMG=localhost:8085/portfolio/devsecops-api:${1:-1.2}
CTX=$(mktemp -d); trap 'rm -rf "$CTX"' EXIT
lister() { ls -1 | grep -v '^@' || true; ls -1d @*/* 2>/dev/null || true; }
docker run --rm --entrypoint sh "$BASE" -c "cd node_modules; $(declare -f lister); lister" | sort > "$CTX/image.txt"
(cd node_modules; lister) | sort > "$CTX/hote.txt"
# seulement les paquets de PRODUCTION (l'image 1.0 est construite avec npm ci --omit=dev)
{ npm ls --omit=dev --all --parseable 2>/dev/null || true; } | sed 's#.*/node_modules/##' | sort -u > "$CTX/prod.txt"
comm -13 "$CTX/image.txt" "$CTX/hote.txt" | comm -12 - "$CTX/prod.txt" > "$CTX/nouveaux.txt"
test "$(wc -l < "$CTX/nouveaux.txt")" -le 40 || { echo "trop de paquets : verifier"; exit 1; }
test -s "$CTX/nouveaux.txt" || { echo "aucun paquet nouveau detecte"; exit 1; }
echo "== paquets ajoutes a l'image :"; cat "$CTX/nouveaux.txt"
mkdir -p "$CTX/ctx/node_modules"
cp -r src package.json package-lock.json "$CTX/ctx/"
while read -r m; do mkdir -p "$CTX/ctx/node_modules/$(dirname "$m")"; cp -r "node_modules/$m" "$CTX/ctx/node_modules/$m"; done < "$CTX/nouveaux.txt"
cat > "$CTX/ctx/Dockerfile" <<'DF'
ARG BASE
FROM ${BASE}
LABEL org.opencontainers.image.description="API 1.2 = 1.0 + observabilite (metriques, correlation) ; couche ajoutee car apk add injoignable"
COPY --chown=node:node package.json package-lock.json ./
COPY --chown=node:node src ./src
COPY --chown=node:node node_modules ./node_modules
DF
docker build -q --build-arg BASE="$BASE" -t "$IMG" "$CTX/ctx" >/dev/null
echo "== test de l'image :"
docker run --rm --entrypoint node "$IMG" -e "require('prom-client'); require('./src/observability'); console.log('prom-client et observability charges : ok')"
echo "== publication dans Harbor :"
docker push "$IMG" 2>&1 | tee /tmp/api12-push.log | tail -2
