#!/usr/bin/env bash
# Q148 : crée le Secret Kubernetes (valeur sensible de démonstration) sans jamais l'écrire dans Git.
# Le mot de passe est aléatoire et n'est pas affiché. Si le Secret existe déjà, rien n'est modifié.
set -euo pipefail

NS=portfolio
DIR="$(cd "$(dirname "$0")" && pwd)"

kubectl apply -f "$DIR/00-namespace.yaml"

if kubectl get secret portfolio-secret -n "$NS" >/dev/null 2>&1; then
  echo "Secret portfolio-secret déjà présent : inchangé."
  exit 0
fi

PASS="$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)"
kubectl create secret generic portfolio-secret -n "$NS" --from-literal=POSTGRES_PASSWORD="$PASS"
echo "Secret portfolio-secret créé (mot de passe aléatoire, non affiché)."
