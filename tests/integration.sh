#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "1. Démarrage de la stack"
docker compose up -d
for i in $(seq 1 60); do
  curl -sf http://localhost:3000 >/dev/null && break
  sleep 3
done

MARK="integration-$(date +%s)"
echo "2. Envoi via le frontend (3000) -> API -> PostgreSQL"
CODE=$(curl -s -o /tmp/resp.json -w "%{http_code}" -X POST http://localhost:3000/api/contact \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test CI\",\"email\":\"ci@example.com\",\"message\":\"$MARK\"}")
echo "   code HTTP : $CODE"
[ "$CODE" = "201" ] || { echo "ECHEC : code attendu 201"; cat /tmp/resp.json; exit 1; }

echo "3. Vérification en base"
COUNT=$(docker compose exec -T db psql -U portfolio -d portfolio -tAc "SELECT count(*) FROM \"Message\" WHERE message='$MARK';")
[ "$COUNT" = "1" ] || { echo "ECHEC : message absent de la base"; exit 1; }

echo "4. Requête invalide refusée par la chaîne complète"
BAD=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/contact \
  -H "Content-Type: application/json" -d '{"name":"x","email":"nope","message":"y"}')
[ "$BAD" = "400" ] || { echo "ECHEC : 400 attendu, reçu $BAD"; exit 1; }

echo "OK : frontend -> API -> PostgreSQL validé"
