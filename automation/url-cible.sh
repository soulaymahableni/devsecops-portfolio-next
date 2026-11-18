#!/usr/bin/env bash
# Affiche l'URL du frontend d'un environnement (ou renvoie telle quelle une URL http...).
# usage : url-cible.sh <dev|staging|prod|http://...>
set -euo pipefail
case "${1:?env ou url}" in
  http*) echo "$1";;
  *) NS=portfolio-$1
     IP=$(kubectl -n "$NS" get svc frontend -o jsonpath='{.spec.clusterIP}')
     PORT=$(kubectl -n "$NS" get svc frontend -o jsonpath='{.spec.ports[0].port}')
     echo "http://$IP:$PORT";;
esac
