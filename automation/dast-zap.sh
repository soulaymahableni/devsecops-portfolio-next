#!/usr/bin/env bash
# Q238 : analyse dynamique OWASP ZAP (baseline : passive + spider, sans attaque active).
# usage : dast-zap.sh <dev|staging|prod|http://...> [dossier-de-sortie]
# Echec (code 1) si une alerte de risque ELEVE est trouvee (ZAP_FAIL_ON=high, defaut) ou MOYEN (medium).
set -euo pipefail
cd "$(dirname "$0")/.."
URL=$(bash automation/url-cible.sh "${1:?env ou url}")
OUT=${2:-zap-out}; mkdir -p "$OUT"; chmod 777 "$OUT"
IMAGE=${ZAP_IMAGE:-ghcr.io/zaproxy/zaproxy:stable}
echo "== ZAP baseline sur $URL"
# -I : ne pas echouer sur les simples avertissements (le seuil est applique plus bas)
docker run --rm --network host -v "$PWD/$OUT:/zap/wrk:rw" "$IMAGE" \
  zap-baseline.py -t "$URL" -J zap.json -r zap.html -I -m 2 || true
test -s "$OUT/zap.json" || { echo "rapport ZAP absent"; exit 1; }
python3 - "$OUT/zap.json" "${ZAP_FAIL_ON:-high}" <<'PY'
import json, sys
rapport, seuil = sys.argv[1], sys.argv[2]
niveaux = {"3": "High", "2": "Medium", "1": "Low", "0": "Informational"}
alertes = [a for s in json.load(open(rapport)).get("site", []) for a in s.get("alerts", [])]
print("%-8s %-14s %s" % ("RISQUE", "INSTANCES", "ALERTE"))
for a in sorted(alertes, key=lambda x: -int(x["riskcode"])):
    print("%-8s %-14s %s" % (niveaux[a["riskcode"]], a.get("count", "?"), a["name"]))
limite = 3 if seuil == "high" else 2
bloquantes = [a for a in alertes if int(a["riskcode"]) >= limite]
print("\nTotal : %d alerte(s), dont %d au niveau %s ou plus" % (len(alertes), len(bloquantes), seuil))
sys.exit(1 if bloquantes else 0)
PY
