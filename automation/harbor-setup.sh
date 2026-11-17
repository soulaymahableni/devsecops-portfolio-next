#!/usr/bin/env bash
# Q201-Q202 : projet Harbor, images, compte robot en lecture seule, imagePullSecret
set -euo pipefail
HARBOR=192.168.190.141:8085
API=http://$HARBOR/api/v2.0
read -rsp "Mot de passe admin Harbor : " HP; echo
curl -sf -o /dev/null -u "admin:$HP" $API/users/current || { echo "ECHEC : mot de passe incorrect ou Harbor injoignable"; exit 1; }

echo "== 1. projet prive portfolio =="
code=$(curl -s -o /dev/null -w '%{http_code}' -u "admin:$HP" -X POST $API/projects \
  -H 'Content-Type: application/json' -d '{"project_name":"portfolio","metadata":{"public":"false"}}')
echo "HTTP $code (201 = cree, 409 = existe deja)"

echo "== 2. envoi des images =="
echo "$HP" | docker login localhost:8085 -u admin --password-stdin
for img in devsecops-portfolio devsecops-api; do
  docker tag $img:1.0 localhost:8085/portfolio/$img:1.0
  docker push localhost:8085/portfolio/$img:1.0 2>&1 | tail -1
done

echo "== 3. compte robot lecture seule =="
resp=$(curl -s -u "admin:$HP" -X POST $API/robots -H 'Content-Type: application/json' -w '\n%{http_code}' -d '{
  "name":"k3s-pull","description":"lecture seule pour K3s (Q202)","duration":-1,
  "level":"project","disable":false,
  "permissions":[{"kind":"project","namespace":"portfolio","access":[{"resource":"repository","action":"pull"}]}]}')
code=$(echo "$resp" | tail -1); body=$(echo "$resp" | sed '$d')
if [ "$code" != "201" ]; then echo "ECHEC robot : HTTP $code"; echo "$body" | head -c 300; echo; echo "(409 = le robot existe deja : supprime-le dans l'interface Harbor puis relance)"; exit 1; fi
RN=$(echo "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin)["name"])')
RS=$(echo "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin)["secret"])')
echo "robot cree : $RN"

echo "== 4. imagePullSecret harbor-pull (namespace portfolio) =="
kubectl create secret docker-registry harbor-pull -n portfolio \
  --docker-server=$HARBOR --docker-username="$RN" --docker-password="$RS" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "== 5. le robot peut-il LIRE (pull) ? =="
curl -s -o /dev/null -w "lecture avec le robot : HTTP %{http_code} (200 attendu)\n" -u "$RN:$RS" http://$HARBOR/v2/portfolio/devsecops-api/tags/list

echo "== 6. contenu du projet =="
curl -s -u "admin:$HP" "$API/projects/portfolio/repositories" | python3 -c '
import sys, json
for r in json.load(sys.stdin): print(" ", r["name"], "| artefacts :", r["artifact_count"])'

echo "== 7. Cosign =="
cosign version 2>&1 | grep -E "GitVersion" || true
find ~ -maxdepth 3 -name "cosign.key" 2>/dev/null | head -3
echo "FIN : lot B etape 1 terminee"
